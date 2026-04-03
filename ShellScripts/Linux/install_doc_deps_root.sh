#!/bin/bash

# This script must be run as root (for example with sudo).

run_script() {
    # If current user ID is NOT 0 (root)
    if [[ $EUID -ne 0 ]]; then
        echo "This script requires root to install dependencies. Rerun and escalate privileges (eg. sudo ...)"
        return 1
    fi

    # Initialize flags as local variables
    local INSTALL_PYTHON=false
    local INSTALL_SOFFICE=false
    local INSTALL_WEASYPRINT=false
    local INSTALL_DOXYGEN=false
    local SCRIPT_DIR

    # Parse Command Line Arguments
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --python)      INSTALL_PYTHON=true ;;
            --soffice)     INSTALL_SOFFICE=true ;;
            --weasyprint)  INSTALL_WEASYPRINT=true ;;
            --doxygen)     INSTALL_DOXYGEN=true ;;
            --all)
               INSTALL_PYTHON=true
               INSTALL_SOFFICE=true
               INSTALL_WEASYPRINT=true
               INSTALL_DOXYGEN=true
               ;;
            -h|--help)
               echo "Usage: ./install_doc_deps_root.sh options"
               echo "Options:"
               echo "  --python       Install Python"
               echo "  --soffice      Install soffice (Libreoffice)"
               echo "  --weasyprint   Install WeasyPrint dependencies"
               echo "  --doxygen      Install Doxygen"
               echo "  --all          Install all dependencies"
               exit 0
               ;;
            *) echo "Unknown parameter: $1"; exit 1 ;;
        esac
        shift
    done

    # Split declaration and assignment for SCRIPT_DIR to preserve exit codes
    SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
    pushd "$SCRIPT_DIR" > /dev/null

    # Source helper function - ensure it exists
    if [[ -f "./install_package_fn.sh" ]]; then
        source ./install_package_fn.sh
    else
        echo "❌ install_package_fn.sh not found!" >&2
        popd > /dev/null
        return 1
    fi

    if [[ "$INSTALL_PYTHON" == true ]]; then
        if ! command -v python3 >/dev/null 2>&1; then
            echo "📥 Python not found. Installing system package..."
            if ! install_package python; then
                popd > /dev/null
                return 1
            fi
        fi
    fi

    if [[ "$INSTALL_SOFFICE" == true ]]; then
        if ! command -v soffice >/dev/null 2>&1; then
            echo "📥 LibreOffice soffice not found. Installing system package..."
            if ! install_package soffice; then
                popd > /dev/null
                return 1
            fi
        fi
    fi

    if [[ "$INSTALL_WEASYPRINT" == true ]]; then
        if ! install_package weasyprint-deps; then
            popd > /dev/null
            return 1
        fi
    fi

    if [[ "$INSTALL_DOXYGEN" == true ]]; then
        if ! command -v doxygen >/dev/null 2>&1; then
            echo "📥 Doxygen not found. Installing system package..."
            if ! install_package doxygen; then
                popd > /dev/null
                return 1
            fi
        fi
    fi

    popd > /dev/null
}

run_script "$@"
status=$?

# Exit only if not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    exit $status
fi