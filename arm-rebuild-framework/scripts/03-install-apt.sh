#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/lib/common.sh"

manifest="$ROOT_DIR/manifests/apt-packages.txt"
[[ -f "$manifest" ]] || die "Missing manifest: $manifest"

log_info "Installing APT packages from $manifest"
while IFS= read -r pkg; do
  [[ -z "$pkg" || "$pkg" =~ ^# ]] && continue

  case "$pkg" in
    cups|system-config-printer|printer-driver-brlaser)
      want_feature ENABLE_PRINTER_SUPPORT || { log_info "Skipping $pkg due to profile"; continue; }
      ;;
    simple-scan)
      want_feature ENABLE_SCANNER_SUPPORT || { log_info "Skipping $pkg due to profile"; continue; }
      ;;
    timeshift|duplicity|borgbackup|restic|rclone)
      want_feature ENABLE_BACKUP_TOOLS || { log_info "Skipping $pkg due to profile"; continue; }
      ;;
    vlc|gimp|imagemagick)
      want_feature ENABLE_MEDIA_TOOLS || { log_info "Skipping $pkg due to profile"; continue; }
      ;;
    podman)
      want_feature ENABLE_VIRTUALIZATION_TOOLS || want_feature ENABLE_DOCKER || { log_info "Skipping $pkg due to profile"; continue; }
      ;;
  esac

  install_apt_pkg "$pkg"
done < "$manifest"

if want_feature ENABLE_DOCKER; then
  for pkg in docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin; do
    install_apt_pkg "$pkg"
  done
fi
