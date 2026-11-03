#!/usr/bin/env bash
# ohmymac — one-command macOS terminal setup.
#   git clone <repo> ~/Code/ohmymac && ~/Code/ohmymac/install.sh
# Idempotent: existing files are backed up, then symlinked to this repo.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
GHOSTTY_DIR="$HOME/Library/Application Support/com.mitchellh.ghostty"

c_blue='\033[1;34m'; c_green='\033[1;32m'; c_yellow='\033[1;33m'; c_dim='\033[2m'; c_off='\033[0m'
step() { printf "\n${c_blue}==>${c_off} %s\n" "$*"; }
ok()   { printf "${c_green} ✓${c_off} %s\n" "$*"; }
warn() { printf "${c_yellow} !${c_off} %s\n" "$*"; }

# ---------- 1. Homebrew ----------
step "Homebrew"
if ! command -v brew >/dev/null 2>&1; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
[ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
ok "brew $(brew --version | head -1 | awk '{print $2}')"

# ---------- 2. Packages ----------
step "Packages from Brewfile"
HOMEBREW_NO_AUTO_UPDATE=1 brew bundle --file="$DOTFILES/Brewfile" --no-upgrade
if [ ! -d /Applications/Ghostty.app ]; then
  brew install --cask ghostty
fi
ok "packages installed"

# ---------- 3. Oh My Zsh ----------
step "Oh My Zsh"
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi
ok "oh-my-zsh ready"

# ---------- 4. Symlinks ----------
# link <source in repo> <target in $HOME>
link() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    ok "already linked: ${dst/#$HOME/~}"
    return
  fi
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    mkdir -p "$BACKUP"
    mv "$dst" "$BACKUP/$(basename "$dst")"
    warn "backed up: ${dst/#$HOME/~} -> ${BACKUP/#$HOME/~}/"
  fi
  ln -s "$src" "$dst"
  ok "linked: ${dst/#$HOME/~} -> ${src/#$DOTFILES/\$DOTFILES}"
}

step "Symlinking dotfiles"
link "$DOTFILES/zsh/.zshrc"                          "$HOME/.zshrc"
link "$DOTFILES/git/.gitconfig"                      "$HOME/.gitconfig"
link "$DOTFILES/starship/starship.toml"              "$HOME/.config/starship.toml"
link "$DOTFILES/fastfetch/config.jsonc"              "$HOME/.config/fastfetch/config.jsonc"
link "$DOTFILES/bat/config"                          "$HOME/.config/bat/config"
link "$DOTFILES/bat/themes/Catppuccin Mocha.tmTheme" "$HOME/.config/bat/themes/Catppuccin Mocha.tmTheme"
link "$DOTFILES/ghostty/config.ghostty"              "$GHOSTTY_DIR/config.ghostty"
link "$DOTFILES/nvim"                                "$HOME/.config/nvim"

# ---------- 5. Finishing touches ----------
step "Finishing touches"
bat cache --build >/dev/null && ok "bat theme cache rebuilt"
touch "$HOME/.hushlogin" && ok "'Last login' banner hidden"
chmod go-w /opt/homebrew/share 2>/dev/null || true
chmod -R go-w /opt/homebrew/share/zsh 2>/dev/null || true
rm -f "$HOME"/.zcompdump* && ok "zsh completion cache reset"

if [ ! -f "$HOME/.gitconfig.local" ]; then
  if [ -t 0 ]; then
    printf "\n  Git identity (stored in ~/.gitconfig.local, not committed)\n"
    read -rp "  Name : " git_name
    read -rp "  Email: " git_email
    printf "[user]\n\tname = %s\n\temail = %s\n" "$git_name" "$git_email" > "$HOME/.gitconfig.local"
    ok "~/.gitconfig.local created"
  else
    warn "create ~/.gitconfig.local with a [user] name/email section"
  fi
fi

if [ -d /Applications/Ghostty.app ]; then
  /Applications/Ghostty.app/Contents/MacOS/ghostty +validate-config >/dev/null 2>&1 \
    && ok "ghostty config valid" || warn "ghostty config has warnings, run: ghostty +validate-config"
fi

printf "\n${c_green}Done!${c_off} Quit Ghostty (Cmd+Q) and reopen it, or run: ${c_dim}exec zsh${c_off}\n\n"
