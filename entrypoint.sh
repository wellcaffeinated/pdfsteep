#!/usr/bin/env bash
# linuxserver-style entrypoint: remap the baked-in `watcher` user to
# PUID/PGID, fix ownership on the mounted dirs, then drop privileges.
set -euo pipefail

PUID="${PUID:-1000}"
PGID="${PGID:-1000}"
IN_DIR="${IN_DIR:-/data/in}"
OUT_DIR="${OUT_DIR:-/data/out}"

echo "[pdfsteep] Running as UID=${PUID} GID=${PGID}"
echo "[pdfsteep] IN_DIR=${IN_DIR} OUT_DIR=${OUT_DIR}"

groupmod -o -g "$PGID" watcher
usermod -o -u "$PUID" watcher

mkdir -p "$IN_DIR" "$OUT_DIR"
chown -R watcher:watcher "$IN_DIR" "$OUT_DIR"

exec gosu watcher /usr/local/bin/watch.sh
