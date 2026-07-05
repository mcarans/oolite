parse_manifest() {
    local -n output_ver_full="$1"
    local -n output_githash="$2"
    local -n output_buildtime="$3"
    local -n output_app_date="$4"
    local input_file="$5"

    if [[ ! -f "$input_file" ]]; then  # Ensure the manifest file exists before parsing
        echo "❌ Manifest file '$input_file' not found." >&2
        return 1
    fi

    get_manifest_value() {  # Helper function to extract a string inside quotes for a given key
        local key="$1"
        grep -E "^[[:space:]]*${key}[[:space:]]*=" "$input_file" | sed -E 's/.*"[[:space:]]*([^"]*)[[:space:]]*".*/\1/'
    }

    output_ver_full=$(get_manifest_value "version")
    output_githash=$(get_manifest_value "git_commit_hash")
    output_buildtime=$(get_manifest_value "build_time")
    local clean_date="${output_buildtime//./-}"
    output_app_date=$(date -u -d "${clean_date:0:10}" +"%Y-%m-%d" 2>/dev/null || echo "")
}