#!/bin/bash

#variables
Eden_emuName="eden"
Eden_emuType="$emuDeckEmuTypeAppImage"
Eden_emuPath="$emusFolder/Eden.AppImage"
Eden_configFile="$HOME/.config/eden/qt-config.ini"

# macOS-specific paths
Eden_configPath_mac="${HOME}/Library/Application Support/eden"
Eden_configFile_mac="${HOME}/Library/Application Support/eden/qt-config.ini"

# Guard: declare -A requires bash 4+ (macOS ships bash 3.2)
# https://github.com/eden-emu/eden
if [ "${BASH_VERSINFO[0]:-0}" -ge 4 ]; then
    declare -A Eden_languages
    Eden_languages=(
    ["ja"]=0
    ["en"]=1
    ["fr"]=2
    ["de"]=3
    ["it"]=4
    ["es"]=5
    ["zh"]=6
    ["ko"]=7
    ["nl"]=8
    ["pt"]=9
    ["ru"]=10
    ["tw"]=11)

    declare -A Eden_regions
    Eden_regions=(
    ["ja"]=0 # Japan
    ["en"]=1 # USA
    ["fr"]=2 # Europe
    ["de"]=2 # Europe
    ["it"]=2 # Europe
    ["es"]=2 # Europe
    ["zh"]=4 # China
    ["ko"]=5 # Korea
    ["nl"]=2 # Europe
    ["pt"]=2 # Europe
    ["ru"]=2 # Europe?
    ["tw"]=6 # Taiwan
    )
fi

#cleanupOlderThings
Eden_cleanup() {
	echo "Begin Eden Cleanup"
}

#Install
Eden_install() {
	if [ "$(uname)" != "Linux" ]; then Eden_install_mac "$@"; return $?; fi
	setMSG "Begin Eden Install"
	# Linux install NYI upstream — placeholder
	echo "[eden] Linux install not yet implemented upstream."
}

Eden_install_mac(){
	# Eden mirror repo is unavailable (access blocked / DMCA). No macOS builds exist.
	mac_emu_skip "Eden" "Mirror repo not found — no active macOS builds available"
}

#ApplyInitialSettings
Eden_init() {
	if [ "$(uname)" != "Linux" ]; then Eden_init_mac; return $?; fi
	echo "Begin Eden Init"
	cp "$emudeckBackend/tools/launchers/eden.sh" "$toolsPath/launchers/eden.sh"
	chmod +x "$toolsPath/launchers/eden.sh"
	mkdir -p "$HOME/.config/eden"
	mkdir -p "$HOME/.local/share/eden"
	rsync -avhp "$emudeckBackend/configs/eden/config/." "$HOME/.config/eden"
	rsync -avhp "$emudeckBackend/configs/eden/data/." "$HOME/.local/share/eden"
	configEmuAI "$Eden_emuName" "config" "$HOME/.config/eden" "$emudeckBackend/configs/eden/config" "true"
	configEmuAI "$Eden_emuName" "data" "$HOME/.local/share/eden" "$emudeckBackend/configs/eden/data" "true"
	Eden_setEmulationFolder
	Eden_setupStorage
	Eden_setupSaves
	Eden_finalize
	Eden_addParser
	Eden_flushEmulatorLauncher
	createDesktopShortcut "$HOME/.local/share/applications/eden.desktop" \
						"Eden (AppImage)" \
						"${toolsPath}/launchers/eden.sh" \
						"False"
}

Eden_init_mac(){
	setMSG "Initializing Eden settings (macOS)."
	local cfgDir="${Eden_configPath_mac}"
	mkdir -p "$cfgDir"
	configEmuAI "$Eden_emuName" "config" "$cfgDir" "$emudeckBackend/configs/eden/config" "true"
	local cfgFile="${Eden_configFile_mac}"
	# Storage dirs
	mkdir -p "${storagePath}/eden/dump"
	mkdir -p "${storagePath}/eden/load"
	mkdir -p "${storagePath}/eden/sdmc"
	mkdir -p "${storagePath}/eden/nand"
	mkdir -p "${storagePath}/eden/screenshots"
	mkdir -p "${storagePath}/eden/tas"
	# BIOS/keys symlink
	mkdir -p "${biosPath}/eden"
	mkdir -p "$cfgDir/keys/"
	ln -sn "$cfgDir/keys/" "${biosPath}/eden/keys" 2>/dev/null || true
	# Config paths
	if [ -f "$cfgFile" ]; then
		sed -i "s|Paths\\\\screenshot_path=.*|Paths\\\\screenshot_path=${storagePath}/eden/screenshots|" "$cfgFile"
		sed -i "s|Paths\\\\gamedirs\\\\4\\\\path=.*|Paths\\\\gamedirs\\\\4\\\\path=${romsPath}/switch|" "$cfgFile"
		sed -i "s|dump_directory=.*|dump_directory=${storagePath}/eden/dump|" "$cfgFile"
		sed -i "s|load_directory=.*|load_directory=${storagePath}/eden/load|" "$cfgFile"
		sed -i "s|nand_directory=.*|nand_directory=${storagePath}/eden/nand|" "$cfgFile"
		sed -i "s|sdmc_directory=.*|sdmc_directory=${storagePath}/eden/sdmc|" "$cfgFile"
		sed -i "s|tas_directory=.*|tas_directory=${storagePath}/eden/tas|" "$cfgFile"
	fi
	mkdir -p "${savesPath}/eden/saves"
}

#update
Eden_update() {
	Eden_init
}

#ConfigurePaths
Eden_setEmulationFolder() {
	echo "Begin Eden Path Config"
	sed -i "s|Paths\\\\gamedirs\\\\4\\\\path=.*|Paths\\\\gamedirs\\\\4\\\\path=${romsPath}/switch|" "$Eden_configFile"
	sed -i "s|dump_directory=.*|dump_directory=${storagePath}/eden/dump|" "$Eden_configFile"
	sed -i "s|load_directory=.*|load_directory=${storagePath}/eden/load|" "$Eden_configFile"
	sed -i "s|nand_directory=.*|nand_directory=${storagePath}/eden/nand|" "$Eden_configFile"
	sed -i "s|sdmc_directory=.*|sdmc_directory=${storagePath}/eden/sdmc|" "$Eden_configFile"
	sed -i "s|tas_directory=.*|tas_directory=${storagePath}/eden/tas|" "$Eden_configFile"
	# BIOS symlinks
	unlink "${biosPath}/eden/keys" 2>/dev/null || true
	unlink "${biosPath}/eden/firmware" 2>/dev/null || true
	mkdir -p "$HOME/.local/share/eden/keys/"
	mkdir -p "${biosPath}/eden"
	ln -sn "$HOME/.local/share/eden/keys/" "${biosPath}/eden/keys"
	ln -sn "$HOME/.local/share/eden/nand/system/Contents/registered/" "${biosPath}/eden/firmware"
}

#SetLanguage
Eden_setLanguage(){
	local cfgFile="$Eden_configFile"
	[ "$(uname)" != "Linux" ] && cfgFile="$Eden_configFile_mac"
	setMSG "Setting Eden Language"
	local language=$(locale | grep LANG | cut -d= -f2 | cut -d_ -f1)
	if [[ -f "$cfgFile" ]]; then
		if [ ${Eden_languages[$language]+_} ]; then
			changeLine "language_index=" "language_index=${Eden_languages[$language]}" "$cfgFile"
			changeLine "language_index\\\\default=" "language_index\\\\default=false" "$cfgFile"
			changeLine "region_index=" "region_index=${Eden_regions[$language]}" "$cfgFile"
			changeLine "region_index\\\\default=" "region_index\\\\default=false" "$cfgFile"
		fi
	fi
}

#SetupSaves
Eden_setupSaves() {
	echo "Begin Eden save link"
	unlink "${savesPath}/eden/saves" 2>/dev/null || true
	linkToSaveFolder eden saves "${storagePath}/eden/nand/user/save/"
	linkToSaveFolder eden profiles "${storagePath}/eden/nand/system/save/8000000000000010/su/avators/"
}

#SetupStorage
Eden_setupStorage() {
	echo "Begin Eden storage config"
	mkdir -p "${storagePath}/eden/dump"
	mkdir -p "${storagePath}/eden/load"
	mkdir -p "${storagePath}/eden/sdmc"
	mkdir -p "${storagePath}/eden/nand"
	mkdir -p "${storagePath}/eden/screenshots"
	mkdir -p "${storagePath}/eden/tas"
}

#WipeSettings
Eden_wipe() {
	echo "Begin Eden delete config directories"
	if [ "$(uname)" != "Linux" ]; then
		rm -rf "${Eden_configPath_mac}"
		return
	fi
	rm -rf "$HOME/.config/eden"
	rm -rf "$HOME/.local/share/eden"
}

#Uninstall
Eden_uninstall() {
	if [ "$(uname)" != "Linux" ]; then
		mac_uninstall_app "eden.app"
		removeParser "nintendo_switch_eden.json"
		return
	fi
	echo "Begin Eden uninstall"
	removeParser "nintendo_switch_eden.json"
	rm -rf "$Eden_emuPath"
}

#setABXYstyle
Eden_setABXYstyle() {
	echo "NYI"
}

#WideScreenOn
Eden_wideScreenOn() {
	echo "NYI"
}

#WideScreenOff
Eden_wideScreenOff() {
	echo "NYI"
}

#BezelOn
Eden_bezelOn() {
	echo "NYI"
}

#BezelOff
Eden_bezelOff() {
	echo "NYI"
}

#finalExec - Extra stuff
Eden_finalize() {
	echo "Begin Eden finalize"
	Eden_cleanup
}

Eden_IsInstalled() {
	if [ "$(uname)" != "Linux" ]; then mac_app_installed "eden.app"; return; fi
	if [ -e "$Eden_emuPath" ]; then
		echo "true"
	else
		echo "false"
	fi
}

Eden_resetConfig() {
	Eden_init &>/dev/null && echo "true" || echo "false"
}

Eden_setResolution(){
	local cfgFile="$Eden_configFile"
	[ "$(uname)" != "Linux" ] && cfgFile="$Eden_configFile_mac"
	case $edenResolution in
		"720P") multiplier=2; docked="false";;
		"1080P") multiplier=2; docked="true";;
		"1440P") multiplier=3; docked="false";;
		"4K") multiplier=3; docked="true";;
		*) echo "Error"; return 1;;
	esac
	RetroArch_setConfigOverride "resolution_setup" $multiplier "$cfgFile"
	RetroArch_setConfigOverride "use_docked_mode" $docked "$cfgFile"
}

Eden_flushEmulatorLauncher(){
	flushEmulatorLaunchers "eden"
}

Eden_addParser(){
	addParser "nintendo_switch_eden.json"
}
