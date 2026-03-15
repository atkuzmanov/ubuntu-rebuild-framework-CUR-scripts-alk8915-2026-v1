#!/usr/bin/env bash
set -Eeuo pipefail

# Clone-this-machine: capture what's installed on the current system into a cache
# for offline install on another machine. No profile or manifests; uses live system state.
# Usage: ./collect-from-machine.sh [output-dir]
# Default output: offline-bundle/clone-cache/

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUNDLE_DIR="$(cd "$SCRIPT_DIR" && pwd)"
ROOT_DIR="$(cd "$BUNDLE_DIR/.." && pwd)"
CACHE_ROOT="${1:-$BUNDLE_DIR/clone-cache}"
# User to own cache files (in case sudo creates root-owned files); used for chown at end
CACHE_OWNER_UID="${SUDO_UID:-$(id -u)}"
CACHE_OWNER_GID="${SUDO_GID:-$(id -g)}"

APT_DIR="$CACHE_ROOT/apt"
SNAP_DIR="$CACHE_ROOT/snap"
FLATPAK_DIR="$CACHE_ROOT/flatpak"
PIP_DIR="$CACHE_ROOT/pip"
PIPX_DIR="$CACHE_ROOT/pipx"
MANUAL_DIR="$CACHE_ROOT/vendor"
META_DIR="$CACHE_ROOT/meta"
LOG_DIR="$CACHE_ROOT/logs"

if [[ -f "$ROOT_DIR/lib/common.sh" && -f "$ROOT_DIR/lib/logging.sh" ]]; then
  export RUN_LOG="${RUN_LOG:-/dev/null}"
  source "$ROOT_DIR/lib/common.sh"
  source "$ROOT_DIR/lib/logging.sh"
  log_info "Clone-from-machine: writing cache to $CACHE_ROOT"
else
  log_info() { printf '[%s] %s\n' "$(date '+%F %T')" "$*"; }
  log_warn() { printf '[%s] WARN: %s\n' "$(date '+%F %T')" "$*" >&2; }
fi

have() { command -v "$1" >/dev/null 2>&1; }
save_cmd_output() {
  local outfile="$1"; shift
  if "$@" >"$outfile" 2>"$outfile.stderr"; then :; else log_warn "command failed: $*"; fi
}

mkdir -p "$APT_DIR/archives/partial" "$SNAP_DIR" "$FLATPAK_DIR" "$PIP_DIR/wheelhouse" \
         "$PIPX_DIR/wheelhouse" "$MANUAL_DIR" "$META_DIR" "$LOG_DIR"

UBUNTU_CODENAME="$(. /etc/os-release 2>/dev/null && printf '%s' "${VERSION_CODENAME:-unknown}")"
TIMESTAMP="$(date +%F-%H%M%S)"
cat > "$META_DIR/collection-info.txt" <<META
mode=clone-from-machine
collection_timestamp=$TIMESTAMP
ubuntu_codename=$UBUNTU_CODENAME
hostname=$(hostname)
kernel=$(uname -r)
META

save_cmd_output "$META_DIR/os-release.txt" cat /etc/os-release
save_cmd_output "$META_DIR/uname-a.txt" uname -a
save_cmd_output "$META_DIR/dpkg-query.txt" dpkg-query -W -f='${binary:Package}\t${Version}\n' 2>/dev/null || true

# APT: manual packages + download into archives
log_info "Saving APT package list (apt-mark showmanual)"
apt-mark showmanual 2>/dev/null | sort -u > "$APT_DIR/apt-manual.txt" || true
dpkg --get-selections > "$APT_DIR/dpkg-selections.txt" 2>/dev/null || true

if [[ -s "$APT_DIR/apt-manual.txt" ]]; then
  log_info "Downloading APT packages and dependencies into local cache"
  sudo apt-get update
  mapfile -t APT_MANUAL < "$APT_DIR/apt-manual.txt"
  if ((${#APT_MANUAL[@]} > 0)); then
    # --reinstall forces download of .deb files even when packages are already installed
    sudo apt-get \
      -o Dir::Cache::archives="$APT_DIR/archives" \
      -o APT::Keep-Downloaded-Packages=true \
      -y --download-only --reinstall install "${APT_MANUAL[@]}" \
      | tee "$LOG_DIR/apt-download.log" || log_warn "Some APT packages could not be downloaded"
  fi
fi

# Snap: list then download each
if have snap; then
  log_info "Saving snap manifest and downloading snaps"
  snap list --all > "$SNAP_DIR/snap-list.txt" 2>/dev/null || true
  awk 'NR>1 {print $1}' "$SNAP_DIR/snap-list.txt" 2>/dev/null | sort -u > "$SNAP_DIR/snap-names.txt" || true
  if [[ -s "$SNAP_DIR/snap-names.txt" ]]; then
    while IFS= read -r snap_name; do
      [[ -z "$snap_name" ]] && continue
      log_info "Downloading snap: $snap_name"
      (cd "$SNAP_DIR" && snap download "$snap_name") || log_warn "Could not download snap $snap_name"
    done < "$SNAP_DIR/snap-names.txt"
  fi
fi

# Flatpak: list apps, then build bundle from correct repo (user or system)
if have flatpak; then
  log_info "Saving flatpak manifest and building bundles"
  flatpak list --app --columns=application,branch,installation > "$FLATPAK_DIR/flatpak-apps.tsv" 2>/dev/null || true
  while IFS=$'\t' read -r app_id branch installation; do
    [[ -z "${app_id:-}" ]] && continue
    [[ "$app_id" == "Application ID" ]] && continue
    bundle_name="${app_id//\//_}-${branch:-stable}-${installation:-system}.flatpak"
    repo_path=""
    if [[ "$installation" == "user" ]]; then
      repo_path="$HOME/.local/share/flatpak/repo"
    else
      repo_path="/var/lib/flatpak/repo"
    fi
    if [[ -d "$repo_path" ]]; then
      log_info "Bundling flatpak: $app_id ($installation)"
      flatpak build-bundle "$repo_path" "$FLATPAK_DIR/$bundle_name" "$app_id" "${branch:-stable}" \
        || log_warn "Could not bundle flatpak $app_id"
    else
      log_warn "Flatpak repo not found: $repo_path"
    fi
  done < "$FLATPAK_DIR/flatpak-apps.tsv" 2>/dev/null || true
fi

# Pip user packages
if have python3 && python3 -m pip --version >/dev/null 2>&1; then
  log_info "Saving pip user manifest and downloading wheels"
  python3 -m pip freeze --user > "$PIP_DIR/pip-user-freeze.txt" 2>/dev/null || true
  if [[ -s "$PIP_DIR/pip-user-freeze.txt" ]]; then
    python3 -m pip download -r "$PIP_DIR/pip-user-freeze.txt" -d "$PIP_DIR/wheelhouse" \
      | tee "$LOG_DIR/pip-download.log" || log_warn "Some pip wheels could not be downloaded"
  fi
fi

# Pipx: list -> specs -> download wheels
if have pipx; then
  log_info "Saving pipx manifest and downloading wheels"
  pipx list --json > "$PIPX_DIR/pipx-list.json" 2>/dev/null || true
  if [[ -f "$PIPX_DIR/pipx-list.json" ]]; then
    python3 - "$PIPX_DIR/pipx-list.json" "$PIPX_DIR/pipx-specs.txt" <<'PY' 2>/dev/null || true
import json, sys
src, dst = sys.argv[1], sys.argv[2]
with open(src, 'r', encoding='utf-8') as f:
    data = json.load(f)
packages = data.get('venvs', {})
with open(dst, 'w', encoding='utf-8') as out:
    for name, meta in sorted(packages.items()):
        spec = meta.get('metadata', {}).get('main_package', {}).get('package_or_url') or name
        out.write(spec + '\n')
PY
    if [[ -s "$PIPX_DIR/pipx-specs.txt" ]]; then
      python3 -m pip download -d "$PIPX_DIR/wheelhouse" $(tr '\n' ' ' < "$PIPX_DIR/pipx-specs.txt") \
        | tee "$LOG_DIR/pipx-download.log" || log_warn "Some pipx wheels could not be downloaded"
    fi
  fi
fi

# Copy obvious installers from Downloads
log_info "Copying manual installers from ~/Downloads (if present)"
find "$HOME/Downloads" -maxdepth 1 -type f \( \
  -iname '*.deb' -o -iname '*.AppImage' -o -iname '*.run' -o -iname '*.sh' \
  -o -iname '*.tar.gz' -o -iname '*.tar.xz' -o -iname '*.zip' \
\) -print0 2>/dev/null | while IFS= read -r -d '' file; do
  cp -n "$file" "$MANUAL_DIR/" 2>/dev/null || true
done

cat > "$MANUAL_DIR/README.txt" <<'TXT'
Manual installers (from clone). Add vendor .deb, AppImages, etc. here.
See MANUAL-SOFTWARE-NOTES.txt for install steps.
TXT
[[ -f "$MANUAL_DIR/MANUAL-SOFTWARE-NOTES.txt" ]] || printf '%s\n' "# Add notes: installer name, how to install, root/license/post-install" > "$MANUAL_DIR/MANUAL-SOFTWARE-NOTES.txt"

# Any root-owned files (e.g. apt/archives from sudo apt-get) must be owned by the invoker so find/sha256sum and copying work
log_info "Fixing cache ownership"
sudo chown -R "$CACHE_OWNER_UID:$CACHE_OWNER_GID" "$CACHE_ROOT" 2>/dev/null || true

# Checksums
log_info "Creating SHA256SUMS"
(cd "$CACHE_ROOT" && find . -type f ! -name 'SHA256SUMS' -print0 | sort -z | xargs -0 sha256sum > SHA256SUMS) || true

log_info "Clone cache created at: $CACHE_ROOT"
log_info "Copy clone-cache/ and install-from-clone-cache.sh to target; run: ./install-from-clone-cache.sh $CACHE_ROOT"
