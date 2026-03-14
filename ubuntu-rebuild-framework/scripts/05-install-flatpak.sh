#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/lib/common.sh"

if ! want_feature INSTALL_FLATPAKS; then
  log_info "Flatpak install step skipped by profile"
  exit 0
fi

require_command flatpak
if ! flatpak remotes | grep -Fq flathub; then
  run_cmd flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
else
  log_info "Flathub remote already configured"
fi

manifest="$ROOT_DIR/manifests/flatpak-packages.txt"
while IFS='|' read -r pkg flag; do
  [[ -z "$pkg" || "$pkg" =~ ^# ]] && continue
  if [[ -n "$flag" ]] && ! want_feature "$flag"; then
    log_info "Skipping flatpak $pkg due to profile flag $flag"
    continue
  fi
  install_flatpak_pkg "$pkg"
done < "$manifest"
