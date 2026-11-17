#!/usr/bin/env bash
# macOS defaults for the AeroSpace desktop (managed by ~/Code/ohmymac).
# Run by `install.sh desktop`, or on its own: ./macos/desktop.sh   Undo: --revert
set -euo pipefail

# def <domain> <key> <type> <value>: write the value, or delete it under --revert so
# macOS falls back to its own default.
REVERT=0; [ "${1:-}" = "--revert" ] && REVERT=1
def() {
  if [ "$REVERT" = 1 ]; then defaults delete "$1" "$2" 2>/dev/null || true
  else defaults write "$@"; fi
}

# ---- Menu bar: auto-hide (edge-to-edge windows with AeroSpace) ----
def NSGlobalDomain _HIHideMenuBar -bool true
def NSGlobalDomain AppleMenuBarVisibleInFullscreen -bool false

# ---- Mission Control / Spaces (recommended for AeroSpace) ----
def com.apple.dock mru-spaces -bool false          # don't rearrange spaces by recent use
def com.apple.dock expose-group-apps -bool true    # group windows by app
def com.apple.spaces spans-displays -bool false     # displays have separate spaces

for app in Dock SystemUIServer; do killall "$app" >/dev/null 2>&1 || true; done
if [ "$REVERT" = 1 ]; then echo "desktop defaults reverted"
else echo "desktop defaults applied (Spaces settings need a logout to take effect)"; fi
