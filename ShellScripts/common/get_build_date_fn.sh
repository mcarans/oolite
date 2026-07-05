#!/bin/bash
#
# Calculates the Oolite build date
#

SUITE_PARENT=$(basename "${BASH_SOURCE[1]}")  # Get the name of the script that is sourcing this file
ALLOWED_SCRIPT="get_version.sh"  # Define the ONLY script allowed to source this
if [[ "$SUITE_PARENT" != "$ALLOWED_SCRIPT" ]]; then
    echo "❌ This file can only be sourced by $ALLOWED_SCRIPT!" >&2
    unset SUITE_PARENT ALLOWED_SCRIPT
    return 1 2>/dev/null || exit 1
fi
unset SUITE_PARENT ALLOWED_SCRIPT

get_build_date() {
    local -n return_cpp_date="$1"
    local -n return_app_date="$2"
    local -n return_buildtime="$3"
    local -n return_builder="$4"
    local buildtime="$5"


    if [[ -n "$buildtime" ]]; then
        return_buildtime="$buildtime"
    else
        local getversion_timestamp=$(git log -1 --format=%ct)
        return_buildtime=$(date -u -d "@$getversion_timestamp" "+%Y.%m.%d %H:%M")
    fi

    local clean_date="${return_buildtime//./-}"
    return_cpp_date=$(date -u -d "$clean_date" +"%b%e %Y")
    return_app_date=$(date -u -d "$clean_date" +"%Y-%m-%d")

    if [[ "$GITHUB_REPOSITORY" == "OoliteProject/oolite" ]]; then
        return_builder="OoliteProject"
    else
        return_builder="unknown"
    fi
}