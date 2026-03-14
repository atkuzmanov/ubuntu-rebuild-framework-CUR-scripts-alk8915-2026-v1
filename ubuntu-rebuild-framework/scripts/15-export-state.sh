#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/lib/common.sh"

if ! want_feature RUN_EXPORTS; then
  log_info "State export skipped by profile"
  exit 0
fi

ensure_dir "$ROOT_DIR/state/exports"

log_info "Exporting package state"
apt-mark showmanual | sort > "$ROOT_DIR/state/exports/apt-manual-packages.txt"
snap list 2>/dev/null | awk 'NR>1 {print $1}' | sort > "$ROOT_DIR/state/exports/snap-packages.txt" || true
flatpak list --app --columns=application 2>/dev/null | sort > "$ROOT_DIR/state/exports/flatpak-packages.txt" || true
pipx list --short 2>/dev/null | sort > "$ROOT_DIR/state/exports/pipx-packages.txt" || true
cargo install --list 2>/dev/null | awk -F' ' '/ v[0-9]/{print $1}' | sort -u > "$ROOT_DIR/state/exports/cargo-packages.txt" || true
uv tool list 2>/dev/null | awk '{print $1}' | sort -u > "$ROOT_DIR/state/exports/uv-tools.txt" || true
npm list -g --depth=0 2>/dev/null | sed '1,1d' | sed 's/.* //' | cut -d@ -f1 | sort -u > "$ROOT_DIR/state/exports/npm-global-packages.txt" || true

cp "$ROOT_DIR/state/exports/apt-manual-packages.txt" "$ROOT_DIR/manifests/apt-packages-exported.txt"
cp "$ROOT_DIR/state/exports/snap-packages.txt" "$ROOT_DIR/manifests/snap-packages-exported.txt" || true
cp "$ROOT_DIR/state/exports/flatpak-packages.txt" "$ROOT_DIR/manifests/flatpak-packages-exported.txt" || true
cp "$ROOT_DIR/state/exports/pipx-packages.txt" "$ROOT_DIR/manifests/pipx-packages-exported.txt" || true
cp "$ROOT_DIR/state/exports/cargo-packages.txt" "$ROOT_DIR/manifests/cargo-packages-exported.txt" || true
cp "$ROOT_DIR/state/exports/uv-tools.txt" "$ROOT_DIR/manifests/uv-tools-exported.txt" || true
cp "$ROOT_DIR/state/exports/npm-global-packages.txt" "$ROOT_DIR/manifests/npm-global-packages-exported.txt" || true

log_warn "Exports written to manifests/*-exported.txt. To update apt-packages.txt: diff the files, then cp manifests/apt-packages-exported.txt manifests/apt-packages.txt if satisfied. apt-mark showmanual can include transitional and dependency-shaped packages—review before committing."
