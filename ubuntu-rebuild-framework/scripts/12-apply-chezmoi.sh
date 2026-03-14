#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/lib/common.sh"

if ! want_feature APPLY_CHEZMOI; then
  log_info "chezmoi apply skipped by profile"
  exit 0
fi

command -v chezmoi >/dev/null 2>&1 || die "chezmoi is not installed"

CHEZMOI_REPO="${CHEZMOI_REPO:-}"
if [[ -z "$CHEZMOI_REPO" ]]; then
  log_warn "CHEZMOI_REPO is empty in the selected profile. Skipping chezmoi init/apply."
  exit 0
fi

if [[ ! -d "$HOME/.local/share/chezmoi" ]]; then
  run_cmd chezmoi init "$CHEZMOI_REPO"
else
  log_info "chezmoi source already initialized"
fi

run_cmd chezmoi apply
