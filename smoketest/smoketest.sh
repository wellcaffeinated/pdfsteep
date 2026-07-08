#!/usr/bin/env bash
# End-to-end smoketest: downloads a real PDF from arXiv, drops it in a temp
# data dir's "in" subfolder, brings up the compose stack pointed at that temp
# dir, waits for the converted markdown to show up in "out", then tears
# everything down and removes the temp dir it created.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE_FILE="${ROOT_DIR}/docker-compose.yml"
PROJECT_NAME="pdfsteep-smoketest"

PDF_URL="${SMOKETEST_PDF_URL:-https://arxiv.org/pdf/1706.03762}"  # "Attention Is All You Need"
PDF_NAME="smoketest"
TIMEOUT="${SMOKETEST_TIMEOUT:-60}"  # no ML inference, conversion is near-instant
POLL_INTERVAL=2

TMP_DIR="$(mktemp -d "${ROOT_DIR}/smoketest/tmp.XXXXXX")"
TMP_IN="${TMP_DIR}/data/in"
TMP_OUT="${TMP_DIR}/data/out"
mkdir -p "$TMP_IN" "$TMP_OUT"

export DATA_DIR="${TMP_DIR}/data"  # container's default IN_DIR/OUT_DIR (/data/in, /data/out) live under here

cleanup() {
    local status=$?
    echo "[smoketest] Tearing down compose stack..."
    docker compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" down --remove-orphans >/dev/null 2>&1 || true
    echo "[smoketest] Removing ${TMP_DIR}"
    rm -rf "$TMP_DIR"
    exit "$status"
}
trap cleanup EXIT

echo "[smoketest] Downloading sample PDF from ${PDF_URL}..."
curl -fsSL "$PDF_URL" -o "${TMP_IN}/${PDF_NAME}.pdf"

echo "[smoketest] Building image..."
docker compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" build

echo "[smoketest] Starting container (DATA_DIR=${DATA_DIR})..."
docker compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" up -d

OUT_FILE="${TMP_OUT}/${PDF_NAME}/${PDF_NAME}.md"
echo "[smoketest] Waiting up to ${TIMEOUT}s for ${OUT_FILE}..."
elapsed=0
while [ ! -f "$OUT_FILE" ]; do
    if [ "$elapsed" -ge "$TIMEOUT" ]; then
        echo "[smoketest] TIMEOUT waiting for conversion output" >&2
        docker compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" logs
        exit 1
    fi
    sleep "$POLL_INTERVAL"
    elapsed=$((elapsed + POLL_INTERVAL))
done

if [ -s "$OUT_FILE" ]; then
    echo "[smoketest] PASS: ${OUT_FILE} exists and is non-empty"
    echo "[smoketest] Preview:"
    head -n 10 "$OUT_FILE"
else
    echo "[smoketest] FAIL: ${OUT_FILE} exists but is empty" >&2
    exit 1
fi
