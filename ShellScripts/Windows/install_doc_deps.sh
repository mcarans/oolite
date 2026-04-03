#!/bin/bash

run_script() {
    # Initialize local variables
    local SCRIPT_DIR
    local INSTALL_PYTHON=false
    local INSTALL_SOFFICE=false
    local INSTALL_WEASYPRINT=false

    SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
    pushd "$SCRIPT_DIR" > /dev/null

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
               popd > /dev/null
               exit 0
               ;;
            *)
               echo "❌ Unknown parameter: $1" >&2
               popd > /dev/null
               exit 1
               ;;
        esac
        shift
    done

    if [[ "$INSTALL_PYTHON" == true ]]; then
        if ! command -v python >/dev/null 2>&1; then
            echo "📥 Python not found. Installing system package..."
            if ! pacboy -S python-pip --noconfirm; then
                echo "❌ Could not install Python!" >&2
                popd > /dev/null
                return 1
            fi
        fi
    fi

    if [[ "$INSTALL_SOFFICE" == true ]]; then
        if ! command -v soffice >/dev/null 2>&1; then
            echo "📥 LibreOffice soffice not found. Installing system package..."
            # Note: winget may require an interactive shell or admin rights
            if ! winget install LibreOffice.LibreOffice; then
                echo "❌ Could not install LibreOffice with winget!" >&2
                popd > /dev/null
                return 1
            fi
        fi
    fi

    if [[ "$INSTALL_WEASYPRINT" == true ]]; then
        echo "📦 Installing WeasyPrint dependencies..."
        if ! pacboy -S pango libffi shared-mime-info --noconfirm; then
            echo "❌ Could not install WeasyPrint dependencies!" >&2
            popd > /dev/null
            return 1
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