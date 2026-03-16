#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/lib/common.sh"

if ! want_feature INSTALL_UV_TOOLS; then
  log_info "uv tools step skipped by profile"
  exit 0
fi

if ! command -v uv >/dev/null 2>&1; then
  log_warn "uv not found; skipping uv tool installation"
  exit 0
fi

manifest="$ROOT_DIR/manifests/uv-tools.txt"
while IFS= read -r app; do
  [[ -z "$app" || "$app" =~ ^# ]] && continue
  install_uv_tool "$app"
done < "$manifest"
