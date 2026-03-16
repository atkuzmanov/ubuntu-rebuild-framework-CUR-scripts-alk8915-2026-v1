#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/lib/common.sh"

if ! want_feature INSTALL_SNAPS; then
  log_info "Snap install step skipped by profile"
  exit 0
fi

manifest="$ROOT_DIR/manifests/snap-packages.txt"
[[ -f "$manifest" ]] || die "Missing manifest: $manifest"

while IFS='|' read -r pkg args flag; do
  [[ -z "$pkg" || "$pkg" =~ ^# ]] && continue

  if [[ -n "$flag" ]] && ! want_feature "$flag"; then
    log_info "Skipping snap $pkg due to profile flag $flag"
    continue
  fi

  if [[ -n "$args" ]]; then
    # shellcheck disable=SC2086
    install_snap_pkg "$pkg" $args
  else
    install_snap_pkg "$pkg"
  fi
done < "$manifest"
