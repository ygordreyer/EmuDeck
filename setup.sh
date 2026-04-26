#!/bin/bash
#
##
## set backend location
##
# I think this should just be in the source, so there's one spot for initialization. hrm, no i'm wrong. Here is best.
emudeckBackend="$HOME/.config/EmuDeck/backend/"
. "$emudeckBackend/vars.sh"
MSG=$emudeckLogs/msg.log
echo "0" > "$MSG"

#Darwin
appleChip=$(uname -m)
if [ "$(uname)" != "Linux" ]; then

	# ── C1: Re-exec under Homebrew bash 5+ (macOS ships bash 3.2 which lacks declare -A) ──
	if [ -z "${EMUDECK_BASH_REEXEC:-}" ] && [ "${BASH_VERSINFO[0]:-0}" -lt 4 ]; then
		if ! command -v brew >/dev/null 2>&1; then
			echo "ERROR: Homebrew is required on macOS. Install it from https://brew.sh and re-run."
			exit 1
		fi
		if ! command -v bash >/dev/null 2>&1 || ! bash --version 2>/dev/null | grep -q 'version [4-9]'; then
			echo "[EmuDeck] Installing bash 5+ (macOS ships bash 3.2 which is too old)..."
			brew install bash || { echo "ERROR: brew install bash failed."; exit 1; }
		fi
		BREW_BASH="$(brew --prefix bash)/bin/bash"
		if [ -x "$BREW_BASH" ]; then
			echo "[EmuDeck] Re-executing under bash 5+ ($BREW_BASH)..."
			export EMUDECK_BASH_REEXEC=1
			exec "$BREW_BASH" "$0" "$@"
		fi
	fi

	# ── C2: Ensure rsync 3.2+ is available (macOS ships BSD rsync 2.6.9 which lacks --mkpath) ──
	if ! rsync --help 2>&1 | grep -q -- '--mkpath'; then
		if ! command -v brew >/dev/null 2>&1; then
			echo "ERROR: Homebrew is required on macOS. Install it from https://brew.sh and re-run."
			exit 1
		fi
		echo "[EmuDeck] Installing rsync 3+ (macOS ships BSD rsync 2.6.9 which lacks --mkpath)..."
		brew install rsync || { echo "ERROR: brew install rsync failed."; exit 1; }
	fi
	# Prepend Homebrew rsync to PATH so all downstream rsync calls use it
	PATH="$(brew --prefix rsync)/bin:$PATH"

	# ── C3: Self-heal stale backend (wrong remote or missing darwin/ dir) ──
	# Handles the case where the user ran setup.sh directly against a stale upstream clone.
	_WANTED_REMOTE="https://github.com/ygordreyer/EmuDeck.git"
	if [ -d "${emudeckBackend}/.git" ]; then
		_cur_remote=$(cd "$emudeckBackend" && git config --get remote.origin.url 2>/dev/null || true)
		if [ "$_cur_remote" != "$_WANTED_REMOTE" ] || [ ! -d "${emudeckBackend}/darwin" ]; then
			echo "[EmuDeck] Backend is stale or wrong remote (found: ${_cur_remote:-none}) — refreshing from $_WANTED_REMOTE..."
			cd "$emudeckBackend"
			git remote set-url origin "$_WANTED_REMOTE"
			git fetch --depth=1 origin "${1:-main}"
			git reset --hard "origin/${1:-main}"
			# Re-exec so we run the freshly-pulled setup.sh, not the stale one.
			export EMUDECK_BASH_REEXEC=1
			exec "${BASH:-bash}" "$0" "$@"
		fi
	fi

	# Auto-install gnu-sed via Homebrew if not already present
	if ! command -v gsed >/dev/null 2>&1; then
		if command -v brew >/dev/null 2>&1; then
			echo "[EmuDeck] Installing gnu-sed (required on macOS)..."
			brew install gnu-sed || { echo "ERROR: brew install gnu-sed failed. Install Homebrew from https://brew.sh first."; exit 1; }
		else
			echo "ERROR: Homebrew is required on macOS to run EmuDeck. Install it from https://brew.sh and re-run."
			exit 1
		fi
	fi
	if [ "$appleChip" = 'arm64' ]; then
		PATH="/opt/homebrew/opt/gnu-sed/libexec/gnubin:$PATH"
	else
		PATH="/usr/local/opt/gnu-sed/libexec/gnubin:$PATH"
	fi
	export PATH

	# Pre-seed ~/emudeck/settings.sh with macOS defaults if the file is missing or empty
	mkdir -p "$HOME/emudeck"
	if [ ! -s "$HOME/emudeck/settings.sh" ]; then
		cat > "$HOME/emudeck/settings.sh" <<'DARWIN_SETTINGS'
system="darwin"
Home="$HOME"
emulationPath="$HOME/Emulation"
romsPath="$HOME/Emulation/roms"
toolsPath="$HOME/Emulation/tools"
biosPath="$HOME/Emulation/bios"
savesPath="$HOME/Emulation/saves"
storagePath="$HOME/Emulation/storage"
DARWIN_SETTINGS
	fi

	# Decky Loader is Linux/SteamOS-only — disable on macOS
	doInstallRetroLibrary=false
fi

#
##
## Pid Lock...
##
#

mkdir -p "$HOME/.config/EmuDeck"
mkdir -p "$emudeckLogs"
PIDFILE="$emudeckFolder/install.pid"


if [ -f "$PIDFILE" ]; then
  PID=$(cat "$PIDFILE")
  ps -p "$PID" > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo "Process already running"
    exit 1
  else
    ## Process not found assume not running
    echo $$ > "$PIDFILE"
    if [ $? -ne 0 ]; then
      echo "Could not create PID file"
      exit 1
    fi
  fi
else
  echo $$ > "$PIDFILE"
  if [ $? -ne 0 ]; then
    echo "Could not create PID file"
    exit 1
  fi
fi

function finish {
  echo "Script terminating. Exit code $?"
  finished=true
  rm "$MSG"

}
trap finish EXIT


#
##
## Init...
##
#


#Clean up previous installations
rm ~/emudek.log 2>/dev/null # This is emudeck's old log file, it's not a typo!
rm -rf ~/dragoonDoriseTools

#Creating log file
LOGFILE="$emudeckLogs/emudeckSetup.log"

mkdir -p "$HOME/.config/EmuDeck"

#Custom Scripts
mkdir -p "$emudeckFolder/custom_scripts"
echo $'#!/bin/bash\nemudeckBackend="$HOME/.config/EmuDeck/backend/"\nsource "$emudeckBackend/functions/all.sh"' > "$emudeckFolder/custom_scripts/example.sh"

echo "Press the button to start..." > "$LOGFILE"

mv "${LOGFILE}" "$emudeckLogs/emudeckSetup.last.log" #backup last log

if echo "${@}" > "${LOGFILE}" ; then
	echo "Log created"
else
	exit
fi

#exec > >(tee "${LOGFILE}") 2>&1
#Installation log
{
date "+%Y.%m.%d-%H:%M:%S %Z"
#Mark if this not a fresh install
FOLDER="$emudeckFolder"
if [ -d "$FOLDER" ]; then
	echo "" > "$emudeckFolder/.finished"
fi
sleep 1
SECONDTIME="$emudeckFolder/.finished"

# ── C4: macOS environment diagnostic — shows in every log for easy debugging ──────────────
if [ "$(uname)" != "Linux" ]; then
	echo "==== EmuDeck macOS environment ===="
	echo "bash:   $BASH ($BASH_VERSION)"
	echo "rsync:  $(command -v rsync 2>/dev/null || echo 'NOT FOUND') — $(rsync --version 2>/dev/null | head -1 || echo 'N/A')"
	echo "remote: $(cd "$emudeckBackend" && git config --get remote.origin.url 2>/dev/null || echo 'N/A')"
	echo "HEAD:   $(cd "$emudeckBackend" && git rev-parse --short HEAD 2>/dev/null || echo 'N/A')"
	echo "system: ${system:-unknown (settings.sh not yet sourced)}"
	echo "===================================="
fi
# ─────────────────────────────────────────────────────────────────────────────────────────

#Lets log github API limits just in case
echo 'Github API limits:'
curl -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28"  "https://api.github.com/rate_limit"


#
##
## Start of installation
##
#



source "$emudeckBackend"/functions/helperFunctions.sh
source "$emudeckBackend"/functions/jsonToBashVars.sh
jsonToBashVars "$emudeckFolder/settings.json"
source "$emudeckBackend/functions/all.sh"


#after sourcing functins, check if path is empty.
# [[ -z "$emulationPath" ]] && { echo "emulationPath is Empty!"; setMSG "There's been an issue, please restart the app"; exit 1; }



echo "Current Settings: "
grep -vi pass "$emuDecksettingsFile"


#
#Environment Check
#
echo ""
echo "Env Details: "
getEnvironmentDetails
testRealDeck

#this sets up the settings file with defaults, in case they don't have a new setting we've added.
#also echos them all out so they are in the log.
#echo "Setup Settings File: "
#createUpdateSettingsFile

#create folders after tests!
createFolders

#setup Proton-Launch.sh
#because this path gets updated by sed, we really should be installing it every and allowing it to be updated every time. In case the user changes their path.
if [ "$(uname)" == "Linux" ]; then
    cp "$emudeckBackend/tools/proton-launch.sh" "${toolsPath}/proton-launch.sh"
    chmod +x "${toolsPath}/proton-launch.sh"
fi
cp "$emudeckBackend/tools/appID.py" "${toolsPath}/appID.py"

# Setup emu-launch.sh
cp "$emudeckBackend/tools/emu-launch.sh" "${toolsPath}/emu-launch.sh"
chmod +x "${toolsPath}/emu-launch.sh"


max_jobs=5
current_jobs=0

for install_command in \
	"$doInstallESDE ESDE_install" \
	"$doInstallPegasus pegasus_install" \
	"$doInstallSRM SRM_install" \
	"$doInstallRetroLibrary Plugins_installDeckyRomLibrary" \
	"$doInstallPCSX2QT PCSX2QT_install" \
	"$doInstallPrimeHack Primehack_install" \
	"$doInstallRPCS3 RPCS3_install" \
	"$doInstallAzahar Azahar_install" \
	"$doInstallDolphin Dolphin_install" \
	"$doInstallDuck DuckStation_install" \
	"$doInstallRA RetroArch_install" \
	"$doInstallRMG RMG_install" \
	"$doInstallares ares_install" \
	"$doInstallPPSSPP PPSSPP_install" \
	"$doInstallYuzu Yuzu_install" \
	"$doInstallSuyu suyu_install" \
	"$doInstallRyujinx Ryujinx_install" \
	"$doInstallMAME MAME_install" \
	"$doInstallXemu Xemu_install" \
	"$doInstallCemu Cemu_install" \
	"$doInstallCemuNative CemuNative_install" \
	"$doInstallScummVM ScummVM_install" \
	"$doInstallVita3K Vita3K_install" \
	"$doInstallMGBA mGBA_install" \
	"$doInstallFlycast Flycast_install" \
	"$doInstallmelonDS melonDS_install" \
	"$doInstallBigPEmu BigPEmu_install" \
	"$doInstallSupermodel Supermodel_install" \
	"$doInstallXenia Xenia_install" \
	"$doInstallModel2 Model2_install" \
	"$doInstallShadPS4 ShadPS4_install"; do

	condition=$(echo "$install_command" | awk '{print $1}')
	command=$(echo "$install_command" | cut -d' ' -f2-)

	if [ "$condition" == "true" ]; then
		echo "Executing $command"
		$command &
		current_jobs=$((current_jobs + 1))
	fi

	if [ $current_jobs -ge $max_jobs ]; then
		wait
		current_jobs=0
	fi
done
setMSG "Waiting for installation tasks to finish.."
wait # Wait for any remaining jobs to finish

setMSG "Configuring emulators & tools.."

max_jobs=5
current_jobs=0

for setup_command in \
	"$doSetupSRM SRM_init" \
	"$doSetupESDE ESDE_init" \
	"$doSetupPegasus pegasus_init" \
	"$doSetupRA RetroArch_init" \
	"$doSetupPrimehack Primehack_init" \
	"$doSetupDolphin Dolphin_init" \
	"$doSetupPCSX2QT PCSX2QT_init" \
	"$doSetupRPCS3 RPCS3_init" \
	"$doSetupAzahar Azahar_init" \
	"$doSetupDuck DuckStation_init" \
	"$doSetupYuzu Yuzu_init" \
	"$doSetupCitron Citron_init" \
	"$doSetupRyujinx Ryujinx_init" \
	"$doSetupShadPS4 ShadPS4_init" \
	"$doSetupPPSSPP PPSSPP_init" \
	"$doSetupXemu Xemu_init" \
	"$doSetupMAME MAME_init" \
	"$doSetupScummVM ScummVM_init" \
	"$doSetupVita3K Vita3K_init" \
	"$doSetupRMG RMG_init" \
	"$doSetupares ares_init" \
	"$doSetupmelonDS melonDS_init" \
	"$doSetupMGBA mGBA_init" \
	"$doSetupCemuNative CemuNative_init" \
	"$doSetupFlycast Flycast_init" \
	"$doSetupSupermodel Supermodel_init" \
	"$doSetupModel2 Model2_init" \
	"$doSetupCemu Cemu_init" \
	"$doSetupBigPEmu BigPEmu_init" \
	"$doSetupXenia Xenia_init"; do

	condition=$(echo "$setup_command" | awk '{print $1}')
	command=$(echo "$setup_command" | awk '{print $2}')

	if [ "$condition" == "true" ]; then
		echo "Executing $command"
		$command &
		current_jobs=$((current_jobs + 1))
	fi

	if [ $current_jobs -ge $max_jobs ]; then
		wait
		current_jobs=0
	fi
done

wait # Wait for any remaining jobs to finish

#
##
##End of installation
##
#


#Always install
if [ "$(uname)" == "Linux" ]; then
    BINUP_install &
    FlatpakUP_install &
fi
AutoCopy_install &
server_install &
CHD_install &

#
##
## Overrides for non Steam hardware...
##
#


#
#Fixes for 16:9 Screens
#
if [ "$doSetupRA" == "true" ]; then
	if [ "$(getScreenAR)" == 169 ];then
		nonDeck_169Screen
	fi

	#Anbernic Win600 Special configuration
	if [ "$(getProductName)" == "Win600" ];then
		nonDeck_win600
	fi
fi

if [ "$system" == "chimeraos" ]; then
	mkdir -p $HOME/Applications

	downloads_dir="$HOME/Downloads"
	destination_dir="$HOME/Applications"
	file_name="EmuDeck"

	mkdir -p $destination_dir

	find "$downloads_dir" -type f -name "*$file_name*.AppImage" -exec mv {} "$destination_dir/$file_name.AppImage" \;

	chmod +x "$destination_dir/EmuDeck.AppImage"

fi


createDesktopIcons &


if [ "$controllerLayout" == "bayx" ] || [ "$controllerLayout" == "baxy" ] ; then
	controllerLayout_BAYX &
else
	controllerLayout_ABXY &
fi

#
##
##Plugins
##
#

#GyroDSU
#Plugins_installSteamDeckGyroDSU

#EmuDeck updater on gaming Mode
#mkdir -p "${toolsPath}/updater"
#cp -v "$emudeckBackend/tools/updater/emudeck-updater.sh" "${toolsPath}/updater/"
#chmod +x "${toolsPath}/updater/emudeck-updater.sh"

#RemotePlayWhatever
# if [[ ! $branch == "main" ]]; then
# 	RemotePlayWhatever_install
# fi

#
# We mark the script as finished
#
setMSG "Waiting for setup tasks to finish.."
wait
echo "" > "$emudeckFolder/.finished"
echo "" > "$emudeckFolder/.ui-finished"
echo "100" > "$emudeckLogs/msg.log"
echo "# Installation Complete" >> "$emudeckLogs/msg.log"
finished=true
rm "$PIDFILE"

#
## We check all the selected emulators are installed
#



checkInstalledEmus


#
# Run custom scripts... shhh for now ;)
#

for entry in "$emudeckFolder"/custom_scripts/*.sh
do
	 bash $entry
done
} | tee "${LOGFILE}" 2>&1
