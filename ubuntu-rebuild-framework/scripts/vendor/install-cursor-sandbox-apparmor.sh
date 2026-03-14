#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/lib/common.sh"

if ! want_feature INSTALL_CURSOR; then
  log_info "Skipping Cursor sandbox AppArmor package because INSTALL_CURSOR is disabled"
  exit 0
fi

if ! want_feature INSTALL_CURSOR_SANDBOX_APPARMOR; then
  log_info "Skipping Cursor sandbox AppArmor package because INSTALL_CURSOR_SANDBOX_APPARMOR is disabled"
  exit 0
fi

TMP_DIR="${TMP_DIR:-/tmp/ubuntu-rebuild}"
mkdir -p "$TMP_DIR"

PKG_NAME="cursor-sandbox-apparmor"
PKG_VERSION="0.4.0"
DEB_FILE="${PKG_NAME}_${PKG_VERSION}_all.deb"
DEB_PATH="$TMP_DIR/$DEB_FILE"
DEB_URL="https://downloads.cursor.com/lab/enterprise/${DEB_FILE}"

if dpkg -s "$PKG_NAME" >/dev/null 2>&1; then
  installed_version="$(dpkg-query -W -f='${Version}' "$PKG_NAME" 2>/dev/null || true)"
  if [ "$installed_version" = "$PKG_VERSION" ]; then
    log_info "$PKG_NAME already installed at version $PKG_VERSION"
    exit 0
  fi
  log_info "$PKG_NAME is installed but version differs (installed: ${installed_version:-unknown}, expected: $PKG_VERSION)"
fi

log_info "Downloading $PKG_NAME from $DEB_URL"
run_cmd curl -fsSL "$DEB_URL" -o "$DEB_PATH"

log_info "Installing $PKG_NAME"
if ! sudo dpkg -i "$DEB_PATH"; then
  log_warn "dpkg reported dependency issues, attempting apt-get install -f"
  run_cmd sudo apt-get install -f -y
fi

if dpkg -s "$PKG_NAME" >/dev/null 2>&1; then
  final_version="$(dpkg-query -W -f='${Version}' "$PKG_NAME" 2>/dev/null || true)"
  log_info "$PKG_NAME installed successfully (version: ${final_version:-unknown})"
else
  log_error "Failed to install $PKG_NAME"
  exit 1
fi