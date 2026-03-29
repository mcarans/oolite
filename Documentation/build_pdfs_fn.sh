#!/bin/bash

build_pdfs() {
    SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
    pushd "$SCRIPT_DIR"

    if python3 --version >/dev/null 2>&1; then
        PYTHON_CMD="python3"
    elif python --version >/dev/null 2>&1; then
        PYTHON_CMD="python"
    else
      echo "❌ Python executable not found" >&2
      return 1
    fi

    PDF_DIR="assets/pdfs"
    PDF_FULLDIR="build/documentation/docs/$PDF_DIR"
    cd ..
    rm -rf "$PDF_FULLDIR"
    mkdir -p "$PDF_FULLDIR"
    cd build/documentation/docs

    PANDOC_VER="3.9"
    OS_TYPE=$(uname -s)

    if [[ "$OS_TYPE" == *"MSYS"* || "$OS_TYPE" == *"MINGW"* ]]; then
        PANDOC_FILE="pandoc-${PANDOC_VER}-windows-x86_64.zip"
        EXTRACT_CMD="unzip -o"
        EXTRACTED_BIN="pandoc-${PANDOC_VER}/pandoc.exe"
        PANDOC_BIN="pandoc.exe"
    else
        PANDOC_FILE="pandoc-${PANDOC_VER}-linux-amd64.tar.gz"
        EXTRACT_CMD="tar -xzf"
        EXTRACTED_BIN="pandoc-${PANDOC_VER}/bin/pandoc"
        PANDOC_BIN="pandoc"
    fi

    # Check if Pandoc is already available
    if ! command -v "$PANDOC_BIN" >/dev/null 2>&1; then
        PANDOC_BIN="./$PANDOC_BIN"
        if [[ ! -x "$PANDOC_BIN" ]]; then
            # Download if not found anywhere
            echo "📥 Downloading pandoc..."
            PANDOC_URL="https://github.com/jgm/pandoc/releases/download/${PANDOC_VER}/${PANDOC_FILE}"

            if ! curl -L -o "$PANDOC_FILE" "$PANDOC_URL"; then
                echo "❌ pandoc download failed!" >&2
                rm -f "$PANDOC_FILE"
                return 1
            fi

            if ! $EXTRACT_CMD "$PANDOC_FILE"; then
                echo "❌ $PANDOC_FILE could not be extracted!" >&2
                rm -f "$PANDOC_FILE"
                rm -rf "pandoc-${PANDOC_VER}"
                return 1
            fi

            if ! mv "$EXTRACTED_BIN" "$PANDOC_BIN"; then
                echo "❌ $PANDOC_FILE could not be extracted!" >&2
                rm -f "$PANDOC_FILE"
                rm -rf "pandoc-${PANDOC_VER}"
                return 1
            fi
            rm -f "$PANDOC_FILE"
            rm -rf "pandoc-${PANDOC_VER}"
        fi
    fi

    VENV_DIR=".venv"
    if [ ! -d "$VENV_DIR" ]; then
        echo "Creating virtual environment..."
        "$PYTHON_CMD" -m venv "$VENV_DIR"
    fi
    if [ -d "$VENV_DIR/Scripts" ]; then
        source "$VENV_DIR/Scripts/activate"
    else
        source "$VENV_DIR/bin/activate"
    fi
    "$PYTHON_CMD" -m pip install --upgrade weasyprint

    if ! $PYTHON_CMD -m weasyprint --version >/dev/null 2>&1; then
        echo "❌ WeasyPrint install failed or Pango libraries not found!">&2
        exit 1
    fi

    declare -A DOCS=(
        ["index.md"]="OoliteReadMe.pdf"
        ["advice.md"]="AdviceForNewCommanders.pdf"
        ["privacy.md"]="Privacy.pdf"
        ["license.md"]="License.pdf"
    )

    for SRC in "${!DOCS[@]}"; do
        DEST="${DOCS[$SRC]}"

        if ! "$PANDOC_BIN" "$SRC" -o "$PDF_DIR/$DEST" \
            --pdf-engine=weasyprint \
            --css=style.css; then
            echo "❌ Failed to convert $SRC" >&2
            return 1
        fi
    done

    echo "✅ PDF conversion completed successfully"
    deactivate
    popd
}
