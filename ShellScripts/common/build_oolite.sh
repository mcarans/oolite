#!/bin/bash
# No parameters: build target = release
# One parameter: build target

run_script() {
    # Initialize local variables
    local SCRIPT_DIR
    local TARGET
    local SHARE

    # First optional parameter is build target. Default target is release.
    SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
    pushd "$SCRIPT_DIR" > /dev/null

    # These remain exports so the 'make' child process can see them
    export CC=clang
    export CXX=clang++

    cd ../..

    if [[ -z "$1" ]]; then
        TARGET=release
    else
        TARGET=$1
    fi

    if [[ -z "$MINGW_PREFIX" ]]; then
        SHARE="/usr/local/share"
    else
        SHARE="${MINGW_PREFIX}/share"
    fi

    # Source GNUstep - local variables above are safe from being overwritten
    if [[ -f "$SHARE/GNUstep/Makefiles/GNUstep.sh" ]]; then
        source "$SHARE/GNUstep/Makefiles/GNUstep.sh"
    else
        echo "❌ GNUstep configuration not found in $SHARE" >&2
        popd > /dev/null
        return 1
    fi

    make -f Makefile clean
    if ! make -f Makefile "$TARGET" -j$(nproc); then
        echo "❌ Oolite build failed!" >&2
        popd > /dev/null
        return 1
    fi
    echo "✅ Oolite build completed successfully"

    popd > /dev/null
}

run_script "$@"
status=$?

# Exit only if not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    exit $status
fi