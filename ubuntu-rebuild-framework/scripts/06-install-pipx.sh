#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/lib/common.sh"

if ! want_feature INSTALL_PIPX; then
  log_info "pipx step skipped by profile"
  exit 0
fi

require_command pipx
run_cmd pipx ensurepath || true

manifest="$ROOT_DIR/manifests/pipx-packages.txt"
while IFS= read -r app; do
  [[ -z "$app" || "$app" =~ ^# ]] && continue
  install_pipx_app "$app"
done < "$manifest"
