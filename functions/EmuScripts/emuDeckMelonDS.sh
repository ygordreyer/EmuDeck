#!/bin/bash
#variables
melonDS_emuName="MelonDS"
melonDS_emuType="$emuDeckEmuTypeFlatpak"
melonDS_emuPath="net.kuribo64.melonDS"
melonDS_releaseURL=""
melonDS_configFile="$HOME/.var/app/net.kuribo64.melonDS/config/melonDS/melonDS.ini"

# macOS-specific paths
melonDS_configPath_mac="${HOME}/Library/Application Support/melonDS"
melonDS_configFile_mac="${HOME}/Library/Application Support/melonDS/melonDS.ini"

#cleanupOlderThings
melonDS_cleanup(){
	echo "NYI"
}

#Install
melonDS_install(){
	if [ "$(uname)" != "Linux" ]; then melonDS_install_mac "$@"; return $?; fi
	setMSG "Installing $melonDS_emuName"
	installEmuFP "${melonDS_emuName}" "${melonDS_emuPath}" "emulator" ""
}

#Fix for autoupdate
Melonds_install(){
	melonDS_install
}

melonDS_install_mac(){
	mac_install_cask "MelonDS" "melonds" "melonDS.app" || return 1
	mac_deploy_launcher "melonds" "/Applications/melonDS.app"
}

#ApplyInitialSettings
melonDS_init(){
	if [ "$(uname)" != "Linux" ]; then melonDS_init_mac; return $?; fi
	setMSG "Initializing $melonDS_emuName settings."
	configEmuFP "${melonDS_emuName}" "${melonDS_emuPath}" "true"
	melonDS_setupStorage
	melonDS_setEmulationFolder
	melonDS_setupSaves
	#SRM_createParsers
	melonDS_addSteamInputProfile
	melonDS_flushEmulatorLauncher
	melonDS_addParser
}

melonDS_init_mac(){
	setMSG "Initializing $melonDS_emuName settings (macOS)."
	local cfgDir="${melonDS_configPath_mac}"
	mkdir -p "$cfgDir"
	configEmuAI "$melonDS_emuName" "config" "$cfgDir" "$emudeckBackend/configs/net.kuribo64.melonDS" "true"
	local cfgFile="${melonDS_configFile_mac}"
	# Setup save dirs first
	mkdir -p "${savesPath}/melonds/saves"
	mkdir -p "${savesPath}/melonds/states"
	mkdir -p "${storagePath}/melonDS/cheats"
	# Set paths in config
	if [ -f "$cfgFile" ]; then
		changeLine "BIOS9Path=" "BIOS9Path=${biosPath}/bios9.bin" "$cfgFile"
		changeLine "BIOS7Path=" "BIOS7Path=${biosPath}/bios7.bin" "$cfgFile"
		changeLine "FirmwarePath=" "FirmwarePath=${biosPath}/firmware.bin" "$cfgFile"
		changeLine "DSiBIOS9Path=" "DSiBIOS9Path=${biosPath}/dsi_bios9.bin" "$cfgFile"
		changeLine "DSiBIOS7Path=" "DSiBIOS7Path=${biosPath}/dsi_bios7.bin" "$cfgFile"
		changeLine "DSiFirmwarePath=" "DSiFirmwarePath=${biosPath}/dsi_firmware.bin" "$cfgFile"
		changeLine "DSiNANDPath=" "DSiNANDPath=${biosPath}/dsi_nand.bin" "$cfgFile"
		changeLine "LastROMFolder=" "LastROMFolder=${romsPath}/nds" "$cfgFile"
		changeLine "SaveFilePath=" "SaveFilePath=${savesPath}/melonds/saves" "$cfgFile"
		changeLine "SavestatePath=" "SavestatePath=${savesPath}/melonds/states" "$cfgFile"
	fi
}

#update
melonDS_update(){
	if [ "$(uname)" != "Linux" ]; then melonDS_init_mac; return $?; fi
	setMSG "Updating $melonDS_emuName settings."
	configEmuFP "${melonDS_emuName}" "${melonDS_emuPath}"
	updateEmuFP "${melonDS_emuName}" "${melonDS_emuPath}" "emulator" ""
	melonDS_setupStorage
	melonDS_setEmulationFolder
	melonDS_setupSaves
	melonDS_addSteamInputProfile
	melonDS_flushEmulatorLauncher
}

#ConfigurePaths
melonDS_setEmulationFolder(){
	setMSG "Setting $melonDS_emuName Emulation Folder"
	changeLine "BIOS9Path=" "BIOS9Path=${biosPath}/bios9.bin" "${melonDS_configFile}"
	changeLine "BIOS7Path=" "BIOS7Path=${biosPath}/bios7.bin" "${melonDS_configFile}"
	changeLine "FirmwarePath=" "FirmwarePath=${biosPath}/firmware.bin" "${melonDS_configFile}"
	changeLine "DSiBIOS9Path=" "DSiBIOS9Path=${biosPath}/dsi_bios9.bin" "${melonDS_configFile}"
	changeLine "DSiBIOS7Path=" "DSiBIOS7Path=${biosPath}/dsi_bios7.bin" "${melonDS_configFile}"
	changeLine "DSiFirmwarePath=" "DSiFirmwarePath=${biosPath}/dsi_firmware.bin" "${melonDS_configFile}"
	changeLine "DSiNANDPath=" "DSiNANDPath=${biosPath}/dsi_nand.bin" "${melonDS_configFile}"
	changeLine "LastROMFolder=" "LastROMFolder=${romsPath}/nds" "${melonDS_configFile}"
}

#SetupSaves
melonDS_setupSaves(){
	setMSG "Setting $melonDS_emuName Saves Folder"
	mkdir -p "${savesPath}/melonds/saves"
	mkdir -p "${savesPath}/melonds/states"
	changeLine "SaveFilePath=" "SaveFilePath=${savesPath}/melonds/saves" "${melonDS_configFile}"
	changeLine "SavestatePath=" "SavestatePath=${savesPath}/melonds/states" "${melonDS_configFile}"
}

#SetupStorage
melonDS_setupStorage(){
	setMSG "Setting $melonDS_emuName Storage Folder"
	mkdir -p "$storagePath/melonDS/cheats"
}

#WipeSettings
melonDS_wipe(){
	setMSG "Wiping $melonDS_emuName config directory. (factory reset)"
	if [ "$(uname)" != "Linux" ]; then
		rm -rf "${melonDS_configPath_mac}"
		return
	fi
	rm -rf "$HOME/.var/app/$melonDS_emuPath"
}

#Uninstall
melonDS_uninstall(){
	if [ "$(uname)" != "Linux" ]; then
		mac_uninstall_cask "MelonDS" "melonds" "melonDS.app"
		removeParser "nintendo_nds_melonds.json"
		return
	fi
	setMSG "Uninstalling $melonDS_emuName."
	removeParser "nintendo_nds_melonds.json"
	uninstallEmuFP "${melonDS_emuName}" "${melonDS_emuPath}" "emulator" ""
}

#setABXYstyle
melonDS_setABXYstyle(){
	local cfgFile="$melonDS_configFile"
	[ "$(uname)" != "Linux" ] && cfgFile="$melonDS_configFile_mac"
	changeLine "Joy_A=" "Joy_A=0" "${cfgFile}"
	changeLine "Joy_B=" "Joy_B=1" "${cfgFile}"
	changeLine "Joy_X=" "Joy_X=2" "${cfgFile}"
	changeLine "Joy_Y=" "Joy_Y=3" "${cfgFile}"
}

melonDS_setBAYXstyle(){
	local cfgFile="$melonDS_configFile"
	[ "$(uname)" != "Linux" ] && cfgFile="$melonDS_configFile_mac"
	changeLine "Joy_A=" "Joy_A=1" "${cfgFile}"
	changeLine "Joy_B=" "Joy_B=0" "${cfgFile}"
	changeLine "Joy_X=" "Joy_X=3" "${cfgFile}"
	changeLine "Joy_Y=" "Joy_Y=2" "${cfgFile}"
}

#Migrate
melonDS_migrate(){
	echo "NYI"
}

#WideScreenOn
melonDS_wideScreenOn(){
	echo "NYI"
}

#WideScreenOff
melonDS_wideScreenOff(){
	echo "NYI"
}

#BezelOn
melonDS_bezelOn(){
	echo "NYI"
}

#BezelOff
melonDS_bezelOff(){
	echo "NYI"
}

#finalExec - Extra stuff
melonDS_finalize(){
	echo "NYI"
}

melonDS_IsInstalled(){
	if [ "$(uname)" != "Linux" ]; then mac_app_installed "melonDS.app"; return; fi
	isFpInstalled "$melonDS_emuPath"
}

melonDS_resetConfig(){
	melonDS_init &>/dev/null && echo "true" || echo "false"
}

melonDS_addSteamInputProfile(){
	addSteamInputCustomIcons
	setMSG "Adding $melonDS_emuName Steam Input Profile."
	rsync -r --exclude='*/' "$emudeckBackend/configs/steam-input/" "$HOME/.steam/steam/controller_base/templates/"
}

melonDS_setResolution(){
	local cfgFile="$melonDS_configFile"
	[ "$(uname)" != "Linux" ] && cfgFile="$melonDS_configFile_mac"
	case $melonDSResolution in
		"720P") WindowWidth=1024; WindowHeight=768;;
		"1080P") WindowWidth=1536; WindowHeight=1152;;
		"1440P") WindowWidth=2048; WindowHeight=1536;;
		"4K") WindowWidth=2816; WindowHeight=2112;;
		*) echo "Error"; return 1;;
	esac
	RetroArch_setConfigOverride "WindowWidth" $WindowWidth "$cfgFile"
	RetroArch_setConfigOverride "WindowHeight" $WindowHeight "$cfgFile"
}

melonDS_flushEmulatorLauncher(){
	flushEmulatorLaunchers "melonds"
}

melonDS_addParser(){
	addParser "nintendo_nds_melonds.json"
}
