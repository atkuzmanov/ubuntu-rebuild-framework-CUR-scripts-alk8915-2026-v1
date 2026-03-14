
# Ubuntu Rebuild Framework – Repository Guide

This document explains the structure of the Ubuntu Rebuild Framework repository and the purpose of each component.

The framework is designed to make rebuilding a development machine:

- reproducible
- safe to re-run
- modular
- profile driven
- easy to debug

---

# High-Level Architecture

The rebuild process follows a staged pipeline.

```text
rebuild.sh
   │
   ├── 00-preflight.sh
   ├── 01-system-prep.sh
   ├── 02-install-repositories.sh
   ├── 03-install-apt.sh
   ├── 03b-install-kali-safe-tools.sh
   ├── 04-install-snap.sh
   ├── 05-install-flatpak.sh
   ├── 06-install-pipx.sh
   ├── 07-install-cargo.sh
   ├── 08-install-uv-tools.sh
   ├── 09-install-npm-global.sh
   ├── 10-install-manual-apps.sh
   ├── 11-install-chezmoi.sh
   ├── 12-apply-chezmoi.sh
   ├── 13-post-chezmoi.sh
   ├── 14-validate.sh
   ├── 15-export-state.sh
   └── 98-manual-checklist.sh
```

Each stage is intentionally isolated so failures are easy to debug and rerun.

---

# Repository Tree

```text
ubuntu-rebuild-framework/
├── README.md
├── rebuild.sh
├── docs/
│   ├── adding-new-software.md
│   ├── architecture.md
│   ├── framework-conventions.md
│   ├── framework-overview.md
│   ├── machine-notes.md
│   ├── manual-steps.md
│   ├── rebuild-procedure.md
│   └── troubleshooting.md
├── lib/
│   ├── common.sh
│   ├── logging.sh
│   └── packages.sh
├── logs/
├── manifests/
│   ├── apt-packages.txt
│   ├── apt-repositories.sh
│   ├── cargo-packages.txt
│   ├── flatpak-packages.txt
│   ├── kali-safe-apt-packages.txt
│   ├── manual-downloads.txt
│   ├── npm-global-packages.txt
│   ├── pipx-packages.txt
│   ├── snap-packages.txt
│   └── uv-tools.txt
├── profiles/
│   ├── laptop.env
│   ├── vm.env
│   └── workstation.env
├── scripts/
│   ├── 00-preflight.sh
│   ├── 01-system-prep.sh
│   ├── 02-install-repositories.sh
│   ├── 03-install-apt.sh
│   ├── 03b-install-kali-safe-tools.sh
│   ├── 04-install-snap.sh
│   ├── 05-install-flatpak.sh
│   ├── 06-install-pipx.sh
│   ├── 07-install-cargo.sh
│   ├── 08-install-uv-tools.sh
│   ├── 09-install-npm-global.sh
│   ├── 10-install-manual-apps.sh
│   ├── 11-install-chezmoi.sh
│   ├── 12-apply-chezmoi.sh
│   ├── 13-post-chezmoi.sh
│   ├── 14-validate.sh
│   ├── 15-export-state.sh
│   ├── 98-manual-checklist.sh
│   └── vendor/
│       ├── install-cursor-sandbox-apparmor.sh
│       ├── install-cursor.sh
│       ├── install-insync.sh
│       ├── install-ledger-live.sh
│       └── install-warp.sh
└── state/
    └── exports/
```

---

# Directory Explanations

## rebuild.sh

Main orchestration script.

Responsibilities:

- load profile
- execute stages in order
- handle `--dry-run`
- handle `--only-step`
- handle `--skip-step`
- manage logs

This script is the entry point for rebuilding a system.

---

# docs/

Documentation for the rebuild framework.

Important documents include:

| File | Purpose |
|-----|------|
| framework-overview.md | Project overview |
| architecture.md | Technical architecture |
| adding-new-software.md | Where new software belongs |
| framework-conventions.md | Coding conventions |
| troubleshooting.md | Fix common rebuild issues |
| rebuild-procedure.md | Step-by-step rebuild instructions |

---

# lib/

Shared helper functions used by scripts.

### common.sh

Provides utilities like:

- `run_cmd`
- `want_feature`
- `die`
- environment helpers

### logging.sh

Provides structured logging:

- `log_info`
- `log_warn`
- `log_error`
- `log_section`

### packages.sh

Shared package installation helpers.

---

# manifests/

Lists of software to install.

These are **data files**, not scripts.

Examples:

| Manifest | Purpose |
|--------|--------|
| apt-packages.txt | core apt packages |
| snap-packages.txt | snap applications |
| flatpak-packages.txt | flatpak apps |
| pipx-packages.txt | Python CLI tools |
| cargo-packages.txt | Rust CLI tools |
| npm-global-packages.txt | Node global tools |
| kali-safe-apt-packages.txt | curated Kali-style tools |

The install scripts read these manifests.

---

# profiles/

Machine configuration profiles.

Examples:

```text
laptop.env
vm.env
workstation.env
```

Profiles enable feature flags such as:

```bash
INSTALL_KALI_SAFE_TOOLS=true
ENABLE_DOCKER=true
INSTALL_CURSOR=true
```

This allows the same rebuild framework to be used on multiple machine types.

---

# scripts/

All rebuild stages live here.

The numeric prefixes enforce execution order.

Examples:

| Script | Purpose |
|------|------|
| 00-preflight.sh | environment checks |
| 01-system-prep.sh | base system configuration |
| 02-install-repositories.sh | apt repository setup |
| 03-install-apt.sh | apt package installation |
| 03b-install-kali-safe-tools.sh | optional security tools |
| 10-install-manual-apps.sh | vendor installers |
| 11-install-chezmoi.sh | install chezmoi |
| 12-apply-chezmoi.sh | apply dotfiles |
| 14-validate.sh | verify installation |
| 15-export-state.sh | regenerate manifests |

---

# scripts/vendor/

Vendor-specific installers.

Examples:

| Script | Purpose |
|------|------|
| install-cursor.sh | Cursor editor |
| install-cursor-sandbox-apparmor.sh | Cursor sandbox fix |
| install-warp.sh | Warp terminal |
| install-insync.sh | Google Drive client |
| install-ledger-live.sh | Ledger wallet software |

Vendor installers usually:

- download packages
- install `.deb`
- configure permissions
- handle dependencies

---

# state/

Stores generated state information.

### exports/

Contains exported manifests produced by:

```
scripts/15-export-state.sh
```

This allows the rebuild framework to track the current machine state.

---

# logs/

Every rebuild run generates a timestamped log file.

Example:

```
logs/rebuild-laptop-2026-03-15-173200.log
```

Logs are useful for:

- debugging failures
- auditing installations
- reproducing issues

---

# Typical Usage

Run a full rebuild:

```bash
./rebuild.sh --profile laptop
```

Dry run:

```bash
./rebuild.sh --profile laptop --dry-run
```

Run only one stage:

```bash
./rebuild.sh --profile laptop --only-step 03-install-apt.sh
```

Skip a stage:

```bash
./rebuild.sh --profile laptop --skip-step 03b-install-kali-safe-tools.sh
```

---

# Design Philosophy

The framework intentionally separates:

| Concern | Tool |
|------|------|
| software installation | rebuild scripts |
| configuration files | chezmoi |
| machine differences | profiles |
| package lists | manifests |

This separation prevents configuration drift and keeps the system maintainable.

---

# Long-Term Benefits

This framework enables:

- reproducible machines
- easy migrations to new hardware
- fast VM provisioning
- consistent development environments
- safe experimentation with new tools

