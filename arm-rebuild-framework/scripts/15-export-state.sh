#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export RUN_LOG="${RUN_LOG:-/dev/null}"
source "$ROOT_DIR/lib/common.sh"

# When run from rebuild.sh, profile sets RUN_EXPORTS; when run standalone it is unset — run export in that case
if [[ -n "${RUN_EXPORTS:-}" ]] && ! want_feature RUN_EXPORTS; then
  log_info "State export skipped by profile (RUN_EXPORTS=false)"
  exit 0
fi

ensure_dir "$ROOT_DIR/state/exports"

log_info "Exporting package state"
apt-mark showmanual | sort > "$ROOT_DIR/state/exports/apt-manual-packages.txt"
dpkg --get-selections > "$ROOT_DIR/state/exports/dpkg-selections.txt" 2>/dev/null || true
snap list 2>/dev/null | awk 'NR>1 {print $1}' | sort > "$ROOT_DIR/state/exports/snap-packages.txt" || true
snap list --all 2>/dev/null > "$ROOT_DIR/state/exports/snap-list.txt" || true
flatpak list --app --columns=application 2>/dev/null | sort > "$ROOT_DIR/state/exports/flatpak-packages.txt" || true
flatpak list --app --columns=application,branch,installation 2>/dev/null > "$ROOT_DIR/state/exports/flatpak-apps.tsv" || true
pipx list --short 2>/dev/null | sort > "$ROOT_DIR/state/exports/pipx-packages.txt" || true
pipx list --json 2>/dev/null > "$ROOT_DIR/state/exports/pipx-list.json" || true
python3 -m pip freeze --user 2>/dev/null | sort > "$ROOT_DIR/state/exports/pip-user-packages.txt" || true
cargo install --list 2>/dev/null | awk -F' ' '/ v[0-9]/{print $1}' | sort -u > "$ROOT_DIR/state/exports/cargo-packages.txt" || true
uv tool list 2>/dev/null | awk '{print $1}' | sort -u > "$ROOT_DIR/state/exports/uv-tools.txt" || true
npm list -g --depth=0 2>/dev/null | sed '1,1d' | sed 's/.* //' | cut -d@ -f1 | sort -u > "$ROOT_DIR/state/exports/npm-global-packages.txt" || true

# Meta: when/where this export was taken
UBUNTU_CODENAME="$(. /etc/os-release 2>/dev/null && printf '%s' "${VERSION_CODENAME:-unknown}")"
TIMESTAMP="$(date +%F-%H%M%S)"
cat > "$ROOT_DIR/state/exports/collection-info.txt" <<META
export_timestamp=$TIMESTAMP
ubuntu_codename=$UBUNTU_CODENAME
hostname=$(hostname)
kernel=$(uname -r)
META

cp "$ROOT_DIR/state/exports/apt-manual-packages.txt" "$ROOT_DIR/manifests/apt-packages-exported.txt"
cp "$ROOT_DIR/state/exports/snap-packages.txt" "$ROOT_DIR/manifests/snap-packages-exported.txt" || true
cp "$ROOT_DIR/state/exports/flatpak-packages.txt" "$ROOT_DIR/manifests/flatpak-packages-exported.txt" || true
cp "$ROOT_DIR/state/exports/pipx-packages.txt" "$ROOT_DIR/manifests/pipx-packages-exported.txt" || true
cp "$ROOT_DIR/state/exports/pip-user-packages.txt" "$ROOT_DIR/manifests/pip-user-packages-exported.txt" || true
cp "$ROOT_DIR/state/exports/cargo-packages.txt" "$ROOT_DIR/manifests/cargo-packages-exported.txt" || true
cp "$ROOT_DIR/state/exports/uv-tools.txt" "$ROOT_DIR/manifests/uv-tools-exported.txt" || true
cp "$ROOT_DIR/state/exports/npm-global-packages.txt" "$ROOT_DIR/manifests/npm-global-packages-exported.txt" || true

log_warn "Exports written to state/exports/ and manifests/*-exported.txt. To update manifests: diff the files, then cp manifests/*-exported.txt manifests/*.txt if satisfied. apt-mark showmanual can include transitional and dependency-shaped packages—review before committing."
