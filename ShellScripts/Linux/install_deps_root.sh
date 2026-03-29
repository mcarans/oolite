#!/bin/bash

# This script must be run as root (for example with sudo).


run_script() {
    # If current user ID is NOT 0 (root)
    if [[ $EUID -ne 0 ]]; then
        echo "This script requires root to install dependencies. Rerun and escalate privileges (eg. sudo ...)"
        return 1
    fi

    # Initialize flags with defaults
    INSTALL_CORE=true
    INSTALL_APPIMAGE=false
    INSTALL_FLATPAK=false

    # Parse Command Line Arguments
    # If any specific flags are passed, we assume the user might NOT want the core
    # unless they also use --all or don't use any flags at all.
    if [[ "$#" -gt 0 ]]; then
        # Check if user is ONLY asking for AppImage or Flatpak
        # This allows us to disable the heavy core build if they just want tools
        INSTALL_CORE=false
    fi

    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --appimage)    INSTALL_APPIMAGE=true ;;
            --flatpak)     INSTALL_FLATPAK=true ;;
            --core)        INSTALL_CORE=true ;;
            --all)
               INSTALL_CORE=true
               INSTALL_APPIMAGE=true
               INSTALL_FLATPAK=true
               ;;
            -h|--help)
               echo "Usage: ./install_deps_root.sh [options]"
               echo "Options:"
               echo "  --core         Install only base build dependencies (default if no args)"
               echo "  --appimage     Install only AppImage tools"
               echo "  --flatpak      Install only Flatpak tools"
               echo "  --all          Install everything"
               exit 0
               ;;
            *) echo "Unknown parameter: $1"; exit 1 ;;
        esac
        shift
    done

    # If no arguments were provided at all, default to core
    if [[ "$INSTALL_CORE" == false && "$INSTALL_APPIMAGE" == false && "$INSTALL_FLATPAK" == false ]]; then
        INSTALL_CORE=true
    fi

    SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
    pushd "$SCRIPT_DIR"

    source ./install_package_fn.sh

    # --- SECTION 1: CORE DEPENDENCIES ---
    if [[ "$INSTALL_CORE" == true ]]; then
        echo "📦 Installing Core Build Dependencies..."

        # Array of packages to keep the code clean
        local pkgs=(
            base-devel clang lldb cmake gnutls-dev icu-dev ffi-dev
            xslt-dev png-dev zlib-dev nspr-dev espeak-ng-dev
            vorbis-dev openal-dev opengl-dev glu-dev sdl12-compat x11-dev
        )

        for pkg in "${pkgs[@]}"; do
            install_package "$pkg" || return 1
        done

        if [ ! -d /usr/share/espeak-ng-data ]; then
            if [ ! -d /usr/local/share/espeak-ng-data ]; then
                if [ ! -d /usr/lib/x86_64-linux-gnu/espeak-ng-data ]; then
                    echo "❌ espeak-ng-data not in /usr/share, /usr/local/share or /usr/lib/x86_64-linux-gnu!"
                    return 1
                fi
            fi
        fi

        export CC=clang
        export CXX=clang++

        if ! cd ../../build; then
            echo "❌ build folder doesn't exist!" >&2
            return 1
        fi

        cd libobjc2
        rm -rf build
        mkdir build
        cd build
        if ! cmake -DTESTS=on -DCMAKE_BUILD_TYPE=Release -DGNUSTEP_INSTALL_TYPE=NONE -DEMBEDDED_BLOCKS_RUNTIME=ON -DOLDABI_COMPAT=OFF ../; then
            echo "❌ libobjc2 cmake configure failed!" >&2
            return 1
        fi

        if ! cmake --build .; then
            echo "❌ libobjc2 cmake build failed!" >&2
            return 1
        fi
        cmake --install .
        cd ../..

        cd tools-make
        make clean

        # Bash
        if [[ ${CURRENT_DISTRO,,} == "redhat" ]]; then
            LIB_PARAM="--with-libdir=lib64"
        else
            LIB_PARAM=""
        fi

        if ! ./configure --with-library-combo=ng-gnu-gnu --with-runtime-abi=gnustep-2.2 ${LIB_PARAM:+"$LIB_PARAM"}; then
            echo "❌ tools-make configure failed!" >&2
            return 1
        fi
        make
        make install
        cd ..

        cd libs-base
        make clean
        source /usr/local/share/GNUstep/Makefiles/GNUstep.sh
        if ! ./configure; then
            echo "❌ libs-base configure failed!" >&2
            return 1
        fi
        if ! make -j$(nproc); then
            echo "❌ libs-base make failed!" >&2
            return 1
        fi
        make install
        cd ..
    fi

    # --- SECTION 2: APPIMAGE TOOLS ---
    if [[ "$INSTALL_APPIMAGE" == true ]]; then
        echo "📦 Installing AppImage Tools..."
        install_package appimage || return 1

        local BIN="$HOME/.local/bin"
        mkdir -p "$BIN"

        source ShellScripts/Linux/install_appimage_tool_fn.sh
        install_appimage_tool "$BIN" "appimagetool" "https://github.com/AppImage/appimagetool/releases/download/continuous/" || return 1

        LINTER_BIN="$BIN/appdir-lint.sh"
        EXCLUDE_LIST="$BIN/excludelist"
    
        if [ ! -x "$LINTER_BIN" ] || [ ! -f "$EXCLUDE_LIST" ]; then
            echo "📥 Downloading AppDir linter and excludelist..."
            curl -o "$LINTER_BIN" -L https://raw.githubusercontent.com/AppImage/AppImages/master/appdir-lint.sh || { echo "❌ Linter download failed" >&2; exit 1; }
            curl -o "$EXCLUDE_LIST" -L https://raw.githubusercontent.com/AppImage/AppImages/master/excludelist || { echo "❌ Excludelist download failed" >&2; exit 1; }
            chmod +x "$LINTER_BIN"
        fi
        
        install_appimage_tool "$BIN" "linuxdeploy" "https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/" || return 1
    fi

    if [[ "$INSTALL_FLATPAK" == true ]]; then
        install_package flatpak || return 1
    fi

	popd
}

run_script "$@"
status=$?


# Exit only if not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    exit $status
fi

