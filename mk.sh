#!/bin/bash

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
pushd "$SCRIPT_DIR" > /dev/null

set -u -o pipefail  # Strict expansions

# --- Error Handling Trap ---
cleanup_and_exit() {
    local exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        exit_code=1  # force 0 exit code to 1 to indicate an error
    fi
    echo "❌ Oolite build failed on line $1 with exit code $exit_code!" >&2
    popd > /dev/null 2>&1 || true  # Always pop the directory stack before exiting
    if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then  # Exit only if not sourced
        exit "$exit_code"
    fi
}
trap 'cleanup_and_exit ${LINENO}' ERR  # Trap any command errors (ERR) passing ${LINENO} to know where it failed

# --- Feature Flags & Options ---
NATIVE_FILE=""
VER_FULL=""
GITHUB_REPOSITORY=""
CLEAN_BUILD=false
SETUP_FLAGS=() # Array to cleanly store additional meson setup arguments
COMPILE_FLAGS=() # Array to cleanly store additional meson compile arguments
INSTALL_FLAGS=() # Array to cleanly store additional meson install arguments

meson_clean() {
    local build_dir="build/meson_$1"
    echo "--> Cleaning target build directory: ${build_dir}"
    rm -rf "$build_dir"  # If --clean was specified, delete the specific build directory first
}

meson_setup() {
    local build_dir="build/meson_$1"
    if [[ "$CLEAN_BUILD" == true ]]; then
        meson_clean $1
    fi
    echo "--> Running Meson setup for: $1"
    # Setup with --reconfigure, fallback to fresh setup. SETUP_FLAGS safely expands the array only if it's not empty
    meson setup "$build_dir" $2 ${SETUP_FLAGS[@]+"${SETUP_FLAGS[@]}"} --native-file "${NATIVE_FILE}" --reconfigure 2>/dev/null || \
    meson setup "$build_dir" $2 ${SETUP_FLAGS[@]+"${SETUP_FLAGS[@]}"} --native-file "${NATIVE_FILE}"
}

meson_compile() {
    echo "--> Running Meson build for: $1"
    meson compile -C "build/meson_$1" ${COMPILE_FLAGS[@]+"${COMPILE_FLAGS[@]}"}
}

meson_install() {
    echo "--> Running Meson install for: $1"
    meson install -C "build/meson_$1" ${INSTALL_FLAGS[@]+"${INSTALL_FLAGS[@]}"}
}

show_help() {  # Script Help Menu
    echo "Usage: $0 [options] <action> <profile>"
    echo "       $0 [options] <global_action>"
    echo ""
    echo "Options:"
    echo -e "  \033[36m--clean\033[0m                        Delete target build directory before compiling"
    echo -e "  \033[36m--setup-flags=\"...\"\033[0m          Pass additional arguments directly to 'meson setup'"
    echo -e "  \033[36m--compile-flags=\"...\"\033[0m        Pass additional arguments directly to 'meson compile'"
    echo -e "  \033[36m--install-flags=\"...\"\033[0m        Pass additional arguments directly to 'meson install'"
    echo -e "  \033[36m--native-file=\"...\"\033[0m          Specify native file (defaults to clang.ini)"
    echo -e "  \033[36m--ver-full=\"...\"\033[0m             Specify full version string"
    echo -e "  \033[36m--github-repository=\"...\"\033[0m    Specify target GitHub repository"
    echo ""
    echo "Profile Actions (Requires profile as second parameter):"
    echo -e "  \033[36msetup <profile>\033[0m              Setup a release build directory"
    echo -e "  \033[36mcompile <profile>\033[0m            Compile a build directory"
    echo -e "  \033[36mbuild <profile>\033[0m              Setup and compile a build profile"
    echo -e "  \033[36minstall <profile>\033[0m            Install a built profile configuration"
    echo -e "  \033[36mtest <profile>\033[0m               Run test suites (deployment profile excluded)"
    echo -e "  \033[36mclean <profile>\033[0m              Clean a specific profile's directory"
    echo -e "  \033[36mflatpak-internal <profile>\033[0m   Build flatpak dependencies internally"
    echo -e "  \033[36mpkg-flatpak <profile>\033[0m        Package a Flatpak application"
    echo -e "  \033[36mpkg-appimage <profile>\033[0m       Package a Linux AppImage installer"
    echo -e "  \033[36mpkg-win <profile>\033[0m            Package a Windows NSIS installer"
    echo ""
    echo "Global Actions:"
    echo -e "  \033[36mclean-all\033[0m                    Remove generated artifacts for all builds"
    echo -e "  \033[36mhelp\033[0m                         Show this breakdown menu"
    echo ""
    echo "Profiles:"
    echo -e "  \033[32mdeployment, test, dev, debug\033[0m"
}

validate_profile() {
    local profile="$1"
    if [[ "$profile" != "deployment" && "$profile" != "test" && "$profile" != "dev" && "$profile" != "debug" ]]; then
        echo "❌ Invalid profile '$profile'. Expected: deployment, test, dev, or debug." >&2
        exit 1
    fi
}

execute_target() {  # Target Execution Logic
    local action="$1"
    local profile="${2:-}"

    case "$action" in
        setup)
            validate_profile "$profile"
            if [[ "$profile" == "deployment" ]]; then
                meson_setup "deployment" "-Ddeployment_release=true -Ddebug=false -Dstrip_bin=true -Db_lto=true"
            elif [[ "$profile" == "test" ]]; then
                meson_setup "test" "-Ddebug=false -Dstrip_bin=true -Db_lto=true"
            elif [[ "$profile" == "dev" ]]; then
                meson_setup "dev" "-Ddev_release=true -Ddebug=false -Dstrip_bin=false"
            elif [[ "$profile" == "debug" ]]; then
                meson_setup "debug" "-Ddebug=true -Dstrip_bin=false"
            fi
            ;;
        compile)
            validate_profile "$profile"
            meson_compile "$profile"
            ;;
        build)
            validate_profile "$profile"
            execute_target "setup" "$profile"
            execute_target "compile" "$profile"
            ;;
        install)
            validate_profile "$profile"
            meson_install "$profile"
            ;;
        test)
            validate_profile "$profile"
            if [[ "$profile" == "deployment" ]]; then
                echo "❌ Cannot test deployment as not set up for debug console!" >&2
                exit 1
            fi
            source tests/run_test_fn.sh && run_test "$profile"
            ;;
        clean)
            validate_profile "$profile"
            meson_clean "$profile"
            ;;
        flatpak-internal)
            validate_profile "$profile"
            execute_target "build" "$profile"
            source installers/flatpak/flatpak_postbuild_fn.sh && flatpak_postbuild "meson_${profile}/oolite.app" "${VER_FULL:-}" "${APP_DATE:-}"
            ;;
        pkg-flatpak)
            validate_profile "$profile"
            source installers/flatpak/create_flatpak_fn.sh && create_flatpak "${VER_FULL:-}" "$GITHUB_REPOSITORY"
            ;;
        pkg-appimage)
            validate_profile "$profile"
            local suffix=""
            if [[ "$profile" != "deployment" ]]; then suffix="$profile"; fi
            meson configure "build/meson_$profile" --prefix=$(realpath -m "build/oolite.AppDir")
            meson_install "$profile"
            source installers/appimage/create_appimage_fn.sh && create_appimage "meson_${profile}/oolite.app" "${VER_FULL:-}" "${APP_DATE:-}" "$suffix"
            ;;
        pkg-win)
            validate_profile "$profile"
            local suffix=""
            if [[ "$profile" != "deployment" ]]; then suffix="$profile"; fi
            source installers/win32/create_nsis_fn.sh && create_nsis "meson_${profile}/oolite.app" "${VER_FULL:-}" "${VER_GITHASH:-}" "${BUILDTIME:-}" "$suffix"
            ;;
        *)
            echo "❌ Fatal structural error handling action '$action'" >&2
            exit 1
            ;;
    esac
}

ACTION=""
PROFILE=""

# --- Flexible Argument Parser (Allows flags and positionals anywhere) ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        --clean)
            CLEAN_BUILD=true
            shift
            ;;
        --setup-flags=*)
            read -r -a flags_array <<< "${1#*=}"
            SETUP_FLAGS+=("${flags_array[@]}")
            shift
            ;;
        --compile-flags=*)
            read -r -a flags_array <<< "${1#*=}"
            COMPILE_FLAGS+=("${flags_array[@]}")
            shift
            ;;
        --install-flags=*)
            read -r -a flags_array <<< "${1#*=}"
            INSTALL_FLAGS+=("${flags_array[@]}")
            shift
            ;;
        --native-file=*)
            NATIVE_FILE="${1#*=}"
            shift
            ;;
        --ver-full=*)
            VER_FULL="${1#*=}"
            shift
            ;;
        --github-repository=*)
            GITHUB_REPOSITORY="${1#*=}"
            shift
            ;;
        help|--help|-h)
            show_help
            exit 0
            ;;
        -*)
            echo "❌ Unknown option '$1'" >&2
            show_help
            exit 1
            ;;
        *)
            # Process sequential text items dynamically
            if [[ -z "$ACTION" ]]; then
                ACTION="$1"
            elif [[ -z "$PROFILE" ]]; then
                PROFILE="$1"
            else
                echo "❌ Unexpected extra argument '$1'." >&2
                show_help
                exit 1
            fi
            shift
            ;;
    esac
done

if [[ -z "$ACTION" ]]; then
    show_help  # Fallback to help menu if no action was provided
    exit 1
fi

# Intercept global action 'clean-all' before validating profile requirements
if [[ "$ACTION" == "clean-all" ]]; then
    echo "--> Cleaning all build artifacts..."
    rm -rf build/meson_*
    trap - ERR
    popd > /dev/null
    echo "✅ Oolite task 'clean-all' completed successfully"
    exit 0
fi

# Everything past this point strictly requires a profile parameter
if [[ -z "$PROFILE" ]]; then
    echo "❌ Error: Action '$ACTION' requires a target profile parameter." >&2
    show_help
    exit 1
fi

if [[ -z "$NATIVE_FILE" ]]; then
    NATIVE_FILE="clang.ini"  # Apply default if it wasn't passed as an option
fi

execute_target "$ACTION" "$PROFILE"

trap - ERR  # Successful Exit
popd > /dev/null

echo "✅ Oolite task '$ACTION $PROFILE' completed successfully"

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    exit 0
fi