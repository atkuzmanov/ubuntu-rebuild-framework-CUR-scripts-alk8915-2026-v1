# Machine Rebuild Procedure

Follow these steps to rebuild a machine.

## 1 Install Ubuntu

Perform a normal Ubuntu installation.

Recommended options:

- Full disk encryption
- Latest LTS release
- Default GNOME desktop

## 2 Install basic tools

After first login:

sudo apt update
sudo apt install -y git curl

## 3 Clone rebuild repository

git clone https://github.com/you/ubuntu-rebuild-framework.git
cd ubuntu-rebuild-framework

Replace the URL with your own rebuild repository.

## 3b Configure profile (optional)

Before running the rebuild, you may want to set `CHEZMOI_REPO` in your profile file (`profiles/<profile>.env`). Set it to your dotfiles repository URL so chezmoi can apply your configuration. Leave it empty to skip the chezmoi step.

## 4 Run rebuild

./rebuild.sh --profile laptop

Available profiles:

- laptop
- workstation
- vm

## 5 Wait for completion

The script will install:

- package repositories
- apt packages
- snap packages
- flatpak packages
- developer tooling
- vendor applications
- chezmoi configuration

## 6 Verify system

Run:

scripts/14-validate.sh

## 7 Export system state (optional)

scripts/15-export-state.sh

This updates manifests to match the current machine.
