#!/bin/bash

run_script() {
    local PANDOC_VER="3.1.11"
    local PANDOC_FILE="pandoc-${PANDOC_VER}-windows-x86_64.zip"
    local TEMP_DIR=$(mktemp -d)
    local BIN="/usr/bin"

    if [ ! -d "$BIN" ]; then
        echo "Creating $BIN directory"
        mkdir -p "$BIN"
    fi

    # Check if Pandoc is already in the system PATH
    if command -v pandoc &> /dev/null; then
        echo "✔️ Pandoc is already installed at $(command -v pandoc)"
    else
        echo "📥 Pandoc not found. Installing to $BIN..."

        # Ensure unzip is available for MSYS2
        if ! command -v unzip &> /dev/null; then
            echo "Missing 'unzip'. Installing via pacman..."
            pacman -S --noconfirm unzip
        fi

        local PANDOC_URL="https://github.com/jgm/pandoc/releases/download/${PANDOC_VER}/${PANDOC_FILE}"

        # Download to temporary directory
        if ! curl -L -o "$TEMP_DIR/$PANDOC_FILE" "$PANDOC_URL"; then
            echo "❌ Pandoc download failed!" >&2
            rm -rf "$TEMP_DIR"
            exit 1
        fi

        # Extract directly to get the binary
        if ! unzip -o "$TEMP_DIR/$PANDOC_FILE" -d "$TEMP_DIR" > /dev/null; then
            echo "❌ Extraction failed!" >&2
            rm -rf "$TEMP_DIR"
            exit 1
        fi

        # Move to $BIN and set permissions
        # Note: Windows zip structure usually places pandoc.exe in the root of the archive folder
        if mv "$TEMP_DIR/pandoc-${PANDOC_VER}/pandoc.exe" "$BIN/pandoc.exe"; then
            chmod +x "$BIN/pandoc.exe"
            echo "✅ Pandoc installed successfully to $BIN/pandoc.exe"
        else
            echo "❌ Failed to move binary to $BIN" >&2
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