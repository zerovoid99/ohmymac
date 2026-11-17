# ohmymac

A modular macOS dev setup: **Ghostty, Oh My Zsh, Starship, tmux and Neovim (LazyVim)**, plus optional language
toolchains and desktop tweaks. Catppuccin Mocha everywhere, JetBrainsMono Nerd Font.

- **Pick what you want.** An interactive menu, or name the modules on the command line.
- **Safe to re-run.** Idempotent; anything it replaces is backed up first.
- **Reversible.** `uninstall.sh` removes modules and puts your previous files back.
- **Previewable.** `--dry-run` shows every command without changing anything.

Requires macOS on Apple Silicon. Homebrew is installed if missing.

## Quick start

On a brand-new Mac, one command does everything: it installs the Xcode Command Line Tools (so `git` exists),
clones this repo to `~/Code/ohmymac`, and opens the installer.

```sh
curl -fsSL https://raw.githubusercontent.com/zerovoid99/ohmymac/main/bootstrap.sh | bash
```

Arguments are passed to the installer, e.g. `... | bash -s -- dev herdr`. If git is already there:

```sh
git clone https://github.com/zerovoid99/ohmymac.git ~/Code/ohmymac
~/Code/ohmymac/install.sh
```

The menu opens with `core` selected. Type numbers to toggle modules, then press Enter.

```text
   1 [x] core       terminal setup: zsh, Starship, Ghostty, tmux, Neovim, git, CLI tools
   2 [ ] cli        newer curl, wget and rsync from Homebrew, ahead of the macOS versions
   3 [ ] node       nvm + Node.js LTS                                   ✓ installed (default 26)
   ...
>
```

## Modules

| Module      | Installs                                                                          |
|-------------|-----------------------------------------------------------------------------------|
| `core`      | Homebrew, the `Brewfile` packages, Ghostty, Oh My Zsh, config symlinks, tmux plugins |
| `cli`       | Newer `curl`, `wget` and `rsync` from Homebrew, ahead of the macOS versions on PATH |
| `apps`      | Everything in `Brewfile.apps`: Docker CLI, gitleaks, semgrep, trivy, just, cloudflared, ffmpeg, ImageMagick, VS Code, Inkscape |
| `node`      | nvm, cloned from its repo so no profile is edited, plus Node.js LTS               |
| `rust`      | rustup and the stable toolchain (official installer)                              |
| `go`        | Go from Homebrew; `go install` puts tools in `~/go/bin`                           |
| `ruby`      | rbenv, ruby-build and the latest stable Ruby (compiled, takes a few minutes)      |
| `python`    | uv (standalone, updates with `uv self update`) and the latest Python              |
| `java`      | Eclipse Temurin JDK; `JAVA_HOME` is set for you                                   |
| `herdr`     | [Herdr](https://herdr.dev), a desktop app for terminals and coding agents         |
| `desktop`   | AeroSpace tiling and JankyBorders, auto-hide menu bar, Spaces settings            |
| `macos`     | Fast key repeat, no autocorrect or smart quotes, Dock, Finder and screenshot defaults |
| `wallpaper` | A Catppuccin Mocha wallpaper                                                      |

Groups: **`dev`** = node, rust, go, ruby, python, java. **`all`** = every module.

Toolchains you already have are detected and left alone, for example uv or Go from Homebrew, an existing JDK, or
an nvm default.

```sh
./install.sh --list              # every module and whether it's installed
./install.sh dev                 # all language toolchains
./install.sh rust python herdr   # exactly these (core is added if it's missing)
./install.sh --all --dry-run     # preview everything, change nothing
./install.sh --yes               # no menu, no questions: core only
./install.sh --update            # update the repo and everything installed
```

| Option          | Effect                                                  |
|-----------------|---------------------------------------------------------|
| `-a, --all`     | select every module                                     |
| `-u, --update`  | update the repo and installed modules (see [Updating](#updating)) |
| `-n, --dry-run` | print the commands instead of running them              |
| `-y, --yes`     | skip the menu and prompts                               |
| `-v, --verbose` | show command output live instead of a spinner           |
| `-l, --list`    | list modules with their status                          |

## After installing

1. **Open a new terminal** (or run `exec zsh`).
2. **Add an SSH key for GitHub.** Git sends every `https://github.com/` URL over SSH, and so do `gh` and Neovim's
   plugin manager. Create `~/.ssh/id_ed25519` and add the public key to GitHub.
3. **Check your git identity.** The installer asks for it once and saves it to `~/.gitconfig.local`.
4. **Log out and back in** if you installed `macos` or `desktop`; some keyboard and Spaces settings need it.

## Local overrides

The repo is public, so anything personal or machine-specific lives in files next to the managed ones. These files
are never committed, and the managed configs load them automatically.

| File                  | For                                                                   |
|-----------------------|-----------------------------------------------------------------------|
| `~/.zshenv.local`     | Secrets and exports every process needs (`export ANTHROPIC_API_KEY=...`). Kept at `chmod 600`. |
| `~/.zshrc.local`      | Personal aliases, functions and tool snippets (pnpm, opencode, ...)   |
| `~/.gitconfig.local`  | `[user]` name and email, and any other personal git settings          |
| `~/.ssh/config.local` | Machine-specific hosts (OrbStack, work servers)                       |

If you already have a `~/.zshenv`, the installer moves it to `~/.zshenv.local` instead of burying it in a backup.

Some installers append to `~/.zshrc`, which turns the symlink into a regular copy. When that happens, move the added
lines to `~/.zshrc.local` and run `./install.sh core` to relink.

## How the shell is wired

| File           | Role                                                                                      |
|----------------|-------------------------------------------------------------------------------------------|
| `zsh/path.zsh` | The single PATH definition: `~/.local/bin`, cargo, nvm's default Node (without loading nvm), rbenv shims, `~/go/bin`, Homebrew curl, Homebrew. Directories that don't exist are dropped. |
| `~/.zshenv`    | Read by every zsh, including scripts and non-interactive tools such as editors, Claude Code hooks and MCP servers. Loads `path.zsh`, then `~/.zshenv.local`. |
| `~/.zshrc`     | Interactive setup: Oh My Zsh, Starship, fzf, aliases. Loads `path.zsh` again, because macOS `path_helper` moves the system directories back to the front in login shells, then loads `~/.zshrc.local`. |

## Updating

```sh
./install.sh --update            # everything installed
./install.sh --update rust node  # just these
```

| Step      | What runs                                                                          |
|-----------|------------------------------------------------------------------------------------|
| repo      | `git pull --ff-only`, then the installer restarts with the new code (skipped when the repo has local changes) |
| `core`    | `brew update`, `brew upgrade` (every Homebrew package, not only ohmymac's), Oh My Zsh, tmux plugins, Neovim plugins |
| `node`    | nvm to its latest release, then the newest Node matching your default (`26` → latest 26.x) |
| `rust`    | `rustup update`                                                                    |
| `python`  | `uv self update` (standalone uv) and `uv tool upgrade --all`                      |
| `ruby`    | Reports a newer Ruby if there is one; switching versions stays your call          |

Configs are symlinked, so a plain `git pull` already applies config changes. Run `./install.sh core` when new
packages or links were added.

## Uninstall

```sh
./uninstall.sh                   # menu, nothing preselected
./uninstall.sh desktop ruby      # remove these modules
./uninstall.sh core              # remove config symlinks and restore your previous files
./uninstall.sh --all --purge -n  # preview removing everything, packages included
```

- Symlinks are removed only when they point into this repo, and the newest backup is restored.
- Packages, Oh My Zsh and tmux plugins stay unless you add `--purge`.
- `macos` and `desktop` reset their settings to the macOS defaults.
- `uninstall.sh` asks before it changes anything. Skip the question with `--yes`.

## Secret scanning

The repo is public, so `install.sh core` enables a pre-commit hook (`.githooks/pre-commit`, through
`git config core.hooksPath`) that runs `gitleaks` on staged changes and blocks the commit when it finds a key or
token. The `apps` module installs gitleaks; without it the hook warns and lets the commit through. For a false
positive, commit with `git commit --no-verify`.

## Troubleshooting

| Problem                                    | Look at                                                          |
|--------------------------------------------|------------------------------------------------------------------|
| A module failed                            | The log path printed in the summary (`~/Library/Logs/ohmymac/`). Fix the cause and re-run; finished modules are skipped quickly. |
| A previous config file disappeared         | `~/.dotfiles-backup/<timestamp>/`, under the same path as in `$HOME` |
| Repo changes to `.zshrc` have no effect    | `ls -l ~/.zshrc` should be a symlink; see [Local overrides](#local-overrides) |
| `git clone` from GitHub asks for a key     | Add `~/.ssh/id_ed25519` to GitHub (see [After installing](#after-installing)) |
| Ghostty shows config warnings              | `ghostty +validate-config`                                       |

## Repository layout

| Path               | Linked to / used for                                                  |
|--------------------|-----------------------------------------------------------------------|
| `install.sh`       | Installer entry point                                                 |
| `uninstall.sh`     | Uninstaller entry point                                               |
| `bootstrap.sh`     | One-line setup for a new Mac (Command Line Tools, clone, install)     |
| `.githooks/`       | Pre-commit secret scan for this repo                                  |
| `lib/`             | Installer internals: helpers, module definitions, menu                |
| `Brewfile`         | Packages for `core`                                                   |
| `Brewfile.apps`    | Packages for `apps`                                                   |
| `Brewfile.desktop` | Packages for `desktop`                                                |
| `zsh/`             | `~/.zshrc`, `~/.zshenv`, plus `path.zsh`                              |
| `starship/`        | `~/.config/starship.toml`                                             |
| `ghostty/`         | `~/Library/Application Support/com.mitchellh.ghostty/config.ghostty`  |
| `nvim/`            | `~/.config/nvim` (LazyVim + Catppuccin)                               |
| `tmux/`            | `~/.config/tmux/tmux.conf` (TPM + Catppuccin)                         |
| `git/`             | `~/.gitconfig`                                                        |
| `lazygit/`         | `~/Library/Application Support/lazygit/config.yml`                    |
| `bat/`             | `~/.config/bat/`                                                      |
| `fastfetch/`       | `~/.config/fastfetch/config.jsonc`                                    |
| `ssh/`             | `~/.ssh/config` (keys are never in the repo)                          |
| `aerospace/`       | `~/.config/aerospace/aerospace.toml` (`desktop`)                      |
| `borders/`         | `~/.config/borders/bordersrc` (`desktop`)                             |
| `macos/`           | `defaults.sh`, `desktop.sh`, `wallpaper.sh`; each accepts `--revert` except the wallpaper |

## Cheat sheet

**Shell**

| Keys / command      | Does                                              |
|---------------------|---------------------------------------------------|
| `cd proj`           | Jump with zoxide; partial names work (`cdi` picks interactively) |
| `fcd` · `fe`        | Pick a folder to enter · pick a file to edit      |
| `bat` · `fd` · `rg` | Modern `cat` · `find` · `grep`, under their own names so pasted commands keep working |
| `dust` · `duf` · `btop` | Modern `du` · `df` · `top`                    |
| `Ctrl+T` · `Ctrl+R` · `Alt+C` | fzf: find file · search history · jump to folder |
| `..` · `...`        | Up one · two folders                              |
| `killport 3000` · `ports` | Free a port · list listening ports          |
| `reload` · `zshrc`  | Reload · edit the zsh config                      |

**Git**

| Keys / command          | Does                                          |
|-------------------------|-----------------------------------------------|
| `gs` · `gd` · `gl`      | Status · diff · log graph                     |
| `gfb`                   | Pick a branch with fzf and switch to it       |
| `lg`                    | lazygit                                       |
| `C` (in lazygit)        | Conventional commit: type → scope → summary   |
| `Ctrl+O` (in lazygit)   | Open the repo on GitHub                       |

**Ghostty**

| Keys                       | Does                         |
|----------------------------|------------------------------|
| `Cmd+T` · `Cmd+N`          | New tab · new window         |
| `Cmd+D` · `Cmd+Shift+D`    | Split right · split down     |
| `Cmd+Alt+←↑↓→`             | Move between splits          |
| `Cmd+Shift+Enter`          | Zoom the current split       |
| `Cmd+Shift+R`              | Reload config                |

**tmux** (prefix is `Ctrl+Space`)

| Keys                          | Does                                              |
|-------------------------------|---------------------------------------------------|
| `tm`                          | Attach to or create a session named after this folder |
| `prefix \|` · `prefix -`      | Split right · split down                          |
| `Ctrl+hjkl`                   | Move between panes, also across Neovim splits     |
| `prefix m`                    | Zoom pane                                         |
| `prefix 1..9` · `n` · `p`     | Switch window                                     |
| `prefix I`                    | Install plugins                                   |

**Neovim** (leader is `Space`)

| Keys                | Does                    |
|---------------------|-------------------------|
| `v file`            | Open a file             |
| `Space e`           | File tree               |
| `Space f f` · `Space s g` | Find file · grep  |
| `Space g g`         | lazygit                 |
| `Space l`           | Plugin manager          |

**AeroSpace** (`desktop` module, `Alt` is Option)

| Keys                          | Does                                  |
|-------------------------------|---------------------------------------|
| `Alt+hjkl` · `Alt+Shift+hjkl` | Focus · move window                   |
| `Alt+1..9` · `Alt+Shift+1..9` | Go to workspace · send window there   |
| `Alt+Tab`                     | Previous workspace                    |
| `Alt+/` · `Alt+,`             | Tiles · accordion layout              |
| `Alt+f` · `Alt+Shift+f`       | Fullscreen · float                    |
| `Alt+-` · `Alt+=`             | Resize                                |
| `Alt+Enter`                   | New Ghostty window                    |
| `Alt+Shift+;` then `r`        | Reset layout                          |
