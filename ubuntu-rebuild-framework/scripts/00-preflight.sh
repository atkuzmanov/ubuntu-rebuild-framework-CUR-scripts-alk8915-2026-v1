#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/common.sh
source "$ROOT_DIR/lib/common.sh"

log_info "Running preflight checks"
require_command bash
require_command sudo
require_command grep
require_command awk
require_command tee

if [[ "$EUID" -eq 0 ]]; then
  die "Run rebuild.sh as your normal user, not as root"
fi

if ! grep -qi ubuntu /etc/os-release; then
  die "This framework currently targets Ubuntu"
fi

log_info "OS: $(. /etc/os-release && echo "$PRETTY_NAME")"
log_info "User: $USER"
log_info "Home: $HOME"
log_info "Profile: $PROFILE"

run_cmd sudo -v
