#!/bin/bash

run_script() {
    local SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

    source "$SCRIPT_DIR/create_venv_fn.sh"

    create_venv()

    if python -m mkdocs --version >/dev/null 2>&1; then
        echo "✅ MkDocs is already installed."
        return 0
    fi

    if python -m pip install -r requirements.txt; then
        echo "❌ Could not install MKDocs and its requirements!" >&2
        deactivate
        return 1
    fi
    deactivate
}

run_script "$@"
status=$?


# Exit only if not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    exit $status
fi

