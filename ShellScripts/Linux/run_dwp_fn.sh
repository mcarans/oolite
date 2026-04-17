run_dwp() {
    # First parameter is GNUstep object directory
    # second parameter is program directory
    local DWP_TOOL=""

    # 1. Determine if we are using Clang or GCC
    if "$CC" -dM -E - < /dev/null 2>/dev/null | grep -q "__clang__"; then
        # 2. Resolve the compiler path to find the version (e.g., LLVM 20)
        # eg. /usr/bin/clang -> ../lib/llvm-20/bin/clang
        local REAL_CLANG_PATH=$(readlink -f "$(command -v "$CC")")

        # Extract digits following 'llvm-' or 'clang-'
        local CLANG_VER=$(echo "$REAL_CLANG_PATH" | grep -oP '(?<=llvm-|clang-)\d+' | head -n 1)

        # Check for a matching versioned llvm-dwp (Ubuntu/Kubuntu style)
        if [[ -n "$CLANG_VER" && -x "/usr/bin/llvm-dwp-$CLANG_VER" ]]; then
            DWP_TOOL="/usr/bin/llvm-dwp-$CLANG_VER"
        # Check for unversioned llvm-dwp (Arch/Fedora style)
        elif command -v llvm-dwp >/dev/null 2>&1; then
            DWP_TOOL=$(command -v llvm-dwp)
        else
            # Fallback: Find the highest versioned llvm-dwp available on the system
            DWP_TOOL=$(ls /usr/bin/llvm-dwp-[0-9]* 2>/dev/null | sort -V | tail -n 1)
        fi
    fi

    # 3. Final Fallback to GNU dwp (if GCC or if LLVM tools were not found)
    if [[ -z "$DWP_TOOL" ]]; then
        DWP_TOOL=$(command -v dwp)
    fi

    # 4. Execution Logic
    if [[ -n "$DWP_TOOL" ]]; then
        # Check for ThinLTO/LTO-Auto folder (Release style)
        if [[ -d "$1/oolite_dwo" ]]; then
            echo "Running $DWP_TOOL with LTO/ThinLTO structure"
            # For LTO, we pack all .dwo files from the specialized subfolder
            "$DWP_TOOL" -e "$1/oolite_dwo/"*.dwo -o "$2/oolite.dwp"
            
        # Check for standard object folder files (Debug/No-LTO style)
        elif ls "$1/oolite.obj/"*.dwo >/dev/null 2>&1; then
            echo "Running $DWP_TOOL with standard object structure"
            "$DWP_TOOL" -e "$1/oolite.obj/"*.dwo -o "$2/oolite.dwp"
            
        else
            echo "❌ No .dwo files found in $1 or $1/oolite_dwo!" >&2
            return 1
        fi        
    else
        echo "Error: No suitable dwp or llvm-dwp utility found!" >&2
        return 1
    fi
}
