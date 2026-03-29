#!/bin/bash

run_script() {
    SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
    pushd "$SCRIPT_DIR"

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

    if [[ "$INSTALL_PYTHON" == true ]]; then
        if ! command -v python >/dev/null 2>&1; then
            echo "📥 Python not found. Installing system package..."
            if ! pacboy -S python-pip --noconfirm; then
                echo "❌ Could not install Python!">&2
                return 1
            fi
        fi
    fi

    if [[ "$INSTALL_SOFFICE" == true ]]; then
        if ! command -v soffice >/dev/null 2>&1; then
            echo "📥 LibreOffice soffice not found. Installing system package..."
            if ! winget install LibreOffice.LibreOffice; then
                echo "❌ Could not install LibreOffice with winget!">&2
                return 1
            fi
        fi
    fi

    if [[ "$INSTALL_WEASYPRINT" == true ]]; then
        if ! pacboy -S pango --noconfirm; then
            echo "❌ Could not install pango!">&2
            return 1
        fi
        if ! pacboy -S libffi --noconfirm; then
            echo "❌ Could not install libffi!">&2
            return 1
        fi
        if ! pacboy -S shared-mime-info --noconfirm; then
            echo "❌ Could not install shared-mime-info!">&2
            return 1
        fi
    fi


    popd
}


run_script "$@"
status=$?


# Exit only if not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    exit $status
fi
