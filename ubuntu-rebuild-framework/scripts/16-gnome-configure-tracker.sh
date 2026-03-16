#!/usr/bin/env bash
set -e

echo "Applying Tracker developer-friendly configuration..."

gsettings set org.freedesktop.Tracker3.Miner.Files index-single-directories "['&DOWNLOAD']"

gsettings set org.freedesktop.Tracker3.Miner.Files index-on-battery false

gsettings set org.freedesktop.Tracker3.Miner.Files throttle 20

gsettings set org.freedesktop.Tracker3.Miner.Files ignored-directories \
"['po', 'CVS', 'core-dumps', 'lost+found', 'node_modules', 'build', 'dist', 'target', '.venv', '.cache', 'Ubuntu-bkps-alk8915-2026-1']"

echo "Restarting Tracker..."

tracker3 daemon -t || true
tracker3 reset --filesystem || true
tracker3 daemon -s || true

echo "Tracker configuration applied."


