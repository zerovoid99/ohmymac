# ohmymac

macOS terminal dotfiles: **Ghostty + Oh My Zsh + Starship + tmux + Neovim (LazyVim)**, Catppuccin Mocha everywhere, JetBrainsMono Nerd Font.

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

Everything is symlinked, so editing a file here takes effect immediately. Commit to keep it.

## Cheat sheet

**Navigation** — `cd proj` (zoxide, partial names work) · `fcd` pick a folder · `fe` pick & open a file · `..` `...`

**fzf** — `Ctrl+T` find file · `Ctrl+R` search history · `Alt+C` jump to folder

**Git** — `gs` status · `gl` log graph · `gd` diff · `gfb` pick a branch · `lg` lazygit

**Ghostty** — `Cmd+D` split right · `Cmd+Shift+D` split down · `Cmd+Alt+←↑↓→` move between splits · `Cmd+Shift+Enter` zoom · `Cmd+Shift+R` reload config

**Neovim** — `v file` · `Space` leader, `Space e` file tree · `Space f f` find file · `Space s g` grep · `Space g g` lazygit · `Space l` plugin manager

**tmux** — prefix is `Ctrl+Space` · `tm` attach/create session for this folder · `prefix |` / `prefix -` split · `Ctrl+hjkl` move between panes (also inside Neovim) · `prefix m` zoom · `Alt+1..5` switch window · `prefix I` install plugins

**Misc** — `killport 3000` · `ports` · `ip` · `reload` · `zshrc` · `ghostty-config`
