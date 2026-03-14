#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/lib/common.sh"

log_info "Validating key commands"

required_cmds=(git curl wget jq rg fzf zsh)

if want_feature ENABLE_WORK_TOOLS; then
  required_cmds+=(java mvn)
fi

if want_feature INSTALL_PIPX; then
  required_cmds+=(pipx)
fi

if want_feature ENABLE_DOCKER; then
  required_cmds+=(docker)
fi

soft_cmds=()
if want_feature INSTALL_KALI_SAFE_TOOLS; then
  soft_cmds=(nmap tcpdump tshark sqlmap gobuster ffuf amass)
fi

missing=0
for cmd in "${required_cmds[@]}"; do
  if command -v "$cmd" >/dev/null 2>&1; then
    log_info "OK: $cmd"
  else
    log_error "Missing command: $cmd"
    missing=1
  fi
done

for cmd in "${soft_cmds[@]}"; do
  if command -v "$cmd" >/dev/null 2>&1; then
    log_info "OK: $cmd"
  else
    log_warn "Optional (Kali) command not found: $cmd (package may be unavailable in repos)"
  fi
done

if [[ "$missing" -ne 0 ]]; then
  die "Validation failed"
fi

log_info "Validation passed"


