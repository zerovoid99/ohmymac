# ohmymac

macOS dev environment: **Ghostty + Oh My Zsh + Starship + tmux + Neovim (LazyVim) + AeroSpace tiling**, Catppuccin Mocha everywhere, JetBrainsMono Nerd Font.

## Install (fresh Mac)

```sh
git clone <this-repo-url> ~/Code/ohmymac
~/Code/ohmymac/install.sh
```

The script installs Homebrew, every package in `Brewfile`, Oh My Zsh, then symlinks the configs into `$HOME`.
Existing files are backed up to `~/.dotfiles-backup/<timestamp>/`. Safe to re-run.

## Layout

| Folder       | Linked to                                                           |
|--------------|---------------------------------------------------------------------|
| `zsh/`       | `~/.zshrc`                                                          |
| `starship/`  | `~/.config/starship.toml`                                           |
| `fastfetch/` | `~/.config/fastfetch/config.jsonc`                                  |
| `ghostty/`   | `~/Library/Application Support/com.mitchellh.ghostty/config.ghostty` |
| `git/`       | `~/.gitconfig` (identity lives in `~/.gitconfig.local`, not committed) |
| `bat/`       | `~/.config/bat/`                                                    |
| `nvim/`      | `~/.config/nvim` (LazyVim + Catppuccin)                             |
| `tmux/`      | `~/.config/tmux/tmux.conf` (TPM + Catppuccin)                       |
| `lazygit/`   | `~/Library/Application Support/lazygit/config.yml`                  |
| `ssh/`       | `~/.ssh/config` (keys themselves are never in the repo)              |
| `aerospace/` | `~/.config/aerospace/aerospace.toml` (tiling window manager)        |
| `borders/`   | `~/.config/borders/bordersrc` (focused-window border)               |
| `macos/`     | `defaults.sh`, run by the installer (not linked)                     |

Everything is symlinked, so editing a file here takes effect immediately. Commit to keep it.

GitHub is always reached over SSH: `https://github.com/...` URLs are rewritten to `git@github.com:` by git, and `gh` clones over SSH too. Put your key at `~/.ssh/id_ed25519` and add the public key to GitHub.

## Cheat sheet

**Navigation** — `cd proj` (zoxide, partial names work) · `fcd` pick a folder · `fe` pick & open a file · `..` `...`

**fzf** — `Ctrl+T` find file · `Ctrl+R` search history · `Alt+C` jump to folder

**Git** — `gs` status · `gl` log graph · `gd` diff · `gfb` pick a branch · `lg` lazygit

**lazygit** — `C` conventional commit (type → scope → summary) · `Ctrl+O` open repo on GitHub · `e` edit file in nvim · `?` all keys

**Ghostty** — `Cmd+D` split right · `Cmd+Shift+D` split down · `Cmd+Alt+←↑↓→` move between splits · `Cmd+Shift+Enter` zoom · `Cmd+Shift+R` reload config

**Neovim** — `v file` · `Space` leader, `Space e` file tree · `Space f f` find file · `Space s g` grep · `Space g g` lazygit · `Space l` plugin manager

**tmux** — prefix is `Ctrl+Space` · `tm` attach/create session for this folder · `prefix |` / `prefix -` split · `Ctrl+hjkl` move between panes (also inside Neovim) · `prefix m` zoom · `prefix 1..9` / `prefix n` / `prefix p` switch window · `prefix I` install plugins

**AeroSpace** (Alt = Option) — `Alt+hjkl` focus · `Alt+Shift+hjkl` move window · `Alt+1..9` workspace · `Alt+Shift+1..9` send window there · `Alt+Tab` previous workspace · `Alt+/` tiles · `Alt+,` accordion · `Alt+f` fullscreen · `Alt+Shift+f` float · `Alt+-` / `Alt+=` resize · `Alt+Enter` new Ghostty · `Alt+Shift+;` then `r` reset layout

**Misc** — `killport 3000` · `ports` · `ip` · `reload` · `zshrc` · `ghostty-config`
