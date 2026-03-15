#!/usr/bin/env bash
set -Eeuo pipefail

# Install from a clone cache produced by collect-from-machine.sh (no profile/manifests).
# Usage: ./install-from-clone-cache.sh [path-to-clone-cache]
# Default: same directory as this script, subdir clone-cache/

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CACHE_ROOT="${1:-$SCRIPT_DIR/clone-cache}"
APT_DIR="$CACHE_ROOT/apt"
SNAP_DIR="$CACHE_ROOT/snap"
FLATPAK_DIR="$CACHE_ROOT/flatpak"
PIP_DIR="$CACHE_ROOT/pip"
PIPX_DIR="$CACHE_ROOT/pipx"
MANUAL_DIR="$CACHE_ROOT/vendor"

log()  { printf '[%s] %s\n' "$(date '+%F %T')" "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }

[[ -d "$CACHE_ROOT" ]] || { echo "Clone cache not found: $CACHE_ROOT" >&2; exit 1; }

if [[ -f "$CACHE_ROOT/SHA256SUMS" ]]; then
  log "Verifying checksums"
  (cd "$CACHE_ROOT" && sha256sum -c SHA256SUMS) || log "WARN: checksum verification had errors; continuing."
fi

# APT from archives + apt-manual.txt
if [[ -d "$APT_DIR/archives" && -f "$APT_DIR/apt-manual.txt" ]]; then
  log "Installing APT packages from clone cache"
  mapfile -t APT_MANUAL < "$APT_DIR/apt-manual.txt"
  if ((${#APT_MANUAL[@]} > 0)); then
    sudo apt-get \
      -o Dir::Cache::archives="$APT_DIR/archives" \
      -o Acquire::Languages=none \
      --no-download -y install "${APT_MANUAL[@]}" \
      || {
        log "APT install had issues; attempting dpkg -i + fix"
        sudo dpkg -i "$APT_DIR/archives/"*.deb 2>/dev/null || true
        sudo apt-get -o Dir::Cache::archives="$APT_DIR/archives" --no-download -f -y install
      }
  fi
fi

# Snap: ack asserts then install .snap
if have snap && compgen -G "$SNAP_DIR/*.assert" >/dev/null 2>&1; then
  log "Installing snaps from clone cache"
  for assert_file in "$SNAP_DIR"/*.assert; do
    sudo snap ack "$assert_file" 2>/dev/null || true
  done
  for snap_file in "$SNAP_DIR"/*.snap; do
    [[ -f "$snap_file" ]] || continue
    sudo snap install "$snap_file" --dangerous 2>/dev/null || log "WARN: failed to install snap $snap_file"
  done
fi

# Flatpak bundles
if have flatpak && compgen -G "$FLATPAK_DIR/*.flatpak" >/dev/null 2>&1; then
  log "Installing flatpak bundles from clone cache"
  for bundle in "$FLATPAK_DIR"/*.flatpak; do
    [[ -f "$bundle" ]] || continue
    flatpak install -y "$bundle" 2>/dev/null || log "WARN: failed to install flatpak bundle $bundle"
  done
fi

# Pip user from wheelhouse
if have python3 && [[ -d "$PIP_DIR/wheelhouse" && -f "$PIP_DIR/pip-user-freeze.txt" ]]; then
  log "Installing pip user packages from clone cache"
  python3 -m pip install --user --no-index --find-links "$PIP_DIR/wheelhouse" -r "$PIP_DIR/pip-user-freeze.txt" \
    || log "WARN: some pip packages could not be installed offline"
fi

# Pipx from wheelhouse
if have pipx && [[ -d "$PIPX_DIR/wheelhouse" && -f "$PIPX_DIR/pipx-specs.txt" ]]; then
  log "Installing pipx packages from clone cache"
  while IFS= read -r spec; do
    [[ -z "$spec" ]] && continue
    pipx install "$spec" --pip-args="--no-index --find-links $PIPX_DIR/wheelhouse" \
      || log "WARN: failed to install pipx package $spec offline"
  done < "$PIPX_DIR/pipx-specs.txt"
fi

# Vendor: remind user to run manually
if [[ -d "$MANUAL_DIR" ]]; then
  log "Manual installer directory: $MANUAL_DIR — review and run vendor installers as needed."
fi

log "Clone-cache installation pass completed."
