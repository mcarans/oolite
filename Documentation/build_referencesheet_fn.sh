#!/bin/bash

build_referencesheet() {
    SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
    pushd "$SCRIPT_DIR"

    local PDF_DIR="docs/assets/pdfs"
    cd ..
    mkdir -p "build/documentation/$PDF_DIR"
    cd build/documentation/
    local PDF_FILE="$PDF_DIR/reference.pdf"
    rm -rf "$PDF_FILE"

    if command -v soffice >/dev/null 2>&1; then
        if [[ "$FAIL_SOFFICENOTFOUND" == "Y" ]]; then
            echo "❌ LibreOffice soffice not found!" >&2
            return 1
        else
            echo "📝 Creating blank PDF for $PDF_FILE (Dependencies missing)"
            echo "%PDF-1.0" > "$PDF_FILE"
            popd
            return 0
        fi
    fi

    cp ../../Doc/OoliteRS.odt ./reference.odt
    if ! soffice --headless --convert-to pdf --outdir ./docs/assets reference.odt; then
        if [[ "$FAIL_SOFFICENOTFOUND" == "Y" ]]; then
            echo "❌ PDF conversion with soffice failed!" >&2
            return 1
        else
            echo "📝 Creating blank PDF for $PDF_FILE (Dependencies missing)"
            echo "%PDF-1.0" > "$PDF_FILE"
        fi
    fi
    echo "✅ PDF conversion completed successfully"
    popd
}
