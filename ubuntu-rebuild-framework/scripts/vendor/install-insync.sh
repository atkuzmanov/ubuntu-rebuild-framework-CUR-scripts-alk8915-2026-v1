#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/lib/common.sh"

if ! want_feature INSTALL_INSYNC; then
  log_info "Skipping Insync because INSTALL_INSYNC is disabled"
  exit 0
fi

log_warn "Insync installer not yet implemented"
exit 0