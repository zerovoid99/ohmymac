# Module definitions for install.sh and uninstall.sh. Sourced, not executed.
# Each module <m> provides:
#   desc_<m>       one-line description
#   status_<m>     exit 0 when installed; may print a short detail ("brew", "v1.2")
#   install_<m>    idempotent install
#   uninstall_<m>  remove it again (PURGE=1 also removes data and shared packages)

MODULES="core cli node rust go ruby python java herdr desktop macos wallpaper"
GROUP_dev="node rust go ruby python java"
PURGE=0

GHOSTTY_DIR="$HOME/Library/Application Support/com.mitchellh.ghostty"
LAZYGIT_DIR="$HOME/Library/Application Support/lazygit"

# ============================================================ core
desc_core() { echo "terminal setup: zsh, Starship, Ghostty, tmux, Neovim, git, CLI tools"; }
status_core() { [ -L "$HOME/.zshrc" ] && [ "$(readlink "$HOME/.zshrc")" = "$DOTFILES/zsh/.zshrc" ]; }

# source|target pairs, shared by install and uninstall
core_links() {
  cat <<EOF
$DOTFILES/zsh/.zshrc|$HOME/.zshrc
$DOTFILES/zsh/.zshenv|$HOME/.zshenv
$DOTFILES/git/.gitconfig|$HOME/.gitconfig
$DOTFILES/starship/starship.toml|$HOME/.config/starship.toml
$DOTFILES/fastfetch/config.jsonc|$HOME/.config/fastfetch/config.jsonc
$DOTFILES/bat/config|$HOME/.config/bat/config
$DOTFILES/bat/themes/Catppuccin Mocha.tmTheme|$HOME/.config/bat/themes/Catppuccin Mocha.tmTheme
$DOTFILES/ghostty/config.ghostty|$GHOSTTY_DIR/config.ghostty
$DOTFILES/nvim|$HOME/.config/nvim
$DOTFILES/tmux/tmux.conf|$HOME/.config/tmux/tmux.conf
$DOTFILES/lazygit/config.yml|$LAZYGIT_DIR/config.yml
$DOTFILES/ssh/config|$HOME/.ssh/config
EOF
}

ensure_brew() {
  if ! has brew; then
    [ -x "$BREW_PREFIX/bin/brew" ] || task_interactive "installing Homebrew" \
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    [ -x "$BREW_PREFIX/bin/brew" ] && eval "$("$BREW_PREFIX/bin/brew" shellenv)"
  fi
  has brew || [ "$DRY_RUN" = 1 ] || die "Homebrew is not available"
}

# An existing ~/.zshenv usually holds personal exports and secrets (API keys). Rather
# than burying it in a backup, it becomes ~/.zshenv.local, which the managed
# ~/.zshenv sources, and is made private (600).
migrate_zshenv() {
  local f="$HOME/.zshenv" local_f="$HOME/.zshenv.local"
  [ -f "$f" ] && [ ! -L "$f" ] || return 0
  if [ -e "$local_f" ]; then
    warn "~/.zshenv and ~/.zshenv.local both exist; ~/.zshenv goes to the backup"
    return 0
  fi
  run mv "$f" "$local_f"
  run chmod 600 "$local_f"
  warn "moved your ~/.zshenv to ~/.zshenv.local (chmod 600); it is still loaded"
}

install_core() {
  step "Homebrew"
  ensure_brew
  ok "brew $(brew --version 2>/dev/null | head -1 | awk '{print $2}')"

  step "Packages"
  task "brew bundle (Brewfile)" env HOMEBREW_NO_AUTO_UPDATE=1 brew bundle --file="$DOTFILES/Brewfile" --no-upgrade
  if [ -d /Applications/Ghostty.app ]; then ok "Ghostty already installed"
  else task "brew install --cask ghostty" brew install --cask ghostty; fi

  step "Oh My Zsh"
  if [ -d "$HOME/.oh-my-zsh" ]; then ok "already installed"
  else
    task "installing Oh My Zsh" env RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
      sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  fi

  step "Config symlinks"
  migrate_zshenv
  local src dst
  while IFS='|' read -r src dst; do link "$src" "$dst"; done <<EOF
$(core_links)
EOF
  run chmod 700 "$HOME/.ssh"
  run chmod 600 "$DOTFILES/ssh/config"
  [ -f "$HOME/.zshenv.local" ] && run chmod 600 "$HOME/.zshenv.local"

  step "tmux plugins"
  local tpm="$HOME/.config/tmux/plugins/tpm"
  if [ -d "$tpm" ]; then ok "TPM present"
  else task "cloning TPM" git_plain clone -q https://github.com/tmux-plugins/tpm "$tpm"; fi
  task "installing tmux plugins" env GIT_CONFIG_GLOBAL=/dev/null "$tpm/bin/install_plugins"

  step "Finishing touches"
  run bat cache --build >/dev/null && ok "bat theme cache rebuilt"
  run touch "$HOME/.hushlogin" && ok "'Last login' banner hidden"
  run chmod go-w "$BREW_PREFIX/share" 2>/dev/null || true
  run chmod -R go-w "$BREW_PREFIX/share/zsh" 2>/dev/null || true
  run rm -f "$HOME"/.zcompdump* && ok "zsh completion cache reset"
  has gh && run gh config set git_protocol ssh && ok "gh uses ssh"
  if [ ! -f "$HOME/.gitconfig.local" ]; then
    if [ -t 0 ] && [ "$DRY_RUN" = 0 ]; then
      printf "\n  Git identity (stored in ~/.gitconfig.local, not committed)\n"
      local git_name git_email
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
  [ -f "$HOME/.ssh/id_ed25519" ] || warn "no ~/.ssh/id_ed25519 yet: GitHub (and Neovim's first plugin sync) need it"
}

uninstall_core() {
  step "Config symlinks"
  local src dst
  while IFS='|' read -r src dst; do unlink_managed "$dst"; done <<EOF
$(core_links)
EOF
  if [ ! -e "$HOME/.zshenv" ] && [ -f "$HOME/.zshenv.local" ]; then
    run mv "$HOME/.zshenv.local" "$HOME/.zshenv"
    ok "moved ~/.zshenv.local back to ~/.zshenv"
  fi
  if [ "$PURGE" = 1 ]; then
    step "Packages and plugins (--purge)"
    run rm -rf "$HOME/.oh-my-zsh" && ok "removed Oh My Zsh"
    run rm -rf "$HOME/.config/tmux/plugins" && ok "removed tmux plugins"
    local formulas casks
    formulas=$(brew bundle list --file="$DOTFILES/Brewfile" --formula 2>/dev/null | tr '\n' ' ')
    casks=$(brew bundle list --file="$DOTFILES/Brewfile" --cask 2>/dev/null | tr '\n' ' ')
    # shellcheck disable=SC2086
    brew_uninstall $formulas
    # shellcheck disable=SC2086
    [ -n "$casks" ] && task "brew uninstall --cask $casks" brew uninstall --cask $casks
  else
    info "packages, Oh My Zsh and tmux plugins kept (add --purge to remove them)"
  fi
}

# ============================================================ cli
CLI_FORMULAS="curl wget rsync"
desc_cli() { echo "newer curl, wget and rsync from Homebrew, ahead of the macOS versions"; }
status_cli() { brew_has curl; }
install_cli() {
  brew_install $CLI_FORMULAS
  info "curl is keg-only; zsh/path.zsh puts $BREW_PREFIX/opt/curl/bin first on PATH"
}
uninstall_cli() { brew_uninstall $CLI_FORMULAS; }

# ============================================================ node
NVM_DIR_="${NVM_DIR:-$HOME/.nvm}"
desc_node() { echo "nvm + Node.js LTS"; }
status_node() {
  [ -s "$NVM_DIR_/nvm.sh" ] || return 1
  local d; d=$(cat "$NVM_DIR_/alias/default" 2>/dev/null) && echo "default $d"
}
nvm_run() { bash -c '. "$0/nvm.sh" && nvm "$@"' "$NVM_DIR_" "$@"; }
install_node() {
  if [ -s "$NVM_DIR_/nvm.sh" ]; then
    ok "nvm present"
  else
    # Manual install from the repo: no install script editing shell profiles.
    task "cloning nvm" git_plain clone -q https://github.com/nvm-sh/nvm.git "$NVM_DIR_"
    if [ "$DRY_RUN" = 0 ]; then
      local tag; tag=$(git -C "$NVM_DIR_" describe --abbrev=0 --tags --match 'v[0-9]*' "$(git -C "$NVM_DIR_" rev-list --tags --max-count=1)")
      task "checking out nvm $tag" git -C "$NVM_DIR_" -c advice.detachedHead=false checkout -q "$tag"
    fi
  fi
  if [ -s "$NVM_DIR_/alias/default" ]; then
    ok "Node default already set ($(cat "$NVM_DIR_/alias/default"))"
  else
    task "nvm install --lts" nvm_run install --lts --latest-npm
    task "nvm alias default lts/*" nvm_run alias default 'lts/*'
  fi
}
uninstall_node() {
  [ -d "$NVM_DIR_" ] || { info "nvm not installed"; return 0; }
  run rm -rf "$NVM_DIR_" && ok "removed $(tilde "$NVM_DIR_") (nvm and every Node version)"
}

# ============================================================ rust
desc_rust() { echo "rustup + stable Rust toolchain"; }
status_rust() { [ -x "$HOME/.cargo/bin/rustup" ]; }
install_rust() {
  if status_rust; then
    ok "rustup present"
    task "rustup update" "$HOME/.cargo/bin/rustup" update
    return
  fi
  if brew_has rust || brew_has rustup; then
    warn "Rust from Homebrew found; it can shadow rustup. Consider: brew uninstall rust"
  fi
  task "installing rustup" sh -c "curl --proto '=https' --tlsv1.2 -fsSL https://sh.rustup.rs | sh -s -- -y --no-modify-path"
}
uninstall_rust() {
  status_rust || { info "rustup not installed"; return 0; }
  task "rustup self uninstall" "$HOME/.cargo/bin/rustup" self uninstall -y
}

# ============================================================ go
desc_go() { echo "Go (Homebrew; tools go to ~/go/bin)"; }
status_go() { brew_has go && return 0; [ -x /usr/local/go/bin/go ] && echo "go.dev installer"; }
install_go() {
  if [ -x /usr/local/go/bin/go ]; then ok "Go from go.dev present"; return; fi
  brew_install go
}
uninstall_go() {
  brew_uninstall go
  info "~/go (your modules and installed tools) is kept"
}

# ============================================================ ruby
desc_ruby() { echo "rbenv + latest stable Ruby (compiled, takes a few minutes)"; }
status_ruby() { has rbenv || [ -x "$BREW_PREFIX/bin/rbenv" ] || return 1; "$BREW_PREFIX/bin/rbenv" global 2>/dev/null; }
install_ruby() {
  brew_install rbenv ruby-build libyaml
  [ "$DRY_RUN" = 1 ] && { info "would install the latest stable Ruby with rbenv"; return; }
  local rbenv="$BREW_PREFIX/bin/rbenv" latest
  latest=$("$rbenv" install -l 2>/dev/null | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | tail -1)
  [ -n "$latest" ] || { err "could not find the latest Ruby version"; return 1; }
  if "$rbenv" versions --bare | grep -qx "$latest"; then ok "Ruby $latest present"
  else task "rbenv install $latest" "$rbenv" install "$latest"; fi
  if [ "$("$rbenv" global)" = system ]; then run "$rbenv" global "$latest" && ok "rbenv global $latest"; fi
  if brew_has ruby; then info "Ruby from Homebrew is still installed; rbenv shims take precedence"; fi
}
uninstall_ruby() {
  brew_uninstall rbenv ruby-build
  [ -d "$HOME/.rbenv" ] && run rm -rf "$HOME/.rbenv" && ok "removed ~/.rbenv (every Ruby version)"
  [ "$PURGE" = 1 ] && brew_uninstall libyaml
  return 0
}

# ============================================================ python
desc_python() { echo "uv (standalone, self-updating) + latest Python"; }
status_python() {
  [ -x "$HOME/.local/bin/uv" ] && return 0
  brew_has uv && echo "brew"
}
install_python() {
  if [ -x "$HOME/.local/bin/uv" ]; then
    task "uv self update" "$HOME/.local/bin/uv" self update
  elif brew_has uv; then
    ok "uv from Homebrew present (brew upgrade uv keeps it current)"
  else
    task "installing uv" sh -c "curl -LsSf https://astral.sh/uv/install.sh | env UV_NO_MODIFY_PATH=1 sh"
  fi
  local uv="$HOME/.local/bin/uv"; [ -x "$uv" ] || uv=uv
  task "uv python install" "$uv" python install
}
uninstall_python() {
  if [ -x "$HOME/.local/bin/uv" ]; then
    run "$HOME/.local/bin/uv" cache clean >/dev/null 2>&1 || true
    run rm -rf "$HOME/.local/share/uv"
    run rm -f "$HOME/.local/bin/uv" "$HOME/.local/bin/uvx"
    ok "removed uv, its Pythons and tools"
  elif brew_has uv; then
    [ "$PURGE" = 1 ] && run rm -rf "$HOME/.local/share/uv"
    brew_uninstall uv
  else
    info "uv not installed"
  fi
}

# ============================================================ java
desc_java() { echo "Eclipse Temurin JDK (latest)"; }
status_java() { /usr/libexec/java_home >/dev/null 2>&1 && /usr/libexec/java_home 2>/dev/null | sed -E 's#.*/([^/]+)/Contents/Home#\1#'; }
install_java() {
  if status_java >/dev/null; then ok "a JDK is already installed"; return; fi
  task_interactive "brew install --cask temurin (asks for your password)" brew install --cask temurin
}
uninstall_java() {
  # temurin, temurin@21, temurin@25, ...
  local casks; casks=$(printf '%s' "$BREW_CASKS" | grep -E '^temurin(@[0-9]+)?$' | tr '\n' ' ')
  if [ -n "${casks// /}" ]; then
    # shellcheck disable=SC2086
    task_interactive "brew uninstall --cask $casks(asks for your password)" brew uninstall --cask $casks
  else
    info "no Temurin cask from Homebrew; other JDKs are left alone"
  fi
}

# ============================================================ herdr
desc_herdr() { echo "Herdr, a desktop app for terminals and coding agents (herdr.dev)"; }
status_herdr() { [ -d /Applications/Herdr.app ] || [ -d "$HOME/Applications/Herdr.app" ]; }
install_herdr() {
  # Herdr updates itself, so it is only installed when missing.
  if status_herdr; then ok "Herdr already installed"; return; fi
  task "brew install --cask herdr-app" brew install --cask herdr-app
  info "Herdr offers to install herdr-core when it first opens"
}
uninstall_herdr() {
  if brew_has_cask herdr-app; then task "brew uninstall --cask herdr-app" brew uninstall --cask herdr-app
  elif [ -d "$HOME/Applications/Herdr.app" ]; then run rm -rf "$HOME/Applications/Herdr.app" && ok "removed ~/Applications/Herdr.app"
  fi
  run rm -f "$HOME/.local/bin/herdr-app"
  if [ "$PURGE" = 1 ]; then
    run rm -f "$HOME/.local/bin/herdr-core" "$HOME/.local/bin/hc"
    run rm -rf "$HOME/.config/herdr-app"
    ok "removed herdr-core and ~/.config/herdr-app"
  else
    info "herdr-core and ~/.config/herdr-app kept (add --purge to remove them)"
  fi
}

# ============================================================ desktop
desc_desktop() { echo "AeroSpace tiling + JankyBorders, auto-hide menu bar"; }
status_desktop() { [ -d /Applications/AeroSpace.app ]; }
install_desktop() {
  task "brew bundle (Brewfile.desktop)" env HOMEBREW_NO_AUTO_UPDATE=1 brew bundle --file="$DOTFILES/Brewfile.desktop" --no-upgrade
  link "$DOTFILES/aerospace/aerospace.toml" "$HOME/.config/aerospace/aerospace.toml"
  link "$DOTFILES/borders/bordersrc"        "$HOME/.config/borders/bordersrc"
  run "$DOTFILES/macos/desktop.sh" >/dev/null && ok "menu bar / Spaces defaults applied"
  if [ -d /Applications/AeroSpace.app ]; then
    run open -a AeroSpace && ok "AeroSpace started (grant Accessibility access when asked)"
  fi
}
uninstall_desktop() {
  run osascript -e 'tell application "System Events" to delete login item "AeroSpace"' >/dev/null 2>&1 || true
  run pkill -x AeroSpace 2>/dev/null || true
  run pkill -x borders 2>/dev/null || true
  if brew_has_cask aerospace; then task "brew uninstall --cask aerospace" brew uninstall --zap --cask aerospace; fi
  brew_uninstall borders
  unlink_managed "$HOME/.config/aerospace/aerospace.toml"
  unlink_managed "$HOME/.config/borders/bordersrc"
  run rmdir "$HOME/.config/aerospace" "$HOME/.config/borders" 2>/dev/null || true
  run "$DOTFILES/macos/desktop.sh" --revert >/dev/null && ok "menu bar / Spaces back to macOS defaults"
  info "remove AeroSpace from System Settings → Privacy & Security → Accessibility if listed"
}

# ============================================================ macos
desc_macos() { echo "developer-friendly macOS defaults (keyboard, Dock, Finder, screenshots)"; }
status_macos() { [ "$(defaults read NSGlobalDomain ApplePressAndHoldEnabled 2>/dev/null)" = 0 ]; }
install_macos() { run "$DOTFILES/macos/defaults.sh" >/dev/null && ok "defaults applied (keyboard changes need a logout)"; }
uninstall_macos() { run "$DOTFILES/macos/defaults.sh" --revert >/dev/null && ok "defaults reverted to macOS values"; }

# ============================================================ wallpaper
WALL_DIR="$HOME/Pictures/Wallpapers/catppuccin-mocha"
desc_wallpaper() { echo "Catppuccin Mocha wallpaper"; }
status_wallpaper() { [ -d "$WALL_DIR" ]; }
install_wallpaper() {
  if run "$DOTFILES/macos/wallpaper.sh" >/dev/null; then ok "wallpaper set"
  else warn "wallpaper not set (offline or no Automation access), run: macos/wallpaper.sh"; fi
}
uninstall_wallpaper() {
  [ -d "$WALL_DIR" ] && run rm -rf "$WALL_DIR" && ok "removed $(tilde "$WALL_DIR")"
  info "macOS keeps showing the current wallpaper until you pick another one"
}
