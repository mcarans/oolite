#!/bin/bash

# This script must be run as root (for example with sudo).


run_script() {
    # If current user ID is NOT 0 (root)
    if [[ $EUID -ne 0 ]]; then
        echo "This script requires root to install dependencies. Rerun and escalate privileges (eg. sudo ...)"
        return 1
    fi

    # Initialize flags as false (not installed by default)
    INSTALL_PYTHON=false
    INSTALL_SOFFICE=false
    INSTALL_WEASYPRINT=false

    # Parse Command Line Arguments
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --python)      INSTALL_PYTHON=true ;;
            --soffice)     INSTALL_SOFFICE=true ;;
            --weasyprint)  INSTALL_WEASYPRINT=true ;;
            --all)
               INSTALL_PYTHON=true
               INSTALL_SOFFICE=true
               INSTALL_WEASYPRINT=true
               ;;
            -h|--help)
               echo "Usage: ./install_doc_deps_root.sh options"
               echo "Options:"
               echo "  --python       Install Python"
               echo "  --soffice      Install soffice (Libreoffice)"
               echo "  --weasyprint   Install WeasyPrint dependencies"
               echo "  --all          Install Python, soffice and WeasyPrint dependencies"
               exit 0
               ;;
            *) echo "Unknown parameter: $1"; exit 1 ;;
        esac
        shift
    done

    SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
    pushd "$SCRIPT_DIR"

    source ./install_package_fn.sh

    if [[ "$INSTALL_PYTHON" == true ]]; then
        if ! command -v python3 >/dev/null 2>&1; then
            echo "📥 Python not found. Installing system package..."
            if ! install_package python; then
                return 1
            fi
        fi
    fi

    if [[ "$INSTALL_SOFFICE" == true ]]; then
        if ! command -v soffice >/dev/null 2>&1; then
            echo "📥 LibreOffice soffice not found. Installing system package..."
            if ! install_package soffice; then
                return 1
            fi
        fi
    fi

    if [[ "$INSTALL_WEASYPRINT" == true ]]; then
        if ! install_package weasyprint-deps; then
            return 1
        fi
    fi
}

run_script "$@"
status=$?


# Exit only if not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    exit $status
fi

