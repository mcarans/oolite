#!/bin/bash

check_rename() {
    # Initialize local variables
    local package_name="$1"
    local pattern="$2"
    local search_term="$3"
    local fullname
    local filename
    local newname
    local files

    # 1. Determine the logical full name
    if [ -z "$search_term" ]; then
        fullname="$package_name"
    else
        fullname="${package_name}_${search_term}"
    fi

    # 2. Find the file safely using an array (handles spaces better than ls)
    files=($pattern)
    filename="${files[0]}"

    if [ ! -e "$filename" ]; then
        echo "❌ No file matching $pattern found!" >&2
        return 1
    fi

    # 3. Handle the optional rename
    if [ -n "$search_term" ]; then
        # Replace the package name part with the fullname part
        newname="${filename/$package_name/$fullname}"

        # Only move if the name actually needs to change
        if [ "$filename" != "$newname" ]; then
            mv "$filename" "$newname"
            filename="$newname"
        fi
    fi

    # Output the result for the caller to capture
    echo "${filename}" "${fullname}"
}