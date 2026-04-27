#!/bin/bash
#variables
Azahar_emuName="Azahar"
Azahar_emuType="$emuDeckEmuTypeAppImage"
Azahar_emuPath="$emusFolder/azahar.AppImage"
Azahar_releaseURL=""
Azahar_configFile="$HOME/.config/azahar-emu/qt-config.ini"
Azahar_configPath="$HOME/.config/azahar-emu"
Azahar_texturesPath="$HOME/.config/azahar-emu/load/textures"

# macOS-specific paths
Azahar_configPath_mac="${HOME}/Library/Application Support/azahar"
Azahar_configFile_mac="${HOME}/Library/Application Support/azahar/qt-config.ini"

#Install
Azahar_install(){
	if [ "$(uname)" != "Linux" ]; then Azahar_install_mac "$@"; return $?; fi
	echo "Begin $Azahar_emuName Install"
	local showProgress="$1"
	local url=$(getReleaseURLGH "azahar-emu/azahar" "AppImage" "")
	if installEmuAI "$Azahar_emuName" "" "$url" "azahar" "AppImage" "emulator" "$showProgress"; then
		mv "$emusFolder/azahar.AppImage" "$Azahar_emuPath"
		chmod +x "$Azahar_emuPath"
	else
		return 1
	fi
}

Azahar_install_mac(){
	setMSG "Installing Azahar (macOS)"
	# Azahar releases ZIP bundles (not DMG). Asset names as of 2125.x:
	#   azahar-macos-arm64-<ver>.zip   (native Apple Silicon)
	#   azahar-macos-universal-<ver>.zip (fallback universal)
	#   azahar-macos-x86_64-<ver>.zip  (Intel/Rosetta)
	# NOTE: avoid azahar-libretro-macos-* — that's the RetroArch core, not standalone.
	local arch
	arch=$(mac_arch)
	local url
	if [ "$arch" = "arm64" ]; then
		url=$(mac_get_gh_release_url "azahar-emu/azahar" "azahar-macos-arm64-.*\.zip" "azahar-macos-universal-.*\.zip")
	else
		url=$(mac_get_gh_release_url "azahar-emu/azahar" "azahar-macos-x86_64-.*\.zip" "azahar-macos-universal-.*\.zip")
	fi
	if [ -z "$url" ]; then
		echo "[mac] ERROR: Could not find Azahar macOS release."
		return 1
	fi
	mac_install_zip "Azahar" "$url" "Azahar.app" || return 1
	mac_deploy_launcher "Azahar" "/Applications/Azahar.app"
}

#ApplyInitialSettings
Azahar_init(){
	if [ "$(uname)" != "Linux" ]; then Azahar_init_mac; return $?; fi
	setMSG "Initializing $Azahar_emuName settings."
	configEmuAI "$Azahar_emuName" "azahar-emu"  "$Azahar_configPath" "$emudeckBackend/configs/azahar" "true"
	Azahar_setEmulationFolder
	Azahar_setupStorage
	Azahar_setupSaves
	Azahar_addSteamInputProfile
	Azahar_flushEmulatorLauncher
	Azahar_setupTextures
	Azahar_addParser
	Azahar_migrate
	#ESDE
	ESDE_refreshCustomEmus
	Azahar_addESConfig
	ESDE_setEmu 'Azahar (Standalone)' n3ds
}

Azahar_init_mac(){
	setMSG "Initializing Azahar settings (macOS)."
	local cfgDir="${Azahar_configPath_mac}"
	mkdir -p "$cfgDir"
	configEmuAI "$Azahar_emuName" "azahar" "$cfgDir" "$emudeckBackend/configs/azahar" "true"
	local cfgFile="${Azahar_configFile_mac}"
	# Setup storage
	mkdir -p "$storagePath/azahar/sdmc"
	mkdir -p "$storagePath/azahar/nand"
	mkdir -p "$storagePath/azahar/screenshots"
	# Setup saves
	mkdir -p "${savesPath}/azahar/saves"
	mkdir -p "${savesPath}/azahar/states"
	# BIOS/keys symlink
	mkdir -p "${biosPath}/azahar/"
	mkdir -p "$cfgDir/sysdata"
	ln -sn "$cfgDir/sysdata" "${biosPath}/azahar/keys" 2>/dev/null || true
	# Set paths in config
	if [ -f "$cfgFile" ]; then
		sed -i "s|Paths\\\\gamedirs\\\\3\\\\path=.*|Paths\\\\gamedirs\\\\3\\\\path=${romsPath}/n3ds|" "$cfgFile"
		sed -i "s|nand_directory=.*|nand_directory=${storagePath}/azahar/nand/|" "$cfgFile"
		sed -i "s|sdmc_directory=.*|sdmc_directory=${storagePath}/azahar/sdmc/|" "$cfgFile"
		sed -i "s|Paths\\\\screenshotPath=.*|Paths\\\\screenshotPath=${storagePath}/azahar/screenshots/|" "$cfgFile"
		sed -i 's/nand_directory\\default=true/nand_directory\\default=false/' "$cfgFile"
		sed -i 's/sdmc_directory\\default=true/sdmc_directory\\default=false/' "$cfgFile"
		sed -i 's/use_custom_storage=false/use_custom_storage=true/' "$cfgFile"
	fi
	# Save link
	mac_link_save "azahar" "azahar/sdmc" "$storagePath/azahar/sdmc"
}

#update
Azahar_update(){
	if [ "$(uname)" != "Linux" ]; then Azahar_init_mac; return $?; fi
	setMSG "Updating $Azahar_emuName settings."
	configEmuAI "$Azahar_emuName" "azahar-emu"  "$Azahar_configPath" "$emudeckBackend/configs/azahar"
	Azahar_setupStorage
	Azahar_setEmulationFolder
	Azahar_setupSaves
	Azahar_addSteamInputProfile
	Azahar_flushEmulatorLauncher
	Azahar_setupTextures
}

Azahar_setupStorage(){
	mkdir -p "$storagePath/azahar/"
	# Migrate from Citra sdmc if Azahar sdmc doesn't exist
	if [ ! -d "$storagePath/azahar/sdmc" ] && [ ! -d "$HOME/.var/app/io.github.azahar.Azahar/data/azahar-emu/sdmc" -o ! -d "$HOME/.local/share/azahar-emu" ] && [ -d "$HOME/.var/app/org.citra_emu.citra/data/citra-emu/sdmc" -o -d "$HOME/.local/share/citra-emu/sdmc" -o -d "$storagePath/citra/sdmc" ]; then
		setMSG "Copying Citra SDMC to the Azahar SDMC folder"
		mkdir -p "$storagePath/azahar"
		if [ -d "$storagePath/citra/sdmc" ]; then
			rsync -av --ignore-existing "$storagePath/citra/sdmc" "$storagePath"/azahar
		elif [ -d "$HOME/.var/app/org.citra_emu.citra/data/citra-emu/sdmc" ]; then
			rsync -av --ignore-existing "$HOME/.var/app/org.citra_emu.citra/data/citra-emu/sdmc" "$storagePath"/azahar
		elif [ -d "$HOME/.local/share/citra-emu/sdmc" ]; then
			rsync -av --ignore-existing "$HOME/.local/share/citra-emu/sdmc" "$storagePath"/azahar
		else
			mkdir -p "$storagePath/citra/sdmc"
		fi
	fi
	if [ ! -d "$storagePath/azahar/sdmc" ] && [ -d "$HOME/.var/app/io.github.azahar.Azahar/data/azahar-emu/sdmc" -o -d "$HOME/.local/share/azahar-emu/sdmc" ]; then
		setMSG "Copying Azahar SDMC to the Emulation/storage folder"
		mkdir -p "$storagePath/azahar"
		if [ -d "$HOME/.var/app/io.github.azahar.Azahar/data/azahar-emu/sdmc" ]; then
			rsync -av --ignore-existing "$HOME/.var/app/io.github.azahar.Azahar/data/azahar-emu/sdmc" "$storagePath"/azahar/ && rm -rf "$HOME/.var/app/io.github.azahar.Azahar/data/azahar-emu/sdmc"
		elif [ -d "$HOME/.local/share/azahar-emu/sdmc" ]; then
			rsync -av --ignore-existing "$HOME/.local/share/azahar-emu/sdmc" "$storagePath"/azahar/ && rm -rf "$HOME/.local/share/azahar-emu/sdmc"
		else
			mkdir -p "$storagePath/azahar/sdmc"
		fi
	else
		mkdir -p "$storagePath/azahar/sdmc"
	fi
	mkdir -p "$storagePath/azahar/nand"
	# Cheats and Texture Packs
	mkdir -p "$HOME/.local/share/azahar-emu/cheats"
	linkToStorageFolder azahar cheats "$HOME/.local/share/azahar-emu/cheats"
	mkdir -p "$HOME/.local/share/azahar-emu/load/textures"
	linkToStorageFolder azahar textures "$HOME/.local/share/azahar-emu/load/textures"
}

#ConfigurePaths
Azahar_setEmulationFolder(){
	setMSG "Setting $Azahar_emuName Emulation Folder"
	mkdir -p "$Azahar_configPath"
	sed -i "s|Paths\\\\gamedirs\\\\3\\\\path=.*|Paths\\\\gamedirs\\\\3\\\\path=${romsPath}/n3ds|" "$Azahar_configFile"
	sed -i "s|nand_directory=.*|nand_directory=${storagePath}/azahar/nand/|" "$Azahar_configFile"
	sed -i "s|sdmc_directory=.*|sdmc_directory=${storagePath}/azahar/sdmc/|" "$Azahar_configFile"
	mkdir -p "$storagePath/azahar/screenshots/"
	sed -i "s|Paths\\\\screenshotPath=.*|Paths\\\\screenshotPath=${storagePath}/azahar/screenshots/|" "$Azahar_configFile"
	sed -i 's/nand_directory\\default=true/nand_directory\\default=false/' "$Azahar_configFile"
	sed -i 's/sdmc_directory\\default=true/sdmc_directory\\default=false/' "$Azahar_configFile"
	sed -i 's/use_custom_storage=false/use_custom_storage=true/' "$Azahar_configFile"
	sed -i 's/use_custom_storage\\default=true/use_custom_storage\\default=false/' "$Azahar_configFile"
	# BIOS/keys symlink
	mkdir -p "${biosPath}/azahar/"
	mkdir -p "$HOME/.local/share/azahar-emu/sysdata"
	ln -sn "$HOME/.local/share/azahar-emu/sysdata" "${biosPath}/azahar/keys"
}

#SetupSaves
Azahar_setupSaves(){
	mkdir -p "$HOME/.local/share/azahar-emu/states"
	linkToSaveFolder azahar saves "$storagePath/azahar/sdmc"
	linkToSaveFolder azahar states "$HOME/.local/share/azahar-emu/states"
}

#Set up textures
Azahar_setupTextures(){
	mkdir -p "$HOME/.local/share/azahar-emu/load/textures"
	linkToTexturesFolder azahar textures "$HOME/.local/share/azahar-emu/load/textures"
}

#WipeSettings
Azahar_wipe(){
	setMSG "Wiping $Azahar_emuName config directory. (factory reset)"
	if [ "$(uname)" != "Linux" ]; then
		rm -rf "${Azahar_configPath_mac}"
		return
	fi
	rm -rf "$HOME/.config/azahar-emu"
}

#Uninstall
Azahar_uninstall(){
	if [ "$(uname)" != "Linux" ]; then
		mac_uninstall_app "Azahar.app"
		removeParser "nintendo_3ds_azahar.json"
		return
	fi
	setMSG "Uninstalling $Azahar_emuName."
	removeParser "nintendo_3ds_azahar.json"
	uninstallEmuAI $Azahar_emuName "azahar-gui" "" "emulator"
}

#setABXYstyle
Azahar_setABXYstyle(){
	local cfgFile="$Azahar_configFile"
	[ "$(uname)" != "Linux" ] && cfgFile="$Azahar_configFile_mac"
	sed -i '/button_a/s/button:1/button:0/' "$cfgFile"
	sed -i '/button_b/s/button:0/button:1/' "$cfgFile"
	sed -i '/button_x/s/button:3/button:2/' "$cfgFile"
	sed -i '/button_y/s/button:2/button:3/' "$cfgFile"
}

Azahar_setBAYXstyle(){
	local cfgFile="$Azahar_configFile"
	[ "$(uname)" != "Linux" ] && cfgFile="$Azahar_configFile_mac"
	sed -i '/button_a/s/button:0/button:1/' "$cfgFile"
	sed -i '/button_b/s/button:1/button:0/' "$cfgFile"
	sed -i '/button_x/s/button:2/button:3/' "$cfgFile"
	sed -i '/button_y/s/button:3/button:2/' "$cfgFile"
}

#finalExec - Extra stuff
Azahar_finalize(){
	echo "NYI"
}

Azahar_IsInstalled(){
	if [ "$(uname)" != "Linux" ]; then mac_app_installed "Azahar.app"; return; fi
	if [ -e "$Azahar_emuPath" ]; then
		echo "true"
	else
		echo "false"
	fi
}

Azahar_resetConfig(){
	Azahar_init &>/dev/null && echo "true" || echo "false"
}

Azahar_addSteamInputProfile(){
	addSteamInputCustomIcons
	setMSG "Adding $Azahar_emuName Steam Input Profile."
	rsync -r --exclude='*/' "$emudeckBackend/configs/steam-input/" "$HOME/.steam/steam/controller_base/templates/"
}

Azahar_setResolution(){
	local cfgFile="$Azahar_configFile"
	[ "$(uname)" != "Linux" ] && cfgFile="$Azahar_configFile_mac"
	case $azaharResolution in
		"720P") multiplier=3;;
		"1080P") multiplier=5;;
		"1440P") multiplier=6;;
		"4K") multiplier=9;;
		*) echo "Error"; return 1;;
	esac
	setConfig "resolution_factor" $multiplier "$cfgFile"
}

Azahar_flushEmulatorLauncher(){
	flushEmulatorLaunchers "Azahar"
}

Azahar_addParser(){
	addParser "nintendo_3ds_azahar.json"
}

Azahar_migrate(){
	rm -rf "$toolsPath/launchers/citra.sh"
	rm -rf "$toolsPath/launchers/lime3ds.sh"
	ln -sf "$toolsPath/launchers/azahar.sh" "$toolsPath/launchers/lime3ds.sh"
	ln -sf "$toolsPath/launchers/azahar.sh" "$toolsPath/launchers/citra.sh"
}

Azahar_addESConfig(){
	[ "$(uname)" != "Linux" ] && return
	ESDE_junksettingsFile
	ESDE_addCustomSystemsFile
	ESDE_setEmulationFolder
	if [[ $(grep -rnw "$es_systemsFile" -e 'azahar') == "" ]]; then
		xmlstarlet ed -S --inplace --subnode '/systemList' --type elem --name 'system' \
		--var newSystem '$prev' \
		--subnode '$newSystem' --type elem --name 'name' -v 'n3ds' \
		--subnode '$newSystem' --type elem --name 'fullname' -v 'Nintendo 3DS' \
		--subnode '$newSystem' --type elem --name 'path' -v '%ROMPATH%/n3ds' \
		--subnode '$newSystem' --type elem --name 'extension' -v '.3ds .3DS .3dsx .3DSX .app .APP .axf .AXF .cci .CCI .cxi .CXI .elf .ELF .7z .7Z .zip .ZIP' \
		--subnode '$newSystem' --type elem --name 'commandP' -v "/usr/bin/bash ${toolsPath}/launchers/azahar.sh %ROM%" \
		--insert '$newSystem/commandP' --type attr --name 'label' --value "Azahar (Standalone)" \
		--subnode '$newSystem' --type elem --name 'platform' -v 'n3ds' \
		--subnode '$newSystem' --type elem --name 'theme' -v 'n3ds' \
		-r 'systemList/system/commandP' -v 'command' \
		"$es_systemsFile"
		xmlstarlet fo "$es_systemsFile" > "$es_systemsFile".tmp && mv "$es_systemsFile".tmp "$es_systemsFile"
		echo "Azahar added to EmulationStation-DE custom_systems"
	fi
}
