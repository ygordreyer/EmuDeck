#!/bin/bash
# darwin/functions/installEmuMacOS.sh
# macOS emulator install primitives.
# Sourced only when system=darwin (via darwin/functions/all.sh).
#
# Public functions:
#   mac_install_cask   <emuName> <caskId> <AppName.app>
#   mac_install_dmg    <emuName> <url>    <AppName.app>
#   mac_install_zip    <emuName> <url>    <AppName.app>
#   mac_install_targz  <emuName> <url>    <AppName.app>
#   mac_emu_skip       <emuName> <reason>

# Shared tmp dir for downloads (cleaned up on exit)
_MAC_EMU_TMPDIR=""

_mac_emu_tmpdir() {
    if [ -z "$_MAC_EMU_TMPDIR" ]; then
        _MAC_EMU_TMPDIR="$(mktemp -d /tmp/emudeck-mac-install.XXXXXX)"
    fi
    echo "$_MAC_EMU_TMPDIR"
}

_mac_emu_cleanup_tmp() {
    if [ -n "$_MAC_EMU_TMPDIR" ] && [ -d "$_MAC_EMU_TMPDIR" ]; then
        rm -rf "$_MAC_EMU_TMPDIR"
        _MAC_EMU_TMPDIR=""
    fi
}
# Register cleanup on script exit
trap '_mac_emu_cleanup_tmp' EXIT

# ─────────────────────────────────────────────────────────────────────────────
# mac_emu_skip <emuName> <reason>
# Graceful early-return for emulators not supported on macOS.
# ─────────────────────────────────────────────────────────────────────────────
mac_emu_skip() {
    local name="$1"
    local reason="${2:-Not available on macOS}"
    echo "[mac] SKIP ${name}: ${reason}"
    return 0
}

# ─────────────────────────────────────────────────────────────────────────────
# mac_install_cask <emuName> <caskId> <AppName.app>
#
# Installs via `brew install --cask`.
# Brew handles: codesigning, placement in /Applications, auto-update tokens.
# Idempotent: brew skips if already installed.
# ─────────────────────────────────────────────────────────────────────────────
mac_install_cask() {
    local name="$1"
    local caskId="$2"
    local appName="$3"

    setMSG "Installing ${name} (macOS)"
    echo "[mac] Installing ${name} via brew cask: ${caskId}"

    # brew install --cask is idempotent; --no-quarantine removes the xattr at install time
    if brew install --cask "$caskId" --no-quarantine 2>&1; then
        echo "[mac] ${name} installed successfully."
        mac_unquarantine "/Applications/${appName}"
        return 0
    else
        echo "[mac] brew install --cask ${caskId} failed."
        return 1
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# mac_install_dmg <emuName> <url> <AppName.app>
#
# Downloads a DMG, mounts it, copies the .app to /Applications, unmounts.
# ─────────────────────────────────────────────────────────────────────────────
mac_install_dmg() {
    local name="$1"
    local url="$2"
    local appName="$3"

    if [ -z "$url" ]; then
        echo "[mac] ERROR: No download URL provided for ${name}."
        return 1
    fi

    setMSG "Installing ${name} (macOS)"
    echo "[mac] Installing ${name} via DMG: ${url}"

    local tmpDir
    tmpDir="$(_mac_emu_tmpdir)/${name}"
    mkdir -p "$tmpDir"

    local dmgFile="${tmpDir}/${name}.dmg"
    local mountPoint="${tmpDir}/mount"

    # Download
    echo "[mac] Downloading DMG..."
    if ! curl -L --progress-bar -o "$dmgFile" "$url"; then
        echo "[mac] ERROR: Download failed for ${name}."
        return 1
    fi

    # Mount
    echo "[mac] Mounting DMG..."
    mkdir -p "$mountPoint"
    if ! hdiutil attach "$dmgFile" -mountpoint "$mountPoint" -nobrowse -quiet; then
        echo "[mac] ERROR: hdiutil attach failed for ${name}."
        return 1
    fi

    # Find .app in mounted volume
    local foundApp
    foundApp=$(find "$mountPoint" -maxdepth 3 -name "${appName}" -type d | head -1)

    if [ -z "$foundApp" ]; then
        # Fallback: find any .app
        foundApp=$(find "$mountPoint" -maxdepth 3 -name "*.app" -type d | head -1)
        echo "[mac] Warning: ${appName} not found; using ${foundApp}"
    fi

    if [ -z "$foundApp" ]; then
        echo "[mac] ERROR: No .app found in DMG for ${name}."
        hdiutil detach "$mountPoint" -quiet 2>/dev/null || true
        return 1
    fi

    # Copy to /Applications (overwrite)
    echo "[mac] Installing ${foundApp} → /Applications/"
    rm -rf "/Applications/${appName}" 2>/dev/null || true
    if ! cp -R "$foundApp" "/Applications/"; then
        echo "[mac] ERROR: cp to /Applications failed. Trying ~/Applications..."
        mkdir -p "${HOME}/Applications"
        cp -R "$foundApp" "${HOME}/Applications/" || { hdiutil detach "$mountPoint" -quiet; return 1; }
    fi

    # Unmount
    hdiutil detach "$mountPoint" -quiet 2>/dev/null || true

    # Remove quarantine
    mac_unquarantine "/Applications/${appName}"
    mac_unquarantine "${HOME}/Applications/${appName}"

    echo "[mac] ${name} installed successfully."
    return 0
}

# ─────────────────────────────────────────────────────────────────────────────
# mac_install_zip <emuName> <url> <AppName.app>
#
# Downloads a ZIP, extracts, finds the .app, copies to /Applications.
# ─────────────────────────────────────────────────────────────────────────────
mac_install_zip() {
    local name="$1"
    local url="$2"
    local appName="$3"

    if [ -z "$url" ]; then
        echo "[mac] ERROR: No download URL provided for ${name}."
        return 1
    fi

    setMSG "Installing ${name} (macOS)"
    echo "[mac] Installing ${name} via ZIP: ${url}"

    local tmpDir
    tmpDir="$(_mac_emu_tmpdir)/${name}"
    mkdir -p "$tmpDir"

    local zipFile="${tmpDir}/${name}.zip"
    local extractDir="${tmpDir}/extracted"
    mkdir -p "$extractDir"

    # Download
    echo "[mac] Downloading ZIP..."
    if ! curl -L --progress-bar -o "$zipFile" "$url"; then
        echo "[mac] ERROR: Download failed for ${name}."
        return 1
    fi

    # Extract
    echo "[mac] Extracting ZIP..."
    if ! unzip -q "$zipFile" -d "$extractDir"; then
        echo "[mac] ERROR: unzip failed for ${name}."
        return 1
    fi

    # Find .app
    local foundApp
    foundApp=$(find "$extractDir" -maxdepth 5 -name "${appName}" -type d | head -1)

    if [ -z "$foundApp" ]; then
        foundApp=$(find "$extractDir" -maxdepth 5 -name "*.app" -type d | head -1)
        echo "[mac] Warning: ${appName} not found; using ${foundApp}"
    fi

    if [ -z "$foundApp" ]; then
        echo "[mac] ERROR: No .app found in ZIP for ${name}."
        return 1
    fi

    # Copy to /Applications
    echo "[mac] Installing ${foundApp} → /Applications/"
    rm -rf "/Applications/${appName}" 2>/dev/null || true
    if ! cp -R "$foundApp" "/Applications/"; then
        echo "[mac] ERROR: cp to /Applications failed. Trying ~/Applications..."
        mkdir -p "${HOME}/Applications"
        cp -R "$foundApp" "${HOME}/Applications/" || return 1
    fi

    mac_unquarantine "/Applications/${appName}"
    mac_unquarantine "${HOME}/Applications/${appName}"

    echo "[mac] ${name} installed successfully."
    return 0
}

# ─────────────────────────────────────────────────────────────────────────────
# mac_install_targz <emuName> <url> <AppName.app>
#
# Downloads a .tar.gz, extracts, finds the .app, copies to /Applications.
# Used for Ryujinx and similar.
# ─────────────────────────────────────────────────────────────────────────────
mac_install_targz() {
    local name="$1"
    local url="$2"
    local appName="$3"

    if [ -z "$url" ]; then
        echo "[mac] ERROR: No download URL provided for ${name}."
        return 1
    fi

    setMSG "Installing ${name} (macOS)"
    echo "[mac] Installing ${name} via tar.gz: ${url}"

    local tmpDir
    tmpDir="$(_mac_emu_tmpdir)/${name}"
    mkdir -p "$tmpDir"

    local tarFile="${tmpDir}/${name}.tar.gz"
    local extractDir="${tmpDir}/extracted"
    mkdir -p "$extractDir"

    # Download
    echo "[mac] Downloading tar.gz..."
    if ! curl -L --progress-bar -o "$tarFile" "$url"; then
        echo "[mac] ERROR: Download failed for ${name}."
        return 1
    fi

    # Extract
    echo "[mac] Extracting tar.gz..."
    if ! tar -xzf "$tarFile" -C "$extractDir"; then
        echo "[mac] ERROR: tar extraction failed for ${name}."
        return 1
    fi

    # Find .app
    local foundApp
    foundApp=$(find "$extractDir" -maxdepth 5 -name "${appName}" -type d | head -1)

    if [ -z "$foundApp" ]; then
        foundApp=$(find "$extractDir" -maxdepth 5 -name "*.app" -type d | head -1)
        echo "[mac] Warning: ${appName} not found; using ${foundApp}"
    fi

    if [ -z "$foundApp" ]; then
        echo "[mac] ERROR: No .app found in tar.gz for ${name}."
        return 1
    fi

    # Copy to /Applications
    echo "[mac] Installing ${foundApp} → /Applications/"
    rm -rf "/Applications/${appName}" 2>/dev/null || true
    if ! cp -R "$foundApp" "/Applications/"; then
        echo "[mac] ERROR: cp to /Applications failed. Trying ~/Applications..."
        mkdir -p "${HOME}/Applications"
        cp -R "$foundApp" "${HOME}/Applications/" || return 1
    fi

    mac_unquarantine "/Applications/${appName}"
    mac_unquarantine "${HOME}/Applications/${appName}"

    echo "[mac] ${name} installed successfully."
    return 0
}

# ─────────────────────────────────────────────────────────────────────────────
# mac_install_7z <emuName> <url> <AppName.app>
#
# Downloads a .7z archive, extracts with 7z (p7zip), finds the .app, copies
# to /Applications. Requires: brew install p7zip
# Used for RPCS3 (rpcs3-*_macos.7z) and any other 7z-distributed emulators.
# ─────────────────────────────────────────────────────────────────────────────
mac_install_7z() {
    local name="$1"
    local url="$2"
    local appName="$3"

    if [ -z "$url" ]; then
        echo "[mac] ERROR: No download URL provided for ${name}."
        return 1
    fi

    # Ensure 7z is available
    if ! command -v 7z >/dev/null 2>&1 && ! command -v 7za >/dev/null 2>&1; then
        echo "[mac] 7z not found — installing p7zip via Homebrew..."
        if ! brew install p7zip 2>&1; then
            echo "[mac] ERROR: Failed to install p7zip. Cannot extract .7z archive for ${name}."
            return 1
        fi
    fi
    local _7z_cmd="7z"
    command -v 7z >/dev/null 2>&1 || _7z_cmd="7za"

    setMSG "Installing ${name} (macOS)"
    echo "[mac] Installing ${name} via .7z: ${url}"

    local tmpDir
    tmpDir="$(_mac_emu_tmpdir)/${name}"
    mkdir -p "$tmpDir"

    local archiveFile="${tmpDir}/${name}.7z"
    local extractDir="${tmpDir}/extracted"
    mkdir -p "$extractDir"

    # Download
    echo "[mac] Downloading .7z archive..."
    if ! curl -L --progress-bar -o "$archiveFile" "$url"; then
        echo "[mac] ERROR: Download failed for ${name}."
        return 1
    fi

    # Extract
    echo "[mac] Extracting .7z archive..."
    if ! ${_7z_cmd} x "$archiveFile" -o"$extractDir" -y 2>&1; then
        echo "[mac] ERROR: 7z extraction failed for ${name}."
        return 1
    fi

    # Find .app in extracted content
    local foundApp
    foundApp=$(find "$extractDir" -maxdepth 5 -name "${appName}" -type d | head -1)

    if [ -z "$foundApp" ]; then
        foundApp=$(find "$extractDir" -maxdepth 5 -name "*.app" -type d | head -1)
        echo "[mac] Warning: ${appName} not found; using ${foundApp}"
    fi

    if [ -z "$foundApp" ]; then
        echo "[mac] ERROR: No .app found in .7z archive for ${name}."
        return 1
    fi

    # Copy to /Applications
    echo "[mac] Installing ${foundApp} → /Applications/"
    rm -rf "/Applications/${appName}" 2>/dev/null || true
    if ! cp -R "$foundApp" "/Applications/"; then
        echo "[mac] ERROR: cp to /Applications failed. Trying ~/Applications..."
        mkdir -p "${HOME}/Applications"
        cp -R "$foundApp" "${HOME}/Applications/" || return 1
    fi

    mac_unquarantine "/Applications/${appName}"
    mac_unquarantine "${HOME}/Applications/${appName}"

    echo "[mac] ${name} installed successfully."
    return 0
}

# ─────────────────────────────────────────────────────────────────────────────
# mac_uninstall_cask <emuName> <caskId>
# Uninstalls a cask-installed app. Falls back to mac_uninstall_app on failure.
# ─────────────────────────────────────────────────────────────────────────────
mac_uninstall_cask() {
    local name="$1"
    local caskId="$2"
    local appName="${3:-}"

    echo "[mac] Uninstalling ${name} cask: ${caskId}"
    if brew uninstall --cask "$caskId" 2>/dev/null; then
        echo "[mac] ${name} uninstalled via brew."
    elif [ -n "$appName" ]; then
        mac_uninstall_app "$appName"
    fi
}
