#!/usr/bin/env bash

apt_installed() {
  dpkg -s "$1" >/dev/null 2>&1
}

install_apt_pkg() {
  local pkg="$1"
  if apt_installed "$pkg"; then
    log_info "APT package already installed: $pkg"
  else
    run_cmd sudo apt-get install -y "$pkg"
  fi
}

snap_installed() {
  snap list "$1" >/dev/null 2>&1
}

install_snap_pkg() {
  local pkg="$1"
  shift || true
  if snap_installed "$pkg"; then
    log_info "Snap package already installed: $pkg"
  else
    run_cmd sudo snap install "$pkg" "$@"
  fi
}

flatpak_installed() {
  flatpak info "$1" >/dev/null 2>&1
}

install_flatpak_pkg() {
  local pkg="$1"
  if flatpak_installed "$pkg"; then
    log_info "Flatpak already installed: $pkg"
  else
    run_cmd flatpak install -y flathub "$pkg"
  fi
}

pipx_app_installed() {
  pipx list --short 2>/dev/null | grep -Fxq "$1"
}

install_pipx_app() {
  local app="$1"
  if pipx_app_installed "$app"; then
    log_info "pipx app already installed: $app"
  else
    run_cmd pipx install "$app"
  fi
}

cargo_app_installed() {
  command -v "$1" >/dev/null 2>&1
}

install_cargo_app() {
  local app="$1"
  if cargo_app_installed "$app"; then
    log_info "cargo app already present in PATH: $app"
  else
    run_cmd cargo install "$app"
  fi
}

uv_tool_installed() {
  uv tool list 2>/dev/null | awk '{print $1}' | grep -Fxq "$1"
}

install_uv_tool() {
  local app="$1"
  if uv_tool_installed "$app"; then
    log_info "uv tool already installed: $app"
  else
    run_cmd uv tool install "$app"
  fi
}

npm_global_installed() {
  npm list -g --depth=0 2>/dev/null | grep -Fq " $1@"
}

install_npm_global() {
  local app="$1"
  if npm_global_installed "$app"; then
    log_info "npm global package already installed: $app"
  else
    run_cmd sudo npm install -g "$app"
  fi
}
