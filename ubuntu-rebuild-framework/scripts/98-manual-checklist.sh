#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/lib/common.sh"

cat <<'CHECKLIST' | tee -a "$RUN_LOG"

Manual checklist after rebuild:

1. Log out and back in if group membership changed (for docker) or if default shell was updated (chsh).
2. Sign in to browsers, sync tools, and app stores.
3. Restore secrets that are intentionally not auto-provisioned.
4. Verify printer and scanner discovery if applicable.
5. Verify SMB/NFS mounts if you use NAS shares.
6. Open IntelliJ / IDEs once so they finish first-run setup.
7. Open chezmoi and confirm expected managed files.
8. Review logs/ and state/exports/ before committing manifest changes.
9. Reboot once after a full rebuild on a new machine.

CHECKLIST
