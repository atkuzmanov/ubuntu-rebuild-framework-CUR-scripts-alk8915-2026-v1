#!/usr/bin/env bash
set -Eeuo pipefail

# Run when OFFLINE. Installs all packages from cache/ (populated by download-bundle.sh).
# Usage: ./install-from-bundle.sh --profile <laptop|workstation|vm>
# Run from the offline-bundle directory (e.g. from mounted USB/HDD).

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUNDLE_DIR="$(cd "$SCRIPT_DIR" && pwd)"
ROOT_DIR="$(cd "$BUNDLE_DIR/.." && pwd)"
CACHE_DIR="$BUNDLE_DIR/cache"

[[ -d "$CACHE_DIR" ]] || { echo "Error: cache/ not found. Run download-bundle.sh first when online."; exit 1; }

source "$ROOT_DIR/lib/common.sh"
source "$ROOT_DIR/lib/logging.sh"

PROFILE=""
usage() {
  echo "Usage: $0 --profile <name>"
  echo "  Installs all software from cache/ (offline mode)."
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile) PROFILE="${2:-}"; shift 2 ;;
    -h|--help) usage ;;
    *) log_error "Unknown: $1"; usage ;;
  esac
done

[[ -n "$PROFILE" ]] || usage
PROFILE_FILE="$ROOT_DIR/profiles/${PROFILE}.env"
[[ -f "$PROFILE_FILE" ]] || die "Profile not found: $PROFILE_FILE"
load_profile "$PROFILE_FILE"
log_info "Installing from offline bundle for profile: $PROFILE"

# ---------------------------------------------------------------------------
# 1. APT: add local repo and install
# ---------------------------------------------------------------------------
log_section "APT: installing from local cache"
if [[ -f "$CACHE_DIR/apt/Packages.gz" ]] && ls "$CACHE_DIR/apt/"*.deb >/dev/null 2>&1; then
  # Install GPG keys if we have them (for any repo-add steps)
  if [[ -d "$CACHE_DIR/apt-keys" ]] && ls "$CACHE_DIR/apt-keys/"* >/dev/null 2>&1; then
    run_cmd sudo install -d -m 0755 /etc/apt/keyrings
    run_cmd sudo cp -n "$CACHE_DIR/apt-keys/"* /etc/apt/keyrings/ 2>/dev/null || true
  fi

  # Add local deb directory as apt source
  local_repo="deb [trusted=yes] file://$CACHE_DIR/apt ./"
  echo "$local_repo" | run_cmd sudo tee /etc/apt/sources.list.d/offline-bundle.list
  # Update (may fail for network sources if offline - our file:// repo will still be indexed)
  run_cmd sudo apt-get update || log_warn "apt-get update had errors (expected if offline); continuing..."

  # Build package list (same logic as download script)
  apt_pkgs=()
  while IFS= read -r pkg; do
    [[ -z "$pkg" || "$pkg" =~ ^# ]] && continue
    case "$pkg" in
      cups|system-config-printer|printer-driver-brlaser) want_feature ENABLE_PRINTER_SUPPORT || continue ;;
      simple-scan) want_feature ENABLE_SCANNER_SUPPORT || continue ;;
      timeshift|duplicity|borgbackup|restic|rclone) want_feature ENABLE_BACKUP_TOOLS || continue ;;
      vlc|gimp|imagemagick) want_feature ENABLE_MEDIA_TOOLS || continue ;;
      podman) want_feature ENABLE_VIRTUALIZATION_TOOLS || want_feature ENABLE_DOCKER || continue ;;
    esac
    apt_pkgs+=("$pkg")
  done < "$ROOT_DIR/manifests/apt-packages.txt"
  if want_feature ENABLE_DOCKER; then
    apt_pkgs+=(docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin)
  fi
  if want_feature INSTALL_KALI_SAFE_TOOLS && [[ -f "$ROOT_DIR/manifests/kali-safe-apt-packages.txt" ]]; then
    while IFS= read -r pkg; do
      [[ -z "$pkg" || "$pkg" =~ ^# ]] && continue
      apt_pkgs+=("$pkg")
    done < "$ROOT_DIR/manifests/kali-safe-apt-packages.txt"
  fi

  # Install from local repo (file:// - no network needed)
  run_cmd sudo apt-get install -y --allow-unauthenticated "${apt_pkgs[@]}"
  # Fix any broken deps
  run_cmd sudo apt-get install -f -y 2>/dev/null || true
else
  log_warn "No apt cache found; skipping apt install"
fi

# ---------------------------------------------------------------------------
# 2. SNAP: install from local .snap files
# ---------------------------------------------------------------------------
if want_feature INSTALL_SNAPS && command -v snap >/dev/null 2>&1; then
  log_section "Snap: installing from cache"
  # Build map of pkg -> args from manifest (e.g. code -> --classic)
  declare -A snap_args
  while IFS='|' read -r pkg args _; do
    [[ -z "$pkg" || "$pkg" =~ ^# ]] && continue
    snap_args["$pkg"]="$args"
  done < "$ROOT_DIR/manifests/snap-packages.txt"

  for snapfile in "$CACHE_DIR/snap/"*.snap; do
    [[ -f "$snapfile" ]] || continue
    base="$(basename "$snapfile" .snap)"
    pkg="${base%%_*}"  # code_123 -> code
    if snap list "$pkg" >/dev/null 2>&1; then
      log_info "Snap already installed: $pkg"
    else
      assertfile="${snapfile%.snap}.assert"
      if [[ -f "$assertfile" ]]; then
        run_cmd sudo snap ack "$assertfile"
      fi
      extra="${snap_args[$pkg]:-}"
      if [[ -n "$extra" ]]; then
        run_cmd sudo snap install "$snapfile" $extra 2>/dev/null || run_cmd sudo snap install "$snapfile" --dangerous $extra
      else
        run_cmd sudo snap install "$snapfile" 2>/dev/null || run_cmd sudo snap install "$snapfile" --dangerous
      fi
    fi
  done
fi

# ---------------------------------------------------------------------------
# 3. FLATPAK: install from .flatpak bundles
# ---------------------------------------------------------------------------
if want_feature INSTALL_FLATPAKS && command -v flatpak >/dev/null 2>&1; then
  log_section "Flatpak: installing from bundles"
  for bundle in "$CACHE_DIR/flatpak/"*.flatpak; do
    [[ -f "$bundle" ]] || continue
    run_cmd flatpak install -y --or-update "$bundle"
  done
fi

# ---------------------------------------------------------------------------
# 4. PIPX: install from wheels
# ---------------------------------------------------------------------------
if want_feature INSTALL_PIPX && command -v pipx >/dev/null 2>&1; then
  log_section "Pipx: installing from cache"
  while IFS= read -r app; do
    [[ -z "$app" || "$app" =~ ^# ]] && continue
    if pipx list --short 2>/dev/null | grep -Fxq "$app"; then
      log_info "pipx app already installed: $app"
    else
      whl="$(ls "$CACHE_DIR/pipx/"*"${app}"*.whl "$CACHE_DIR/pipx/${app}"*.whl 2>/dev/null | head -1)"
      if [[ -n "$whl" && -f "$whl" ]]; then
        run_cmd pipx install "$whl"
      else
        log_warn "No wheel found for pipx: $app"
      fi
    fi
  done < "$ROOT_DIR/manifests/pipx-packages.txt"
fi

# ---------------------------------------------------------------------------
# 5. UV: install tools from wheels
# ---------------------------------------------------------------------------
if want_feature INSTALL_UV_TOOLS && command -v uv >/dev/null 2>&1; then
  log_section "UV: installing tools from cache"
  while IFS= read -r app; do
    [[ -z "$app" || "$app" =~ ^# ]] && continue
    if uv tool list 2>/dev/null | awk '{print $1}' | grep -Fxq "$app"; then
      log_info "uv tool already installed: $app"
    else
      whl="$(ls "$CACHE_DIR/uv/"*"${app}"*.whl "$CACHE_DIR/uv/${app}"*.whl 2>/dev/null | head -1)"
      if [[ -n "$whl" && -f "$whl" ]]; then
        run_cmd uv tool install "$whl"
      else
        log_warn "No wheel found for uv: $app"
      fi
    fi
  done < "$ROOT_DIR/manifests/uv-tools.txt"
fi

# ---------------------------------------------------------------------------
# 6. NPM: install from packed tarballs
# ---------------------------------------------------------------------------
if want_feature INSTALL_NPM_GLOBAL && command -v npm >/dev/null 2>&1; then
  log_section "NPM: installing from cache"
  for tgz in "$CACHE_DIR/npm/"*.tgz; do
    [[ -f "$tgz" ]] || continue
    run_cmd sudo npm install -g "$tgz"
  done
fi

# ---------------------------------------------------------------------------
# 7. CARGO: limited offline (would need vendored registry)
# ---------------------------------------------------------------------------
if want_feature INSTALL_CARGO && command -v cargo >/dev/null 2>&1; then
  if [[ -d "$CACHE_DIR/cargo/registry" ]]; then
    log_section "Cargo: installing from cached registry"
    export CARGO_HOME="$CACHE_DIR/cargo"
    while IFS= read -r app; do
      [[ -z "$app" || "$app" =~ ^# ]] && continue
      if command -v "$app" >/dev/null 2>&1; then
        log_info "cargo app already present: $app"
      else
        run_cmd cargo install "$app" --offline 2>/dev/null || log_warn "Cargo install failed (offline): $app"
      fi
    done < "$ROOT_DIR/manifests/cargo-packages.txt"
    unset CARGO_HOME
  else
    log_warn "No cargo registry cache; cargo packages require network"
  fi
fi

# ---------------------------------------------------------------------------
# 8. VENDOR: install manual .deb and AppImages
# ---------------------------------------------------------------------------
if want_feature INSTALL_MANUAL_APPS; then
  log_section "Vendor: installing from cache"
  for deb in "$CACHE_DIR/vendor/"*.deb; do
    [[ -f "$deb" ]] && run_cmd sudo dpkg -i "$deb" 2>/dev/null || true
  done
  run_cmd sudo apt-get install -f -y 2>/dev/null || true
  for appimg in "$CACHE_DIR/vendor/"*.AppImage; do
    [[ -f "$appimg" ]] && run_cmd chmod +x "$appimg" && run_cmd mkdir -p "$HOME/Applications" && run_cmd cp "$appimg" "$HOME/Applications/"
  done
fi

log_section "Offline installation complete"
log_info "Review manifests/manual-downloads.txt for any apps that need manual setup."
