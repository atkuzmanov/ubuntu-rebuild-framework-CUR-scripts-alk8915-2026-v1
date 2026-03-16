#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/lib/common.sh"

if ! want_feature INSTALL_CARGO; then
  log_info "cargo step skipped by profile"
  exit 0
fi

if ! command -v cargo >/dev/null 2>&1; then
  log_warn "cargo not found; skipping cargo tools. Install Rust toolchain first if needed."
  exit 0
fi

manifest="$ROOT_DIR/manifests/cargo-packages.txt"
while IFS= read -r app; do
  [[ -z "$app" || "$app" =~ ^# ]] && continue
  install_cargo_app "$app"
done < "$manifest"
