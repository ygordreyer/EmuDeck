#!/bin/bash
#variables
ares_emuName="ares"
ares_emuType="$emuDeckEmuTypeFlatpak"
ares_emuPath="dev.ares.ares"
ares_configFile="$HOME/.var/app/dev.ares.ares/data/ares/settings.bml"

# macOS-specific paths
ares_configPath_mac="${HOME}/Library/Application Support/dev.ares.ares"
ares_configFile_mac="${HOME}/Library/Application Support/dev.ares.ares/settings.bml"

#cleanupOlderThings
ares_cleanup(){
	echo "NYI"
}

#Install
ares_install() {
	if [ "$(uname)" != "Linux" ]; then ares_install_mac "$@"; return $?; fi
	setMSG "Installing $ares_emuName"
	installEmuFP "${ares_emuName}" "${ares_emuPath}" "emulator" ""
}

ares_install_mac(){
	mac_install_cask "ares" "ares" "ares.app" || return 1
	mac_deploy_launcher "ares" "/Applications/ares.app"
}

#ApplyInitialSettings
ares_init() {
	if [ "$(uname)" != "Linux" ]; then ares_init_mac; return $?; fi
	setMSG "Initializing $ares_emuName settings."
	configEmuFP "${ares_emuName}" "${ares_emuPath}" "true"
	ares_setupStorage
	ares_setEmulationFolder
	ares_setupSaves
	ares_getDefaultShaders
	ares_getQuarkShaders
	ares_addESConfig
	#SRM_createParsers
	ares_flushEmulatorLauncher
}

ares_init_mac(){
	setMSG "Initializing $ares_emuName settings (macOS)."
	local cfgDir="${ares_configPath_mac}"
	mkdir -p "$cfgDir"
	configEmuAI "$ares_emuName" "config" "$cfgDir" "$emudeckBackend/configs/dev.ares.ares" "true"
	local cfgFile="${ares_configFile_mac}"
	# Create storage/save dirs
	mkdir -p "${savesPath}/ares/"
	mkdir -p "${storagePath}/ares/screenshots"
	# Apply paths in config (same sed-based approach as Linux)
	if [ -f "$cfgFile" ]; then
		sed -i "s|/home/deck/Emulation/roms/|${romsPath}\/|g" "$cfgFile"
		sed -i "s|/home/deck/Emulation/bios/|${biosPath}\/|g" "$cfgFile"
		sed -i "s|/home/deck/Emulation/saves|${savesPath}|g" "$cfgFile"
		sed -i "s|/home/deck/Emulation/storage|${storagePath}|g" "$cfgFile"
	fi
}

#update
ares_update() {
	if [ "$(uname)" != "Linux" ]; then ares_init_mac; return $?; fi
	setMSG "Installing $ares_emuName"
	configEmuFP "${ares_emuName}" "${ares_emuPath}"
	updateEmuFP "${ares_emuName}" "${ares_emuPath}" "emulator" ""
	ares_setupStorage
	ares_setEmulationFolder
	ares_setupSaves
	ares_getDefaultShaders
	ares_getQuarkShaders
	ares_addESConfig
	ares_flushEmulatorLauncher
}

#ConfigurePaths
ares_setEmulationFolder(){
	setMSG "Setting $ares_emuName Emulation Folder"
	sed -i "s|/home/deck/Emulation/roms/|${romsPath}\/|g" "$ares_configFile"
	sed -i "s|/home/deck/Emulation/bios/|${biosPath}\/|g" "$ares_configFile"
}

#SetupSaves
ares_setupSaves(){
	mkdir -p "${savesPath}/ares/"
	sed -i "s|/home/deck/Emulation/saves|${savesPath}|g" "$ares_configFile"
}

#SetupStorage
ares_setupStorage(){
	mkdir -p "${storagePath}/ares/"
	mkdir -p "${storagePath}/ares/screenshots"
	sed -i "s|/home/deck/Emulation/storage|${storagePath}|g" "$ares_configFile"
}

ares_addESConfig(){
	# Linux-only: uses xmlstarlet to add systems to ES-DE config
	[ "$(uname)" != "Linux" ] && return
	local UserROMsPath='/home/deck/Emulation/roms/'
	# Bandai SuFami Turbo
	if [[ $(grep -rnw "$es_systemsFile" -e 'sufami') == "" ]]; then
		xmlstarlet ed -S --inplace --subnode '/systemList' --type elem --name 'system' \
		--var newSystem '$prev' \
		--subnode '$newSystem' --type elem --name 'name' -v 'sufami' \
		--subnode '$newSystem' --type elem --name 'fullname' -v 'Bandai SuFami Turbo' \
		--subnode '$newSystem' --type elem --name 'path' -v '%ROMPATH%/sufami' \
		--subnode '$newSystem' --type elem --name 'extension' -v '.bml .BML .bs .BS .fig .FIG .sfc .SFC .smc .SMC .st .ST .7z .7Z .zip .ZIP' \
		--subnode '$newSystem' --type elem --name 'commandP' -v "/usr/bin/bash ${toolsPath}/launchers/ares-emu.sh STBIOS.bin --fullscreen --system \"Super Famicom\" %ROM%" \
		--insert '$newSystem/commandP' --type attr --name 'label' --value "ares (Standalone)" \
		--subnode '$newSystem' --type elem --name 'platform' -v 'sufami' \
		--subnode '$newSystem' --type elem --name 'theme' -v 'sufami' \
		-r 'systemList/system/commandP' -v 'command' \
		"$es_systemsFile"
		xmlstarlet fo "$es_systemsFile" > "$es_systemsFile".tmp && mv "$es_systemsFile".tmp "$es_systemsFile"
	fi
}

function ares_getDefaultShaders() {
	[ "$(uname)" != "Linux" ] && return
	local systemShadersFolder="/var/lib/flatpak/app/dev.ares.ares/x86_64/stable/active/files/share/ares/Shaders"
	local userShadersFolder="$HOME/.local/share/flatpak/app/dev.ares.ares/current/active/files/share/ares/Shaders"
	local flatpakShadersFolder="$HOME/.var/app/$ares_emuPath/data/ares/Shaders"
	if [ ! -d "$flatpakShadersFolder" ]; then mkdir -p "$flatpakShadersFolder"; fi
	if [ -d "$systemShadersFolder" ]; then
		cp -r "$systemShadersFolder"/* "$flatpakShadersFolder"
	elif [ -d "$userShadersFolder" ]; then
		cp -r "$userShadersFolder"/* "$flatpakShadersFolder"
	fi
}

function ares_getQuarkShaders() {
	[ "$(uname)" != "Linux" ] && return
	local shaderfolders_dir="$HOME/.var/app/$ares_emuPath/data/ares/Shaders"
	local quarkshaders_repo="https://github.com/hizzlekizzle/quark-shaders.git"
	local shaders_branch="master"
	if [ ! -d "$shaderfolders_dir" ]; then mkdir -p "$shaderfolders_dir"; fi
	cd "$shaderfolders_dir" || exit
	if ! git rev-parse --git-dir > /dev/null 2>&1; then git init; fi
	if ! git remote get-url origin > /dev/null 2>&1; then git remote add origin "$quarkshaders_repo"; fi
	if ! git config core.sparsecheckout > /dev/null 2>&1; then git config core.sparsecheckout true; fi
	if ! grep -Fxq "/*" .git/info/sparse-checkout; then echo "/*" >> .git/info/sparse-checkout; fi
	git fetch --depth=1 origin "$shaders_branch"
	if ! git merge FETCH_HEAD > /dev/null 2>&1; then
		git reset --hard HEAD > /dev/null 2>&1
		git clean -fd > /dev/null 2>&1
		git fetch --depth=1 origin "$shaders_branch"
		git merge FETCH_HEAD > /dev/null 2>&1 || echo "Error: Failed to update Quark Shaders"
	fi
}

#WipeSettings
ares_wipe(){
	if [ "$(uname)" != "Linux" ]; then
		rm -rf "${ares_configPath_mac}"
		return
	fi
	rm -rf "$HOME/.var/app/$ares_emuPath"
}

#Uninstall
ares_uninstall(){
	if [ "$(uname)" != "Linux" ]; then mac_uninstall_cask "ares" "ares" "ares.app"; return; fi
	uninstallEmuFP "${ares_emuName}" "${ares_emuPath}" "emulator" ""
}

#setABXYstyle
ares_setABXYstyle(){
	echo "NYI"
}

#Migrate
ares_migrate(){
	echo "NYI"
}

#WideScreenOn
ares_wideScreenOn(){
	echo "NYI"
}

#WideScreenOff
ares_wideScreenOff(){
	echo "NYI"
}

#BezelOn
ares_bezelOn(){
	echo "NYI"
}

#BezelOff
ares_bezelOff(){
	echo "NYI"
}

ares_IsInstalled(){
	if [ "$(uname)" != "Linux" ]; then mac_app_installed "ares.app"; return; fi
	isFpInstalled "$ares_emuPath"
}

ares_resetConfig(){
	ares_init &>/dev/null && echo "true" || echo "false"
}

ares_addSteamInputProfile(){
	addSteamInputCustomIcons
}

#finalExec - Extra stuff
ares_finalize(){
	echo "NYI"
}

ares_flushEmulatorLauncher(){
	flushEmulatorLaunchers "$ares_emuName"
}
