# Ubuntu Rebuild Framework – Analysis and Improvements

This document summarizes the analysis of your rebuild framework, identifies issues, and documents improvements.

---

## Overall Assessment

Your framework is well-designed and aligns with your goals:

- **Idempotent** – scripts check before installing
- **Profile-driven** – clear separation via `profiles/*.env`
- **Chezmoi as a step** – rebuild scripts own orchestration; chezmoi is step 12
- **Good boundaries** – apt, snap, flatpak, pipx, cargo, uv, npm, vendor installers all covered

The architecture, lib helpers, and documentation are solid.

---

## Issues Found and Fixes Applied

### 1. Helm repository key path bug (apt-repositories.sh)

**Problem:** `configure_helm_repo` checks for `/etc/apt/keyrings/helm.asc` but creates `helm.gpg`. The key file is never found, so the repo key is re-downloaded on every run.

**Fix:** Change the existence check to use `helm.gpg` (the file actually created).

### 2. Manual apps step ignores INSTALL_MANUAL_APPS

**Problem:** `10-install-manual-apps.sh` runs all vendor scripts regardless of `INSTALL_MANUAL_APPS`. The VM profile sets `INSTALL_MANUAL_APPS=false`, but vendor scripts are still invoked (they exit early, but the step should skip entirely for consistency).

**Fix:** Add an early exit when `INSTALL_MANUAL_APPS` is false.

### 3. Missing dependency: uv

**Problem:** `08-install-uv-tools.sh` requires `uv` to be installed, but `uv` is not installed anywhere. It is not in `pipx-packages.txt` or `apt-packages.txt`.

**Fix:** Add `uv` to `pipx-packages.txt`. Pipx runs in step 06, before step 08, so uv will be available.

### 4. Missing dependency: Rust/cargo

**Problem:** `07-install-cargo.sh` requires `cargo`. The manifest does not install Rust. The script exits with a warning if cargo is missing, so cargo tools are never installed.

**Fix:** Add `cargo` and `rustc` to `apt-packages.txt` (Ubuntu provides them in the default repositories). Note: apt packages may lag behind the latest Rust release. If you need the newest toolchain, consider adding a dedicated `install-rustup.sh` vendor step that runs `curl -sSf https://sh.rustup.rs | sh -s -- -y` instead of relying on apt.

### 5. CHEZMOI_REPO placeholder

**Problem:** All profiles have `CHEZMOI_REPO=""`. Step 12 skips chezmoi init/apply when empty, with a warning. This is intentional, but not clearly documented.

**Fix:** Add comments in profile files and update `docs/rebuild-procedure.md` so users know they must set `CHEZMOI_REPO` to their dotfiles repo.

### 6. rebuild-procedure.md placeholder

**Problem:** Step 3 says `git clone <your-rebuild-repo>` without guidance.

**Fix:** Use a generic example URL and note that users should replace it with their own repo.

### 7. Architecture doc missing 03b step

**Problem:** `docs/architecture.md` lists the execution flow but omits `03b-install-kali-safe-tools.sh`.

**Fix:** Add 03b to the architecture flow.

---

## Vendor Installers (Not Yet Implemented)

These vendor scripts exist but only log a warning and exit:

- `install-cursor.sh` – "Add your preferred Cursor installation method here"
- `install-warp.sh` – "Warp installer not yet implemented"
- `install-insync.sh` – "Insync installer not yet implemented"
- `install-ledger-live.sh` – "Ledger Live installer not yet implemented"

Only `install-cursor-sandbox-apparmor.sh` is fully implemented.

**Recommendation:** Keep them as stubs until you decide to implement. They respect profile flags and exit cleanly. Add a short comment in each stating it is a stub. When ready, refer to `docs/adding-new-software.md` for the pattern.

---

## Optional Improvements (Applied)

### Export script ✓

`15-export-state.sh` now writes apt export to `apt-packages-exported.txt` instead of overwriting `apt-packages.txt`. The user reviews, diffs, and manually copies if satisfied. README, adding-new-software.md, and troubleshooting.md updated.

### Validation strictness for Kali tools ✓

Kali tool checks in `14-validate.sh` are now soft: missing commands log a warning instead of failing validation. Core commands (git, curl, etc.) remain hard failures.

### snapd guarantee ✓

`01-system-prep.sh` now installs `snapd` when `INSTALL_SNAPS` is true, so snap works on minimal/server installs.

### chsh interactivity ✓

`13-post-chezmoi.sh` logs a warning before `chsh` that it may prompt for a password. `docs/manual-steps.md` documents the manual fallback. `98-manual-checklist.sh` mentions chsh in the login reminder.

---

## Checklist of Placeholders to Complete

| Item                         | Location                       | Action                                               |
|-----------------------------|--------------------------------|------------------------------------------------------|
| `CHEZMOI_REPO`              | `profiles/*.env`               | Set to your dotfiles repo URL                        |
| `git clone <your-rebuild-repo>` | `docs/rebuild-procedure.md` | Replace with your repo URL or a clear placeholder    |
| Cursor installer             | `scripts/vendor/install-cursor.sh` | Implement when needed                          |
| Warp installer              | `scripts/vendor/install-warp.sh`   | Implement when needed                          |
| Insync installer            | `scripts/vendor/install-insync.sh` | Implement when needed                         |
| Ledger Live installer       | `scripts/vendor/install-ledger-live.sh` | Implement when needed                    |

---

## Summary of Fixes Applied in This Session

All of the following fixes have been applied to the framework:

1. Fix Helm key path check in `manifests/apt-repositories.sh` (helm.asc → helm.gpg)
2. Add `INSTALL_MANUAL_APPS` check to `10-install-manual-apps.sh`
3. Add `uv` to `pipx-packages.txt`
4. Add `cargo` and `rustc` to `apt-packages.txt`
5. Document `CHEZMOI_REPO` in profiles and `rebuild-procedure.md`
6. Update `rebuild-procedure.md` clone step
7. Add `03b` to `docs/architecture.md`

**Optional improvements (second pass):**

8. Export script: apt now writes to `apt-packages-exported.txt`; user merges manually
9. Validation: Kali tools are soft checks (warn only)
10. snapd: installed in `01-system-prep.sh` when `INSTALL_SNAPS` is true
11. chsh: warning before run; documented in manual-steps.md and checklist
