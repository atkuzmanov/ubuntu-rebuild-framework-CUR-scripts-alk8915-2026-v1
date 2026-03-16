#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/lib/common.sh"

if ! want_feature INSTALL_CURSOR; then
  log_info "Skipping Cursor installation because INSTALL_CURSOR is disabled"
  exit 0
fi

if command -v cursor >/dev/null 2>&1; then
  log_info "Cursor command already present"
  exit 0
fi

log_warn "Cursor installer is not yet implemented in install-cursor.sh"
log_warn "Add your preferred Cursor installation method here"
exit 0