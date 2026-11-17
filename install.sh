#!/usr/bin/env bash
# ohmymac — one-command macOS terminal setup.
#   git clone <repo> ~/Code/ohmymac && ~/Code/ohmymac/install.sh [options]
# Idempotent: existing files are backed up, then symlinked to this repo.
# Only the terminal setup is installed by default; everything else is opt-in.
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: install.sh [options]

Installs the terminal setup: Homebrew packages, Oh My Zsh, Ghostty, Starship,
tmux, Neovim, git, lazygit, bat and ssh configs. Optional modules are off
unless you pass their flag:

  --desktop     AeroSpace tiling + JankyBorders, and the menu bar / Spaces
                defaults they need (macos/desktop.sh)
  --macos       developer-friendly macOS defaults (macos/defaults.sh)
  --wallpaper   download and set a Catppuccin Mocha wallpaper
  --all         all of the above
  -h, --help    show this help
EOF
}

WITH_DESKTOP=0; WITH_MACOS=0; WITH_WALLPAPER=0
for arg in "$@"; do
  case "$arg" in
    --desktop)   WITH_DESKTOP=1 ;;
    --macos)     WITH_MACOS=1 ;;
    --wallpaper) WITH_WALLPAPER=1 ;;
    --all)       WITH_DESKTOP=1; WITH_MACOS=1; WITH_WALLPAPER=1 ;;
    -h|--help)   usage; exit 0 ;;
    *)           printf "unknown option: %s\n\n" "$arg" >&2; usage >&2; exit 1 ;;
  esac
done

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
GHOSTTY_DIR="$HOME/Library/Application Support/com.mitchellh.ghostty"
LAZYGIT_DIR="$HOME/Library/Application Support/lazygit"

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
if [ "$WITH_DESKTOP" = 1 ]; then
  HOMEBREW_NO_AUTO_UPDATE=1 brew bundle --file="$DOTFILES/Brewfile.desktop" --no-upgrade
fi
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
link "$DOTFILES/tmux/tmux.conf"                      "$HOME/.config/tmux/tmux.conf"
link "$DOTFILES/lazygit/config.yml"                  "$LAZYGIT_DIR/config.yml"
link "$DOTFILES/ssh/config"                          "$HOME/.ssh/config"
if [ "$WITH_DESKTOP" = 1 ]; then
  link "$DOTFILES/aerospace/aerospace.toml"          "$HOME/.config/aerospace/aerospace.toml"
  link "$DOTFILES/borders/bordersrc"                 "$HOME/.config/borders/bordersrc"
fi
chmod 700 "$HOME/.ssh"; chmod 600 "$DOTFILES/ssh/config"

# ---------- 5. tmux plugins (TPM) ----------
step "tmux plugins"
if [ ! -d "$HOME/.config/tmux/plugins/tpm" ]; then
  # ignore ~/.gitconfig: its https->ssh rewrite fails before an SSH key is set up
  GIT_CONFIG_GLOBAL=/dev/null git clone -q https://github.com/tmux-plugins/tpm "$HOME/.config/tmux/plugins/tpm"
fi
GIT_CONFIG_GLOBAL=/dev/null "$HOME/.config/tmux/plugins/tpm/bin/install_plugins" >/dev/null && ok "tmux plugins installed"

# ---------- 6. Optional macOS tweaks ----------
if [ "$WITH_MACOS" = 1 ] || [ "$WITH_DESKTOP" = 1 ] || [ "$WITH_WALLPAPER" = 1 ]; then
  step "macOS tweaks"
fi
if [ "$WITH_MACOS" = 1 ]; then
  "$DOTFILES/macos/defaults.sh" >/dev/null && ok "defaults applied"
fi
if [ "$WITH_DESKTOP" = 1 ]; then
  "$DOTFILES/macos/desktop.sh" >/dev/null && ok "menu bar / Spaces defaults applied"
fi
if [ "$WITH_WALLPAPER" = 1 ]; then
  if "$DOTFILES/macos/wallpaper.sh" >/dev/null; then
    ok "catppuccin wallpaper set"
  else
    warn "wallpaper not set (offline or no Automation access), run: macos/wallpaper.sh"
  fi
fi

# ---------- 7. Finishing touches ----------
step "Finishing touches"
bat cache --build >/dev/null && ok "bat theme cache rebuilt"
touch "$HOME/.hushlogin" && ok "'Last login' banner hidden"
chmod go-w /opt/homebrew/share 2>/dev/null || true
chmod -R go-w /opt/homebrew/share/zsh 2>/dev/null || true
rm -f "$HOME"/.zcompdump* && ok "zsh completion cache reset"
command -v gh >/dev/null && gh config set git_protocol ssh && ok "gh uses ssh"

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

if [ "$WITH_DESKTOP" = 1 ] && [ -d /Applications/AeroSpace.app ]; then
  open -a AeroSpace && ok "AeroSpace started (grant Accessibility access when asked)"
fi

printf "\n${c_green}Done!${c_off} Quit Ghostty (Cmd+Q) and reopen it, or run: ${c_dim}exec zsh${c_off}\n"
skipped=()
[ "$WITH_DESKTOP" = 1 ]   || skipped+=(--desktop)
[ "$WITH_MACOS" = 1 ]     || skipped+=(--macos)
[ "$WITH_WALLPAPER" = 1 ] || skipped+=(--wallpaper)
if [ ${#skipped[@]} -gt 0 ]; then
  printf "${c_dim}Optional modules not installed: %s (see install.sh --help)${c_off}\n" "${skipped[*]}"
fi
printf "\n"
