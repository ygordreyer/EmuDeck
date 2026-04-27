#!/bin/bash

FlatpakUP_toolName="EmuDeck Flatpak Updater"
FlatpakUP_toolType="script"
FlatpakUP_toolPath="${toolsPath}/flatpakupdate/flatpakupdate.sh"



FlatpakUp_install(){
	# macOS: Flatpak is Linux-only.
	if [ "$(uname)" != "Linux" ]; then echo "[EmuDeck] Skipping FlatpakUP — Flatpak is Linux-only."; return 0; fi

	rsync -avhp --mkpath "$emudeckBackend/tools/flatpakupdate" "$toolsPath/"

	chmod +x "$FlatpakUP_toolPath"
	#update the paths in the script
	sed -i "s|/run/media/mmcblk0p1/Emulation/roms|${romsPath}|g" "$FlatpakUP_toolPath"
	sed -i "s|/run/media/mmcblk0p1/Emulation/tools|${toolsPath}|g" "$FlatpakUP_toolPath"

	#createDesktopShortcut "$FlatpakUP_Shortcutlocation" "$FlatpakUP_toolName" "bash $FlatpakUP_toolPath"  "True"
}
