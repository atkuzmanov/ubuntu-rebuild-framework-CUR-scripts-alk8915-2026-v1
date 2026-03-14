# Architecture

This document explains the architecture of the Ubuntu rebuild framework.

## Design Principles

The rebuild system follows these principles:

- Idempotent scripts
- Clear responsibility boundaries
- Layered execution stages
- Profile-based configuration
- Minimal hidden logic

The framework is designed so that the entire machine can be rebuilt safely and repeatedly.

## Execution Flow

The rebuild process is orchestrated by `rebuild.sh` and executes scripts in order:

1. `00-preflight.sh` – sanity checks
2. `01-system-prep.sh` – base system preparation
3. `02-install-repositories.sh` – apt repository setup
4. `03-install-apt.sh` – apt packages
5. `03b-install-kali-safe-tools.sh` – optional Kali-style tools (profile-gated)
6. `04-install-snap.sh` – snap packages
7. `05-install-flatpak.sh` – flatpak packages
8. `06-install-pipx.sh` – pipx tools
9. `07-install-cargo.sh` – Rust cargo tools
10. `08-install-uv-tools.sh` – Python uv tools
11. `09-install-npm-global.sh` – Node global tools
12. `10-install-manual-apps.sh` – vendor/manual installers
13. `11-install-chezmoi.sh` – install chezmoi
14. `12-apply-chezmoi.sh` – apply dotfiles
15. `13-post-chezmoi.sh` – post configuration
16. `14-validate.sh` – validation checks
17. `15-export-state.sh` – export installed state

## Responsibility Boundaries

### Rebuild Scripts

Responsible for:

- installing packages
- configuring repositories
- installing development tooling
- running vendor installers

### Chezmoi

Responsible for:

- configuration files
- shell setup
- git configuration
- editor configuration
- user-level preferences

### Profiles

Profiles control which components are installed on a machine.

Example:

- laptop
- workstation
- vm

Profiles enable conditional features such as Docker, virtualization, or GUI apps.

## Vendor Installers

Vendor installers live in:

scripts/vendor/

These scripts handle:

- AppImages
- downloaded .deb files
- proprietary installers

## State Export

The framework can export the current machine state using:

scripts/15-export-state.sh

This updates package manifests so the rebuild system remains accurate.
