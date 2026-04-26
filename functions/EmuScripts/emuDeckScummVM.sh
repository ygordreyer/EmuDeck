#!/bin/bash
#variables
ScummVM_emuName="ScummVM"
ScummVM_emuType="$emuDeckEmuTypeFlatpak"
ScummVM_emuPath="org.scummvm.ScummVM"
ScummVM_releaseURL=""
ScummVM_configFile="$HOME/.var/app/org.scummvm.ScummVM/config/scummvm/scummvm.ini"

# macOS-specific paths
ScummVM_configPath_mac="${HOME}/Library/Application Support/ScummVM"
ScummVM_configFile_mac="${HOME}/Library/Application Support/ScummVM/scummvm.ini"

#cleanupOlderThings
ScummVM_cleanup(){
	echo "NYI"
}

#Install
ScummVM_install(){
	if [ "$(uname)" != "Linux" ]; then ScummVM_install_mac "$@"; return $?; fi
	installEmuFP "${ScummVM_emuName}" "${ScummVM_emuPath}" "emulator" ""
}

#Fix for autoupdate
Scummvm_install(){
	ScummVM_install
}

ScummVM_install_mac(){
	mac_install_cask "ScummVM" "scummvm" "ScummVM.app" || return 1
	mac_deploy_launcher "scummvm" "/Applications/ScummVM.app"
}

#ApplyInitialSettings
ScummVM_init(){
	if [ "$(uname)" != "Linux" ]; then ScummVM_init_mac; return $?; fi
	configEmuFP "${ScummVM_emuName}" "${ScummVM_emuPath}" "true"
	updateEmuFP "${ScummVM_emuName}" "${ScummVM_emuPath}" "emulator" ""
	ScummVM_setupStorage
	ScummVM_setEmulationFolder
	ScummVM_setupSaves
	#SRM_createParsers
	ScummVM_flushEmulatorLauncher
	ScummVM_setLanguage
}

ScummVM_init_mac(){
	setMSG "Initializing $ScummVM_emuName settings (macOS)."
	local cfgDir="${ScummVM_configPath_mac}"
	mkdir -p "$cfgDir"
	configEmuAI "$ScummVM_emuName" "config" "$cfgDir" "$emudeckBackend/configs/org.scummvm.ScummVM" "true"
	local cfgFile="${ScummVM_configFile_mac}"
	mkdir -p "${savesPath}/scummvm/saves"
	if [ -f "$cfgFile" ]; then
		changeLine "browser_lastpath=" "browser_lastpath=${romsPath}/scummvm" "$cfgFile"
		changeLine "savepath=" "savepath=${savesPath}/scummvm/saves" "$cfgFile"
	fi
	# Set language
	local language=$(locale | grep LANG | cut -d= -f2 | cut -d. -f1)
	if [ -f "$cfgFile" ]; then
		changeLine "gui_language=" "gui_language=${language}" "$cfgFile"
	fi
}

ScummVM_setLanguage(){
	setMSG "Setting ScummVM Language"
	local cfgFile="$ScummVM_configFile"
	[ "$(uname)" != "Linux" ] && cfgFile="$ScummVM_configFile_mac"
	local language=$(locale | grep LANG | cut -d= -f2 | cut -d. -f1)
	changeLine "gui_language=" "gui_language=${language}" "$cfgFile"
}

#update
ScummVM_update(){
	if [ "$(uname)" != "Linux" ]; then ScummVM_init_mac; return $?; fi
	configEmuFP "${ScummVM_emuName}" "${ScummVM_emuPath}"
	ScummVM_setupStorage
	ScummVM_setEmulationFolder
	ScummVM_setupSaves
	ScummVM_flushEmulatorLauncher
}

#ConfigurePaths
ScummVM_setEmulationFolder(){
	changeLine "browser_lastpath=" "browser_lastpath=${romsPath}/scummvm" "$ScummVM_configFile"
}

#SetupSaves
ScummVM_setupSaves(){
	local cfgFile="$ScummVM_configFile"
	changeLine "savepath=" "savepath=${savesPath}/scummvm/saves" "$cfgFile"
	moveSaveFolder scummvm saves "$HOME/.var/app/org.scummvm.ScummVM/data/scummvm/saves"
}

#SetupStorage
ScummVM_setupStorage(){
	echo "NYI"
}

#WipeSettings
ScummVM_wipe(){
	if [ "$(uname)" != "Linux" ]; then
		rm -rf "${ScummVM_configPath_mac}"
		return
	fi
	rm -rf "$HOME/.var/app/$ScummVM_emuPath"
}

#Uninstall
ScummVM_uninstall(){
	if [ "$(uname)" != "Linux" ]; then mac_uninstall_cask "ScummVM" "scummvm" "ScummVM.app"; return; fi
	uninstallEmuFP "${ScummVM_emuName}" "${ScummVM_emuPath}" "emulator" ""
}

#setABXYstyle
ScummVM_setABXYstyle(){
	echo "NYI"
}

#Migrate
ScummVM_migrate(){
	echo "NYI"
}

#WideScreenOn
ScummVM_wideScreenOn(){
	echo "NYI"
}

#WideScreenOff
ScummVM_wideScreenOff(){
	echo "NYI"
}

#BezelOn
ScummVM_bezelOn(){
	echo "NYI"
}

#BezelOff
ScummVM_bezelOff(){
	echo "NYI"
}

ScummVM_IsInstalled(){
	if [ "$(uname)" != "Linux" ]; then mac_app_installed "ScummVM.app"; return; fi
	isFpInstalled "$ScummVM_emuPath"
}

ScummVM_resetConfig(){
	ScummVM_init &>/dev/null && echo "true" || echo "false"
}

#finalExec - Extra stuff
ScummVM_finalize(){
	echo "NYI"
}

ScummVM_setResolution(){
	echo "NYI"
}

ScummVM_flushEmulatorLauncher(){
	flushEmulatorLaunchers "scummvm"
}
