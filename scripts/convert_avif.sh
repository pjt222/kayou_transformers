#!/usr/bin/env bash
# Convert all AVIF files in manual_downloads/ to JPEG in manual_downloads/cards/
# Requires: ffmpeg with libdav1d support
# Usage: bash scripts/convert_avif.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
SRC_DIR="$REPO_ROOT/manual_downloads"
DST_DIR="$SRC_DIR/cards"

if [ ! -d "$SRC_DIR" ]; then
  echo "Source directory not found: $SRC_DIR"
  exit 1
fi

mkdir -p "$DST_DIR"

converted=0
skipped=0

for avif_file in "$SRC_DIR"/*.avif; do
  [ -f "$avif_file" ] || continue

  base="$(basename "$avif_file" .avif)"
  jpg_file="$DST_DIR/${base}.jpg"

  if [ -f "$jpg_file" ]; then
    skipped=$((skipped + 1))
    continue
  fi

  ffmpeg -loglevel warning -i "$avif_file" "$jpg_file"
  converted=$((converted + 1))
done

echo "Done. Converted: $converted, Skipped (already exist): $skipped"
