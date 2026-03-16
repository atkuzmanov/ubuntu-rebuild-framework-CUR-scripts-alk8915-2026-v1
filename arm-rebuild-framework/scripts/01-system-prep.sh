#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/lib/common.sh"

log_info "Preparing base system"
run_cmd sudo apt-get update
run_cmd sudo apt-get install -y \
  curl git wget ca-certificates gnupg lsb-release software-properties-common apt-transport-https

if want_feature INSTALL_SNAPS; then
  install_apt_pkg snapd
fi

if want_feature ENABLE_TLP; then
  install_apt_pkg tlp
  run_cmd sudo systemctl enable tlp || true
  run_cmd sudo systemctl start tlp || true
fi

SYSCTL_FILE="/etc/sysctl.d/90-nasko-dev-userns.conf"
SYSCTL_CONTENT=$'# Required for Electron apps and dev tools (Cursor, Chrome sandbox, etc.)\nkernel.apparmor_restrict_unprivileged_userns=0\n'

if ! sudo test -f "$SYSCTL_FILE" || ! printf '%s' "$SYSCTL_CONTENT" | sudo cmp -s - "$SYSCTL_FILE"; then
  log_info "Configuring AppArmor user namespace setting for dev tools"
  printf '%s' "$SYSCTL_CONTENT" | run_cmd sudo tee "$SYSCTL_FILE" >/dev/null
  run_cmd sudo sysctl --system
else
  log_info "Dev userns sysctl already configured"
fi


