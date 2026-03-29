#!/bin/bash

run_script() {
    local PANDOC_VER="3.9"
    local PANDOC_FILE="pandoc-${PANDOC_VER}-linux-amd64.tar.gz"
    local TEMP_DIR=$(mktemp -d)
    local BIN="$HOME/.local/bin"

    if [ ! -d "$BIN" ]; then
        echo "Creating $BIN directory"
        mkdir -p "$BIN"
    fi

    # Check if Pandoc is already in the system PATH
    if ! command -v pandoc >/dev/null 2>&1; then
        echo "📥 Pandoc not found. Installing to $BIN..."

        local PANDOC_URL="https://github.com/jgm/pandoc/releases/download/${PANDOC_VER}/${PANDOC_FILE}"

        # Download to temporary directory
        if ! curl -L -o "$TEMP_DIR/$PANDOC_FILE" "$PANDOC_URL"; then
            echo "❌ Pandoc download failed!" >&2
            rm -rf "$TEMP_DIR"
            exit 1
        fi

        # Extract directly to get the binary
        # --strip-components=2 pulls 'pandoc' out of 'pandoc-x.x/bin/'
        if ! tar -xzf "$TEMP_DIR/$PANDOC_FILE" -C "$TEMP_DIR"; then
            echo "❌ Extraction failed!" >&2
            rm -rf "$TEMP_DIR"
            exit 1
        fi

        # Move to $BIN and set permissions
        # Note: Adjusting path based on standard Pandoc tarball structure
        if mv "$TEMP_DIR/pandoc-${PANDOC_VER}/bin/pandoc" "$BIN/pandoc"; then
            chmod +x "$BIN/pandoc"
            echo "✅ Pandoc installed successfully to $BIN/pandoc"
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

