#!/bin/bash

CHD_toolName="EmuDeck Compression Tool"
CHD_toolType="script"
CHD_toolPath="${toolsPath}/chdconv/chddeck.sh"
CHD_Shortcutlocation="$HOME/Desktop/EmuDeckCHD.desktop"

CHD_install(){
    # macOS: chdman5 is a Linux binary. chdman is available via brew (chdman is bundled with mame-tools).
    if [ "$(uname)" != "Linux" ]; then
        echo "[EmuDeck] Skipping CHD Linux binary install on macOS."
        echo "[EmuDeck] To install chdman on macOS: brew install rom-tools"
        return 0
    fi

    rsync -avhp --mkpath "$emudeckBackend/tools/chdconv" "$toolsPath/"

    chmod +x "$CHD_toolPath"
    chmod +x "$toolsPath"/chdconv/chdman5
    
    #update the paths in the script
    sed -i "s|/run/media/mmcblk0p1/Emulation/roms|${romsPath}|g" "$CHD_toolPath"
    sed -i "s|/run/media/mmcblk0p1/Emulation/tools|${toolsPath}|g" "$CHD_toolPath"
    
    #createDesktopShortcut "$CHD_Shortcutlocation" "$CHD_toolName" "bash $CHD_toolPath" "True"
}

