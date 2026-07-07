#!/bin/bash
#
# Calculates the Oolite version number and build dates
#


if [[ -v MINGW_PREFIX ]]; then
    echo "=== HYBRID PROCESS DETECTION DIAGNOSTICS ==="
    echo "Current Bash POSIX PID (\$\$): $$"

    # 1. Capture the native Windows PID for the current shell
    PS_OUTPUT=$(ps -p $$)
    WIN_PID=$(echo "$PS_OUTPUT" | awk 'NR>1 {print $4}')
    echo "1. Current Shell Windows PID: ${WIN_PID:-FAILED}"

    if [ -z "$WIN_PID" ]; then
        echo "❌ ERROR: Could not extract Windows PID from ps."
        PARENT_PROCESS="unknown"
    else
        # 2. Query Windows Kernel for the Parent Windows PID (Using single quotes to protect PS variables)
        PARENT_WINPID=$(powershell.exe -Command '
            try {
                $proc = Get-Process -Id '"$WIN_PID"' -ErrorAction Stop
                Write-Output $proc.Parent.Id
            } catch {
                Write-Output "FAILED"
            }
        ' 2>/dev/null | tr -d '\r')

        echo "2. Parent Native Windows PID: $PARENT_WINPID"

        if [ -z "$PARENT_WINPID" ] || [ "$PARENT_WINPID" = "FAILED" ]; then
            echo "❌ ERROR: PowerShell could not resolve Parent Windows PID."
            PARENT_PROCESS="unknown"
        else
            # 3. Reference Parent Windows PID back against MSYS2 POSIX map
            LOCAL_PS=$(ps)
            PARENT_PROCESS=$(echo "$LOCAL_PS" | awk -v winpid="$PARENT_WINPID" '$4 == winpid {print $NF}' | xargs basename .exe 2>/dev/null)
            echo "3. MSYS2 Table Mapping for PID $PARENT_WINPID: ${PARENT_PROCESS:-NONE}"

            # 4. Fallback/Normalization Block
            if [ "$PARENT_PROCESS" = "python" ] || [ -z "$PARENT_PROCESS" ]; then
                echo "4. Detected 'python' or empty map. Cross-checking environment for Meson..."
                if echo "$LOCAL_PS" | grep -q "meson"; then
                    PARENT_PROCESS="meson"
                    echo "   -> Contextual Match: Found active 'meson' context in local ps table."
                else
                    PARENT_PROCESS="python"
                fi
            fi
        fi
    fi

    echo "=== FINAL RESOLUTION ==="
    echo "Parent Process identified as: $PARENT_PROCESS"
    echo "============================================="
else
    PARENT_PROCESS=$(ps -p $PPID -o comm= 2>/dev/null || true)
fi
if [[ "$PARENT_PROCESS" != "meson" ]] || [[ -z "$MESON_BUILD_ROOT" ]]; then
    SUITE_PARENT=$(basename "${BASH_SOURCE[1]}")  # Get the name of the script that is sourcing this file
    ALLOWED_SCRIPT="create_flatpak_fn.sh"  # Define the ONLY script allowed to source this
    if [[ "$SUITE_PARENT" != "$ALLOWED_SCRIPT" ]]; then
        echo "❌ Parent process is $PARENT_PROCESS, Bash parent is $SUITE_PARENT. This file can only be called by meson or sourced by $ALLOWED_SCRIPT!" >&2
        unset SUITE_PARENT ALLOWED_SCRIPT
        return 1 2>/dev/null || exit 1
    fi
    unset SUITE_PARENT ALLOWED_SCRIPT
fi


run_script() {
    local build_dir="$1"  # Input string arguments

    if [[ -z "$build_dir" ]]; then
        echo "❌ build_dir argument is required!" >&2
        return 1
    fi

    source "ShellScripts/common/get_build_date_fn.sh"
    local output_ver_githash=$(git rev-parse --short=7 HEAD)
    local dirty_suffix=""
    git diff --quiet || dirty_suffix="-dirty"
    local lookup_hash="${output_ver_githash}${dirty_suffix}"
    local output_ver_full=""
    local output_buildtime=""
    local version_file="$build_dir/.meson_version"
    if [[ -z "${VER_FULL-}" ]]; then
        if [[ -f "$version_file" ]]; then  # Check if cache exists and has a matching hash context
            local githash ver_full ver_nsis ver_gitrev cpp_date app_date buildtime builder
            source "$version_file" 2>/dev/null
            if [[ "$ver_githash" == "$lookup_hash" ]]; then
                echo "$ver_full"
                return 0
            fi
        fi
    else
        output_ver_full="$VER_FULL"
    fi

    if [[ -z "$output_ver_full" ]]; then
        local exact_tag=""  # Check for an exact Git tag first on a clean tree
        if [[ -z "$dirty_suffix" ]]; then
            exact_tag=$(git describe --tags --exact-match HEAD 2>/dev/null)
        fi
        if [[ -n "$exact_tag" ]]; then
            output_ver_full="$exact_tag"
        else
            if ! command -v gitversion &> /dev/null; then  # exact tag didn't hit, use gitversion for ver_full
                echo "❌ gitversion binary not found!" >&2
                exit 1
            fi
            local gitversion_json=$(gitversion)  # Run gitversion and get json output
            local ver_semver=$(echo "$gitversion_json" | jq -r '.SemVer')
            if [[ -z "$dirty_suffix" ]]; then
                output_ver_full="$ver_semver"
            else
                local ver_uncommitted=$(echo "$gitversion_json" | jq -r '.UncommittedChanges')
                output_ver_full="${ver_semver}+dirty.${ver_uncommitted}"
            fi
        fi
    fi

    local clean_ver="${output_ver_full#v}"  # Strip any leading 'v', prerelease tags (-alpha), or build metadata (+)
    clean_ver="${clean_ver%%-*}"  # Example: "v1.91.0-alpha.1+dirty.3" -> "1.91.0"
    clean_ver="${clean_ver%%+*}"
    local ver_maj=$(echo "$clean_ver" | cut -d. -f1)  # Parse out Major, Minor, Patch using standard dot delimiters
    local ver_min=$(echo "$clean_ver" | cut -d. -f2)
    local ver_rev=$(echo "$clean_ver" | cut -d. -f3)
    [[ -z "$ver_rev" ]] && ver_rev="0"

    if [[ -z "$dirty_suffix" ]]; then  # Use git for other metrics for clean repository
        local closest_tag=$(git describe --tags --abbrev=0 2>/dev/null)  # Derive distance from closest Git tag
        local ver_dist="0"
        if [[ -n "$closest_tag" ]]; then
            ver_dist=$(git rev-list --count "${closest_tag}..HEAD")
        else
            ver_dist=$(git rev-list --count HEAD)
        fi
        output_ver_nsis="$ver_maj.$ver_min.$ver_rev.$ver_dist"
    else
        local ver_uncommitted=$(git status --porcelain 2>/dev/null | wc -l)  # Dirty repo: get uncommitted file count
        output_ver_nsis="$ver_maj.$ver_min.$ver_rev.$ver_uncommitted"
    fi

    local output_cpp_date output_app_date output_builder
    get_build_date output_cpp_date output_app_date output_buildtime output_builder "${BUILDTIME-}"

    cat << EOF > "$version_file"  # Write new values to the hidden cache file
ver_githash="$lookup_hash"
ver_full="$output_ver_full"
ver_nsis="$output_ver_nsis"
cpp_date="$output_cpp_date"
app_date="$output_app_date"
buildtime="$output_buildtime"
builder="$output_builder"
EOF

    echo "$output_ver_full"
}

# Exit only if not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_script "$@"
    exit $?
fi
