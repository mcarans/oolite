#!/bin/bash

run_script() {
    SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

    source "$SCRIPT_DIR/create_venv_fn.sh"

    create_venv()

    if ! python -m pip install --upgrade weasyprint; then
        echo "❌ WeasyPrint install failed or Pango dependencies not installed!">&2
        deactivate
        return 1
    fi

    if ! python -m weasyprint --version >/dev/null 2>&1; then
        echo "❌ WeasyPrint install failed or Pango dependencies not installed!">&2
        deactivate
        return 1
    fi
    deactivate
}
