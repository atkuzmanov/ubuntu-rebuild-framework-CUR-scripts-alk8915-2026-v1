# Security and privacy before publishing

Before pushing this repository to a public GitHub (or any public host), verify:

## What is safe to commit

- All scripts, manifests, and documentation in this framework
- Profile files with `CHEZMOI_REPO=""` (empty or your public repo URL)
- Placeholder URLs like `git@github.com:you/dotfiles.git`

## What must NOT be committed

- **API keys, tokens, passwords** – none are present in this framework
- **SSH keys or private key material** – manage via chezmoi or manually
- **Secrets in profile files** – keep `CHEZMOI_REPO` empty or use a public URL; do not put tokens in env files

## If your git repo root is the parent folder

If you initialize git at the parent of `ubuntu-rebuild-framework/` (e.g. the full workspace), add to `.gitignore`:

```
.specstory/
.vscode/
.cursorindexingignore
```

These may contain:

- User email addresses
- Workspace IDs
- Full chat/conversation history
- Local filesystem paths

## Recommended repo layout

Initialize git with `ubuntu-rebuild-framework/` as the root so that `.specstory`, `.vscode`, and other tooling folders stay outside the repository:

```bash
cd ubuntu-rebuild-framework
git init
```

The included `.gitignore` excludes `logs/`, `state/exports/`, and `*-exported.txt` from this folder.
