#!/usr/bin/env bash
# Watches IN_DIR for PDFs and converts each one to markdown in OUT_DIR via
# marker (https://github.com/datalab-to/marker). Runs as an unprivileged
# user, dropped to by entrypoint.sh.
set -uo pipefail

IN_DIR="${IN_DIR:-/data/in}"
OUT_DIR="${OUT_DIR:-/data/out}"
OUTPUT_FORMAT="${OUTPUT_FORMAT:-markdown}"
MARKER_EXTRA_ARGS="${MARKER_EXTRA_ARGS:-}"

convert_pdf() {
    local pdf="$1"
    local name
    name="$(basename "$pdf")"

    # marker_single writes to OUT_DIR/<pdf-basename-without-ext>/
    echo "[marker-watch] Converting ${name}"
    # shellcheck disable=SC2086
    if marker_single "$pdf" --output_dir "$OUT_DIR" --output_format "$OUTPUT_FORMAT" $MARKER_EXTRA_ARGS; then
        echo "[marker-watch] Done: ${name}"
    else
        echo "[marker-watch] FAILED: ${name}" >&2
    fi
}

# Pick up anything already sitting in IN_DIR before the watch loop starts.
shopt -s nullglob nocaseglob
for f in "$IN_DIR"/*.pdf; do
    convert_pdf "$f"
done
shopt -u nullglob nocaseglob

echo "[marker-watch] Watching ${IN_DIR} for new PDFs..."
inotifywait -m -q -e close_write -e moved_to --format '%f' "$IN_DIR" | while read -r filename; do
    case "$filename" in
        *.pdf|*.PDF)
            convert_pdf "$IN_DIR/$filename"
            ;;
    esac
done
