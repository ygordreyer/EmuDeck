#!/bin/bash
#variables
MAME_emuName="MAME"
MAME_emuType="$emuDeckEmuTypeFlatpak"
MAME_emuPath="org.mamedev.MAME"
MAME_releaseURL=""
MAME_configFile="$HOME/.mame/mame.ini"

# macOS-specific paths — MAME on macOS also uses ~/.mame/ (brew install mame)
MAME_configPath_mac="${HOME}/.mame"
MAME_configFile_mac="${HOME}/.mame/mame.ini"

#cleanupOlderThings
MAME_cleanup(){
	echo "NYI"
}

#Install
MAME_install(){
	if [ "$(uname)" != "Linux" ]; then MAME_install_mac "$@"; return $?; fi
	installEmuFP "${MAME_emuName}" "${MAME_emuPath}" "emulator" ""
}

#Fix for autoupdate
Mame_install(){
	MAME_install
}

MAME_install_mac(){
	# MAME on macOS is installed via brew install mame (not cask — it's a CLI app)
	setMSG "Installing MAME (macOS)"
	if brew install mame 2>&1; then
		echo "[mac] MAME installed successfully via brew."
		# Deploy a launcher script wrapping the mame CLI
		mkdir -p "${toolsPath}/launchers"
		mkdir -p "${romsPath}/emulators"
		cat > "${toolsPath}/launchers/mame.sh" << 'LAUNCHER'
#!/bin/bash
exec mame "$@"
LAUNCHER
		chmod +x "${toolsPath}/launchers/mame.sh"
		cp -f "${toolsPath}/launchers/mame.sh" "${romsPath}/emulators/mame.sh"
	else
		echo "[mac] brew install mame failed."
		return 1
	fi
}

#ApplyInitialSettings
MAME_init(){
	if [ "$(uname)" != "Linux" ]; then MAME_init_mac; return $?; fi
	configEmuAI "${MAME_emuName}" "mame" "$HOME/.mame" "$emudeckBackend/configs/mame" "true"
	MAME_setupStorage
	MAME_setEmulationFolder
	MAME_setupSaves
	#SRM_createParsers
	MAME_flushEmulatorLauncher
	MAME_addSteamInputProfile
	MAME_addParser
	# Backup mame.ini if writeconfig was enabled
	if [ -f "$storagePath/mame/ini/mame.ini" ]; then
		mv "$storagePath/mame/ini/mame.ini" "$storagePath/mame/ini/mame.ini.bak"
	fi
	if [ -f "$HOME/.mame/ini/mame.ini" ]; then
		mv "$HOME/.mame/ini/mame.ini" "$HOME/.mame/ini/mame.ini.bak"
	fi
}

MAME_init_mac(){
	setMSG "Initializing MAME settings (macOS)."
	# MAME uses ~/.mame/ on macOS as well
	mkdir -p "$HOME/.mame"
	configEmuAI "${MAME_emuName}" "mame" "$HOME/.mame" "$emudeckBackend/configs/mame" "true"
	MAME_setupStorage
	MAME_setEmulationFolder
	MAME_setupSaves
	MAME_addParser
}

#update
MAME_update(){
	if [ "$(uname)" != "Linux" ]; then MAME_init_mac; return $?; fi
	configEmuAI "${MAME_emuName}" "mame" "$HOME/.mame" "$emudeckBackend/configs/mame"
	updateEmuFP "${MAME_emuName}" "${MAME_emuPath}" "emulator" ""
	MAME_setupStorage
	MAME_setEmulationFolder
	MAME_setupSaves
	MAME_flushEmulatorLauncher
	MAME_addSteamInputProfile
}

#ConfigurePaths
MAME_setEmulationFolder(){
	local cfgFile="$MAME_configFile"
	changeLine "rompath                   " "rompath                   ${romsPath}/arcade;${biosPath};${biosPath}/mame" "$cfgFile"
	changeLine "samplepath                " "samplepath                ${storagePath}/mame/samples;"'$HOME/.mame/samples' "$cfgFile"
	changeLine "artpath                   " "artpath                   ${storagePath}/mame/artwork;"'$HOME/.mame/artwork' "$cfgFile"
	changeLine "ctrlrpath                 " "ctrlrpath                 ${storagePath}/mame/ctrlr;"'$HOME/.mame/ctrlr' "$cfgFile"
	changeLine "inipath                   " "inipath                   ${storagePath}/mame/ini;"'$HOME/.mame/ini;$HOME/.mame' "$cfgFile"
	changeLine "cheatpath                 " "cheatpath                 ${storagePath}/mame/cheat;"'$HOME/.mame/cheat' "$cfgFile"
	changeLine "pluginspath               " "pluginspath               ${storagePath}/mame/plugins;"'$HOME/.mame/plugins' "$cfgFile"
}

#SetupSaves
MAME_setupSaves(){
	local cfgFile="$MAME_configFile"
	changeLine "nvram_directory           " "nvram_directory           ${savesPath}/mame/saves" "$cfgFile"
	changeLine "state_directory           " "state_directory           ${savesPath}/mame/states" "$cfgFile"
	moveSaveFolder MAME saves "$HOME/.mame/nvram"
	moveSaveFolder MAME states "$HOME/.mame/sta"
}

#SetupStorage
MAME_setupStorage(){
	mkdir -p "$storagePath/mame/samples"
	mkdir -p "$storagePath/mame/artwork"
	mkdir -p "$storagePath/mame/ctrlr"
	mkdir -p "$storagePath/mame/ini"
	mkdir -p "$storagePath/mame/cheat"
	mkdir -p "$storagePath/mame/plugins"
	mkdir -p "$HOME/.mame/samples"
	mkdir -p "$HOME/.mame/artwork"
	mkdir -p "$HOME/.mame/ctrlr"
	mkdir -p "$HOME/.mame/ini"
	mkdir -p "$HOME/.mame/cheat"
	mkdir -p "$HOME/.mame/plugins"
}

#WipeSettings
MAME_wipe(){
	if [ "$(uname)" != "Linux" ]; then
		rm -rf "$HOME/.mame"
		return
	fi
	rm -rf "$HOME/.mame"
}

#Uninstall
MAME_uninstall(){
	if [ "$(uname)" != "Linux" ]; then
		brew uninstall mame 2>/dev/null || true
		removeParser "arcade_mame.json"
		removeParser "philips_cdi_mame.json"
		removeParser "snk_neogeocd_mame.json"
		return
	fi
	removeParser "arcade_mame.json"
	removeParser "philips_cdi_mame.json"
	removeParser "snk_neogeocd_mame.json"
	uninstallEmuFP "${MAME_emuName}" "${MAME_emuPath}" "emulator" ""
}

#setABXYstyle
MAME_setABXYstyle(){
	echo "NYI"
}

#Migrate
MAME_migrate(){
	echo "NYI"
}

#WideScreenOn
MAME_wideScreenOn(){
	echo "NYI"
}

#WideScreenOff
MAME_wideScreenOff(){
	echo "NYI"
}

#BezelOn
MAME_bezelOn(){
	echo "NYI"
}

#BezelOff
MAME_bezelOff(){
	echo "NYI"
}

MAME_IsInstalled(){
	if [ "$(uname)" != "Linux" ]; then
		if command -v mame >/dev/null 2>&1; then
			echo "true"
		else
			echo "false"
		fi
		return
	fi
	isFpInstalled "$MAME_emuPath"
}

MAME_resetConfig(){
	MAME_init &>/dev/null && echo "true" || echo "false"
}

#finalExec - Extra stuff
MAME_finalize(){
	echo "NYI"
}

MAME_flushEmulatorLauncher(){
	flushEmulatorLaunchers "mame"
}

MAME_addSteamInputProfile(){
	setMSG "Adding $MAME_emuName Steam Input Profile."
	rsync -r --exclude='*/' "$emudeckBackend/configs/steam-input/emudeck_steam_deck_light_gun_controls.vdf" "$HOME/.steam/steam/controller_base/templates/emudeck_steam_deck_light_gun_controls.vdf"
}

MAME_addParser(){
	addParser "arcade_mame.json"
	addParser "philips_cdi_mame.json"
	addParser "snk_neogeocd_mame.json"
}
