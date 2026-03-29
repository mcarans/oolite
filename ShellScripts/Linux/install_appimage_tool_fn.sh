# Function to install an AppImage tool
install_appimage_tool() {
    local target_path="$1/$2"

    if ! command -v "$target_path" &> /dev/null && \
       ! command -v "$2" &> /dev/null; then
        echo "📥 $2 not found. Downloading..."

        # Create temp file
        local temp_bin="/tmp/$2-$(uname -m).AppImage"

        if ! curl -L -o "$temp_bin" "$3"; then
            echo "❌ $2 download failed!" >&2
            return 1
        fi

        chmod +x "$temp_bin"

        echo "📦 Installing to $target_path..."
        if mv "$temp_bin" "$target_path"; then
            echo "✅ $2 installed successfully."
        else
            echo "❌ Failed to move $2. Check permissions." >&2
            rm -f "$temp_bin"
            return 1
        fi
    else
        echo "✔️ $2 is already installed."
    fi
}