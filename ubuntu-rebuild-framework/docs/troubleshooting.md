# Troubleshooting Guide

This document lists common issues that may occur when running the Ubuntu rebuild framework
and how to fix them.

---

## APT lock errors

Error example:

Could not get lock /var/lib/dpkg/lock-frontend

Fix:

sudo rm /var/lib/dpkg/lock-frontend
sudo rm /var/cache/apt/archives/lock
sudo dpkg --configure -a

---

## Broken packages

Error example:

E: Unmet dependencies

Fix:

sudo apt --fix-broken install

---

## dpkg interrupted

Error example:

dpkg was interrupted, you must manually run dpkg --configure -a

Fix:

sudo dpkg --configure -a

---

## Snap not responding

Restart snap daemon:

sudo systemctl restart snapd

---

## Flatpak install issues

Reinstall flathub repository:

flatpak remote-delete flathub
flatpak remote-add flathub https://flathub.org/repo/flathub.flatpakrepo

---

## Docker group permissions

If Docker commands require sudo:

sudo usermod -aG docker $USER

Then log out and log back in.

---

## AppArmor / Electron sandbox issues

If Electron apps fail to launch:

Verify sysctl configuration:

sysctl kernel.apparmor_restrict_unprivileged_userns

Expected value:

kernel.apparmor_restrict_unprivileged_userns = 0

If not:

sudo sysctl --system

---

## Rebuild script stops unexpectedly

Check logs:

logs/

Look for the last executed script and run it manually for debugging.

Example:

bash scripts/03-install-apt.sh

---

## Exporting system state

If manifests drift from the real system:

```bash
scripts/15-export-state.sh
```

This writes to `manifests/*-exported.txt`. For apt, review the diff then `cp manifests/apt-packages-exported.txt manifests/apt-packages.txt` if satisfied. Commit the updated manifests.

---

## Cursor sandbox issues

If Cursor refuses to start due to sandbox errors:

Verify package:

dpkg -l | grep cursor-sandbox-apparmor

If missing:

Re-run:

scripts/10-install-manual-apps.sh

---

## General debugging strategy

1. Identify the failing stage
2. Run the script manually
3. Inspect logs
4. Fix the issue
5. Re-run rebuild

The rebuild framework is designed to be idempotent, so it is safe to run again.
