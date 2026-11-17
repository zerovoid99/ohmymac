# ohmymac

macOS dev environment: **Ghostty + Oh My Zsh + Starship + tmux + Neovim (LazyVim)**, with optional AeroSpace tiling, Catppuccin Mocha everywhere, JetBrainsMono Nerd Font.

## Install (fresh Mac)

```sh
git clone <this-repo-url> ~/Code/ohmymac
~/Code/ohmymac/install.sh
```

An interactive menu lets you pick modules; `core` is preselected. Everything is idempotent and safe to re-run:
existing files are backed up to `~/.dotfiles-backup/<timestamp>/` (same relative path as in `$HOME`), and
command output goes to `~/Library/Logs/ohmymac/`. A failing module doesn't stop the others.

| Module      | What it installs                                                                 |
|-------------|----------------------------------------------------------------------------------|
| `core`      | Homebrew, `Brewfile`, Ghostty, Oh My Zsh, config symlinks, tmux plugins           |
| `cli`       | newer `curl`, `wget`, `rsync` from Homebrew, ahead of the macOS versions on PATH  |
| `node`      | nvm (cloned from its repo, no profile edits) + Node.js LTS                        |
| `rust`      | rustup + stable toolchain (official installer, `--no-modify-path`)                |
| `go`        | Go from Homebrew; `go install` tools land in `~/go/bin`                          |
| `ruby`      | rbenv + ruby-build + the latest stable Ruby                                      |
| `python`    | uv (standalone, `uv self update`) + the latest Python via `uv python install`    |
| `java`      | Eclipse Temurin JDK; `JAVA_HOME` is set automatically                            |
| `herdr`     | [Herdr](https://herdr.dev), a desktop app for terminals and coding agents        |
| `desktop`   | AeroSpace + JankyBorders (`Brewfile.desktop`), auto-hide menu bar, Spaces settings |
| `macos`     | `macos/defaults.sh`: key repeat, no autocorrect, Dock, Finder, screenshots       |
| `wallpaper` | Catppuccin Mocha wallpaper                                                       |

Groups: `dev` = node, rust, go, ruby, python, java; `all` = everything.

```sh
./install.sh --list              # what's available and what's installed
./install.sh dev                 # all language toolchains
./install.sh rust python herdr   # exactly these (core is added if missing)
./install.sh --all --dry-run     # preview, change nothing
./install.sh -y                  # non-interactive: core only
```

Tools that are already present (for example uv or Go from Homebrew, a JDK, an nvm default) are detected and left as they are.

## Uninstall

```sh
./uninstall.sh                   # interactive menu, nothing preselected
./uninstall.sh desktop ruby      # remove these modules
./uninstall.sh core              # remove config symlinks, restore your previous files
./uninstall.sh --all --purge -n  # preview removing everything, packages included
```

Symlinks are only removed when they point into this repo, and the newest backup is put back. Packages, Oh My Zsh and
tmux plugins stay unless you pass `--purge`. `macos` and `desktop` revert their settings to the macOS defaults
(`macos/defaults.sh --revert`).

## Shell files

| File               | Role                                                                                   |
|--------------------|----------------------------------------------------------------------------------------|
| `~/.zshenv`        | → `zsh/.zshenv`. Read by every zsh, including scripts and tools like Claude Code hooks. Sets PATH, then loads `~/.zshenv.local`. |
| `zsh/path.zsh`     | The one PATH definition: `~/.local/bin`, cargo, nvm's default Node (without loading nvm), rbenv shims, `~/go/bin`, keg-only curl, Homebrew. Missing dirs are dropped. |
| `~/.zshrc`         | → `zsh/.zshrc`. Interactive setup; re-applies PATH because macOS `path_helper` reorders it in login shells. Loads `~/.zshrc.local` at the end. |
| `~/.zshenv.local`  | Yours, not committed, `chmod 600`: secrets and personal exports (`export ANTHROPIC_API_KEY=...`). An existing `~/.zshenv` is moved here on install. |
| `~/.zshrc.local`   | Yours, not committed: personal aliases and tool snippets (pnpm, etc.).                  |

Installers that append to `~/.zshrc` replace the symlink with a regular file. If that happens, move the added lines to
`~/.zshrc.local` and re-run `./install.sh core`.

## Layout

| Folder       | Linked to                                                           |
|--------------|---------------------------------------------------------------------|
| `zsh/`       | `~/.zshrc`, `~/.zshenv` (see [Shell files](#shell-files))           |
| `starship/`  | `~/.config/starship.toml`                                           |
| `fastfetch/` | `~/.config/fastfetch/config.jsonc`                                  |
| `ghostty/`   | `~/Library/Application Support/com.mitchellh.ghostty/config.ghostty` |
| `git/`       | `~/.gitconfig` (identity lives in `~/.gitconfig.local`, not committed) |
| `bat/`       | `~/.config/bat/`                                                    |
| `nvim/`      | `~/.config/nvim` (LazyVim + Catppuccin)                             |
| `tmux/`      | `~/.config/tmux/tmux.conf` (TPM + Catppuccin)                       |
| `lazygit/`   | `~/Library/Application Support/lazygit/config.yml`                  |
| `ssh/`       | `~/.ssh/config` (machine-specific hosts in `~/.ssh/config.local`; keys never in the repo) |
| `aerospace/` | `~/.config/aerospace/aerospace.toml` (tiling window manager, `desktop` module) |
| `borders/`   | `~/.config/borders/bordersrc` (focused-window border, `desktop` module)  |
| `macos/`     | `defaults.sh`, `desktop.sh`, `wallpaper.sh`, run by modules (not linked) |
| `lib/`       | installer internals: helpers, module definitions, menu              |

Everything is symlinked, so editing a file here takes effect immediately. Commit to keep it.

GitHub is always reached over SSH: `https://github.com/...` URLs are rewritten to `git@github.com:` by git, and `gh` clones over SSH too. Put your key at `~/.ssh/id_ed25519` and add the public key to GitHub.

## Cheat sheet

**Navigation** — `cd proj` (zoxide, partial names work) · `fcd` pick a folder · `fe` pick & open a file · `..` `...`

**fzf** — `Ctrl+T` find file · `Ctrl+R` search history · `Alt+C` jump to folder

**Git** — `gs` status · `gl` log graph · `gd` diff · `gfb` pick a branch · `lg` lazygit

**lazygit** — `C` conventional commit (type → scope → summary) · `Ctrl+O` open repo on GitHub · `e` edit file in nvim · `?` all keys

**Ghostty** — `Cmd+T` new tab · `Cmd+N` new window · `Cmd+D` split right · `Cmd+Shift+D` split down · `Cmd+Alt+←↑↓→` move between splits · `Cmd+Shift+Enter` zoom · `Cmd+Shift+R` reload config

**Neovim** — `v file` · `Space` leader, `Space e` file tree · `Space f f` find file · `Space s g` grep · `Space g g` lazygit · `Space l` plugin manager

**tmux** — prefix is `Ctrl+Space` · `tm` attach/create session for this folder · `prefix |` / `prefix -` split · `Ctrl+hjkl` move between panes (also inside Neovim) · `prefix m` zoom · `prefix 1..9` / `prefix n` / `prefix p` switch window · `prefix I` install plugins

**AeroSpace** (`desktop` module, Alt = Option) — `Alt+hjkl` focus · `Alt+Shift+hjkl` move window · `Alt+1..9` workspace · `Alt+Shift+1..9` send window there · `Alt+Tab` previous workspace · `Alt+/` tiles · `Alt+,` accordion · `Alt+f` fullscreen · `Alt+Shift+f` float · `Alt+-` / `Alt+=` resize · `Alt+Enter` new Ghostty · `Alt+Shift+;` then `r` reset layout

**Misc** — `killport 3000` · `ports` · `ip` · `reload` · `zshrc` · `ghostty-config`
