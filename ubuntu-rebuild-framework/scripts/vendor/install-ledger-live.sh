#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/lib/common.sh"

if ! want_feature INSTALL_LEDGER_LIVE; then
  log_info "Skipping Ledger Live because INSTALL_LEDGER_LIVE is disabled"
  exit 0
fi

log_warn "Ledger Live installer not yet implemented"
exit 0