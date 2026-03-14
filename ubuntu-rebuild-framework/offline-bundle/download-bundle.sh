#!/usr/bin/env bash
set -Eeuo pipefail

# Run when ONLINE. Downloads all packages from manifests into cache/ for offline use.
# Usage: ./download-bundle.sh --profile <laptop|workstation|vm>

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUNDLE_DIR="$(cd "$SCRIPT_DIR" && pwd)"
ROOT_DIR="$(cd "$BUNDLE_DIR/.." && pwd)"
CACHE_DIR="$BUNDLE_DIR/cache"

source "$ROOT_DIR/lib/common.sh"
source "$ROOT_DIR/lib/logging.sh"

PROFILE=""
usage() {
  echo "Usage: $0 --profile <name>"
  echo "  Downloads all software from manifests into cache/ for offline installation."
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
log_info "Creating offline bundle for profile: $PROFILE"

# Create cache directories
for d in apt apt-keys snap flatpak pipx uv npm cargo vendor; do
  mkdir -p "$CACHE_DIR/$d"
done

# ---------------------------------------------------------------------------
# 1. APT: configure repos, update, download packages
# ---------------------------------------------------------------------------
log_section "APT: configuring repos and downloading packages"
source "$ROOT_DIR/manifests/apt-repositories.sh"
configure_docker_repo || true
configure_helm_repo || true
configure_brave_repo || true
run_cmd sudo apt-get update

# Collect GPG keys for later (in case target needs them for repo setup)
if [[ -d /etc/apt/keyrings ]]; then
  run_cmd sudo cp -n /etc/apt/keyrings/* "$CACHE_DIR/apt-keys/" 2>/dev/null || true
fi

# Build apt package list (mirror logic from 03-install-apt.sh)
apt_pkgs=()
while IFS= read -r pkg; do
  [[ -z "$pkg" || "$pkg" =~ ^# ]] && continue
  case "$pkg" in
    cups|system-config-printer|printer-driver-brlaser)
      want_feature ENABLE_PRINTER_SUPPORT || continue ;;
    simple-scan)
      want_feature ENABLE_SCANNER_SUPPORT || continue ;;
    timeshift|duplicity|borgbackup|restic|rclone)
      want_feature ENABLE_BACKUP_TOOLS || continue ;;
    vlc|gimp|imagemagick)
      want_feature ENABLE_MEDIA_TOOLS || continue ;;
    podman)
      want_feature ENABLE_VIRTUALIZATION_TOOLS || want_feature ENABLE_DOCKER || continue ;;
  esac
  apt_pkgs+=("$pkg")
done < "$ROOT_DIR/manifests/apt-packages.txt"

if want_feature ENABLE_DOCKER; then
  apt_pkgs+=(docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin)
fi

# Kali-safe tools
if want_feature INSTALL_KALI_SAFE_TOOLS && [[ -f "$ROOT_DIR/manifests/kali-safe-apt-packages.txt" ]]; then
  while IFS= read -r pkg; do
    [[ -z "$pkg" || "$pkg" =~ ^# ]] && continue
    apt_pkgs+=("$pkg")
  done < "$ROOT_DIR/manifests/kali-safe-apt-packages.txt"
fi

# Download with dependencies into cache/apt
log_info "Downloading ${#apt_pkgs[@]} apt packages and dependencies"
run_cmd sudo apt-get install -y --download-only "${apt_pkgs[@]}"
run_cmd sudo bash -c "cp -n /var/cache/apt/archives/*.deb '$CACHE_DIR/apt/' 2>/dev/null || true"

# Create local apt repo index
require_command dpkg-scanpackages || run_cmd sudo apt-get install -y dpkg-dev
log_info "Creating apt package index"
(cd "$CACHE_DIR/apt" && dpkg-scanpackages . /dev/null 2>/dev/null | gzip -9c > Packages.gz) || true

# ---------------------------------------------------------------------------
# 2. SNAP: download each package
# ---------------------------------------------------------------------------
if want_feature INSTALL_SNAPS; then
  log_section "Snap: downloading packages"
  while IFS='|' read -r pkg args flag; do
    [[ -z "$pkg" || "$pkg" =~ ^# ]] && continue
    [[ -n "$flag" ]] && ! want_feature "$flag" && continue
    log_info "Downloading snap: $pkg"
    (cd "$CACHE_DIR/snap" && snap download "$pkg" $args 2>/dev/null) || log_warn "Snap download failed: $pkg"
  done < "$ROOT_DIR/manifests/snap-packages.txt"
fi

# ---------------------------------------------------------------------------
# 3. FLATPAK: install then build bundles
# ---------------------------------------------------------------------------
if want_feature INSTALL_FLATPAKS && command -v flatpak >/dev/null 2>&1; then
  log_section "Flatpak: installing and creating bundles"
  flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
  while IFS='|' read -r pkg flag; do
    [[ -z "$pkg" || "$pkg" =~ ^# ]] && continue
    [[ -n "$flag" ]] && ! want_feature "$flag" && continue
    log_info "Installing and bundling flatpak: $pkg"
    flatpak install -y flathub "$pkg" 2>/dev/null || log_warn "Flatpak install failed: $pkg"
    if flatpak info "$pkg" >/dev/null 2>&1; then
      ref="$(flatpak info --show-ref "$pkg" 2>/dev/null)"
      if [[ -n "$ref" ]]; then
        run_cmd flatpak build-bundle /var/lib/flatpak/repo "$CACHE_DIR/flatpak/${pkg//[^a-zA-Z0-9._-]/_}.flatpak" "$ref" 2>/dev/null || log_warn "Flatpak bundle failed: $pkg"
      fi
    fi
  done < "$ROOT_DIR/manifests/flatpak-packages.txt"
fi

# ---------------------------------------------------------------------------
# 4. PIPX: download wheels
# ---------------------------------------------------------------------------
if want_feature INSTALL_PIPX && command -v pip >/dev/null 2>&1; then
  log_section "Pipx: downloading wheels"
  while IFS= read -r app; do
    [[ -z "$app" || "$app" =~ ^# ]] && continue
    log_info "Downloading pipx wheel: $app"
    pip download "$app" -d "$CACHE_DIR/pipx" 2>/dev/null || log_warn "Pip download failed: $app"
  done < "$ROOT_DIR/manifests/pipx-packages.txt"
fi

# ---------------------------------------------------------------------------
# 5. UV: download tool wheels
# ---------------------------------------------------------------------------
if want_feature INSTALL_UV_TOOLS && command -v uv >/dev/null 2>&1; then
  log_section "UV: downloading tools"
  while IFS= read -r app; do
    [[ -z "$app" || "$app" =~ ^# ]] && continue
    log_info "Downloading uv tool: $app"
    pip download "$app" -d "$CACHE_DIR/uv" 2>/dev/null || log_warn "UV/pip download failed: $app"
  done < "$ROOT_DIR/manifests/uv-tools.txt"
fi

# ---------------------------------------------------------------------------
# 6. NPM: pack global packages
# ---------------------------------------------------------------------------
if want_feature INSTALL_NPM_GLOBAL && command -v npm >/dev/null 2>&1; then
  log_section "NPM: packing packages"
  while IFS= read -r app; do
    [[ -z "$app" || "$app" =~ ^# ]] && continue
    log_info "Packing npm: $app"
    (cd "$CACHE_DIR/npm" && npm pack "$app" 2>/dev/null) || log_warn "NPM pack failed: $app"
  done < "$ROOT_DIR/manifests/npm-global-packages.txt"
fi

# ---------------------------------------------------------------------------
# 7. CARGO: copy registry cache (run 'cargo install <pkg>' for each first to populate)
# ---------------------------------------------------------------------------
if want_feature INSTALL_CARGO && command -v cargo >/dev/null 2>&1; then
  log_section "Cargo: copying registry cache"
  # Pre-fetch crates by running install (downloads to ~/.cargo/registry)
  while IFS= read -r app; do
    [[ -z "$app" || "$app" =~ ^# ]] && continue
    log_info "Fetching cargo crate: $app"
    cargo install "$app" 2>/dev/null || log_warn "Cargo install failed: $app"
  done < "$ROOT_DIR/manifests/cargo-packages.txt"
  if [[ -d "$HOME/.cargo/registry" ]]; then
    log_info "Copying cargo registry to bundle"
    run_cmd cp -a "$HOME/.cargo/registry" "$CACHE_DIR/cargo/" 2>/dev/null || log_warn "Could not copy cargo registry"
  else
    log_warn "No cargo registry found; run 'cargo install <pkg>' for each manifest entry first"
  fi
fi

# ---------------------------------------------------------------------------
# 8. VENDOR: copy manual installers
# ---------------------------------------------------------------------------
if [[ -n "${OFFLINE_VENDOR_SOURCE_DIR:-}" && -d "$OFFLINE_VENDOR_SOURCE_DIR" ]]; then
  log_section "Vendor: copying from $OFFLINE_VENDOR_SOURCE_DIR"
  run_cmd cp -a "$OFFLINE_VENDOR_SOURCE_DIR"/* "$CACHE_DIR/vendor/" 2>/dev/null || true
fi

log_section "Download complete"
log_info "Cache size: $(du -sh "$CACHE_DIR" 2>/dev/null | cut -f1)"
log_info "Copy the entire offline-bundle folder to external storage (USB/HDD)."
log_info "On target machine, run: ./install-from-bundle.sh --profile $PROFILE"
