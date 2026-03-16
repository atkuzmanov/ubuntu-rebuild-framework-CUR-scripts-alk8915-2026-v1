#!/usr/bin/env bash
set -Eeuo pipefail

# This file is sourced by scripts/02-install-repositories.sh
# Add or remove blocks as needed.

configure_docker_repo() {
  if ! want_feature ENABLE_DOCKER; then
    log_info "Docker repo skipped by profile"
    return 0
  fi

  sudo install -m 0755 -d /etc/apt/keyrings
  if [[ ! -f /etc/apt/keyrings/docker.asc ]]; then
    run_shell 'curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo tee /etc/apt/keyrings/docker.asc >/dev/null'
    run_cmd sudo chmod a+r /etc/apt/keyrings/docker.asc
  else
    log_info "Docker key already present"
  fi

  local codename
  codename="$(. /etc/os-release && echo "$VERSION_CODENAME")"
  local repo_line
  repo_line="deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu ${codename} stable"

  if ! grep -Fqx "$repo_line" /etc/apt/sources.list.d/docker.list 2>/dev/null; then
    if [[ "${DRY_RUN:-0}" -eq 1 ]]; then
      log_info "Dry run: would write Docker repo"
    else
      printf '%s\n' "$repo_line" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
      log_info "Docker repo configured"
    fi
  else
    log_info "Docker repo already configured"
  fi
}

configure_helm_repo() {
  if ! want_feature ENABLE_WORK_TOOLS; then
    log_info "Helm repo skipped by profile"
    return 0
  fi

  sudo install -m 0755 -d /etc/apt/keyrings
  if [[ ! -f /etc/apt/keyrings/helm.gpg ]]; then
    run_shell 'curl -fsSL https://baltocdn.com/helm/signing.asc | sudo gpg --dearmor -o /etc/apt/keyrings/helm.gpg'
    run_cmd sudo chmod a+r /etc/apt/keyrings/helm.gpg
  else
    log_info "Helm key already present"
  fi

  local repo_line
  repo_line='deb [arch=amd64 signed-by=/etc/apt/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main'

  if ! grep -Fqx "$repo_line" /etc/apt/sources.list.d/helm-stable-debian.list 2>/dev/null; then
    if [[ "${DRY_RUN:-0}" -eq 1 ]]; then
      log_info "Dry run: would write Helm repo"
    else
      printf '%s\n' "$repo_line" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list >/dev/null
      log_info "Helm repo configured"
    fi
  else
    log_info "Helm repo already configured"
  fi
}

configure_brave_repo() {
  if ! want_feature INSTALL_GUI_APPS; then
    log_info "Brave repo skipped by profile"
    return 0
  fi

  # If Brave is already configured by the system (e.g. base image),
  # avoid adding a duplicate repo line with a different signed-by path,
  # which causes 'Conflicting values set for option Signed-By' errors.
  #
  # Additionally, if both a legacy .list entry and a newer .sources entry
  # exist for Brave, normalize them to use the same Signed-By path so that
  # apt-get update does not fail.
  if grep -Rqs 'https://brave-browser-apt-release.s3.brave.com/' /etc/apt/sources.list /etc/apt/sources.list.d 2>/dev/null; then
    local sources_file=/etc/apt/sources.list.d/brave-browser-release.sources
    local list_file=/etc/apt/sources.list.d/brave-browser-release.list
    local canonical_key=/usr/share/keyrings/brave-browser-archive-keyring.gpg

    if [[ -f "$sources_file" && -f "$list_file" ]]; then
      # If .sources uses /usr/share/keyrings and .list uses /etc/apt/keyrings,
      # rewrite the .list file to also use /usr/sharekeyrings to avoid conflicts.
      if grep -q "Signed-By: $canonical_key" "$sources_file" 2>/dev/null; then
        if grep -q "/etc/apt/keyrings/brave-browser-archive-keyring.gpg" "$list_file" 2>/dev/null; then
          log_info "Normalizing Brave APT repo signed-by path to $canonical_key"
          sudo sed -i 's#/etc/apt/keyrings/brave-browser-archive-keyring.gpg#/usr/share/keyrings/brave-browser-archive-keyring.gpg#g' "$list_file" || true
        fi
      fi
    fi

    log_info "Brave repo already configured by system; skipping custom Brave repo setup"
    return 0
  fi

  sudo install -m 0755 -d /etc/apt/keyrings
  if [[ ! -f /etc/apt/keyrings/brave-browser-archive-keyring.gpg ]]; then
    run_shell 'curl -fsSLo /tmp/brave.asc https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg && sudo install -m 644 /tmp/brave.asc /etc/apt/keyrings/brave-browser-archive-keyring.gpg'
  else
    log_info "Brave key already present"
  fi

  local repo_line
  repo_line='deb [signed-by=/etc/apt/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main'

  if ! grep -Fqx "$repo_line" /etc/apt/sources.list.d/brave-browser-release.list 2>/dev/null; then
    if [[ "${DRY_RUN:-0}" -eq 1 ]]; then
      log_info "Dry run: would write Brave repo"
    else
      printf '%s\n' "$repo_line" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list >/dev/null
      log_info "Brave repo configured"
    fi
  else
    log_info "Brave repo already configured"
  fi
}
