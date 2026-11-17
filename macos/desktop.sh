#!/usr/bin/env bash
# macOS defaults for the AeroSpace desktop (managed by ~/Code/ohmymac).
# Run by `install.sh --desktop`, or on its own: ./macos/desktop.sh
# Reversible with `defaults delete <domain> <key>`.
set -euo pipefail

# ---- Menu bar: auto-hide (edge-to-edge windows with AeroSpace) ----
defaults write NSGlobalDomain _HIHideMenuBar -bool true
defaults write NSGlobalDomain AppleMenuBarVisibleInFullscreen -bool false

# ---- Mission Control / Spaces (recommended for AeroSpace) ----
defaults write com.apple.dock mru-spaces -bool false          # don't rearrange spaces by recent use
defaults write com.apple.dock expose-group-apps -bool true    # group windows by app
defaults write com.apple.spaces spans-displays -bool false     # displays have separate spaces

for app in Dock SystemUIServer; do killall "$app" >/dev/null 2>&1 || true; done
echo "desktop defaults applied (Spaces settings need a logout to take effect)"
