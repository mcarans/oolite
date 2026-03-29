#!/bin/bash

build_referencesheet() {
    SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
    pushd "$SCRIPT_DIR"

    PDF_DIR="docs/assets/pdfs"
    cd ..
    mkdir -p "build/documentation/$PDF_DIR"
    cd build/documentation/
    rm -rf "$PDF_DIR/reference.pdf"

    PKG_OK=$(command -v soffice)
    if [ "" = "$PKG_OK" ]; then
        if [[ "$FAIL_SOFFICENOTFOUND" == "Y" ]]; then
            echo "❌ LibreOffice soffice not found!" >&2
            return 1
        else
            echo "%PDF-1.0" > "$PDF_DIR/reference.pdf"
            popd
            return 0
        fi
    fi

    cp ../../Doc/OoliteRS.odt ./reference.odt
    if ! soffice --headless --convert-to pdf --outdir ./docs/assets reference.odt; then
        echo "❌ PDF conversion with soffice failed!" >&2
        return 1
    fi
    echo "✅ PDF conversion completed successfully"
    popd
}
