#!/bin/bash

run_script() {
    # Configuration
    PANDOC_VER="3.1.11" # Ensure this matches your desired version
    TARGET_BIN="/usr/bin/pandoc.exe"
    TEMP_DIR="/tmp/pandoc_install"

    # 1. Check if already installed in MSYS2 path
    if command -v pandoc &> /dev/null; then
        echo "✔️ Pandoc is already installed at $(command -v pandoc)"
    else
        echo "📥 Pandoc not found. Starting MSYS2-specific installation..."

        # Ensure unzip is available
        if ! command -v unzip &> /dev/null; then
            echo "Missing 'unzip'. Installing via pacman..."
            pacman -S --noconfirm unzip
        fi

        # Prepare environment
        mkdir -p "$TEMP_DIR"
        PANDOC_FILE="pandoc-${PANDOC_VER}-windows-x86_64.zip"
        PANDOC_URL="https://github.com/jgm/pandoc/releases/download/${PANDOC_VER}/${PANDOC_FILE}"

        echo "Downloading: $PANDOC_URL"
        if ! curl -L -o "$TEMP_DIR/$PANDOC_FILE" "$PANDOC_URL"; then
            echo "❌ Pandoc download failed!" >&2
            rm -rf "$TEMP_DIR"
            exit 1
        fi

        # Extract
        echo "📦 Extracting..."
        if ! unzip -o "$TEMP_DIR/$PANDOC_FILE" -d "$TEMP_DIR" > /dev/null; then
            echo "❌ Extraction failed!" >&2
            rm -rf "$TEMP_DIR"
            exit 1
        fi

        # MSYS2/Windows zip contains a folder: pandoc-<version>/bin/pandoc.exe
        # (or sometimes just pandoc-<version>/pandoc.exe depending on the release)
        EXTRACTED_PATH=$(find "$TEMP_DIR" -name "pandoc.exe" -type f)

        if [[ -f "$EXTRACTED_PATH" ]]; then
            echo "🚀 Installing to $TARGET_BIN..."
            mv "$EXTRACTED_PATH" "$TARGET_BIN"
            chmod +x "$TARGET_BIN"
            echo "✅ Pandoc installed successfully."
        else
            echo "❌ Could not locate pandoc.exe in the extracted files." >&2
            rm -rf "$TEMP_DIR"
            exit 1
        fi

        # Cleanup
        rm -rf "$TEMP_DIR"
    fi
}

run_script "$@"
status=$?


# Exit only if not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    exit $status
fi

