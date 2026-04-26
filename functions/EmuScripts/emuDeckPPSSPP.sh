#!/bin/bash
#variables
PPSSPP_emuName="PPSSPP"
PPSSPP_emuType="$emuDeckEmuTypeFlatpak"
PPSSPP_emuPath="org.ppsspp.PPSSPP"
PPSSPP_releaseURL=""
PPSSPP_configFile="$HOME/.var/app/${PPSSPP_emuPath}/config/ppsspp/PSP/SYSTEM/ppsspp.ini"

# macOS-specific paths
PPSSPP_configPath_mac="${HOME}/Library/Application Support/PPSSPP"
PPSSPP_configFile_mac="${HOME}/Library/Application Support/PPSSPP/PSP/SYSTEM/ppsspp.ini"

#cleanupOlderThings
PPSSPP_cleanup(){
	echo "NYI"
}

#Install
PPSSPP_install(){
	if [ "$(uname)" != "Linux" ]; then PPSSPP_install_mac "$@"; return $?; fi
	setMSG "Installing $PPSSPP_emuName"
	installEmuFP "${PPSSPP_emuName}" "${PPSSPP_emuPath}" "emulator" ""
}

#Fix for autoupdate
Ppsspp_install(){
	PPSSPP_install
}

PPSSPP_install_mac(){
	mac_install_cask "PPSSPP" "ppsspp" "PPSSPP.app" || return 1
	mac_deploy_launcher "ppsspp" "/Applications/PPSSPP.app"
}

#ApplyInitialSettings
PPSSPP_init(){
	if [ "$(uname)" != "Linux" ]; then PPSSPP_init_mac; return $?; fi
	setMSG "Initializing $PPSSPP_emuName settings."
	configEmuFP "${PPSSPP_emuName}" "${PPSSPP_emuPath}" "true"
	PPSSPP_setupStorage
	PPSSPP_setEmulationFolder
	PPSSPP_setupSaves
	PPSSPP_setRetroAchievements
	#SRM_createParsers
	PPSSPP_flushEmulatorLauncher
}

PPSSPP_init_mac(){
	setMSG "Initializing $PPSSPP_emuName settings (macOS)."
	local cfgDir="${PPSSPP_configPath_mac}/PSP/SYSTEM"
	mkdir -p "$cfgDir"
	# Set paths in config
	local cfgFile="${PPSSPP_configFile_mac}"
	if [ -f "$cfgFile" ]; then
		iniFieldUpdate "$cfgFile" "General" "CurrentDirectory" "${romsPath}/psp"
	fi
	# Setup saves
	mkdir -p "${savesPath}/ppsspp/saves"
	mkdir -p "${savesPath}/ppsspp/states"
	mac_link_save "ppsspp" "PPSSPP/PSP/SAVEDATA" "${savesPath}/ppsspp/saves"
	mac_link_save "ppsspp" "PPSSPP/PSP/PPSSPP_STATE" "${savesPath}/ppsspp/states"
}

#update
PPSSPP_update(){
	if [ "$(uname)" != "Linux" ]; then PPSSPP_init_mac; return $?; fi
	setMSG "Updating $PPSSPP_emuName settings."
	configEmuFP "${PPSSPP_emuName}" "${PPSSPP_emuPath}"
	updateEmuFP "${PPSSPP_emuName}" "${PPSSPP_emuPath}" "emulator" ""
	PPSSPP_setupStorage
	PPSSPP_setEmulationFolder
	PPSSPP_setupSaves
	PPSSPP_flushEmulatorLauncher
}

#ConfigurePaths
PPSSPP_setEmulationFolder(){
	setMSG "Setting $PPSSPP_emuName Emulation Folder"
	iniFieldUpdate "$PPSSPP_configFile" "General" "CurrentDirectory" "${romsPath}/psp"
}

#SetupSaves
PPSSPP_setupSaves(){
	linkToSaveFolder ppsspp saves "$HOME/.var/app/org.ppsspp.PPSSPP/config/ppsspp/PSP/SAVEDATA"
	linkToSaveFolder ppsspp states "$HOME/.var/app/org.ppsspp.PPSSPP/config/ppsspp/PSP/PPSSPP_STATE"
}

#SetupStorage
PPSSPP_setupStorage(){
	echo "NYI"
}

#WipeSettings
PPSSPP_wipe(){
	if [ "$(uname)" != "Linux" ]; then
		rm -rf "${PPSSPP_configPath_mac}"
		return
	fi
	rm -rf "$HOME/.var/app/$PPSSPP_emuPath"
}

#Uninstall
PPSSPP_uninstall(){
	if [ "$(uname)" != "Linux" ]; then mac_uninstall_cask "PPSSPP" "ppsspp" "PPSSPP.app"; return; fi
	uninstallEmuFP "${PPSSPP_emuName}" "${PPSSPP_emuPath}" "emulator" ""
}

#setABXYstyle
PPSSPP_setABXYstyle(){
	echo "NYI"
}

#Migrate
PPSSPP_migrate(){
	echo "NYI"
}

#WideScreenOn
PPSSPP_wideScreenOn(){
	echo "NYI"
}

#WideScreenOff
PPSSPP_wideScreenOff(){
	echo "NYI"
}

#BezelOn
PPSSPP_bezelOn(){
	echo "NYI"
}

#BezelOff
PPSSPP_bezelOff(){
	echo "NYI"
}

PPSSPP_IsInstalled(){
	if [ "$(uname)" != "Linux" ]; then mac_app_installed "PPSSPP.app"; return; fi
	isFpInstalled "$PPSSPP_emuPath"
}

PPSSPP_resetConfig(){
	PPSSPP_init &>/dev/null && echo "true" || echo "false"
}

#finalExec - Extra stuff
PPSSPP_finalize(){
	echo "NYI"
}

PPSSPP_retroAchievementsOn() {
	local cfgFile="$PPSSPP_configFile"
	[ "$(uname)" != "Linux" ] && cfgFile="$PPSSPP_configFile_mac"
	iniFieldUpdate "$cfgFile" "Achievements" "AchievementsEnable" "True"
}
PPSSPP_retroAchievementsOff() {
	local cfgFile="$PPSSPP_configFile"
	[ "$(uname)" != "Linux" ] && cfgFile="$PPSSPP_configFile_mac"
	iniFieldUpdate "$cfgFile" "Achievements" "AchievementsEnable" "False"
}

PPSSPP_retroAchievementsHardCoreOn() {
	local cfgFile="$PPSSPP_configFile"
	[ "$(uname)" != "Linux" ] && cfgFile="$PPSSPP_configFile_mac"
	iniFieldUpdate "$cfgFile" "Achievements" "AchievementsChallengeMode" "True"
}
PPSSPP_retroAchievementsHardCoreOff() {
	local cfgFile="$PPSSPP_configFile"
	[ "$(uname)" != "Linux" ] && cfgFile="$PPSSPP_configFile_mac"
	iniFieldUpdate "$cfgFile" "Achievements" "AchievementsChallengeMode" "False"
}

PPSSPP_retroAchievementsSetLogin() {
	local cfgFile="$PPSSPP_configFile"
	[ "$(uname)" != "Linux" ] && cfgFile="$PPSSPP_configFile_mac"

	local PPSSPP_token
	if [ "$(uname)" != "Linux" ]; then
		PPSSPP_token="${PPSSPP_configPath_mac}/PSP/SYSTEM/ppsspp_retroachievements.dat"
	else
		PPSSPP_token="$HOME/.var/app/${PPSSPP_emuPath}/config/ppsspp/PSP/SYSTEM/ppsspp_retroachievements.dat"
	fi

	rau=$(cat "$emudeckFolder/.rau")
	rat=$(cat "$emudeckFolder/.rat")
	touch "$PPSSPP_token"

	echo "Evaluate RetroAchievements Login."
	if [ ${#rat} -lt 1 ]; then
		echo "--No token."
	elif [ ${#rau} -lt 1 ]; then
		echo "--No username."
	else
		echo "Valid Retroachievements Username and Password length"
		iniFieldUpdate "$cfgFile" "Achievements" "AchievementsUserName" "${rau}"
		if [ ! -s "$PPSSPP_token" ]; then
			echo "${rat}" >> "${PPSSPP_token}"
		fi
		PPSSPP_retroAchievementsOn
	fi
}

PPSSPP_setRetroAchievements(){
	PPSSPP_retroAchievementsSetLogin
	if [ "$achievementsHardcore" == "true" ]; then
		PPSSPP_retroAchievementsHardCoreOn
	else
		PPSSPP_retroAchievementsHardCoreOff
	fi
}

PPSSPP_addSteamInputProfile(){
	addSteamInputCustomIcons
}

PPSSPP_setResolution(){
	echo "NYI"
}

PPSSPP_flushEmulatorLauncher(){
	flushEmulatorLaunchers "ppsspp"
}
