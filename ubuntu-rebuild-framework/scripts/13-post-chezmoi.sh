#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/lib/common.sh"

if ! want_feature RUN_POST_CHEZMOI; then
  log_info "Post-chezmoi step skipped by profile"
  exit 0
fi

if [[ "${DEFAULT_SHELL:-}" == "zsh" ]]; then
  if command -v zsh >/dev/null 2>&1; then
    current_shell="$(getent passwd "$USER" | cut -d: -f7)"
    zsh_path="$(command -v zsh)"
    if [[ "$current_shell" != "$zsh_path" ]]; then
      log_warn "chsh may prompt for your password. If it fails or hangs, run: chsh -s $(command -v zsh) $USER manually after logging in."
      run_cmd chsh -s "$zsh_path" "$USER"
    else
      log_info "Default shell already set to zsh"
    fi
  fi
fi

if want_feature ENABLE_DOCKER; then
  if getent group docker >/dev/null 2>&1; then
    if id -nG "$USER" | tr ' ' '\n' | grep -Fxq docker; then
      log_info "User already in docker group"
    else
      run_cmd sudo usermod -aG docker "$USER"
      log_warn "Docker group membership updated; log out and back in for it to take effect"
    fi
  fi
fi

if [[ -f "$HOME/.local/share/chezmoi/.chezmoidata.yaml" ]]; then
  log_info "chezmoi data file detected"
fi
