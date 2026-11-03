#!/usr/bin/env bash
# Developer-friendly macOS defaults (managed by ~/Code/ohmymac).
# All user-level, reversible with `defaults delete <domain> <key>`. Run: ./macos/defaults.sh
set -euo pipefail

# ---- Keyboard: fast repeat, hold-to-repeat (needed for vim-style navigation) ----
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
# no auto-correct / smart quotes / smart dashes: they corrupt code
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false

# ---- Dock ----
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0.3
defaults write com.apple.dock tilesize -int 42
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock minimize-to-application -bool true

# ---- Menu bar: auto-hide (edge-to-edge windows with AeroSpace) ----
defaults write NSGlobalDomain _HIHideMenuBar -bool true
defaults write NSGlobalDomain AppleMenuBarVisibleInFullscreen -bool false

# ---- Mission Control / Spaces (recommended for AeroSpace) ----
defaults write com.apple.dock mru-spaces -bool false          # don't rearrange spaces by recent use
defaults write com.apple.dock expose-group-apps -bool true    # group windows by app
defaults write com.apple.spaces spans-displays -bool false     # displays have separate spaces

# ---- Finder ----
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"      # search current folder
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"      # list view
defaults write com.apple.finder _FXSortFoldersFirst -bool true
defaults write com.apple.finder NewWindowTarget -string "PfHm"           # new windows open at ~
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# ---- Screenshots ----
mkdir -p "$HOME/Pictures/Screenshots"
defaults write com.apple.screencapture location -string "$HOME/Pictures/Screenshots"
defaults write com.apple.screencapture disable-shadow -bool true
defaults write com.apple.screencapture type -string "png"

# ---- Trackpad ----
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# ---- Misc ----
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true   # expanded save dialogs
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false  # save to disk, not iCloud

for app in Dock Finder SystemUIServer; do killall "$app" >/dev/null 2>&1 || true; done
echo "macOS defaults applied (some keyboard settings need a logout to take effect)"
