#!/bin/bash
# darwin/functions/all.sh
# Sourced last in functions/all.sh when system=darwin.
# Loads all macOS-specific helpers and install primitives.

source "$emudeckBackend/darwin/functions/helpers.sh"
source "$emudeckBackend/darwin/functions/installEmuMacOS.sh"

# ── rsync --mkpath compatibility wrapper ──────────────────────────────────────
# macOS ships rsync 2.6.9 which lacks --mkpath. C2 in setup.sh prepends Homebrew
# rsync 3 to PATH, but background subshells may lose that PATH override.
# This wrapper strips --mkpath and forwards everything else, so all rsync calls
# work regardless of which rsync binary is actually resolved.
rsync() {
    local args=()
    for arg in "$@"; do
        [ "$arg" != "--mkpath" ] && args+=("$arg")
    done
    command rsync "${args[@]}"
}
export -f rsync
# ─────────────────────────────────────────────────────────────────────────────
