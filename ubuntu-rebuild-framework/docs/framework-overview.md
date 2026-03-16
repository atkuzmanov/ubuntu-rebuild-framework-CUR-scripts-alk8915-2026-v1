# Ubuntu Rebuild Framework – Overview

This repository provides a structured and reproducible way to rebuild an Ubuntu development machine.

Design goals:

- Reproducible environment
- Idempotent scripts
- Clear separation of responsibilities
- Safe to re-run multiple times
- Works for laptops, workstations, and VMs

Architecture layers:

1. Preflight checks
2. Base system preparation
3. Repository configuration
4. Package installation
5. Vendor/manual installers
6. Configuration via chezmoi
7. Post configuration tasks
8. Validation
9. State export

Core principle:

**Installation logic lives in rebuild scripts. Configuration lives in chezmoi.**
