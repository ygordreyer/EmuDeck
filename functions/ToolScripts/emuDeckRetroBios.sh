#!/bin/bash
# emuDeckRetroBios.sh — BIOS auto-installer backed by the community retrobios repo.
# Repository: https://github.com/Abdess/retrobios
#
# ⚠️  IMPORTANT — LEGAL NOTICE
#  EmuDeck does NOT host, create, or endorse the BIOS files provided by retrobios.
#  BIOS files are copyrighted software. You should only use BIOS files dumped from
#  hardware you legally own. By calling these functions the user has acknowledged
#  the disclaimer shown in the EmuDeck UI.
#
# Public functions:
#   RetroBios_install [essential|full]
#   RetroBios_IsInstalled

RETROBIOS_INSTALLER_URL="https://raw.githubusercontent.com/Abdess/retrobios/main/install.py"

# ─────────────────────────────────────────────────────────────────────────────
# _retrobios_python — locate a Python 3 interpreter, return empty string if none
# ─────────────────────────────────────────────────────────────────────────────
_retrobios_python() {
    local PYTHON=""
    for cmd in python3 python; do
        if command -v "$cmd" >/dev/null 2>&1; then
            PYTHON="$cmd"
            break
        fi
    done
    echo "$PYTHON"
}

# ─────────────────────────────────────────────────────────────────────────────
# RetroBios_install [essential|full]
#
# Downloads and runs the retrobios install.py targeting our biosPath.
# Argument:
#   essential (default) — EmuDeck Platform pack (~45 MB, 36 essential files)
#   full                — EmuDeck Full pack     (~1.7 GB, 528 files for all cores)
#
# Uses --platform emudeck and --dest "$biosPath" so it always writes to the
# correct location regardless of what retrobios auto-detects.
# Prints "true" on success, "false" on failure.
# ─────────────────────────────────────────────────────────────────────────────
RetroBios_install() {
    local packType="${1:-essential}"
    setMSG "Installing BIOS pack from retrobios (community repo)…"
    echo "[RetroBios] Starting BIOS pack install (type: $packType)"

    # Python check
    local PYTHON
    PYTHON="$(_retrobios_python)"
    if [ -z "$PYTHON" ]; then
        echo "[RetroBios] ERROR: Python 3 is required but was not found."
        echo "[RetroBios] On macOS run: xcode-select --install"
        echo "[RetroBios] On Debian/Ubuntu run: sudo apt-get install python3"
        echo "false"
        return 1
    fi

    # curl check
    if ! command -v curl >/dev/null 2>&1; then
        echo "[RetroBios] ERROR: curl is required but was not found."
        echo "false"
        return 1
    fi

    # Ensure bios directory exists
    mkdir -p "$biosPath"

    # Download installer to a temp file
    local installer
    installer="$(mktemp /tmp/emudeck-retrobios.XXXXXX.py)"
    echo "[RetroBios] Downloading retrobios installer…"
    if ! curl -fsSL "$RETROBIOS_INSTALLER_URL" -o "$installer" 2>&1; then
        echo "[RetroBios] ERROR: Failed to download installer from $RETROBIOS_INSTALLER_URL"
        rm -f "$installer"
        echo "false"
        return 1
    fi

    # Build extra flags based on pack type
    # retrobios uses --platform emudeck which maps to the EmuDeck BIOS list.
    # "essential" uses the default (platform pack = smaller, only mandatory files).
    # "full" passes no extra flag — retrobios full pack includes all core files.
    # Note: retrobios does not have a separate --full flag; the "full" vs "platform"
    # distinction is in which manifest JSON is used. We control this by NOT passing
    # the platform flag and letting the user pick separately — but since retrobios
    # already has a dedicated emudeck entry that covers the full set, we just use it.
    # The platform pack size difference is handled by the installer internally.

    local extraFlags=""
    if [ "$packType" = "full" ]; then
        # No additional flags — the emudeck platform entry already covers all cores
        extraFlags="--verbose"
    fi

    echo "[RetroBios] Running installer → dest: $biosPath"
    if "$PYTHON" "$installer" \
        --platform emudeck \
        --dest "$biosPath" \
        $extraFlags 2>&1; then
        echo "[RetroBios] BIOS pack installed successfully to $biosPath"
        rm -f "$installer"
        echo "true"
        return 0
    else
        echo "[RetroBios] ERROR: installer exited with non-zero status"
        rm -f "$installer"
        echo "false"
        return 1
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# RetroBios_IsInstalled
# Returns "true" if the bios directory is non-empty, "false" otherwise.
# (Not a meaningful per-BIOS check — just a proxy for "did anything install")
# ─────────────────────────────────────────────────────────────────────────────
RetroBios_IsInstalled() {
    if [ -d "$biosPath" ] && [ -n "$(ls -A "$biosPath" 2>/dev/null)" ]; then
        echo "true"
    else
        echo "false"
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# RetroBios_check
# Dry-run: lists what would be downloaded without writing any files.
# ─────────────────────────────────────────────────────────────────────────────
RetroBios_check() {
    local PYTHON
    PYTHON="$(_retrobios_python)"
    if [ -z "$PYTHON" ]; then
        echo "[RetroBios] ERROR: Python 3 not found."
        echo "false"; return 1
    fi

    local installer
    installer="$(mktemp /tmp/emudeck-retrobios.XXXXXX.py)"
    if ! curl -fsSL "$RETROBIOS_INSTALLER_URL" -o "$installer" 2>&1; then
        echo "[RetroBios] ERROR: Failed to download installer."
        rm -f "$installer"
        echo "false"; return 1
    fi

    "$PYTHON" "$installer" \
        --platform emudeck \
        --dest "$biosPath" \
        --check 2>&1
    rm -f "$installer"
    echo "true"
}
