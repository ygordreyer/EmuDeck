#!/bin/bash

#variables
Vita3K_emuName="Vita3K"
Vita3K_emuType="$emuDeckEmuTypeBinary"
Vita3K_emuPath="$emusFolder/Vita3K"
Vita3K_configFile="$HOME/.config/Vita3K/config.yml"

# macOS-specific paths
Vita3K_configPath_mac="${HOME}/Library/Application Support/Vita3K"
Vita3K_configFile_mac="${HOME}/Library/Application Support/Vita3K/config.yml"

#cleanupOlderThings
Vita3K_cleanup(){
	echo "Begin Vita3K Cleanup"
}

#Install
Vita3K_install(){
	if [ "$(uname)" != "Linux" ]; then Vita3K_install_mac "$@"; return $?; fi
	echo "Begin Vita3K Install"
	local showProgress="$1"
	if installEmuBI "$Vita3K_emuName" "$(getReleaseURLGH "Vita3K/Vita3K" "ubuntu-latest.zip")" "" "zip" "$showProgress"; then
		unzip -o "$emusFolder/Vita3K.zip" -d "$Vita3K_emuPath" && rm -rf "$emusFolder/Vita3K.zip"
		chmod +x "$Vita3K_emuPath/Vita3K"
	else
		return 1
	fi
}

#Fix for autoupdate
Vita3k_install(){
	Vita3K_install
}

Vita3K_install_mac(){
	setMSG "Installing Vita3K (macOS)"
	local url
	url=$(mac_get_gh_release_url "Vita3K/Vita3K" "Vita3K-macOS\.dmg" "Vita3K.*macOS.*\.dmg")
	if [ -z "$url" ]; then
		echo "[mac] ERROR: Could not find Vita3K macOS release."
		return 1
	fi
	mac_install_dmg "Vita3K" "$url" "Vita3K.app" || return 1
	mac_deploy_launcher "vita3k" "/Applications/Vita3K.app"
}

#ApplyInitialSettings
Vita3K_init(){
	if [ "$(uname)" != "Linux" ]; then Vita3K_init_mac; return $?; fi
	echo "Begin Vita3K Init"
	configEmuAI "Vita3K" "config" "$HOME/.config/Vita3K" "$emudeckBackend/configs/Vita3K" "true"
	Vita3K_setEmulationFolder
	Vita3K_setupStorage
	Vita3K_setupSaves
	Vita3K_finalize
	#SRM_createParsers
	Vita3K_flushEmulatorLauncher
}

Vita3K_init_mac(){
	setMSG "Initializing Vita3K settings (macOS)."
	local cfgDir="${Vita3K_configPath_mac}"
	mkdir -p "$cfgDir"
	configEmuAI "Vita3K" "config" "$cfgDir" "$emudeckBackend/configs/Vita3K" "true"
	local cfgFile="${Vita3K_configFile_mac}"
	if [ -f "$cfgFile" ]; then
		changeLine "pref-path: " "pref-path: ${storagePath}/Vita3K/" "$cfgFile"
	fi
	mkdir -p "$storagePath/Vita3K/ux0/app"
	mkdir -p "$storagePath/Vita3K/ux0/user/00/savedata"
	# InstalledGames symlink
	unlink "$romsPath/psvita/InstalledGames" 2>/dev/null || true
	ln -s "$storagePath/Vita3K/ux0/app" "$romsPath/psvita/InstalledGames"
	# Save link
	mkdir -p "${savesPath}/Vita3K"
	ln -sf "$storagePath/Vita3K/ux0/user/00/savedata" "${savesPath}/Vita3K/saves" 2>/dev/null || true
}

#update
Vita3K_update(){
	if [ "$(uname)" != "Linux" ]; then Vita3K_init_mac; return $?; fi
	echo "Begin Vita3K update"
	configEmuAI "Vita3K" "config" "$HOME/.config/Vita3K" "$emudeckBackend/configs/Vita3K"
	Vita3K_setEmulationFolder
	Vita3K_setupStorage
	Vita3K_setupSaves
	Vita3K_finalize
	Vita3K_flushEmulatorLauncher
}

#ConfigurePaths
Vita3K_setEmulationFolder(){
	echo "Begin Vita3K Path Config"
	local prefpath_directoryOpt='pref-path: '
	local newprefpath_directoryOpt="$prefpath_directoryOpt""$storagePath/Vita3K/"
	changeLine "$prefpath_directoryOpt" "$newprefpath_directoryOpt" "$Vita3K_configFile"
}

#SetupSaves
Vita3K_setupSaves(){
	echo "Begin Vita3K save link"
	linkToSaveFolder Vita3K saves "$storagePath/Vita3K/ux0/user/00/savedata"
}

#SetupStorage
Vita3K_setupStorage(){
	echo "Begin Vita3K storage config"
	mkdir -p "$storagePath/Vita3K/ux0/app"
	unlink "$romsPath/psvita/InstalledGames" 2>/dev/null || true
	ln -s "$storagePath/Vita3K/ux0/app" "$romsPath/psvita/InstalledGames"
}

#WipeSettings
Vita3K_wipe(){
	echo "Begin Vita3K delete config directories"
	if [ "$(uname)" != "Linux" ]; then
		rm -rf "${Vita3K_configPath_mac}"
		return
	fi
	rm -rf "$HOME/.config/Vita3K"
}

#Uninstall
Vita3K_uninstall(){
	if [ "$(uname)" != "Linux" ]; then
		mac_uninstall_app "Vita3K.app"
		return
	fi
	echo "Begin Vita3K uninstall"
	uninstallGeneric $Vita3K_emuName $Vita3K_emuPath "" "emulator"
}

#Migrate
Vita3K_migrate(){
	echo "NYI"
}

#setABXYstyle
Vita3K_setABXYstyle(){
	echo "NYI"
}

#WideScreenOn
Vita3K_wideScreenOn(){
	echo "NYI"
}

#WideScreenOff
Vita3K_wideScreenOff(){
	echo "NYI"
}

#BezelOn
Vita3K_bezelOn(){
	echo "NYI"
}

#BezelOff
Vita3K_bezelOff(){
	echo "NYI"
}

#finalExec - Extra stuff
Vita3K_finalize(){
	echo "Begin Vita3K finalize"
}

Vita3K_IsInstalled(){
	if [ "$(uname)" != "Linux" ]; then mac_app_installed "Vita3K.app"; return; fi
	if [ -e "$Vita3K_emuPath/Vita3K" ]; then
		echo "true"
	else
		echo "false"
	fi
}

Vita3K_resetConfig(){
	Vita3K_init &>/dev/null && echo "true" || echo "false"
}

Vita3K_setResolution(){
	echo "NYI"
}

Vita3K_flushEmulatorLauncher(){
	flushEmulatorLaunchers "vita3k"
}
