#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/lib/common.sh"

if ! want_feature INSTALL_MANUAL_APPS; then
  log_info "Manual apps step skipped by profile"
  exit 0
fi

log_info "Installing vendor/manual applications"

VENDOR_DIR="$ROOT_DIR/scripts/vendor"

run_vendor_script() {
  local script_path="$1"

  if [ ! -f "$script_path" ]; then
    log_warn "Vendor script not found: $script_path"
    return 0
  fi

  run_cmd bash "$script_path"
}

run_vendor_script "$VENDOR_DIR/install-cursor-sandbox-apparmor.sh"

# Optional future vendor installers:
run_vendor_script "$VENDOR_DIR/install-cursor.sh"
run_vendor_script "$VENDOR_DIR/install-warp.sh"
run_vendor_script "$VENDOR_DIR/install-insync.sh"
run_vendor_script "$VENDOR_DIR/install-ledger-live.sh"

log_info "Vendor/manual application stage completed"



# #!/usr/bin/env bash
# set -Eeuo pipefail
# ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# source "$ROOT_DIR/lib/common.sh"

# if ! want_feature INSTALL_MANUAL_APPS; then
#   log_info "Manual apps step skipped by profile"
#   exit 0
# fi

# ensure_dir "$HOME/Applications"
# ensure_dir "$ROOT_DIR/state/exports"

# install_ledger_live_placeholder() {
#   if [[ -f "$HOME/Applications/ledger-live.AppImage" ]]; then
#     log_info "Ledger Live AppImage already present"
#   else
#     log_warn "Ledger Live is tracked as a manual app. Place the AppImage at ~/Applications/ledger-live.AppImage if you use it."
#   fi
# }

# install_cursor_placeholder() {
#   if command -v cursor >/dev/null 2>&1; then
#     log_info "Cursor already installed"
#   else
#     log_warn "Cursor is tracked as a manual app. Install it from the vendor package if desired."
#   fi
# }

# install_brother_scanner_placeholder() {
#   if want_feature ENABLE_SCANNER_SUPPORT; then
#     log_warn "Brother scanner packages are model-specific; keep your known-good vendor steps in a separate model-specific script if needed."
#   fi
# }

# install_ledger_live_placeholder
# install_cursor_placeholder
# install_brother_scanner_placeholder

# cp "$ROOT_DIR/manifests/manual-downloads.txt" "$ROOT_DIR/state/exports/manual-downloads-last-run.txt"
# log_info "Manual app inventory copied to state/exports/manual-downloads-last-run.txt"


