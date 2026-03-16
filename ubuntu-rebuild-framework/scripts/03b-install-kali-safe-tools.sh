#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/lib/common.sh"

MANIFEST="$ROOT_DIR/manifests/kali-safe-apt-packages.txt"

if ! want_feature INSTALL_KALI_SAFE_TOOLS; then
  log_info "Skipping Kali-style safe tools because INSTALL_KALI_SAFE_TOOLS is disabled"
  exit 0
fi

if [ ! -f "$MANIFEST" ]; then
  log_warn "Manifest not found: $MANIFEST"
  exit 0
fi

log_info "Installing curated Kali-style safe tools from Ubuntu-compatible package sources"

run_cmd sudo apt-get update

while IFS= read -r pkg || [ -n "$pkg" ]; do
  pkg="${pkg%%#*}"
  pkg="$(echo -n "$pkg" | xargs)"
  [ -z "$pkg" ] && continue

  if dpkg -s "$pkg" >/dev/null 2>&1; then
    log_info "Already installed: $pkg"
    continue
  fi

  if apt-cache show "$pkg" >/dev/null 2>&1; then
    log_info "Installing: $pkg"
    run_cmd sudo apt-get install -y "$pkg"
  else
    log_warn "Package not available on this machine/repo set, skipping: $pkg"
  fi
done < "$MANIFEST"

if want_feature INSTALL_WIRESHARK && dpkg -s wireshark-common >/dev/null 2>&1; then
  log_info "Configuring wireshark-common for non-root packet capture where possible"

  if command -v debconf-set-selections >/dev/null 2>&1; then
    printf 'wireshark-common wireshark-common/install-setuid boolean true\n' | run_cmd sudo debconf-set-selections

    if ! run_cmd sudo dpkg-reconfigure -f noninteractive wireshark-common; then
      log_warn "dpkg-reconfigure for wireshark-common failed, continuing"
    fi
  fi

  if groups "${USER:-$(whoami)}" | grep -qw wireshark; then
    log_info "User already in wireshark group"
  else
    if ! run_cmd sudo usermod -aG wireshark "${USER:-$(whoami)}"; then
      log_warn "Failed to add ${USER:-$(whoami)} to wireshark group"
    else
      log_warn "You may need to log out and back in for wireshark group membership to apply"
    fi
  fi
fi

log_info "Finished installing Kali-style safe tools"


