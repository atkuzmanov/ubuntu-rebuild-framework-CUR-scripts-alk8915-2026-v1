#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/lib/common.sh"

if ! want_feature INSTALL_WARP; then
  log_info "Skipping Warp because INSTALL_WARP is disabled"
  exit 0
fi

log_warn "Warp installer not yet implemented"
exit 0