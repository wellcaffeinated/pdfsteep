#!/usr/bin/env bash
# Watches IN_DIR for PDFs and converts each one to markdown in OUT_DIR via
# pymupdf4llm (convert.py). Runs as an unprivileged user, dropped to by
# entrypoint.sh.
set -uo pipefail

IN_DIR="${IN_DIR:-/data/in}"
OUT_DIR="${OUT_DIR:-/data/out}"

convert_pdf() {
    local pdf="$1"
    local name
    name="$(basename "$pdf")"

    # convert.py writes to OUT_DIR/<pdf-basename-without-ext>/
    echo "[pdfsteep] Converting ${name}"
    if python3 /usr/local/bin/convert.py "$pdf" "$OUT_DIR"; then
        echo "[pdfsteep] Done: ${name}"
    else
        echo "[pdfsteep] FAILED: ${name}" >&2
    fi
}

# Pick up anything already sitting in IN_DIR before the watch loop starts.
shopt -s nullglob nocaseglob
for f in "$IN_DIR"/*.pdf; do
    convert_pdf "$f"
done
shopt -u nullglob nocaseglob

echo "[pdfsteep] Watching ${IN_DIR} for new PDFs..."
inotifywait -m -q -e close_write -e moved_to --format '%f' "$IN_DIR" | while read -r filename; do
    case "$filename" in
        *.pdf|*.PDF)
            convert_pdf "$IN_DIR/$filename"
            ;;
    esac
done
