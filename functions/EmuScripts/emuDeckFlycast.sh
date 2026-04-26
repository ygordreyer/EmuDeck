#!/bin/bash

#variables
Flycast_emuName="Flycast"
Flycast_emuType="$emuDeckEmuTypeFlatpak"
Flycast_emuPath="org.flycast.Flycast"
Flycast_configFile="$HOME/.var/app/org.flycast.Flycast/config/flycast/emu.cfg"

# macOS-specific paths
Flycast_configPath_mac="${HOME}/Library/Application Support/flycast"
Flycast_configFile_mac="${HOME}/Library/Application Support/flycast/emu.cfg"

#cleanupOlderThings
Flycast_cleanup(){
	echo "NYI"
}

#Install
Flycast_install(){
	if [ "$(uname)" != "Linux" ]; then Flycast_install_mac "$@"; return $?; fi
	setMSG "Installing $Flycast_emuName"
	installEmuFP "${Flycast_emuName}" "${Flycast_emuPath}" "emulator" ""
}

Flycast_install_mac(){
	mac_install_cask "Flycast" "flycast" "Flycast.app" || return 1
	mac_deploy_launcher "flycast" "/Applications/Flycast.app"
}

#ApplyInitialSettings
Flycast_init(){
	if [ "$(uname)" != "Linux" ]; then Flycast_init_mac; return $?; fi
	setMSG "Initializing $Flycast_emuName settings."
	configEmuFP "${Flycast_emuName}" "${Flycast_emuPath}" "true"
	updateEmuFP "${Flycast_emuName}" "${Flycast_emuPath}" "emulator" ""
	Flycast_setupStorage
	Flycast_setEmulationFolder
	Flycast_setupSaves
	#SRM_createParsers
	Flycast_flushEmulatorLauncher
	Flycast_addSteamInputProfile
	Flycast_addParser
}

Flycast_init_mac(){
	setMSG "Initializing $Flycast_emuName settings (macOS)."
	local cfgDir="${Flycast_configPath_mac}"
	mkdir -p "$cfgDir"
	configEmuAI "$Flycast_emuName" "config" "$cfgDir" "$emudeckBackend/configs/org.flycast.Flycast" "true"
	local cfgFile="${Flycast_configFile_mac}"
	if [ -f "$cfgFile" ]; then
		changeLine "Dreamcast.ContentPath = " "Dreamcast.ContentPath = ${romsPath}/dreamcast;${romsPath}/atomiswave;${romsPath}/naomi;${romsPath}/naomi2" "$cfgFile"
	fi
	# BIOS symlink
	mkdir -p "${biosPath}/flycast/"
	mkdir -p "${cfgDir}/"
	ln -sn "${cfgDir}/" "${biosPath}/flycast/bios" 2>/dev/null || true
	# Saves
	mkdir -p "${savesPath}/flycast/saves"
	mkdir -p "${savesPath}/flycast/states"
}

#update
Flycast_update(){
	if [ "$(uname)" != "Linux" ]; then Flycast_init_mac; return $?; fi
	setMSG "Updating $Flycast_emuName settings."
	configEmuFP "${Flycast_emuName}" "${Flycast_emuPath}"
	Flycast_setupStorage
	Flycast_setEmulationFolder
	Flycast_setupSaves
	Flycast_flushEmulatorLauncher
	Flycast_addSteamInputProfile
}

#ConfigurePaths
Flycast_setEmulationFolder(){
	setMSG "Setting $Flycast_emuName Emulation Folder"
	changeLine "Dreamcast.ContentPath = " "Dreamcast.ContentPath = ${romsPath}/dreamcast;${romsPath}/atomiswave;${romsPath}/naomi;${romsPath}/naomi2" "${Flycast_configFile}"
	mkdir -p "${biosPath}/flycast/"
	mkdir -p "$HOME/.var/app/org.flycast.Flycast/data/flycast/"
	ln -sn "$HOME/.var/app/org.flycast.Flycast/data/flycast/" "${biosPath}/flycast/bios"
}

#SetupSaves
Flycast_setupSaves(){
	linkToSaveFolder flycast saves "$HOME/.var/app/org.flycast.Flycast/data/flycast/"
	linkToSaveFolder flycast states "$HOME/.var/app/org.flycast.Flycast/config/data/flycast/"
}

#SetupStorage
Flycast_setupStorage(){
	echo "NYI"
}

#WipeSettings
Flycast_wipe(){
	setMSG "Wiping $Flycast_emuName settings folder."
	if [ "$(uname)" != "Linux" ]; then
		rm -rf "${Flycast_configPath_mac}"
		return
	fi
	rm -rf "$HOME/.var/app/$Flycast_emuPath"
}

#Uninstall
Flycast_uninstall(){
	if [ "$(uname)" != "Linux" ]; then
		mac_uninstall_cask "Flycast" "flycast" "Flycast.app"
		removeParser "sega_dreamcast_flycast.json"
		removeParser "atomiswave_flycast.json"
		removeParser "naomi_flycast.json"
		removeParser "naomi2_flycast.json"
		return
	fi
	setMSG "Uninstalling ${Flycast_emuName}."
	removeParser "sega_dreamcast_flycast.json"
	removeParser "atomiswave_flycast.json"
	removeParser "naomi_flycast.json"
	removeParser "naomi2_flycast.json"
	uninstallEmuFP "${Flycast_emuName}" "${Flycast_emuPath}" "emulator" ""
}

#setABXYstyle
Flycast_setABXYstyle(){
	echo "NYI"
}

#Migrate
Flycast_migrate(){
	echo "NYI"
}

#WideScreenOn
Flycast_wideScreenOn(){
	local cfgFile="$Flycast_configFile"
	[ "$(uname)" != "Linux" ] && cfgFile="$Flycast_configFile_mac"
	setMSG "${Flycast_emuName}: Widescreen On"
	sed -i "s|rend.WidescreenGameHacks = .*|rend.WidescreenGameHacks = yes|" "$cfgFile"
	sed -i "s|rend.WideScreen = .*|rend.WideScreen = yes|" "$cfgFile"
}

#WideScreenOff
Flycast_wideScreenOff(){
	local cfgFile="$Flycast_configFile"
	[ "$(uname)" != "Linux" ] && cfgFile="$Flycast_configFile_mac"
	setMSG "${Flycast_emuName}: Widescreen Off"
	sed -i "s|rend.WidescreenGameHacks = .*|rend.WidescreenGameHacks = no|" "$cfgFile"
	sed -i "s|rend.WideScreen = .*|rend.WideScreen = no|" "$cfgFile"
}

#BezelOn
Flycast_bezelOn(){
	echo "NYI"
}

#BezelOff
Flycast_bezelOff(){
	echo "NYI"
}

#finalExec - Extra stuff
Flycast_finalize(){
	echo "NYI"
}

Flycast_IsInstalled(){
	if [ "$(uname)" != "Linux" ]; then mac_app_installed "Flycast.app"; return; fi
	isFpInstalled "$Flycast_emuPath"
}

Flycast_resetConfig(){
	Flycast_init &>/dev/null && echo "true" || echo "false"
}

Flycast_addSteamInputProfile(){
	setMSG "Adding $Flycast_emuName Steam Input Profile."
	rsync -r --exclude='*/' "$emudeckBackend/configs/steam-input/emudeck_steam_deck_light_gun_controls.vdf" "$HOME/.steam/steam/controller_base/templates/emudeck_steam_deck_light_gun_controls.vdf"
}

Flycast_setResolution(){
	echo "NYI"
}

Flycast_flushEmulatorLauncher(){
	flushEmulatorLaunchers "flycast"
}

Flycast_addParser(){
	addParser "sega_dreamcast_flycast.json"
	addParser "atomiswave_flycast.json"
	addParser "naomi_flycast.json"
	addParser "naomi2_flycast.json"
}
