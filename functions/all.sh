#!/bin/bash
appleChip=$(uname -m)
if [ $(uname) != "Linux" ]; then
    system="darwin"
    if [ $appleChip = 'arm64' ]; then
        PATH="/opt/homebrew/opt/gnu-sed/libexec/gnubin:$PATH"
    else
        PATH="/usr/local/opt/gnu-sed/libexec/gnubin:$PATH"
    fi
fi

if [[ -z "$emudeckBackend" ]]; then
    emudeckBackend="$HOME/.config/EmuDeck/backend/"
fi

# ── HARD GUARD: darwin/ must exist before we try to source any macOS scripts ──────────────
# Root cause protection: if the backend was cloned from a branch without macOS support
# (e.g., stale upstream 'beta'), the darwin/ directory won't exist. Fail loudly here
# instead of producing 100 cryptic errors further down.
if [ "$(uname)" != "Linux" ] && [ ! -d "${emudeckBackend}/darwin" ]; then
    echo "[EmuDeck] FATAL: darwin/ directory is missing from backend at ${emudeckBackend}." >&2
    echo "[EmuDeck] The backend was cloned from a branch without macOS support." >&2
    echo "[EmuDeck] Fix: delete ~/.config/EmuDeck and relaunch EmuDeck to force a fresh re-clone." >&2
    exit 1
fi
# ──────────────────────────────────────────────────────────────────────────────────────────

#Vars
source "$emudeckBackend"/vars.sh

#load helpers first, just in case
source "$emudeckBackend"/functions/helperFunctions.sh



# ── macOS: guard against empty/corrupt settings files BEFORE sourcing ─────────
# Root cause of "ROM dirs scattered in $HOME": a stale empty settings.sh (only
# #!/bin/bash, no romsPath) gets sourced → all $vars empty → mkdir "$romsPath/snes"
# expands to mkdir "/snes" or falls back to $HOME/snes. Purge it now.
if [ "$(uname)" != "Linux" ]; then
    _darwin_home_settings="$HOME/emudeck/settings.sh"
    # Purge if it exists but contains no romsPath= line
    if [ -f "$_darwin_home_settings" ] && ! grep -q "^[[:space:]]*romsPath=" "$_darwin_home_settings" 2>/dev/null; then
        echo "[EmuDeck] Purging empty/corrupt $_darwin_home_settings (no romsPath) — will re-seed." >&2
        rm -f "$_darwin_home_settings"
    fi
    # Re-seed if still missing
    if [ ! -f "$_darwin_home_settings" ]; then
        mkdir -p "$HOME/emudeck"
        cat > "$_darwin_home_settings" <<DARWIN_DEFAULTS
#!/bin/bash
system="darwin"
emulationPath="$HOME/Emulation"
romsPath="$HOME/Emulation/roms"
toolsPath="$HOME/Emulation/tools"
biosPath="$HOME/Emulation/bios"
savesPath="$HOME/Emulation/saves"
storagePath="$HOME/Emulation/storage"
DARWIN_DEFAULTS
        echo "[EmuDeck] settings.sh seeded with macOS defaults." >&2
    fi
fi
# ──────────────────────────────────────────────────────────────────────────────

SETTINGSFILE="$emudeckFolder/settings.sh"
if [ -f "$SETTINGSFILE" ] &&  [ ! -L "$SETTINGSFILE" ]; then
    # shellcheck source=./settings.sh
    source "$SETTINGSFILE"
else
    source "$HOME/emudeck/settings.sh"
fi

# ── HARD GUARD: abort if any critical path is empty after sourcing ────────────
# This prevents any downstream mkdir/cp/rsync from writing to the wrong location.
if [ -z "${romsPath:-}" ] || [ -z "${emulationPath:-}" ] || [ -z "${biosPath:-}" ] || [ -z "${savesPath:-}" ]; then
    _err="EmuDeck: settings file is invalid (critical paths empty). To recover, delete ~/.config/EmuDeck and ~/emudeck, then re-run EmuDeck. The current operation has been aborted to prevent file scatter."
    echo "FATAL: $_err" >&2
    if [ "$(uname)" != "Linux" ]; then
        osascript -e "display alert \"EmuDeck install aborted\" message \"$_err\" as critical" 2>/dev/null || true
    fi
    exit 1
fi
# Guard: romsPath must live under $HOME, /Volumes (external Mac drive), or /run/media (Linux SD)
case "$romsPath" in
    "$HOME"/* | /Volumes/* | /run/media/*) : ;;
    *)
        echo "FATAL: romsPath ($romsPath) is not under \$HOME, /Volumes, or /run/media — refusing to proceed." >&2
        exit 1 ;;
esac
# ──────────────────────────────────────────────────────────────────────────────

if [ "$system" != "darwin" ]; then
    export PATH="$emudeckBackend/tools/binaries/:$PATH"
    chmod +x "$emudeckBackend/tools/binaries/xmlstarlet"
fi

source "$emudeckBackend"/functions/checkBIOS.sh
source "$emudeckBackend"/functions/checkInstalledEmus.sh
#source "$emudeckBackend"/functions/cloudServicesManager.sh
source "$emudeckBackend"/functions/configEmuAI.sh
source "$emudeckBackend"/functions/configEmuFP.sh
source "$emudeckBackend"/functions/createDesktopIcons.sh
source "$emudeckBackend"/functions/installEmuFP.sh
source "$emudeckBackend"/functions/uninstallEmuFP.sh
source "$emudeckBackend"/functions/setMSG.sh
source "$emudeckBackend"/functions/emuDeckPrereqs.sh
source "$emudeckBackend"/functions/installEmuAI.sh
source "$emudeckBackend"/functions/uninstallEmuAI.sh
source "$emudeckBackend"/functions/installEmuBI.sh
source "$emudeckBackend"/functions/uninstallGeneric.sh
source "$emudeckBackend"/functions/installToolAI.sh
source "$emudeckBackend"/functions/migrateAndLinkConfig.sh
source "$emudeckBackend"/functions/nonDeck.sh
source "$emudeckBackend"/functions/dialogBox.sh
source "$emudeckBackend"/functions/updateEmuFP.sh
source "$emudeckBackend"/functions/createFolders.sh
source "$emudeckBackend"/functions/runSRM.sh
source "$emudeckBackend"/functions/appImageInit.sh
source "$emudeckBackend"/functions/autofix.sh
source "$emudeckBackend"/functions/generateGameLists.sh
source "$emudeckBackend"/functions/jsonToBashVars.sh

#toolScripts
source "$emudeckBackend"/functions/ToolScripts/emuDeckESDE.sh
source "$emudeckBackend"/functions/ToolScripts/emuDeckPegasus.sh
source "$emudeckBackend"/functions/ToolScripts/emuDeckPlugins.sh
source "$emudeckBackend"/functions/ToolScripts/emuDeckSRM.sh
source "$emudeckBackend"/functions/ToolScripts/emuDeckCHD.sh
source "$emudeckBackend"/functions/ToolScripts/emuDeckBINUP.sh
source "$emudeckBackend"/functions/ToolScripts/emuDeckFlatpakUP.sh
source "$emudeckBackend"/functions/ToolScripts/emuDeckCloudBackup.sh
source "$emudeckBackend"/functions/ToolScripts/emuDeckCloudSync.sh
source "$emudeckBackend"/functions/ToolScripts/emuDeckRemotePlayWhatever.sh
source "$emudeckBackend"/functions/ToolScripts/emuDeckInstallHomebrewGames.sh
source "$emudeckBackend"/functions/ToolScripts/emuDeckMigration.sh
source "$emudeckBackend"/functions/ToolScripts/emuDeckCopyGames.sh
source "$emudeckBackend"/functions/ToolScripts/emuDecky.sh
source "$emudeckBackend"/functions/ToolScripts/emuDeckNetPlay.sh
source "$emudeckBackend"/functions/ToolScripts/emuDeckStore.sh

#emuscripts
#source "$emudeckBackend"/functions/EmuScripts/emuDeckSuyu.sh
source "$emudeckBackend"/functions/EmuScripts/emuDeckCitron.sh
source "$emudeckBackend"/functions/EmuScripts/emuDeckEden.sh
source "$emudeckBackend"/functions/EmuScripts/emuDeckYuzu.sh
source "$emudeckBackend"/functions/EmuScripts/emuDeckCemu.sh
source "$emudeckBackend"/functions/EmuScripts/emuDeckCemuProton.sh
source "$emudeckBackend"/functions/EmuScripts/emuDeckRPCS3.sh
source "$emudeckBackend"/functions/EmuScripts/emuDeckAzahar.sh
source "$emudeckBackend"/functions/EmuScripts/emuDeckDolphin.sh
source "$emudeckBackend"/functions/EmuScripts/emuDeckPrimehack.sh
source "$emudeckBackend"/functions/EmuScripts/emuDeckRetroArch.sh
source "$emudeckBackend"/functions/EmuScripts/emuDeckRyujinx.sh
source "$emudeckBackend"/functions/EmuScripts/emuDeckShadPS4.sh
source "$emudeckBackend"/functions/EmuScripts/emuDeckPPSSPP.sh
source "$emudeckBackend"/functions/EmuScripts/emuDeckDuckStation.sh
source "$emudeckBackend"/functions/EmuScripts/emuDeckXemu.sh
source "$emudeckBackend"/functions/EmuScripts/emuDeckXenia.sh
source "$emudeckBackend"/functions/EmuScripts/emuDeckPCSX2QT.sh
source "$emudeckBackend"/functions/EmuScripts/emuDeckMAME.sh
source "$emudeckBackend"/functions/EmuScripts/emuDeckScummVM.sh
source "$emudeckBackend"/functions/EmuScripts/emuDeckVita3K.sh
source "$emudeckBackend"/functions/EmuScripts/emuDeckMGBA.sh
source "$emudeckBackend"/functions/EmuScripts/emuDeckRMG.sh
source "$emudeckBackend"/functions/EmuScripts/emuDeckMelonDS.sh
source "$emudeckBackend"/functions/EmuScripts/emuDeckBigPEmu.sh
source "$emudeckBackend"/functions/EmuScripts/emuDeckares.sh
source "$emudeckBackend"/functions/EmuScripts/emuDeckFlycast.sh
source "$emudeckBackend"/functions/EmuScripts/emuDeckSupermodel.sh
source "$emudeckBackend"/functions/EmuScripts/emuDeckModel2.sh


# Generic Application scripts
source "$emudeckBackend"/functions/GenericApplicationsScripts/genericApplicationBottles.sh
source "$emudeckBackend"/functions/GenericApplicationsScripts/genericApplicationCider.sh
source "$emudeckBackend"/functions/GenericApplicationsScripts/genericApplicationFlatseal.sh
source "$emudeckBackend"/functions/GenericApplicationsScripts/genericApplicationHeroic.sh
source "$emudeckBackend"/functions/GenericApplicationsScripts/genericApplicationLutris.sh
source "$emudeckBackend"/functions/GenericApplicationsScripts/genericApplicationPlexamp.sh
source "$emudeckBackend"/functions/GenericApplicationsScripts/genericApplicationSpotify.sh
source "$emudeckBackend"/functions/GenericApplicationsScripts/genericApplicationTidal.sh
source "$emudeckBackend"/functions/GenericApplicationsScripts/genericApplicationWarehouse.sh

#remoteplayclientscripts
source "$emudeckBackend"/functions/RemotePlayClientScripts/remotePlayChiaki.sh
source "$emudeckBackend"/functions/RemotePlayClientScripts/remotePlayChiaking.sh
source "$emudeckBackend"/functions/RemotePlayClientScripts/remotePlayGreenlight.sh
source "$emudeckBackend"/functions/RemotePlayClientScripts/remotePlayMoonlight.sh
source "$emudeckBackend"/functions/RemotePlayClientScripts/remotePlayParsec.sh
source "$emudeckBackend"/functions/RemotePlayClientScripts/remotePlayShadow.sh
source "$emudeckBackend"/functions/RemotePlayClientScripts/remotePlaySteamLink.sh


source "$emudeckBackend"/functions/cloudSyncHealth.sh

source "$emudeckBackend"/android/functions/all.sh

# Darwin overrides
if [ "$system" = "darwin" ]; then
    source "$emudeckBackend/darwin/functions/varsOverrides.sh"
	source "$emudeckBackend/darwin/functions/all.sh"
fi