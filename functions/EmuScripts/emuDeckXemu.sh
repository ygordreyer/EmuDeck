#!/bin/bash
#variables
Xemu_emuName="Xemu-Emu"
Xemu_emuType="$emuDeckEmuTypeFlatpak"
Xemu_emuPath="app.xemu.xemu"

# macOS-specific paths
Xemu_configPath_mac="${HOME}/Library/Application Support/xemu"
Xemu_configFile_mac="${HOME}/Library/Application Support/xemu/xemu.toml"

# https://xboxdevwiki.net/EEPROM
# Guard: declare -A requires bash 4+ (macOS ships bash 3.2)
if [ "${BASH_VERSINFO[0]:-0}" -ge 4 ]; then
    declare -A Xemu_languages
    Xemu_languages=(
    ["en"]=1
    ["ja"]=2
    ["de"]=3
    ["fr"]=4
    ["es"]=5
    ["it"]=6
    ["ko"]=7
    ["zh"]=8
    ["pt"]=9)
fi

#cleanupOlderThings
Xemu_cleanup(){
	echo "NYI"
}

#Install
Xemu_install() {
	if [ "$(uname)" != "Linux" ]; then Xemu_install_mac "$@"; return $?; fi
	installEmuFP "${Xemu_emuName}" "${Xemu_emuPath}" "emulator" ""
}

Xemu_install_mac(){
	mac_install_cask "Xemu" "xemu" "xemu.app" || return 1
	mac_deploy_launcher "xemu-emu" "/Applications/xemu.app"
}

#ApplyInitialSettings
Xemu_init() {
	if [ "$(uname)" != "Linux" ]; then Xemu_init_mac; return $?; fi
	configEmuFP "${Xemu_emuName}" "${Xemu_emuPath}" "true"
	updateEmuFP "${Xemu_emuName}" "${Xemu_emuPath}" "emulator" ""
	Xemu_migrate
	Xemu_setupStorage
	Xemu_setEmulationFolder
	Xemu_setCustomizations
	#SRM_createParsers
	Xemu_flushEmulatorLauncher
	Xemu_setLanguage
}

Xemu_init_mac(){
	setMSG "Initializing $Xemu_emuName settings (macOS)."
	local cfgDir="${Xemu_configPath_mac}"
	mkdir -p "$cfgDir"
	configEmuAI "$Xemu_emuName" "config" "$cfgDir" "$emudeckBackend/configs/app.xemu.xemu" "true"
	# Setup storage
	mkdir -p "${storagePath}/xemu"
	# Download HDD image if missing
	if [ ! -f "${storagePath}/xemu/xbox_hdd.qcow2" ]; then
		cd "${storagePath}/xemu"
		curl -L https://github.com/mborgerson/xemu-hdd-image/releases/latest/download/xbox_hdd.qcow2.zip -o xbox_hdd.qcow2.zip && unzip -j xbox_hdd.qcow2.zip && rm -f xbox_hdd.qcow2.zip
	fi
	# Set paths in config
	local cfgFile="${Xemu_configFile_mac}"
	if [ -f "$cfgFile" ]; then
		changeLine "bootrom_path = " "bootrom_path = '${biosPath}/mcpx_1.0.bin'" "$cfgFile"
		changeLine "flashrom_path = " "flashrom_path = '${biosPath}/Complex_4627v1.03.bin'" "$cfgFile"
		changeLine "eeprom_path = " "eeprom_path = '${storagePath}/xemu/eeprom.bin'" "$cfgFile"
		changeLine "hdd_path = " "hdd_path = '${storagePath}/xemu/xbox_hdd.qcow2'" "$cfgFile"
	fi
}

#update
Xemu_update() {
	if [ "$(uname)" != "Linux" ]; then Xemu_init_mac; return $?; fi
	configEmuFP "${Xemu_emuName}" "${Xemu_emuPath}"
	Xemu_migrate
	Xemu_setupStorage
	Xemu_setEmulationFolder
	Xemu_setupSaves
	Xemu_flushEmulatorLauncher
}

#ConfigurePaths
Xemu_setEmulationFolder(){
	local configFile="$HOME/.var/app/app.xemu.xemu/data/xemu/xemu/xemu.toml"
	changeLine "bootrom_path = " "bootrom_path = '${biosPath}/mcpx_1.0.bin'" "$configFile"
	changeLine "flashrom_path = " "flashrom_path = '${biosPath}/Complex_4627v1.03.bin'" "$configFile"
	changeLine "eeprom_path = " "eeprom_path = '${storagePath}/xemu/eeprom.bin'" "$configFile"
	changeLine "hdd_path = " "hdd_path = '${storagePath}/xemu/xbox_hdd.qcow2'" "$configFile"
}

#SetLanguage
Xemu_setLanguage(){
	if [ "$(uname)" != "Linux" ]; then
		setMSG "Setting Xemu Language"
		local language=$(locale | grep LANG | cut -d= -f2 | cut -d_ -f1)
		local eepromPath="${storagePath}/xemu/eeprom.bin"
		if [[ -f "${eepromPath}" ]]; then
			if [ ${Xemu_languages[$language]+_} ]; then
				printf "%02x" "${Xemu_languages[$language]}" | xxd -r -p - | dd of="$eepromPath" obs=1 seek=$((16#90)) conv=block,notrunc
			fi
		fi
		return
	fi
	setMSG "Setting Xemu Language"
	local language=$(locale | grep LANG | cut -d= -f2 | cut -d_ -f1)
	local eepromPath="${storagePath}/xemu/eeprom.bin"
	if [[ -f "${eepromPath}" ]]; then
		if [ ${Xemu_languages[$language]+_} ]; then
			printf "%02x" "${Xemu_languages[$language]}" | xxd -r -p - | dd of="$eepromPath" obs=1 seek=$((16#90)) conv=block,notrunc
		fi
	fi
}

#SetupSaves
Xemu_setupSaves(){
	mkdir -p "$savesPath/xemu/"
	ln -s "${storagePath}/xemu" "$savesPath/xemu/saves"
}

#SetupStorage
Xemu_setupStorage(){
	mkdir -p "${storagePath}/xemu"
	if [ "$(uname)" = "Linux" ]; then
		flatpak override app.xemu.xemu --filesystem="${storagePath}/xemu":rw --user
	fi
	if [[ ! -f "${storagePath}/xemu/xbox_hdd.qcow2" ]]; then
		cd "${storagePath}/xemu"
		curl -L https://github.com/mborgerson/xemu-hdd-image/releases/latest/download/xbox_hdd.qcow2.zip -o xbox_hdd.qcow2.zip && unzip -j xbox_hdd.qcow2.zip && rm -rf xbox_hdd.qcow2.zip
	fi
}

#WipeSettings
Xemu_wipe() {
	if [ "$(uname)" != "Linux" ]; then
		rm -rf "${Xemu_configPath_mac}"
		return
	fi
	rm -rf "$HOME/.var/app/$Xemu_emuPath"
}

#Uninstall
Xemu_uninstall() {
	if [ "$(uname)" != "Linux" ]; then mac_uninstall_cask "Xemu" "xemu" "xemu.app"; return; fi
	uninstallEmuFP "${Xemu_emuName}" "${Xemu_emuPath}" "emulator" ""
}

#setABXYstyle
Xemu_setABXYstyle(){
	echo "NYI"
}

#Migrate
Xemu_migrate(){
	if [ "$(uname)" != "Linux" ]; then echo "NYI on macOS"; return; fi
	if [ ! -f "${storagePath}/xemu/xbox_hdd.qcow2" ] && [ -d "$HOME/.var/app/app.xemu.xemu" ]; then
		echo "xbox hdd does not exist in storagepath."
		setMSG "Moving Xemu HDD and EEPROM to the Emulation/storage folder"
		if [ -f "${savesPath}/xemu/xbox_hdd.qcow2" ]; then
			mv -fv ${savesPath}/xemu/* ${storagePath}/xemu/ && rm -rf ${savesPath}/xemu/
		elif [ -f "$HOME/.var/app/app.xemu.xemu/data/xemu/xemu/xbox_hdd.qcow2" ]; then
			mv "$HOME/.var/app/app.xemu.xemu/data/xemu/xemu/xbox_hdd.qcow2" $storagePath/xemu/
			mv "$HOME/.var/app/app.xemu.xemu/data/xemu/xemu/eeprom.bin" $storagePath/xemu/
		fi
	fi
}

#WideScreenOn
Xemu_wideScreenOn(){
	local cfgFile
	if [ "$(uname)" != "Linux" ]; then
		cfgFile="${Xemu_configFile_mac}"
	else
		cfgFile="$HOME/.var/app/app.xemu.xemu/data/xemu/xemu/xemu.toml"
	fi
	changeLine "fit = " "fit = 'scale_16_9'" "$cfgFile"
}

#WideScreenOff
Xemu_wideScreenOff(){
	local cfgFile
	if [ "$(uname)" != "Linux" ]; then
		cfgFile="${Xemu_configFile_mac}"
	else
		cfgFile="$HOME/.var/app/app.xemu.xemu/data/xemu/xemu/xemu.toml"
	fi
	changeLine "fit = " "fit = 'scale_4_3'" "$cfgFile"
}

#BezelOn
Xemu_bezelOn(){
	echo "NYI"
}

#BezelOff
Xemu_bezelOff(){
	echo "NYI"
}

#finalExec - Extra stuff
Xemu_finalize(){
	echo "NYI"
}

Xemu_IsInstalled(){
	if [ "$(uname)" != "Linux" ]; then mac_app_installed "xemu.app"; return; fi
	isFpInstalled "$Xemu_emuPath"
}

Xemu_resetConfig(){
	Xemu_init &>/dev/null && echo "true" || echo "false"
}

Xemu_setCustomizations(){
	if [ "$arClassic3D" == 169 ]; then
		Xemu_wideScreenOn
	else
		Xemu_wideScreenOff
	fi
}

Xemu_setResolution(){
	echo "NYI"
}

Xemu_flushEmulatorLauncher(){
	flushEmulatorLaunchers "xemu-emu"
}
