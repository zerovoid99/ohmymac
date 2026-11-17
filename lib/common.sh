# Shared helpers for install.sh and uninstall.sh. Sourced, not executed.
# Must stay compatible with the bash 3.2 that ships with macOS.

DOTFILES="${DOTFILES:?DOTFILES must be set before sourcing lib/common.sh}"
TS="$(date +%Y%m%d-%H%M%S)"
BACKUP_ROOT="$HOME/.dotfiles-backup"
BACKUP="$BACKUP_ROOT/$TS"
LOG_DIR="$HOME/Library/Logs/ohmymac"
LOG="$LOG_DIR/$(basename "$0" .sh)-$TS.log"
BREW_PREFIX=/opt/homebrew

DRY_RUN=0
ASSUME_YES=0
exec 3>&1   # the terminal, for messages that must survive `>/dev/null` on a command
VERBOSE=0

# ---------- output ----------
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  c_bold=$'\033[1m'; c_dim=$'\033[2m'; c_red=$'\033[1;31m'; c_green=$'\033[1;32m'
  c_yellow=$'\033[1;33m'; c_blue=$'\033[1;34m'; c_mauve=$'\033[1;35m'; c_off=$'\033[0m'
  IS_TTY=1
else
  c_bold=; c_dim=; c_red=; c_green=; c_yellow=; c_blue=; c_mauve=; c_off=
  IS_TTY=0
fi

header() { printf "\n${c_mauve}%s${c_off}\n" "$*"; }
step()   { printf "\n${c_blue}==>${c_off} ${c_bold}%s${c_off}\n" "$*"; }
ok()     { printf "  ${c_green}✓${c_off} %s\n" "$*"; }
info()   { printf "  ${c_dim}·${c_off} %s\n" "$*"; }
warn()   { printf "  ${c_yellow}!${c_off} %s\n" "$*"; }
err()    { printf "  ${c_red}✗${c_off} %s\n" "$*" >&2; }
die()    { err "$*"; exit 1; }
tilde()  { printf '%s' "${1/#$HOME/~}"; }

log_init() {
  [ "$DRY_RUN" = 1 ] && return 0
  mkdir -p "$LOG_DIR"
  printf '# %s %s\n' "$0" "$TS" > "$LOG"
}

# confirm "question" -> 0 on yes. Default is no; --yes answers yes.
confirm() {
  [ "$ASSUME_YES" = 1 ] && return 0
  [ -t 0 ] || return 1
  local reply
  printf "\n${c_bold}%s${c_off} [y/N] " "$1"
  read -r reply
  case "$reply" in y|Y|yes|YES) return 0 ;; *) return 1 ;; esac
}

# ---------- running commands ----------
# run <cmd> [args...]: execute, or print it under --dry-run.
run() {
  if [ "$DRY_RUN" = 1 ]; then
    printf "  ${c_dim}would run:${c_off} %s\n" "$*" >&3
    return 0
  fi
  "$@"
}

# clean_output: make tool output readable in a log. Progress bars (curl, brew,
# ruby-build) redraw with carriage returns, so only the last frame of each line is
# kept; color and cursor escape codes are dropped. Line-buffered, so output streams.
clean_output() {
  LC_ALL=C sed -l \
    -e $'s/\r$//' \
    -e $'s/.*\r//' \
    -e $'s/\x1b\\[[0-9;?]*[A-Za-z]//g' \
    -e $'s/\x1b\\][^\x07]*\x07//g'
}

# task "label" <cmd> [args...]: run a slow, noisy command with its output in the log
# and a spinner on screen. --verbose streams the output instead. On failure the tail
# of the output is shown.
task() {
  local label="$1"; shift
  if [ "$DRY_RUN" = 1 ]; then
    printf "  ${c_dim}would run:${c_off} %s\n" "$*" >&3
    return 0
  fi
  printf '\n## %s\n$ %s\n' "$label" "$*" >> "$LOG"
  local start=$SECONDS rc
  if [ "$VERBOSE" = 1 ] && [ "$IS_TTY" = 1 ]; then
    # live output (progress bars included) on screen, a clean copy in the log
    info "$label"
    local raw; raw=$(mktemp)
    set +e
    "$@" 2>&1 | tee "$raw"
    rc=${PIPESTATUS[0]}
    set -e
    clean_output < "$raw" >> "$LOG"; rm -f "$raw"
  elif [ "$IS_TTY" = 0 ]; then
    # no terminal (CI, background job, redirected): clean output everywhere
    info "$label"
    set +e
    "$@" 2>&1 < /dev/null | clean_output | tee -a "$LOG"
    rc=${PIPESTATUS[0]}
    set -e
  else
    ( "$@" 2>&1 < /dev/null | clean_output; exit "${PIPESTATUS[0]}" ) >> "$LOG" &
    local pid=$! i=0
    local frames=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)
    while kill -0 "$pid" 2>/dev/null; do
      printf "\r  ${c_blue}%s${c_off} %s ${c_dim}%ss${c_off}" "${frames[i++ % 10]}" "$label" "$((SECONDS - start))"
      sleep 0.1
    done
    set +e; wait "$pid"; rc=$?; set -e
    printf "\r\033[K"
  fi
  if [ "$rc" = 0 ]; then
    ok "$label ${c_dim}($((SECONDS - start))s)${c_off}"
  else
    # Recorded for run_modules: bash 3.2's `set -e` misses failures at the end of an
    # `a && b` list, so the exit status alone can't be trusted to fail the module.
    [ -n "${TASK_FAILURES:-}" ] && printf '%s\n' "$label" >> "$TASK_FAILURES"
    err "$label failed (exit $rc)"
    if [ "$VERBOSE" = 0 ] && [ "$IS_TTY" = 1 ]; then
      tail -n 15 "$LOG" | sed "s/^/    ${c_dim}│${c_off} /"
    fi
  fi
  return "$rc"
}

# Interactive installers (Homebrew asks for a password and RETURN) must keep the terminal.
task_interactive() {
  local label="$1"; shift
  info "$label"
  run "$@"
}

has()   { command -v "$1" >/dev/null 2>&1; }
# brew_has / brew_has_cask read a cached package list, see lib/cli.sh

brew_install() {
  local f missing=()
  for f in "$@"; do brew_has "$f" || missing+=("$f"); done
  if [ ${#missing[@]} -eq 0 ]; then ok "already installed: $*"; return 0; fi
  task "brew install ${missing[*]}" env HOMEBREW_NO_AUTO_UPDATE=1 brew install "${missing[@]}"
}

brew_uninstall() {
  local f present=()
  for f in "$@"; do brew_has "$f" && present+=("$f"); done
  if [ ${#present[@]} -eq 0 ]; then info "not installed with brew: $*"; return 0; fi
  task "brew uninstall ${present[*]}" brew uninstall "${present[@]}"
}

# git without ~/.gitconfig: its https -> ssh rewrite fails before an SSH key exists.
git_plain() { GIT_CONFIG_GLOBAL=/dev/null git "$@"; }

# ---------- symlinks ----------
# Backups keep the path relative to $HOME, so two files named `config` never collide.
backup_path() { printf '%s/%s' "$BACKUP" "${1#$HOME/}"; }

# link <source in repo> <target in $HOME>
link() {
  local src="$1" dst="$2"
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    ok "linked $(tilde "$dst")"
    return 0
  fi
  run mkdir -p "$(dirname "$dst")"
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    local b; b="$(backup_path "$dst")"
    run mkdir -p "$(dirname "$b")"
    run mv "$dst" "$b"
    warn "backed up $(tilde "$dst") → $(tilde "$b")"
  fi
  run ln -s "$src" "$dst"
  ok "linked $(tilde "$dst")"
}

# Newest backup of <target>, or nothing. Older backups stored files by basename only;
# those are used when the name is distinctive enough to be unambiguous.
find_backup() {
  local dst="$1" rel="${1#$HOME/}" base; base="$(basename "$1")"
  local d
  for d in $(ls -1d "$BACKUP_ROOT"/*/ 2>/dev/null | sort -r); do
    d="${d%/}"
    if [ -e "$d/$rel" ] || [ -L "$d/$rel" ]; then printf '%s' "$d/$rel"; return 0; fi
    case "$base" in config|config.yml) continue ;; esac
    if [ -e "$d/$base" ] || [ -L "$d/$base" ]; then printf '%s' "$d/$base"; return 0; fi
  done
  return 1
}

# unlink <target>: remove a symlink that points into this repo, then restore the newest
# backup if there is one. Anything else is left alone.
unlink_managed() {
  local dst="$1"
  if [ ! -L "$dst" ]; then
    [ -e "$dst" ] && info "kept $(tilde "$dst") (not managed by ohmymac)"
    return 0
  fi
  case "$(readlink "$dst")" in
    "$DOTFILES"/*) ;;
    *) info "kept $(tilde "$dst") (links elsewhere)"; return 0 ;;
  esac
  run rm "$dst"
  local b
  if b="$(find_backup "$dst")"; then
    run cp -Rp "$b" "$dst"
    ok "restored $(tilde "$dst") from $(tilde "$b")"
  else
    ok "removed $(tilde "$dst")"
  fi
}
