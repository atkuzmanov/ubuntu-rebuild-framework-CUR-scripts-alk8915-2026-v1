# Offline Bundle – Air-Gapped / No-Internet Setup

This folder lets you **download all software** on a machine with internet, store it locally, then **install everything from local storage** when you have no connectivity (new machine, USB, external HDD, etc.).

## Workflow

1. **When you have internet:** Run `./download-bundle.sh --profile laptop` to download all packages, snaps, flatpaks, pipx tools, etc., into `cache/`.
2. **Copy `offline-bundle/`** (including `cache/`) to external storage (USB, HDD, CD).
3. **On the target machine (no internet):** Mount the storage, `cd` into `offline-bundle`, and run `./install-from-bundle.sh --profile laptop`.

## Requirements

### For downloading (online)
- Same Ubuntu version as target (or compatible)
- `dpkg-dev` (for creating local apt repo): `sudo apt-get install dpkg-dev`
- All package managers: apt, snap, flatpak, pipx, cargo, uv, npm (as needed by your manifests)
- Internet connection

### For installing (offline)
- Fresh or existing Ubuntu install (same major version as bundle)
- Root/sudo access
- The bundle `cache/` directory populated by `download-bundle.sh`

## Directory layout (after download)

```
offline-bundle/
├── README.md
├── download-bundle.sh      # Run when online
├── install-from-bundle.sh  # Run when offline
└── cache/
    ├── apt/                # .deb files + Packages.gz (local apt repo)
    ├── apt-keys/           # GPG keys for external repos (Docker, Brave, etc.)
    ├── snap/               # .snap and .assert files
    ├── flatpak/            # .flatpak bundle files
    ├── pipx/               # Python wheels
    ├── uv/                 # UV tool wheels
    ├── npm/                # npm package tarballs
    ├── cargo/              # Cargo crates (if supported)
    └── vendor/              # Manual .deb, AppImage, etc.
```

## Manual / vendor software

Place manually downloaded installers (`.deb`, `.AppImage`, etc.) in a folder and either:

- Copy them into `offline-bundle/cache/vendor/` before running `install-from-bundle.sh`, **or**
- Set `OFFLINE_VENDOR_SOURCE_DIR` when downloading so they are copied during the bundle step:

  ```bash
  OFFLINE_VENDOR_SOURCE_DIR="$HOME/Downloads/vendor" ./download-bundle.sh --profile laptop
  ```

## Storage size

Expect several GB depending on your manifests (apt + snap + flatpak are largest). Check `du -sh cache/` before copying to removable media.
