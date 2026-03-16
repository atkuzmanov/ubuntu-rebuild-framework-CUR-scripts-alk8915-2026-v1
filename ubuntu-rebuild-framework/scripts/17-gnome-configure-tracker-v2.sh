#!/usr/bin/env bash
set -Eeuo pipefail

# ==========================================================
# Configure GNOME Tracker for developer machines
#
# Prevents heavy CPU usage by limiting indexing scope
# and ignoring large developer directories.
#
# Safe to run multiple times (idempotent).
# ==========================================================

SCHEMA="org.freedesktop.Tracker3.Miner.Files"

log() {
    echo "[INFO] $*"
}

warn() {
    echo "[WARN] $*" >&2
}

have_cmd() {
    command -v "$1" >/dev/null 2>&1
}

set_setting() {
    local key="$1"
    local desired="$2"
    local current

    current="$(gsettings get "$SCHEMA" "$key" 2>/dev/null || true)"

    if [[ "$current" == "$desired" ]]; then
        log "Tracker setting already correct: $key = $desired"
    else
        log "Setting Tracker $key = $desired"
        gsettings set "$SCHEMA" "$key" "$desired"
    fi
}

main() {

    log "Configuring GNOME Tracker (developer-friendly configuration)..."

    if ! have_cmd gsettings; then
        warn "gsettings not found. Skipping Tracker configuration."
        exit 0
    fi

    # ------------------------------------------------------
    # Limit indexing scope
    # ------------------------------------------------------

    set_setting "index-single-directories" "['&DOWNLOAD']"

    # Disable indexing when on battery
    set_setting "index-on-battery" "false"

    # Limit CPU usage
    set_setting "throttle" "20"

    # ------------------------------------------------------
    # Ignore large developer directories
    # ------------------------------------------------------

    set_setting "ignored-directories" "[
        'po',
        'CVS',
        'core-dumps',
        'lost+found',
        'node_modules',
        'build',
        'dist',
        'target',
        '.venv',
        '.cache',
        'Ubuntu-bkps-alk8915-2026-1'
    ]"

    # ------------------------------------------------------
    # Ignore heavy file types
    # ------------------------------------------------------

    set_setting "ignored-files" "[
        '*~',
        '*.o',
        '*.la',
        '*.lo',
        '*.loT',
        '*.in',
        '*.m4',
        '*.rej',
        '*.gmo',
        '*.orig',
        '*.pc',
        '*.omf',
        '*.aux',
        '*.tmp',
        '*.vmdk',
        '*.vm*',
        '*.nvram',
        '*.part',
        '*.rcore',
        '*.lzo',
        '*.img',
        '*.qcow2',
        '*.tar',
        '*.tar.gz',
        '*.zip',
        '*.7z',
        '*.iso'
    ]"

    # ------------------------------------------------------
    # Restart Tracker so changes apply
    # ------------------------------------------------------

    if have_cmd tracker3; then
        log "Restarting Tracker..."

        tracker3 daemon -t || true
        tracker3 daemon -s || true
    else
        warn "tracker3 not installed. Settings applied but service not restarted."
    fi

    # ------------------------------------------------------
    # Show resulting configuration
    # ------------------------------------------------------

    log "Tracker configuration summary:"

    gsettings get "$SCHEMA" index-single-directories || true
    gsettings get "$SCHEMA" index-on-battery || true
    gsettings get "$SCHEMA" throttle || true
    gsettings get "$SCHEMA" ignored-directories || true
    gsettings get "$SCHEMA" ignored-files || true

    log "Tracker configuration complete."
}

main "$@"


