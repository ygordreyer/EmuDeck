#!/bin/bash

#variables
Ryujinx_emuName="Ryujinx"
Ryujinx_emuType="$emuDeckEmuTypeBinary"
Ryujinx_emuPath="$emusFolder/publish"
Ryujinx_configFile="$HOME/.config/Ryujinx/Config.json"
Ryujinx_controllerFile="$HOME/.config/Ryujinx/profiles/controller/Deck.json"

# macOS-specific paths (Ryujinx .app stores data in ~/Library/Application Support/Ryujinx)
Ryujinx_configPath_mac="${HOME}/Library/Application Support/Ryujinx"
Ryujinx_configFile_mac="${HOME}/Library/Application Support/Ryujinx/Config.json"

# https://github.com/Ryujinx/Ryujinx/blob/master/Ryujinx.Ui.Common/Configuration/System/Language.cs
declare -A Ryujinx_languages
Ryujinx_languages=(
["ja"]="Japanese"
["en"]="AmericanEnglish"
["fr"]="French"
["de"]="German"
["it"]="Italian"
["es"]="Spanish"
["zh"]="Chinese"
["ko"]="Korean"
["nl"]="Dutch"
["pt"]="Portuguese"
["ru"]="Russian"
["tw"]="Taiwanese")

declare -A Ryujinx_regions
Ryujinx_regions=(
["ja"]="Japan"
["en"]="USA"
["fr"]="Europe"
["de"]="Europe"
["it"]="Europe"
["es"]="Europe"
["zh"]="China"
["ko"]="Korea"
["nl"]="Europe"
["pt"]="Europe"
["ru"]="Europe"
["tw"]="Taiwan")

#cleanupOlderThings
Ryujinx_cleanup(){
	echo "Begin Ryujinx Cleanup"
}

#Install
Ryujinx_install(){
	if [ "$(uname)" != "Linux" ]; then Ryujinx_install_mac "$@"; return $?; fi
	echo "Begin Ryujinx Install"
	local showProgress=$1
	local url=$(curl -s "https://update.ryujinx.app/api/v1/version/stable/latest?os=linux&arch=amd64" | jq -r '.download_url')
	if installEmuBI "$Ryujinx_emuName" "$url" "" "tar.gz" "$showProgress"; then
		mkdir -p "$emusFolder/publish"
		tar -xvf "$emusFolder/Ryujinx.tar.gz" -C "$emusFolder" && rm -f "$emusFolder/Ryujinx.tar.gz"
		chmod +x "$emusFolder/publish/Ryujinx"
	else
		return 1
	fi
}

Ryujinx_install_mac(){
	setMSG "Installing Ryujinx (macOS)"
	local arch
	arch=$(mac_arch)
	local url
	if [ "$arch" = "arm64" ]; then
		url=$(mac_get_gh_release_url "Ryujinx/release-channel-master" "ryujinx-.*-macos_arm64\.tar\.gz" "ryujinx-.*-macos.*\.tar\.gz")
	else
		url=$(mac_get_gh_release_url "Ryujinx/release-channel-master" "ryujinx-.*-macos_x64\.tar\.gz" "ryujinx-.*-macos.*\.tar\.gz")
	fi
	if [ -z "$url" ]; then
		echo "[mac] ERROR: Could not find Ryujinx macOS release."
		return 1
	fi
	mac_install_targz "Ryujinx" "$url" "Ryujinx.app" || return 1
	mac_deploy_launcher "ryujinx" "/Applications/Ryujinx.app"
}

#ApplyInitialSettings
Ryujinx_init(){
	if [ "$(uname)" != "Linux" ]; then Ryujinx_init_mac; return $?; fi
	echo "Begin Ryujinx Init"
	configEmuAI "Ryujinx" "config" "$HOME/.config/Ryujinx" "$emudeckBackend/configs/Ryujinx" "true"
	Ryujinx_setEmulationFolder
	Ryujinx_setupStorage
	Ryujinx_setupSaves
	Ryujinx_finalize
	#SRM_createParsers
	Ryujinx_flushEmulatorLauncher
	Ryujinx_setLanguage
}

Ryujinx_init_mac(){
	setMSG "Initializing Ryujinx settings (macOS)."
	local cfgDir="${Ryujinx_configPath_mac}"
	mkdir -p "$cfgDir"
	configEmuAI "Ryujinx" "config" "$cfgDir" "$emudeckBackend/configs/Ryujinx" "true"
	local cfgFile="${Ryujinx_configFile_mac}"
	# BIOS/keys symlink
	mkdir -p "${biosPath}/ryujinx/"
	mkdir -p "$cfgDir/system/"
	unlink "${biosPath}/ryujinx/keys" 2>/dev/null || true
	ln -sn "$cfgDir/system" "${biosPath}/ryujinx/keys"
	# ROMs path in config
	if [ -f "$cfgFile" ]; then
		sed -i "s|/run/media/mmcblk0p1/Emulation/roms|${romsPath}|g" "$cfgFile"
	fi
	# Storage
	mkdir -p "${storagePath}/ryujinx/patchesAndDlc"
	mkdir -p "${storagePath}/ryujinx/games"
	local gamesDir="$cfgDir/games"
	if [ -d "$gamesDir" ] && [ ! -L "$gamesDir" ]; then
		rsync -av "$gamesDir/" "${storagePath}/ryujinx/games/" 2>/dev/null || true
		rm -rf "$gamesDir"
	fi
	unlink "$gamesDir" 2>/dev/null || true
	ln -ns "${storagePath}/ryujinx/games/" "$gamesDir"
	# Saves
	mkdir -p "${savesPath}/ryujinx/saves"
	mkdir -p "${savesPath}/ryujinx/saveMeta"
	# Language
	local language=$(locale | grep LANG | cut -d= -f2 | cut -d_ -f1)
	if [ -f "$cfgFile" ] && [ ${Ryujinx_languages[$language]+_} ]; then
		local tmp
		tmp=$(jq ".system_language=\"${Ryujinx_languages[$language]}\"" "$cfgFile")
		echo "$tmp" > "$cfgFile"
		tmp=$(jq ".system_region=\"${Ryujinx_regions[$language]}\"" "$cfgFile")
		echo "$tmp" > "$cfgFile"
	fi
}

#update
Ryujinx_update(){
	if [ "$(uname)" != "Linux" ]; then Ryujinx_init_mac; return $?; fi
	echo "Begin Ryujinx update"
	configEmuAI "Ryujinx" "config" "$HOME/.config/Ryujinx" "$emudeckBackend/configs/Ryujinx"
	Ryujinx_setEmulationFolder
	Ryujinx_setupStorage
	Ryujinx_setupSaves
	Ryujinx_finalize
	Ryujinx_flushEmulatorLauncher
}

#ConfigurePaths
Ryujinx_setEmulationFolder(){
	echo "Begin Ryujinx Path Config"
	unlink "${biosPath}/ryujinx/keys" 2>/dev/null || true
	mkdir -p "$HOME/.config/Ryujinx/system/"
	mkdir -p "${biosPath}/ryujinx/"
	unlink "$HOME/.config/Ryujinx/system" 2>/dev/null || true
	ln -sn "$HOME/.config/Ryujinx/system" "${biosPath}/ryujinx/keys"
	sed -i "s|/run/media/mmcblk0p1/Emulation/roms|${romsPath}|g" "$Ryujinx_configFile"
}

#SetLanguage
Ryujinx_setLanguage(){
	local cfgFile="$Ryujinx_configFile"
	[ "$(uname)" != "Linux" ] && cfgFile="$Ryujinx_configFile_mac"
	setMSG "Setting Ryujinx Language"
	local language=$(locale | grep LANG | cut -d= -f2 | cut -d_ -f1)
	if [[ -f "$cfgFile" ]]; then
		if [ ${Ryujinx_languages[$language]+_} ]; then
			local tmp
			tmp=$(jq ".system_language=\"${Ryujinx_languages[$language]}\"" "$cfgFile")
			echo "$tmp" > "$cfgFile"
			tmp=$(jq ".system_region=\"${Ryujinx_regions[$language]}\"" "$cfgFile")
			echo "$tmp" > "$cfgFile"
		fi
	fi
}

#SetupSaves
Ryujinx_setupSaves(){
	echo "Begin Ryujinx save link"
	if [ -d "${emulationPath}/saves/ryujinx/saves" ]; then
		rm -rf "${emulationPath}/saves/ryujinx/saves"
		rm -rf "${emulationPath}/saves/ryujinx/saveMeta"
	fi
	if [ -d "${emulationPath}/saves/Ryujinx/saves" ]; then
		rm -rf "${emulationPath}/saves/Ryujinx/"
	fi
	linkToSaveFolder ryujinx saves "$HOME/.config/Ryujinx/bis/user/save"
	linkToSaveFolder ryujinx saveMeta "$HOME/.config/Ryujinx/bis/user/saveMeta"
	linkToSaveFolder ryujinx system_saves "$HOME/.config/Ryujinx/bis/system/save"
	linkToSaveFolder ryujinx system "$HOME/.config/Ryujinx/system"
}

#SetupStorage
Ryujinx_setupStorage(){
	echo "Begin Ryujinx storage config"
	local origPath="$HOME/.config/"
	mkdir -p "${storagePath}/ryujinx/patchesAndDlc"
	rsync -av "${origPath}/Ryujinx/games/" "${storagePath}/ryujinx/games/" 2>/dev/null || true
	rm -rf "${origPath}Ryujinx/games"
	unlink "${origPath}/Ryujinx/games" 2>/dev/null || true
	ln -ns "${storagePath}/ryujinx/games/" "${origPath}/Ryujinx/games"
}

#WipeSettings
Ryujinx_wipe(){
	echo "Begin Ryujinx delete config directories"
	if [ "$(uname)" != "Linux" ]; then
		rm -rf "${Ryujinx_configPath_mac}"
		return
	fi
	rm -rf "$HOME/.config/Ryujinx"
}

#Uninstall
Ryujinx_uninstall(){
	if [ "$(uname)" != "Linux" ]; then
		mac_uninstall_app "Ryujinx.app"
		return
	fi
	echo "Begin Ryujinx uninstall"
	uninstallGeneric $Ryujinx_emuName $Ryujinx_emuPath "" "emulator"
}

#setABXYstyle
Ryujinx_setABXYstyle(){
	echo "NYI"
}

#Migrate
Ryujinx_migrate(){
	echo "NYI"
}

#WideScreenOn
Ryujinx_wideScreenOn(){
	echo "NYI"
}

#WideScreenOff
Ryujinx_wideScreenOff(){
	echo "NYI"
}

#BezelOn
Ryujinx_bezelOn(){
	echo "NYI"
}

#BezelOff
Ryujinx_bezelOff(){
	echo "NYI"
}

#finalExec - Extra stuff
Ryujinx_finalize(){
	echo "NYI"
}

Ryujinx_IsInstalled(){
	if [ "$(uname)" != "Linux" ]; then mac_app_installed "Ryujinx.app"; return; fi
	if [ -e "$emusFolder/publish/Ryujinx" ]; then
		echo "true"
	else
		echo "false"
	fi
}

Ryujinx_resetConfig(){
	Ryujinx_init &>/dev/null && echo "true" || echo "false"
}

Ryujinx_setResolution(){
	echo "NYI"
}

Ryujinx_flushEmulatorLauncher(){
	flushEmulatorLaunchers "ryujinx"
}
