#!/bin/bash

# Script to install, initialize and configure ShadPS4 on EmuDeck
# Note: No Bios/Keys symlinks necessary
# Variables

ShadPS4_emuName="ShadPS4"
ShadPS4_emuFileName="Shadps4-qt"
ShadPS4_emuType="$emuDeckEmuTypeAppImage"
ShadPS4_emuPath="$emusFolder"
ShadPS4_dir="$HOME/.local/share/shadPS4"
ShadPS4_configFile="$ShadPS4_dir/config.toml"

# macOS-specific paths
ShadPS4_configPath_mac="${HOME}/Library/Application Support/shadPS4"
ShadPS4_configFile_mac="${HOME}/Library/Application Support/shadPS4/config.toml"

ShadPS4_cleanup(){
	echo "Begin ShadPS4 Cleanup"
}

ShadPS4_install(){
	if [ "$(uname)" != "Linux" ]; then ShadPS4_install_mac "$@"; return $?; fi
	echo "Begin ShadPS4 Install"
	local showProgress=$1
	local api_url='https://api.github.com/repos/shadps4-emu/shadps4-qtlauncher/releases'
	local shadps4_url
	shadps4_url="$(curl -s -H "User-Agent: EmuDeck" "$api_url" \
		| jq -r '.[0].assets[]
				 | select(.name | contains("linux-qt") and endswith(".zip"))
				 | .browser_download_url' \
		| head -n 1)"
	if [[ -z "$shadps4_url" || "$shadps4_url" == "null" ]]; then
		echo "Error getting latest ShadPS4 linux-qt release URL"
		return 1
	fi
	if safeDownload "$ShadPS4_emuName" "$shadps4_url" "$emusFolder/${ShadPS4_emuName}.zip" "$showProgress"; then
		unzip -o "$emusFolder/${ShadPS4_emuName}.zip" -d "$ShadPS4_emuPath" && rm -f "$emusFolder/${ShadPS4_emuName}.zip"
		rm -f "$ShadPS4_emuPath/Shadps4-qt.AppImage"
		mv "$ShadPS4_emuPath"/shadPS4QtLauncher-qt*.AppImage \
		   "$ShadPS4_emuPath/Shadps4-qt.AppImage"
		chmod +x "$ShadPS4_emuPath/Shadps4-qt.AppImage"
		if ! installEmuAI "$ShadPS4_emuName" "" "" "$ShadPS4_emuFileName" "" "emulator"; then
			echo "Error installing ShadPS4"
			return 1
		fi
		ShadPS4_init
	else
		echo "Error installing ShadPS4"
		return 1
	fi
}

ShadPS4_install_mac(){
	setMSG "Installing ShadPS4 (macOS)"
	local arch
	arch=$(mac_arch)
	local url
	if [ "$arch" = "arm64" ]; then
		url=$(mac_get_gh_release_url "shadps4-emu/shadPS4" "shadps4-macos-arm64.*\.dmg" "shadps4-macos.*\.dmg")
	else
		url=$(mac_get_gh_release_url "shadps4-emu/shadPS4" "shadps4-macos-x64.*\.dmg" "shadps4-macos.*\.dmg")
	fi
	if [ -z "$url" ]; then
		echo "[mac] ERROR: Could not find ShadPS4 macOS release."
		return 1
	fi
	mac_install_dmg "ShadPS4" "$url" "shadPS4.app" || return 1
	mac_deploy_launcher "ShadPS4" "/Applications/shadPS4.app"
}

ShadPS4_init(){
	if [ "$(uname)" != "Linux" ]; then ShadPS4_init_mac; return $?; fi
	configEmuAI "$ShadPS4_emuName" "config" "$HOME/.local/share/shadPS4" "$emudeckBackend/configs/shadps4" "true"
	ShadPS4_setupStorage
	ShadPS4_setEmulationFolder
	ShadPS4_setupSaves
	ShadPS4_flushEmulatorLauncher
	ShadPS4_setLanguage
}

ShadPS4_init_mac(){
	setMSG "Initializing ShadPS4 settings (macOS)."
	local cfgDir="${ShadPS4_configPath_mac}"
	mkdir -p "$cfgDir"
	configEmuAI "$ShadPS4_emuName" "config" "$cfgDir" "$emudeckBackend/configs/shadps4" "true"
	local cfgFile="${ShadPS4_configFile_mac}"
	mkdir -p "$storagePath/shadps4/games"
	mkdir -p "$storagePath/shadps4/dlc"
	mkdir -p "${savesPath}/shadps4/saves"
	if [ -f "$cfgFile" ]; then
		sed -i "s|/run/media/mmcblk0p1/Emulation|${emulationPath}|g" "$cfgFile"
	fi
	# BIOS link
	mkdir -p "${biosPath}/shadps4/"
	mkdir -p "$cfgDir/sys_modules"
	ln -sn "$cfgDir/sys_modules" "${biosPath}/shadps4/sys_modules" 2>/dev/null || true
	# Save link
	mac_link_save "shadps4" "shadPS4/savedata" "${savesPath}/shadps4/saves"
	# Language
	local language=$(locale | grep LANG | cut -d= -f2 | cut -d_ -f1)
	[ -f "$cfgFile" ] && changeLine "emulatorLanguage = " "emulatorLanguage = \"${language}\"" "$cfgFile"
}

ShadPS4_update(){
	ShadPS4_install "$1"
}

# Configuration Paths
ShadPS4_setEmulationFolder(){
	echo "Begin ShadPS4 Path Config"
	sed -i "s|/run/media/mmcblk0p1/Emulation|${emulationPath}|g" "$ShadPS4_configFile"
	mkdir -p "${biosPath}/shadps4/"
	mkdir -p "$ShadPS4_dir/sys_modules"
	ln -sn "$ShadPS4_dir/sys_modules" "${biosPath}/shadps4/sys_modules"
	echo "ShadPS4 Path Config Completed"
}

ShadPS4_setLanguage(){
	local cfgFile="$ShadPS4_configFile"
	[ "$(uname)" != "Linux" ] && cfgFile="$ShadPS4_configFile_mac"
	setMSG "Setting ShadPS4 Language"
	local language=$(locale | grep LANG | cut -d= -f2 | cut -d_ -f1)
	changeLine "emulatorLanguage = " "emulatorLanguage = \"${language}\"" "$cfgFile"
}

# Setup Saves
ShadPS4_setupSaves(){
	if [ "$(uname)" != "Linux" ]; then return; fi
	echo "Begin ShadPS4 save link"
	linkToSaveFolder shadps4 saves "${ShadPS4_dir}/savedata"
}

#SetupStorage
ShadPS4_setupStorage(){
	echo "Begin ShadPS4 storage config"
	mkdir -p "$storagePath/shadps4/games"
	mkdir -p "$storagePath/shadps4/dlc"
}

#WipeSettings
ShadPS4_wipe(){
	echo "Begin ShadPS4 delete config directories"
	if [ "$(uname)" != "Linux" ]; then
		rm -rf "${ShadPS4_configPath_mac}"
		return
	fi
	rm -rf "$ShadPS4_dir"
}

#Uninstall
ShadPS4_uninstall(){
	if [ "$(uname)" != "Linux" ]; then
		mac_uninstall_app "shadPS4.app"
		return
	fi
	echo "Begin ShadPS4 uninstall"
	uninstallEmuAI $ShadPS4_emuName "Shadps4-qt" "AppImage" "emulator"
}

#WideScreenOn
ShadPS4_wideScreenOn(){
	echo "NYI"
}

#WideScreenOff
ShadPS4_wideScreenOff(){
	echo "NYI"
}

#BezelOn
ShadPS4_bezelOn(){
	echo "NYI"
}

#BezelOff
ShadPS4_bezelOff(){
	echo "NYI"
}

#finalExec - Extra stuff
ShadPS4_finalize(){
	echo "Begin ShadPS4 finalize"
}

ShadPS4_IsInstalled(){
	if [ "$(uname)" != "Linux" ]; then mac_app_installed "shadPS4.app"; return; fi
	if [ -e "$ShadPS4_emuPath/Shadps4-qt.AppImage" ]; then
		echo "true"
	else
		echo "false"
	fi
}

ShadPS4_resetConfig(){
	ShadPS4_init &>/dev/null && echo "true" || echo "false"
}

ShadPS4_setResolution(){
	echo "NYI"
}

ShadPS4_flushEmulatorLauncher(){
	flushEmulatorLaunchers "ShadPS4"
}
