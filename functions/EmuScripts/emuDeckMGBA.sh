#!/bin/bash
#variables
mGBA_emuName="mGBA"
mGBA_emuType="$emuDeckEmuTypeAppImage"
mGBA_emuPath="$emusFolder/mGBA.AppImage"
mGBA_configFile="$HOME/.config/mgba/config.ini"

# macOS-specific paths
mGBA_configPath_mac="${HOME}/Library/Application Support/mGBA"
mGBA_configFile_mac="${HOME}/Library/Application Support/mGBA/config.ini"

#cleanupOlderThings
mGBA_cleanup(){
	echo "NYI"
}

#Install
mGBA_install(){
	if [ "$(uname)" != "Linux" ]; then mGBA_install_mac "$@"; return $?; fi
	echo "Begin mGBA Install"
	local showProgress="$1"
	if installEmuAI "$mGBA_emuName" "" "$(getReleaseURLGH "mgba-emu/mgba" "x64.appimage")" "" "" "emulator" "$showProgress"; then
		:
	else
		return 1
	fi
}

#Fix for autoupdate
Mgba_install(){
	mGBA_install
}

mGBA_install_mac(){
	mac_install_cask "mGBA" "mgba" "mGBA.app" || return 1
	mac_deploy_launcher "mgba" "/Applications/mGBA.app"
}

#ApplyInitialSettings
mGBA_init(){
	if [ "$(uname)" != "Linux" ]; then mGBA_init_mac; return $?; fi
	setMSG "Initializing $mGBA_emuName settings."
	configEmuAI "$mGBA_emuName" "config" "$HOME/.config/mgba" "$emudeckBackend/configs/mgba" "true"
	mGBA_setupStorage
	mGBA_setEmulationFolder
	mGBA_setupSaves
	#SRM_createParsers
	mGBA_addSteamInputProfile
	mGBA_flushEmulatorLauncher
	mGBA_addParser
}

mGBA_init_mac(){
	setMSG "Initializing $mGBA_emuName settings (macOS)."
	local cfgDir="${mGBA_configPath_mac}"
	mkdir -p "$cfgDir"
	configEmuAI "$mGBA_emuName" "config" "$cfgDir" "$emudeckBackend/configs/mgba" "true"
	local cfgFile="${mGBA_configFile_mac}"
	# ROM path
	if [ -f "$cfgFile" ]; then
		changeLine "lastDirectory=" "lastDirectory=${romsPath}/gba" "$cfgFile"
	fi
	# Saves
	mkdir -p "${savesPath}/mgba/saves"
	mkdir -p "${savesPath}/mgba/states"
	mkdir -p "${storagePath}/mgba/cheats"
	mkdir -p "${storagePath}/mgba/patches"
	mkdir -p "${storagePath}/mgba/screenshots"
	if [ -f "$cfgFile" ]; then
		changeLine "savegamePath=" "savegamePath=${savesPath}/mgba/saves" "$cfgFile"
		changeLine "savestatePath=" "savestatePath=${savesPath}/mgba/states" "$cfgFile"
		changeLine "cheatsPath=" "cheatsPath=${storagePath}/mgba/cheats" "$cfgFile"
		changeLine "patchPath=" "patchPath=${storagePath}/mgba/patches" "$cfgFile"
		changeLine "screenshotPath=" "screenshotPath=${storagePath}/mgba/screenshots" "$cfgFile"
	fi
}

#update
mGBA_update(){
	if [ "$(uname)" != "Linux" ]; then mGBA_init_mac; return $?; fi
	setMSG "Updating $mGBA_emuName settings."
	configEmuAI "$mGBA_emuName" "config" "$HOME/.config/mgba" "$emudeckBackend/configs/mgba"
	mGBA_setupStorage
	mGBA_setEmulationFolder
	mGBA_setupSaves
	mGBA_addSteamInputProfile
	mGBA_flushEmulatorLauncher
}

#ConfigurePaths
mGBA_setEmulationFolder(){
	setMSG "Setting $mGBA_emuName Emulation Folder"
	changeLine "lastDirectory=" "lastDirectory=${romsPath}/gba" "${mGBA_configFile}"
}

#SetupSaves
mGBA_setupSaves(){
	mkdir -p "$savesPath/mgba/saves"
	mkdir -p "$savesPath/mgba/states"
	changeLine "savegamePath=" "savegamePath=${savesPath}/mgba/saves" "${mGBA_configFile}"
	changeLine "savestatePath=" "savestatePath=${savesPath}/mgba/states" "${mGBA_configFile}"
}

#SetupStorage
mGBA_setupStorage(){
	mkdir -p "$storagePath/mgba/cheats"
	mkdir -p "$storagePath/mgba/patches"
	mkdir -p "$storagePath/mgba/screenshots"
	changeLine "cheatsPath=" "cheatsPath=${storagePath}/mgba/cheats" "${mGBA_configFile}"
	changeLine "patchPath=" "patchPath=${storagePath}/mgba/patches" "${mGBA_configFile}"
	changeLine "screenshotPath=" "screenshotPath=${storagePath}/mgba/screenshots" "${mGBA_configFile}"
}

#WipeSettings
mGBA_wipe(){
	setMSG "Wiping $mGBA_emuName settings."
	if [ "$(uname)" != "Linux" ]; then
		rm -rf "${mGBA_configPath_mac}"
		return
	fi
	rm -rf "$HOME/.config/mgba"
}

#Uninstall
mGBA_uninstall(){
	if [ "$(uname)" != "Linux" ]; then
		mac_uninstall_cask "mGBA" "mgba" "mGBA.app"
		removeParser "nintendo_gb_mgba.json"
		removeParser "nintendo_gba_mgba.json"
		removeParser "nintendo_gbc_mgba.json"
		return
	fi
	setMSG "Uninstalling $mGBA_emuName."
	removeParser "nintendo_gb_mgba.json"
	removeParser "nintendo_gba_mgba.json"
	removeParser "nintendo_gbc_mgba.json"
	uninstallEmuAI "$mGBA_emuName" "" "" "emulator"
}

#setABXYstyle
mGBA_setABXYstyle(){
	echo "NYI"
}

#Migrate
mGBA_migrate(){
	echo "NYI"
}

#WideScreenOn
mGBA_wideScreenOn(){
	echo "NYI"
}

#WideScreenOff
mGBA_wideScreenOff(){
	echo "NYI"
}

#BezelOn
mGBA_bezelOn(){
	echo "NYI"
}

#BezelOff
mGBA_bezelOff(){
	echo "NYI"
}

mGBA_IsInstalled(){
	if [ "$(uname)" != "Linux" ]; then mac_app_installed "mGBA.app"; return; fi
	if [ -e "$mGBA_emuPath" ]; then
		echo "true"
	else
		echo "false"
	fi
}

mGBA_resetConfig(){
	mGBA_init &>/dev/null && echo "true" || echo "false"
}

#finalExec - Extra stuff
mGBA_finalize(){
	echo "NYI"
}

mGBA_addSteamInputProfile(){
	addSteamInputCustomIcons
	setMSG "Adding $mGBA_emuName Steam Input Profile."
	rsync -r --exclude='*/' "$emudeckBackend/configs/steam-input/" "$HOME/.steam/steam/controller_base/templates/"
}

mGBA_flushEmulatorLauncher(){
	flushEmulatorLaunchers "mgba"
}

mGBA_addParser(){
	addParser "nintendo_gb_mgba.json"
	addParser "nintendo_gba_mgba.json"
	addParser "nintendo_gbc_mgba.json"
}
