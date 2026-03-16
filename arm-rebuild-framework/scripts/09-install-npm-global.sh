#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/lib/common.sh"

if ! want_feature INSTALL_NPM_GLOBAL; then
  log_info "npm global step skipped by profile"
  exit 0
fi

require_command npm
manifest="$ROOT_DIR/manifests/npm-global-packages.txt"
while IFS= read -r app; do
  [[ -z "$app" || "$app" =~ ^# ]] && continue
  install_npm_global "$app"
done < "$manifest"
