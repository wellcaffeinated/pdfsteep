#!/usr/bin/env bash
# linuxserver-style entrypoint: remap the baked-in `marker` user to
# PUID/PGID, fix ownership on the mounted dirs, then drop privileges.
set -euo pipefail

PUID="${PUID:-1000}"
PGID="${PGID:-1000}"
IN_DIR="${IN_DIR:-/data/in}"
OUT_DIR="${OUT_DIR:-/data/out}"

echo "[marker-watch] Running as UID=${PUID} GID=${PGID}"
echo "[marker-watch] IN_DIR=${IN_DIR} OUT_DIR=${OUT_DIR} OUTPUT_FORMAT=${OUTPUT_FORMAT:-markdown} TORCH_DEVICE=${TORCH_DEVICE:-cpu}"

groupmod -o -g "$PGID" marker
usermod -o -u "$PUID" marker

mkdir -p "$IN_DIR" "$OUT_DIR" /config
chown -R marker:marker "$IN_DIR" "$OUT_DIR" /config

exec gosu marker /usr/local/bin/watch.sh
