#!/usr/bin/env bash
# Developer-friendly macOS defaults (managed by ~/Code/ohmymac).
# All user-level. Run: ./macos/defaults.sh   Undo: ./macos/defaults.sh --revert
set -euo pipefail

# def <domain> <key> <type> <value>: write the value, or delete it under --revert so
# macOS falls back to its own default.
REVERT=0; [ "${1:-}" = "--revert" ] && REVERT=1
def() {
  if [ "$REVERT" = 1 ]; then defaults delete "$1" "$2" 2>/dev/null || true
  else defaults write "$@"; fi
}

# ---- Keyboard: fast repeat, hold-to-repeat (needed for vim-style navigation) ----
def NSGlobalDomain KeyRepeat -int 2
def NSGlobalDomain InitialKeyRepeat -int 15
def NSGlobalDomain ApplePressAndHoldEnabled -bool false
# no auto-correct / smart quotes / smart dashes: they corrupt code
def NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
def NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
def NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
def NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
def NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false

# ---- Dock ----
def com.apple.dock autohide -bool true
def com.apple.dock autohide-delay -float 0
def com.apple.dock autohide-time-modifier -float 0.3
def com.apple.dock tilesize -int 42
def com.apple.dock show-recents -bool false
def com.apple.dock minimize-to-application -bool true

# ---- Finder ----
def NSGlobalDomain AppleShowAllExtensions -bool true
def com.apple.finder AppleShowAllFiles -bool true
def com.apple.finder ShowPathbar -bool true
def com.apple.finder ShowStatusBar -bool true
def com.apple.finder FXDefaultSearchScope -string "SCcf"      # search current folder
def com.apple.finder FXEnableExtensionChangeWarning -bool false
def com.apple.finder FXPreferredViewStyle -string "Nlsv"      # list view
def com.apple.finder _FXSortFoldersFirst -bool true
def com.apple.finder NewWindowTarget -string "PfHm"           # new windows open at ~
def com.apple.desktopservices DSDontWriteNetworkStores -bool true
def com.apple.desktopservices DSDontWriteUSBStores -bool true

# ---- Screenshots ----
[ "$REVERT" = 1 ] || mkdir -p "$HOME/Pictures/Screenshots"
def com.apple.screencapture location -string "$HOME/Pictures/Screenshots"
def com.apple.screencapture disable-shadow -bool true
def com.apple.screencapture type -string "png"

# ---- Trackpad ----
def com.apple.AppleMultitouchTrackpad Clicking -bool true
def com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
def NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# ---- Misc ----
def NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true   # expanded save dialogs
def NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false  # save to disk, not iCloud

for app in Dock Finder SystemUIServer; do killall "$app" >/dev/null 2>&1 || true; done
if [ "$REVERT" = 1 ]; then echo "macOS defaults reverted"
else echo "macOS defaults applied (some keyboard settings need a logout to take effect)"; fi
