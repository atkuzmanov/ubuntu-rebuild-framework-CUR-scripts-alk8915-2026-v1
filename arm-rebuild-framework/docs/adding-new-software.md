# Adding New Software

This document explains where new software should be added in the rebuild framework.

The key rule is:

**Installation belongs in rebuild scripts. Configuration belongs in chezmoi.**

## Decide Installation Method

Determine how the software should be installed.

Possible methods:

- apt package
- snap package
- flatpak package
- pipx tool
- cargo tool
- npm global tool
- vendor installer

## Apt Packages

If the software exists in Ubuntu repositories:

Add it to:

manifests/apt-packages.txt

Example:

ripgrep
fd-find

The install script will pick it up automatically.

## Snap Packages

Add to:

manifests/snap-packages.txt

Example:

code --classic

## Flatpak Applications

Add to:

manifests/flatpak-packages.txt

Example:

org.signal.Signal

## Pipx Tools

Add Python CLI tools to:

manifests/pipx-packages.txt

Example:

poetry
black

## Cargo Tools

Add Rust CLI tools to:

manifests/cargo-packages.txt

Example:

bat
exa

## npm Global Tools

Add Node tools to:

manifests/npm-global-packages.txt

Example:

typescript
pnpm

## Vendor Installers

If software must be downloaded manually, create a vendor installer:

scripts/vendor/install-example.sh

Then call it from:

scripts/10-install-manual-apps.sh

Vendor installers should:

- check if software already exists
- download installer
- install package
- log the result

## Configuration

Application configuration should go in the chezmoi repository.

Examples:

- shell configuration
- editor settings
- git configuration
- application dotfiles

## Offline Bundles

Software added to manifests is included when you run:

```bash
offline-bundle/download-bundle.sh --profile laptop
```

For vendor software (manual .deb, AppImage, etc.), place installers in a folder and either copy them to `offline-bundle/cache/vendor/` before running `install-from-bundle.sh`, or set `OFFLINE_VENDOR_SOURCE_DIR` when downloading:

```bash
OFFLINE_VENDOR_SOURCE_DIR="$HOME/Downloads/vendor" offline-bundle/download-bundle.sh --profile laptop
```

## Updating Manifests

If you manually install software outside the rebuild framework, run:

```bash
scripts/15-export-state.sh
```

This writes to `manifests/*-exported.txt`. For apt packages, diff `apt-packages.txt` and `apt-packages-exported.txt`, then `cp manifests/apt-packages-exported.txt manifests/apt-packages.txt` if satisfied. Commit the updated manifests. Note: `apt-mark showmanual` can include transitional packages—review before committing.
