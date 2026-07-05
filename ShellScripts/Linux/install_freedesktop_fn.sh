#!/bin/bash -x
#
# Installs the manifest and injects version number


install_freedesktop() {
    local build_folder="$1"  # oolite.app directory path (source)
    local app_folder="$2"  # app folder (destination)
    local symbol_folder="$3"  # debug symbol folder
    local metainfo_suffix="$4"  # can be appdata or metainfo

    local err_msg="❌ Error: Failed to"

    local script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
    pushd "$script_dir"

    source ../common/parse_manifest_fn.sh

    echo "Installing metainfo to to $app_folder"

    parse_manifest ver_full githash buildtime app_date "$build_folder/Resources/manifest.plist"

    local appbin="$app_folder/bin"
    local appshr="$app_folder/share"

#    # Install binaries and scripts
#    install -D "$build_folder/oolite" "$appbin/oolite" || { echo "$err_msg install oolite binary" >&2; return 1; }
#    if [[ -f "$build_folder/oolite.debug" ]]; then
#        install -D "$build_folder/oolite.debug" "$app_folder/$symbol_folder/oolite.debug" || { echo "$err_msg install oolite debug symbols" >&2; return 1; }
#    fi
#    install -D "$build_folder/run_oolite.sh" "$appbin/run_oolite.sh" || { echo "$err_msg install run_oolite.sh" >&2; return 1; }
#
#    # Resources copy
     local resourcesdir="$appshr/oolite/Resources"
#    mkdir -p "$resourcesdir"
#    cp -rf "$build_folder/Resources/." "$resourcesdir/" || { echo "$err_msg copy Resources folder" >&2; return 1; }
#
#    # AddOns copy if folder exists in oolite.app
#    if [ -d "$build_folder/AddOns" ]; then
#        local addonsdir="$appshr/oolite/AddOns"
#        mkdir -p "$addonsdir"
#        cp -rf "$build_folder/AddOns/." "$addonsdir/" || { echo "$err_msg copy AddOns folder" >&2; return 1; }
#    fi

    rm -f "$resourcesdir/GNUstep.conf.orig"
    install -D "GNUstep.conf.template" "$resourcesdir/GNUstep.conf.template" || { echo "$err_msg GNUstep template" >&2; return 1; }

    local app_metainfo="$appshr/metainfo/space.oolite.Oolite.$metainfo_suffix.xml"
    install -D ../../installers/FreeDesktop/space.oolite.Oolite.metainfo.xml.template "$app_metainfo" || { echo "$err_msg metainfo template" >&2; return 1; }

    sed -i "s/@VER@/${ver_full}/g" "$app_metainfo"
    sed -i "s/@DATE@/${app_date}/g" "$app_metainfo"

    echo ===========================================
    echo Our manifest looks like this:
    cat "$app_metainfo"
    echo ===========================================

    # Desktop and Icon
    install -D ../../installers/FreeDesktop/space.oolite.Oolite.desktop "$appshr/applications/space.oolite.Oolite.desktop" || { echo "$err_msg desktop file" >&2; return 1; }
    install -D "$build_folder/Resources/Textures/oolite-logo1.png" "$appshr/icons/hicolor/256x256/apps/space.oolite.Oolite.png" || { echo "$err_msg icon file" >&2; return 1; }

    popd
}