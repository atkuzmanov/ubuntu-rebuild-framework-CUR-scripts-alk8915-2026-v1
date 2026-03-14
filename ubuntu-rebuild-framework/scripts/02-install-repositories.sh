#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/lib/common.sh"
# shellcheck source=manifests/apt-repositories.sh
source "$ROOT_DIR/manifests/apt-repositories.sh"

log_info "Configuring apt repositories"
configure_docker_repo
configure_helm_repo
configure_brave_repo
run_cmd sudo apt-get update
