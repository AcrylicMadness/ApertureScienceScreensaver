#!/bin/bash
# Installs ApertureScienceScreensaver.saver for the current user.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SAVER_NAME="ApertureScienceScreensaver.saver"
SRC="$DIR/$SAVER_NAME"
DEST_DIR="$HOME/Library/Screen Savers"

if [ ! -d "$SRC" ]; then
    echo "error: $SAVER_NAME not found next to this script." >&2
    exit 1
fi

mkdir -p "$DEST_DIR"

echo "Installing to $DEST_DIR..."
rm -rf "$DEST_DIR/$SAVER_NAME"
cp -R "$SRC" "$DEST_DIR/"

echo "Done. Opening Screen Saver settings..."
open "x-apple.systempreferences:com.apple.Screen-Saver-Settings.extension" 2>/dev/null || true

echo "Select 'ApertureScienceScreensaver' from the list to preview it."
