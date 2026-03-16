# Framework Conventions

This document defines the conventions used by the Ubuntu rebuild framework so it stays predictable, maintainable, and safe to extend over time.

## Core Principles

The framework follows these principles:

- Idempotent by default
- Safe to re-run
- Explicit rather than hidden
- Layered responsibilities
- Conservative with destructive actions
- Easy to debug
- Profile-driven where appropriate

The goal is not to automate everything. The goal is to automate the right things in a robust way.

## Responsibility Boundaries

Use this rule first:

**Installation belongs in rebuild scripts. Configuration belongs in chezmoi.**

### Rebuild scripts own

- repository setup
- package installation
- vendor installers
- system-level configuration
- validation
- state export

### Chezmoi owns

- dotfiles
- shell configuration
- git configuration
- editor configuration
- application config files
- small user-level helper scripts

### Manual steps own

- disk partitioning
- full-disk encryption
- BIOS / UEFI settings
- account login flows
- secrets that require interactive approval
- hardware-specific judgment calls

## Naming Conventions

### Script naming

Stage scripts must use numeric prefixes so execution order is obvious.

Examples:

- `00-preflight.sh`
- `01-system-prep.sh`
- `10-install-manual-apps.sh`
- `14-validate.sh`

Vendor scripts should use explicit names describing what they install.

Examples:

- `install-cursor-sandbox-apparmor.sh`
- `install-warp.sh`
- `install-insync.sh`

### File naming

Manifest names should reflect the installer or ecosystem:

- `apt-packages.txt`
- `snap-packages.txt`
- `flatpak-packages.txt`
- `pipx-packages.txt`
- `cargo-packages.txt`
- `npm-global-packages.txt`

Profile names should describe the machine role:

- `laptop.env`
- `vm.env`
- `workstation.env`

## Logging Rules

Every stage script should source shared helpers from `lib/common.sh` and use the framework logging functions.

Use:

- `log_info` for normal progress
- `log_warn` for recoverable issues
- `log_error` for failures

Do not mix framework logging with ad hoc `echo` unless there is a very specific reason.

Preferred:

```bash
log_info "Installing apt packages"
```

Avoid:

```bash
echo "Installing apt packages"
```

## Error Handling Rules

Each script should begin with:

```bash
#!/usr/bin/env bash
set -Eeuo pipefail
```

This prevents silent failures and makes debugging more reliable.

Use `run_cmd` for commands that should be logged and executed consistently.

Preferred:

```bash
run_cmd sudo apt-get update
```

If a command is intentionally allowed to fail, make that explicit and explain why.

Preferred:

```bash
run_cmd bash -c 'sudo systemctl enable tlp || true'
```

or:

```bash
if ! run_cmd some-command; then
  log_warn "some-command failed, continuing because it is optional on this profile"
fi
```

Do not hide failures without explanation.

## Idempotency Rules

Every install or configuration step should be safe to run again.

### Packages

Check whether software is already installed before reinstalling when practical.

Examples:

- `dpkg -s <pkg>`
- `snap list <name>`
- `flatpak info <app-id>`
- `command -v <cmd>`

### Files

Do not only check whether a file exists. Also consider whether its content is correct.

Preferred pattern:

- write the expected content
- compare against the existing file
- update only if different

This avoids configuration drift.

### Downloads

Downloaded vendor installers should go to a temporary or cache directory and should be reused or replaced deliberately.

### User modifications

Do not overwrite user-managed files outside the known managed paths unless the design explicitly requires it.

## Feature Flag Rules

Feature flags should be controlled through profile files in `profiles/*.env`.

Examples:

- `INSTALL_CURSOR=true`
- `INSTALL_WARP=false`
- `ENABLE_TLP=true`

Use `want_feature` to read these flags in scripts.

Preferred:

```bash
if want_feature INSTALL_CURSOR; then
  ...
fi
```

Use positive feature names where possible.

Preferred:

- `INSTALL_CURSOR`
- `ENABLE_TLP`

Avoid unclear names such as:

- `NO_CURSOR`
- `DISABLE_NOTHING`

## Where New Software Belongs

Use this decision order:

1. If it is a normal Ubuntu package, put it in `manifests/apt-packages.txt`
2. If it is a snap, put it in `manifests/snap-packages.txt`
3. If it is a flatpak, put it in `manifests/flatpak-packages.txt`
4. If it is a pipx tool, put it in `manifests/pipx-packages.txt`
5. If it is a cargo tool, put it in `manifests/cargo-packages.txt`
6. If it is an npm global tool, put it in `manifests/npm-global-packages.txt`
7. If it requires manual download or vendor-specific logic, create a script in `scripts/vendor/`
8. If it is only configuration, manage it in chezmoi

## Validation Rules

Validation should check for the things that matter most:

- essential commands exist
- package managers are usable
- critical services are active when expected
- expected configuration files exist
- profile-specific features are present when enabled

Validation should not try to prove every possible thing. It should focus on the most important indicators of a healthy rebuild.

## Documentation Rules

If a new stage, feature flag, or vendor installer is added, update the relevant docs.

At minimum, consider updating:

- `docs/architecture.md`
- `docs/adding-new-software.md`
- `docs/rebuild-procedure.md`
- `docs/troubleshooting.md`

If the change is a convention or framework-wide rule, update this document too.

## Git and State Management Rules

The rebuild repo should be version-controlled.

Recommended practice:

- commit manifest changes after export
- commit new vendor scripts with documentation
- keep profiles intentional and readable
- avoid committing secrets

If the machine state changes significantly, run:

```bash
scripts/15-export-state.sh
```

and review the resulting diffs before committing.

## Security Rules

Prefer the most maintainable secure option, not the most complicated option.

Good examples:

- use official repositories when possible
- use signed packages or trusted upstream download sources
- keep manual installers isolated in vendor scripts
- leave dangerous system setup manual where appropriate

Do not add automation that creates more risk than value.

## Practical Standard

When deciding where something belongs, ask:

- Is this installation or configuration?
- Is this system-level or user-level?
- Is this generic or vendor-specific?
- Is this safe to re-run?
- Will this still make sense a year from now?

If the answer is clear, the correct place in the framework is usually clear too.
