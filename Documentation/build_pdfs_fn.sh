#!/bin/bash

build_pdfs() {
    # Define local variables at the top of the function
    local SCRIPT_DIR
    local WEASY_AVAILABLE=true
    local PYTHON_CMD
    local PANDOC_BIN
    local VENV_DIR="../.venv"
    local PDF_DIR="assets/pdfs"
    local PDF_FULLDIR

    SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
    pushd "$SCRIPT_DIR" > /dev/null

    # 1. Check Python
    if python3 --version >/dev/null 2>&1; then
        PYTHON_CMD="python3"
    elif python --version >/dev/null 2>&1; then
        PYTHON_CMD="python"
    else
        echo "❌ Python not found!" >&2
        if [[ "$FAIL_WEASYNOTFOUND" == "Y" ]]; then popd > /dev/null; return 1; fi
        WEASY_AVAILABLE=false
    fi

    # 2. Check Pandoc
    if [ "$WEASY_AVAILABLE" = true ]; then
        if command -v pandoc >/dev/null 2>&1; then
            PANDOC_BIN="pandoc"
        elif [ -f "$HOME/.local/bin/pandoc" ]; then
            PANDOC_BIN="$HOME/.local/bin/pandoc"
        else
            echo "❌ Pandoc not found!" >&2
            if [[ "$FAIL_WEASYNOTFOUND" == "Y" ]]; then popd > /dev/null; return 1; fi
            WEASY_AVAILABLE=false
        fi
    fi

    # 3. Check Virtual Environment folder
    local VENV_DIR="../.venv"
    if [ "$WEASY_AVAILABLE" = true ]; then
        if [ ! -d "$VENV_DIR" ]; then
            echo "❌ Virtual environment folder ($VENV_DIR) not found!" >&2
            if [[ "$FAIL_WEASYNOTFOUND" == "Y" ]]; then popd > /dev/null; return 1; fi
            WEASY_AVAILABLE=false
        else
            # Try to activate based on OS structure
            if [ -f "$VENV_DIR/Scripts/activate" ]; then
                source "$VENV_DIR/Scripts/activate"
            elif [ -f "$VENV_DIR/bin/activate" ]; then
                source "$VENV_DIR/bin/activate"
            else
                echo "❌ Activation script not found in $VENV_DIR!" >&2
                if [[ "$FAIL_WEASYNOTFOUND" == "Y" ]]; then popd > /dev/null; return 1; fi
                WEASY_AVAILABLE=false
            fi
        fi
    fi

    # 4. Check WeasyPrint package
    if [ "$WEASY_AVAILABLE" = true ]; then
        if ! $PYTHON_CMD -m weasyprint --version >/dev/null 2>&1; then
            echo "❌ WeasyPrint or Pango libraries not found in environment!" >&2
            if [[ "$FAIL_WEASYNOTFOUND" == "Y" ]]; then
                if command -v deactivate >/dev/null 2>&1; then deactivate; fi
                popd > /dev/null; return 1;
            fi
            WEASY_AVAILABLE=false
        fi
    fi

    # Prepare Directories
    local PDF_DIR="assets/pdfs"
    mkdir -p "build/documentation/docs/$PDF_DIR"

    pushd "build/documentation/docs" > /dev/null

    declare -A DOCS=(
        ["index.md"]="OoliteReadMe.pdf"
        ["advice.md"]="AdviceForNewCommanders.pdf"
        ["privacy.md"]="Privacy.pdf"
        ["license.md"]="License.pdf"
    )

    for SRC in "${!DOCS[@]}"; do
        DEST="${DOCS[$SRC]}"

        if [ "$WEASY_AVAILABLE" = true ]; then
            echo "📄 Converting $SRC..."
            if ! "$PANDOC_BIN" "$SRC" -o "$PDF_DIR/$DEST" \
                --pdf-engine=weasyprint \
                --css=style.css; then
                echo "❌ Failed to convert $SRC" >&2
                if [[ "$FAIL_WEASYNOTFOUND" == "Y" ]]; then
                    popd > /dev/null; popd > /dev/null; return 1;
                fi
                echo "%PDF-1.0" > "$PDF_DIR/$DEST"
            fi
        else
            echo "📝 Creating blank PDF for $SRC (Dependencies missing)"
            echo "%PDF-1.0" > "$PDF_DIR/$DEST"
        fi
    done

    echo "✅ PDF task finished"

    # Final cleanup
    if command -v deactivate >/dev/null 2>&1; then deactivate; fi
    popd > /dev/null # Leave build/documentation/docs
    popd > /dev/null # Leave SCRIPT_DIR
}