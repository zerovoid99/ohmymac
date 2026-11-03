#!/usr/bin/env bash
# Download Catppuccin Mocha wallpapers and set the default one (managed by ~/Code/ohmymac).
# Source: https://github.com/orangci/walls-catppuccin-mocha
# Usage: ./macos/wallpaper.sh [name]   (default: purpled-night)
set -euo pipefail

BASE="https://raw.githubusercontent.com/orangci/walls-catppuccin-mocha/master"
DIR="$HOME/Pictures/Wallpapers/catppuccin-mocha"
WALLS=(purpled-night.jpg minimalist-black-hole.png)
PICK="${1:-purpled-night}"

mkdir -p "$DIR"
for w in "${WALLS[@]}"; do
  [ -f "$DIR/$w" ] || curl -fsSL -o "$DIR/$w" "$BASE/$w"
done

file=$(ls "$DIR" | grep -E "^${PICK}\.(jpg|jpeg|png)$" | head -1)
[ -n "$file" ] || { echo "no wallpaper named '$PICK' in $DIR"; exit 1; }

osascript -e "tell application \"System Events\" to set picture of every desktop to POSIX file \"$DIR/$file\""
echo "wallpaper set: $DIR/$file"
