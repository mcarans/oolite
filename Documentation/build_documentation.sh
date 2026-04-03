#!/bin/bash

run_script() {
    SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
    pushd "$SCRIPT_DIR"

    rm -rf ../build/documentation
    source ./build_doxygen_fn.sh
    source ./build_referencesheet_fn.sh

    if ! build_doxygen; then
        return 1
    fi

    if ! build_referencesheet; then
        return 1
    fi

    if python3 --version >/dev/null 2>&1; then
        local PYTHON_CMD="python3"
    elif python --version >/dev/null 2>&1; then
        local PYTHON_CMD="python"
    else
      echo "❌ Python executable not found" >&2
      return 1
    fi

    local VENV_DIR="../.venv"
    if [ -d "$VENV_DIR/Scripts" ]; then
        source "$VENV_DIR/Scripts/activate"
    else
        source "$VENV_DIR/bin/activate"
    fi

    cd ../build/documentation/
    cp -r ../../Documentation/* ./
    cp ../../LICENSE.md ./docs/license.md

    if ! mkdocs build --clean; then
        echo "❌ MKDocs build failed!" >&2
        return 1
    fi
    echo "✅ MKDocs build completed successfully"

    deactivate
    popd
}

run_script "$@"
status=$?


# Exit only if not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    exit $status
fi

