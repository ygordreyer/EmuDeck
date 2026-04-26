#!/bin/bash

#variables
Citron_emuName="citron"
Citron_emuType="$emuDeckEmuTypeAppImage"
Citron_emuPath="$emusFolder/citron.AppImage"
Citron_configFile="$HOME/.config/citron/qt-config.ini"

# macOS-specific paths
Citron_configPath_mac="${HOME}/Library/Application Support/citron"
Citron_configFile_mac="${HOME}/Library/Application Support/citron/qt-config.ini"

# https://github.com/citron-emu/citron/blob/master/src/core/file_sys/control_metadata.cpp#L41-L60
declare -A Citron_languages
Citron_languages=(
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

declare -A Citron_regions
Citron_regions=(
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

#cleanupOlderThings
Citron_cleanup() {
	echo "Begin Citron Cleanup"
}

#Install
Citron_install() {
	if [ "$(uname)" != "Linux" ]; then Citron_install_mac "$@"; return $?; fi
	setMSG "Begin Citron Install"
	# Linux install NYI upstream — placeholder
	echo "[citron] Linux install not yet implemented upstream."
}

Citron_install_mac(){
	setMSG "Installing Citron (macOS)"
	local arch
	arch=$(mac_arch)
	local url
	if [ "$arch" = "arm64" ]; then
		url=$(mac_get_gh_release_url "citron-emu/citron" "citron-.*macos-arm64.*\.dmg" "citron-.*macos.*\.dmg")
	else
		url=$(mac_get_gh_release_url "citron-emu/citron" "citron-.*macos-x86_64.*\.dmg" "citron-.*macos.*\.dmg")
	fi
	if [ -z "$url" ]; then
		echo "[mac] ERROR: Could not find Citron macOS release."
		return 1
	fi
	mac_install_dmg "Citron" "$url" "Citron.app" || return 1
	mac_deploy_launcher "citron" "/Applications/Citron.app"
}

#ApplyInitialSettings
Citron_init() {
	if [ "$(uname)" != "Linux" ]; then Citron_init_mac; return $?; fi
	echo "Begin Citron Init"
	cp "$emudeckBackend/tools/launchers/citron.sh" "$toolsPath/launchers/citron.sh"
	chmod +x "$toolsPath/launchers/citron.sh"
	mkdir -p "$HOME/.config/citron"
	mkdir -p "$HOME/.local/share/citron"
	rsync -avhp "$emudeckBackend/configs/citron/config/." "$HOME/.config/citron"
	rsync -avhp "$emudeckBackend/configs/citron/data/." "$HOME/.local/share/citron"
	configEmuAI "$Citron_emuName" "config" "$HOME/.config/citron" "$emudeckBackend/configs/citron/config" "true"
	configEmuAI "$Citron_emuName" "data" "$HOME/.local/share/citron" "$emudeckBackend/configs/citron/data" "true"
	Citron_setEmulationFolder
	Citron_setupStorage
	Citron_setupSaves
	Citron_finalize
	Citron_addParser
	Citron_flushEmulatorLauncher
	createDesktopShortcut "$HOME/.local/share/applications/citron.desktop" \
						"Citron (AppImage)" \
						"${toolsPath}/launchers/citron.sh" \
						"False"
	if [ -e "$ESDE_toolPath" ] || [ -f "${toolsPath}/$ESDE_downloadedToolName" ] || [ -f "${toolsPath}/$ESDE_oldtoolName.AppImage" ]; then
		Citron_addESConfig
	fi
}

Citron_init_mac(){
	setMSG "Initializing Citron settings (macOS)."
	local cfgDir="${Citron_configPath_mac}"
	mkdir -p "$cfgDir"
	configEmuAI "$Citron_emuName" "config" "$cfgDir" "$emudeckBackend/configs/citron/config" "true"
	local cfgFile="${Citron_configFile_mac}"
	# Storage dirs
	mkdir -p "${storagePath}/citron/dump"
	mkdir -p "${storagePath}/citron/load"
	mkdir -p "${storagePath}/citron/sdmc"
	mkdir -p "${storagePath}/citron/nand"
	mkdir -p "${storagePath}/citron/screenshots"
	mkdir -p "${storagePath}/citron/tas"
	# BIOS/keys symlink
	mkdir -p "${biosPath}/citron"
	mkdir -p "$cfgDir/keys/"
	ln -sn "$cfgDir/keys/" "${biosPath}/citron/keys" 2>/dev/null || true
	# Config paths
	if [ -f "$cfgFile" ]; then
		sed -i "s|Paths\\\\screenshot_path=.*|Paths\\\\screenshot_path=${storagePath}/citron/screenshots|" "$cfgFile"
		sed -i "s|Paths\\\\gamedirs\\\\4\\\\path=.*|Paths\\\\gamedirs\\\\4\\\\path=${romsPath}/switch|" "$cfgFile"
		sed -i "s|dump_directory=.*|dump_directory=${storagePath}/citron/dump|" "$cfgFile"
		sed -i "s|load_directory=.*|load_directory=${storagePath}/citron/load|" "$cfgFile"
		sed -i "s|nand_directory=.*|nand_directory=${storagePath}/citron/nand|" "$cfgFile"
		sed -i "s|sdmc_directory=.*|sdmc_directory=${storagePath}/citron/sdmc|" "$cfgFile"
		sed -i "s|tas_directory=.*|tas_directory=${storagePath}/citron/tas|" "$cfgFile"
	fi
	# Saves
	mkdir -p "${savesPath}/citron/saves"
}

#update
Citron_update() {
	Citron_init
}

#ConfigurePaths
Citron_setEmulationFolder() {
	echo "Begin Citron Path Config"
	sed -i "/${screenshotDirOpt}/c\\${newScreenshotDirOpt}" "$Citron_configFile" 2>/dev/null || true
	sed -i "s|Paths\\\\gamedirs\\\\4\\\\path=.*|Paths\\\\gamedirs\\\\4\\\\path=${romsPath}/switch|" "$Citron_configFile"
	sed -i "s|dump_directory=.*|dump_directory=${storagePath}/citron/dump|" "$Citron_configFile"
	sed -i "s|load_directory=.*|load_directory=${storagePath}/citron/load|" "$Citron_configFile"
	sed -i "s|nand_directory=.*|nand_directory=${storagePath}/citron/nand|" "$Citron_configFile"
	sed -i "s|sdmc_directory=.*|sdmc_directory=${storagePath}/citron/sdmc|" "$Citron_configFile"
	sed -i "s|tas_directory=.*|tas_directory=${storagePath}/citron/tas|" "$Citron_configFile"
	# BIOS symlinks
	unlink "${biosPath}/citron/keys" 2>/dev/null || true
	unlink "${biosPath}/citron/firmware" 2>/dev/null || true
	mkdir -p "$HOME/.local/share/citron/keys/"
	mkdir -p "${biosPath}/citron"
	ln -sn "$HOME/.local/share/citron/keys/" "${biosPath}/citron/keys"
	ln -sn "$HOME/.local/share/citron/nand/system/Contents/registered/" "${biosPath}/citron/firmware"
}

#SetLanguage
Citron_setLanguage(){
	local cfgFile="$Citron_configFile"
	[ "$(uname)" != "Linux" ] && cfgFile="$Citron_configFile_mac"
	setMSG "Setting Citron Language"
	local language=$(locale | grep LANG | cut -d= -f2 | cut -d_ -f1)
	if [[ -f "$cfgFile" ]]; then
		if [ ${Citron_languages[$language]+_} ]; then
			changeLine "language_index=" "language_index=${Citron_languages[$language]}" "$cfgFile"
			changeLine "language_index\\\\default=" "language_index\\\\default=false" "$cfgFile"
			changeLine "region_index=" "region_index=${Citron_regions[$language]}" "$cfgFile"
			changeLine "region_index\\\\default=" "region_index\\\\default=false" "$cfgFile"
		fi
	fi
}

#SetupSaves
Citron_setupSaves() {
	echo "Begin Citron save link"
	unlink "${savesPath}/citron/saves" 2>/dev/null || true
	linkToSaveFolder citron saves "${storagePath}/citron/nand/user/save/"
	linkToSaveFolder citron profiles "${storagePath}/citron/nand/system/save/8000000000000010/su/avators/"
}

#SetupStorage
Citron_setupStorage() {
	echo "Begin Citron storage config"
	mkdir -p "${storagePath}/citron/dump"
	mkdir -p "${storagePath}/citron/load"
	mkdir -p "${storagePath}/citron/sdmc"
	mkdir -p "${storagePath}/citron/nand"
	mkdir -p "${storagePath}/citron/screenshots"
	mkdir -p "${storagePath}/citron/tas"
}

#WipeSettings
Citron_wipe() {
	echo "Begin Citron delete config directories"
	if [ "$(uname)" != "Linux" ]; then
		rm -rf "${Citron_configPath_mac}"
		return
	fi
	rm -rf "$HOME/.config/citron"
	rm -rf "$HOME/.local/share/citron"
}

#Uninstall
Citron_uninstall() {
	if [ "$(uname)" != "Linux" ]; then
		mac_uninstall_app "Citron.app"
		removeParser "nintendo_switch_citron.json"
		return
	fi
	echo "Begin Citron uninstall"
	removeParser "nintendo_switch_citron.json"
	rm -rf "$Citron_emuPath"
}

#setABXYstyle
Citron_setABXYstyle() {
	echo "NYI"
}

#WideScreenOn
Citron_wideScreenOn() {
	echo "NYI"
}

#WideScreenOff
Citron_wideScreenOff() {
	echo "NYI"
}

#BezelOn
Citron_bezelOn() {
	echo "NYI"
}

#BezelOff
Citron_bezelOff() {
	echo "NYI"
}

#finalExec - Extra stuff
Citron_finalize() {
	echo "Begin Citron finalize"
	Citron_cleanup
}

Citron_IsInstalled() {
	if [ "$(uname)" != "Linux" ]; then mac_app_installed "Citron.app"; return; fi
	if [ -e "$Citron_emuPath" ]; then
		echo "true"
	else
		echo "false"
	fi
}

Citron_resetConfig() {
	Citron_init &>/dev/null && echo "true" || echo "false"
}

Citron_setResolution(){
	local cfgFile="$Citron_configFile"
	[ "$(uname)" != "Linux" ] && cfgFile="$Citron_configFile_mac"
	case $citronResolution in
		"720P") multiplier=2; docked="false";;
		"1080P") multiplier=2; docked="true";;
		"1440P") multiplier=3; docked="false";;
		"4K") multiplier=3; docked="true";;
		*) echo "Error"; return 1;;
	esac
	RetroArch_setConfigOverride "resolution_setup" $multiplier "$cfgFile"
	RetroArch_setConfigOverride "use_docked_mode" $docked "$cfgFile"
}

Citron_flushEmulatorLauncher(){
	flushEmulatorLaunchers "citron"
}

Citron_addESConfig(){
	[ "$(uname)" != "Linux" ] && return
	ESDE_junksettingsFile
	ESDE_addCustomSystemsFile
	ESDE_setEmulationFolder
	if [[ $(grep -rnw "$es_systemsFile" -e 'switch') == "" ]]; then
		xmlstarlet ed -S --inplace --subnode '/systemList' --type elem --name 'system' \
		--var newSystem '$prev' \
		--subnode '$newSystem' --type elem --name 'name' -v 'switch' \
		--subnode '$newSystem' --type elem --name 'fullname' -v 'Nintendo Switch' \
		--subnode '$newSystem' --type elem --name 'path' -v '%ROMPATH%/switch' \
		--subnode '$newSystem' --type elem --name 'extension' -v '.nca .NCA .nro .NRO .nso .NSO .nsp .NSP .xci .XCI' \
		--subnode '$newSystem' --type elem --name 'commandV' -v "%INJECT%=%BASENAME%.esprefix %EMULATOR_CITRON% -f -g %ROM%" \
		--insert '$newSystem/commandV' --type attr --name 'label' --value "Citron (Standalone)" \
		--subnode '$newSystem' --type elem --name 'platform' -v 'switch' \
		--subnode '$newSystem' --type elem --name 'theme' -v 'switch' \
		-r 'systemList/system/commandV' -v 'command' \
		"$es_systemsFile"
		xmlstarlet fo "$es_systemsFile" > "$es_systemsFile".tmp && mv "$es_systemsFile".tmp "$es_systemsFile"
	fi
	ESDE_refreshCustomEmus
}

Citron_addParser(){
	addParser "nintendo_switch_citron.json"
}
