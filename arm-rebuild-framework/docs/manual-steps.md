# Manual Steps

Some operations should remain manual for safety reasons.

These include:

## BIOS / Firmware

- Enable virtualization
- Configure secure boot if required

## Disk Layout

Partitioning and encryption should always be performed during OS installation.

## Authentication

Log into:

- GitHub
- Google
- Docker registries
- Cloud providers

## Browser Setup

Sign in to your browser profile to restore:

- extensions
- bookmarks
- saved settings

## SSH Keys

If you use hardware tokens or existing SSH keys:

- import keys
- register them with GitHub or servers

## Default shell (chsh)

If the rebuild framework sets your default shell to zsh via `chsh`, it may prompt for your password. If the automated step fails or hangs, run manually after logging in:

```bash
chsh -s $(command -v zsh) $USER
```

Log out and back in for the change to take effect.

## Optional Tools

Some licensed software may require:

- manual downloads
- activation
- login
