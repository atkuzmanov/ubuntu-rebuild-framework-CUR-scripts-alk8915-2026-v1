# Offline Bundle – Air-Gapped / No-Internet Setup

This folder lets you **download all software** on a machine with internet, store it locally, then **install everything from local storage** when you have no connectivity (new machine, USB, external HDD, etc.).

## Workflows

### A) Manifest-based (profile + manifests)

1. **When you have internet:** Run `./download-bundle.sh --profile laptop` to download all packages from manifests into `cache/`.
2. **Copy `offline-bundle/`** (including `cache/`) to external storage (USB, HDD, CD).
3. **On the target machine (no internet):** Mount the storage, `cd` into `offline-bundle`, and run `./install-from-bundle.sh --profile laptop`.

### B) Clone this machine (no profile)

Captures whatever is currently installed (apt-mark manual, snap list, flatpak list, pip --user, pipx) into a separate cache. Use when you want to replicate this machine’s software set without maintaining manifests.

1. **On the source machine (with internet):** Run `./collect-from-machine.sh`. This creates `clone-cache/` (or pass a path: `./collect-from-machine.sh /media/drive/clone-cache`).  
   To **only export lists** of installed software (no downloads):  
   `./collect-from-machine.sh --lists-only [output-dir]` — writes apt, snap, flatpak, pip, pipx and meta list files only.
2. **Copy `clone-cache/`** and `install-from-clone-cache.sh` to the target (or the whole `offline-bundle/` folder).
3. **On the target (offline):** Run `./install-from-clone-cache.sh [path-to-clone-cache]`.

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
├── download-bundle.sh         # Run when online (manifest-based)
├── install-from-bundle.sh     # Run when offline (manifest-based)
├── collect-from-machine.sh   # Run when online (clone this machine)
├── install-from-clone-cache.sh # Run when offline (from clone cache)
├── cache/                    # Manifest-based bundle output
│   ├── apt/                 # .deb files + Packages.gz (local apt repo)
│   ├── apt-keys/            # GPG keys for external repos
│   ├── snap/                # .snap and .assert files
│   ├── flatpak/             # .flatpak bundle files (system + user)
│   ├── pip/                 # pip --user wheelhouse + pip-user-freeze.txt
│   ├── pipx/                # Python wheels
│   ├── uv/, npm/, cargo/    # As used by manifests
│   ├── vendor/              # Manual .deb, AppImage (README.txt, MANUAL-SOFTWARE-NOTES.txt)
│   ├── meta/                # collection-info.txt for debugging
│   └── SHA256SUMS
└── clone-cache/              # Clone-from-machine output (apt/archives, apt-manual.txt, snap/, flatpak/, pip/, pipx/, vendor/, meta/, SHA256SUMS)
```

## Vendor URL list (clone-from-machine)

To automate downloads of packages that apt could not fetch (e.g. third-party .deb), add their **direct download URLs** to **`manifests/vendor-download-urls.txt`**. When you run `collect-from-machine.sh`, it will download each URL into the cache `vendor/` folder.

- One URL per line; lines starting with `#` and empty lines are ignored.
- Optional second column: filename to save as (e.g. `https://example.com/path/file.deb  zoom.deb`). If omitted, the filename is taken from the URL.
- Requires `curl`. Add or update lines, then run `./collect-from-machine.sh` again; new files appear in `cache/vendor/`.

## Manual / vendor software

Place manually downloaded installers (`.deb`, `.AppImage`, etc.) in a folder and either:

- Copy them into `offline-bundle/cache/vendor/` before running `install-from-bundle.sh`, **or**
- Set `OFFLINE_VENDOR_SOURCE_DIR` when downloading so they are copied during the bundle step:

  ```bash
  OFFLINE_VENDOR_SOURCE_DIR="$HOME/Downloads/vendor" ./download-bundle.sh --profile laptop
  ```

## Pip user packages (manifest-based)

Add package names (one per line) to `manifests/pip-user-packages.txt`. They are downloaded into `cache/pip/wheelhouse` and installed with `pip install --user` on the target. Omit or leave the file empty to skip.

## Flatpak user vs system

When building flatpak bundles, the script uses the system repo (`/var/lib/flatpak/repo`) or the user repo (`~/.local/share/flatpak/repo`) depending on where each app is installed, so both user- and system-installed flatpaks are bundled correctly.

## Storage size

Expect several GB depending on your manifests (apt + snap + flatpak are largest). Check `du -sh cache/` or `du -sh clone-cache/` before copying to removable media.
