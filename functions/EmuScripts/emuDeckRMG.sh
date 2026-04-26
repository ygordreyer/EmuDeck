#!/bin/bash
#variables
RMG_emuName="RosaliesMupenGui"
RMG_emuType="$emuDeckEmuTypeFlatpak"
RMG_emuPath="com.github.Rosalie241.RMG"
RMG_configFile="$HOME/.var/app/com.github.Rosalie241.RMG/config/RMG/mupen64plus.cfg"
RMG_glideN64File="$HOME/.var/app/com.github.Rosalie241.RMG/config/RMG/GLideN64.ini"

# macOS-specific paths
RMG_configPath_mac="${HOME}/Library/Application Support/RMG"
RMG_configFile_mac="${HOME}/Library/Application Support/RMG/mupen64plus.cfg"
RMG_glideN64File_mac="${HOME}/Library/Application Support/RMG/GLideN64.ini"

#cleanupOlderThings
RMG_cleanup(){
	echo "NYI"
}

#Install
RMG_install() {
	if [ "$(uname)" != "Linux" ]; then RMG_install_mac "$@"; return $?; fi
	setMSG "Installing $RMG_emuName"
	installEmuFP "${RMG_emuName}" "${RMG_emuPath}" "emulator" ""
}

#Fix for autoupdate
Rmg_install(){
	RMG_install
}

RMG_install_mac(){
	# RMG (Rosalie's Mupen GUI) has no macOS builds — Linux and Windows only.
	mac_emu_skip "RMG" "No macOS builds available — Linux and Windows only"
}

#ApplyInitialSettings
RMG_init() {
	if [ "$(uname)" != "Linux" ]; then RMG_init_mac; return $?; fi
	setMSG "Initializing $RMG_emuName settings."
	configEmuFP "${RMG_emuName}" "${RMG_emuPath}" "true"
	RMG_setupStorage
	RMG_setEmulationFolder
	RMG_setupSaves
	#SRM_createParsers
	RMG_flushEmulatorLauncher
	RMG_addParser
}

RMG_init_mac(){
	setMSG "Initializing $RMG_emuName settings (macOS)."
	local cfgDir="${RMG_configPath_mac}"
	mkdir -p "$cfgDir"
	configEmuAI "$RMG_emuName" "config" "$cfgDir" "$emudeckBackend/configs/com.github.Rosalie241.RMG" "true"
	local cfgFile="${RMG_configFile_mac}"
	local glideFile="${RMG_glideN64File_mac}"
	# Setup save/storage dirs
	mkdir -p "${savesPath}/RMG/saves"
	mkdir -p "${savesPath}/RMG/states"
	mkdir -p "${storagePath}/RMG/"
	mkdir -p "${storagePath}/RMG/cache"
	mkdir -p "${storagePath}/RMG/HiResTextures"
	mkdir -p "${storagePath}/RMG/screenshots"
	# Set paths in config
	if [ -f "$cfgFile" ]; then
		changeLine "Directory = " "Directory = ${romsPath}/n64" "$cfgFile"
		changeLine "64DD_AmericanIPL = " "64DD_AmericanIPL = ${biosPath}/64DD_IPL_US.n64" "$cfgFile"
		changeLine "64DD_JapaneseIPL = " "64DD_JapaneseIPL = ${biosPath}/64DD_IPL_JP.n64" "$cfgFile"
		changeLine "64DD_DevelopmentIPL = " "64DD_DevelopmentIPL = ${biosPath}/64DD_IPL_DEV.n64" "$cfgFile"
		changeLine "SaveSRAMPath = " "SaveSRAMPath = ${savesPath}/RMG/saves" "$cfgFile"
		changeLine "SaveStatePath = " "SaveStatePath = ${savesPath}/RMG/states" "$cfgFile"
		changeLine "ScreenshotPath = " "ScreenshotPath = ${storagePath}/RMG/screenshots" "$cfgFile"
		changeLine "UserDataDirectory = " "UserDataDirectory = \"${cfgDir}\"" "$cfgFile"
		changeLine "UserCacheDirectory = " "UserCacheDirectory = \"${HOME}/Library/Caches/RMG\"" "$cfgFile"
	fi
	if [ -f "$glideFile" ]; then
		changeLine "textureFilter\txHiresEnable=" "textureFilter\txHiresEnable=1" "$glideFile"
		changeLine "textureFilter\txPath=" "textureFilter\txPath=${storagePath}/RMG/HiResTextures" "$glideFile"
		changeLine "textureFilter\txCachePath=" "textureFilter\txCachePath=${storagePath}/RMG/cache" "$glideFile"
	fi
}

#update
RMG_update() {
	if [ "$(uname)" != "Linux" ]; then RMG_init_mac; return $?; fi
	setMSG "Installing $RMG_emuName"
	configEmuFP "${RMG_emuName}" "${RMG_emuPath}"
	updateEmuFP "${RMG_emuName}" "${RMG_emuPath}" "emulator" ""
	RMG_setupStorage
	RMG_setEmulationFolder
	RMG_setupSaves
	RMG_flushEmulatorLauncher
}

#ConfigurePaths
RMG_setEmulationFolder(){
	setMSG "Setting $RMG_emuName Emulation Folder"
	changeLine "Directory = " "Directory = ${romsPath}/n64" "$RMG_configFile"
	changeLine "64DD_AmericanIPL = " "64DD_AmericanIPL = ${biosPath}/64DD_IPL_US.n64" "$RMG_configFile"
	changeLine "64DD_JapaneseIPL = " "64DD_JapaneseIPL = ${biosPath}/64DD_IPL_JP.n64" "$RMG_configFile"
	changeLine "64DD_DevelopmentIPL = " "64DD_DevelopmentIPL = ${biosPath}/64DD_IPL_DEV.n64" "$RMG_configFile"
}

#SetupSaves
RMG_setupSaves(){
	mkdir -p "${savesPath}/RMG/saves"
	mkdir -p "${savesPath}/RMG/states"
	changeLine "SaveSRAMPath = " "SaveSRAMPath = ${savesPath}/RMG/saves" "$RMG_configFile"
	changeLine "SaveStatePath = " "SaveStatePath = ${savesPath}/RMG/states" "$RMG_configFile"
}

#SetupStorage
RMG_setupStorage(){
	mkdir -p "${storagePath}/RMG/"
	mkdir -p "${storagePath}/RMG/cache"
	mkdir -p "${storagePath}/RMG/HiResTextures"
	mkdir -p "${storagePath}/RMG/screenshots"
	changeLine "textureFilter\txHiresEnable=" "textureFilter\txHiresEnable=1" "$RMG_glideN64File"
	changeLine "textureFilter\txPath=" "textureFilter\txPath=${storagePath}/RMG/HiResTextures" "$RMG_glideN64File"
	changeLine "textureFilter\txCachePath=" "textureFilter\txCachePath=${storagePath}/RMG/cache" "$RMG_glideN64File"
	changeLine "ScreenshotPath = " "ScreenshotPath = ${storagePath}/RMG/screenshots" "$RMG_configFile"
	changeLine "UserDataDirectory = " "UserDataDirectory = \"$HOME/.var/app/com.github.Rosalie241.RMG/data/RMG\"" "$RMG_configFile"
	changeLine "UserCacheDirectory = " "UserCacheDirectory = \"$HOME/.var/app/com.github.Rosalie241.RMG/cache/RMG\"" "$RMG_configFile"
}

#WipeSettings
RMG_wipe(){
	if [ "$(uname)" != "Linux" ]; then
		rm -rf "${RMG_configPath_mac}"
		return
	fi
	rm -rf "$HOME/.var/app/$RMG_emuPath"
}

#Uninstall
RMG_uninstall(){
	if [ "$(uname)" != "Linux" ]; then
		mac_uninstall_app "RMG.app"
		removeParser "nintendo_64_rmg.json"
		return
	fi
	removeParser "nintendo_64_rmg.json"
	uninstallEmuFP "${RMG_emuName}" "${RMG_emuPath}" "emulator" ""
}

#Migrate
RMG_migrate(){
	echo "NYI"
}

#WideScreenOn
RMG_wideScreenOn(){
	echo "NYI"
}

#WideScreenOff
RMG_wideScreenOff(){
	echo "NYI"
}

#BezelOn
RMG_bezelOn(){
	echo "NYI"
}

#BezelOff
RMG_bezelOff(){
	echo "NYI"
}

RMG_IsInstalled(){
	if [ "$(uname)" != "Linux" ]; then mac_app_installed "RMG.app"; return; fi
	isFpInstalled "$RMG_emuPath"
}

RMG_resetConfig(){
	RMG_init &>/dev/null && echo "true" || echo "false"
}

RMG_addSteamInputProfile(){
	addSteamInputCustomIcons
}

#finalExec - Extra stuff
RMG_finalize(){
	echo "NYI"
}

RMG_setResolution(){
	echo "NYI"
}

RMG_setABXYstyle(){
	local cfgFile="$RMG_configFile"
	[ "$(uname)" != "Linux" ] && cfgFile="$RMG_configFile_mac"
	sed -i '/\[Rosalie'"'"'s Mupen GUI - Input Plugin User Profile "steamdeck"\]/,/^\[/ {
		s/B_Name *= *"x"/B_Name = "b"/;
		s/B_Data *= *"2"/B_Data = "1"/;
	}' "$cfgFile"
}

RMG_setBAYXstyle(){
	local cfgFile="$RMG_configFile"
	[ "$(uname)" != "Linux" ] && cfgFile="$RMG_configFile_mac"
	sed -i '/\[Rosalie'"'"'s Mupen GUI - Input Plugin User Profile "steamdeck"\]/,/^\[/ {
		s/B_Name *= *"b"/B_Name = "x"/;
		s/B_Data *= *"1"/B_Data = "2"/;
	}' "$cfgFile"
}

RMG_flushEmulatorLauncher(){
	flushEmulatorLaunchers "rosaliesmupengui"
}

RMG_addParser(){
	addParser "nintendo_64_rmg.json"
}
