#!/bin/bash
# darwin/functions/varsOverrides.sh
# macOS-specific variable overrides — sourced at end of functions/all.sh when system=darwin.
# Ensures paths always resolve to ~/Emulation even if settings.sh has shell-literal $HOME.

# Expand any literal "$HOME" strings that may have come from a heredoc written with single quotes
if [ -n "${emulationPath:-}" ]; then
    emulationPath="${emulationPath/\$HOME/$HOME}"
fi
if [ -n "${romsPath:-}" ]; then
    romsPath="${romsPath/\$HOME/$HOME}"
fi
if [ -n "${toolsPath:-}" ]; then
    toolsPath="${toolsPath/\$HOME/$HOME}"
fi
if [ -n "${biosPath:-}" ]; then
    biosPath="${biosPath/\$HOME/$HOME}"
fi
if [ -n "${savesPath:-}" ]; then
    savesPath="${savesPath/\$HOME/$HOME}"
fi
if [ -n "${storagePath:-}" ]; then
    storagePath="${storagePath/\$HOME/$HOME}"
fi
if [ -n "${Home:-}" ]; then
    Home="${Home/\$HOME/$HOME}"
fi

export emulationPath romsPath toolsPath biosPath savesPath storagePath Home

# macOS Library/Application Support base path
appSupportPath="${HOME}/Library/Application Support"
export appSupportPath
