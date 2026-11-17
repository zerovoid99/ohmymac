#!/usr/bin/env bash
# ohmymac installer — modular macOS dev setup. Idempotent and safe to re-run.
#   git clone <repo> ~/Code/ohmymac && ~/Code/ohmymac/install.sh
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ACTION=install
. "$DOTFILES/lib/common.sh"
. "$DOTFILES/lib/modules.sh"
. "$DOTFILES/lib/cli.sh"

usage() {
  cat <<EOF
${c_bold}Usage:${c_off} install.sh [options] [module ...]

With no modules, an interactive menu opens (core is preselected). Without a
terminal, only core is installed. Naming modules installs exactly those; core is
added automatically when it isn't installed yet.

${c_bold}Modules:${c_off}  $MODULES
${c_bold}Groups:${c_off}   dev ($GROUP_dev), all

${c_bold}Options:${c_off}
  -a, --all       install every module
  -u, --update    update the repo and every installed module (or just the ones named)
  -n, --dry-run   show what would happen, change nothing
  -y, --yes       no questions (also skips the git identity prompt)
  -v, --verbose   stream command output instead of a spinner
  -l, --list      list modules and what is installed
  -h, --help      show this help

${c_bold}Examples:${c_off}
  install.sh                     interactive menu
  install.sh dev                 nvm, rustup, Go, rbenv, uv, JDK
  install.sh rust python herdr   just those
  install.sh --all --dry-run     preview everything
  install.sh --update            git pull, brew upgrade, rustup, uv, nvm, plugins

Remove things again with ./uninstall.sh.
EOF
}

UPDATE=0
for arg in "$@"; do
  case "$arg" in
    -a|--all)     add_selection all ;;
    -u|--update)  UPDATE=1 ;;
    -n|--dry-run) DRY_RUN=1 ;;
    -y|--yes)     ASSUME_YES=1 ;;
    -v|--verbose) VERBOSE=1 ;;
    -l|--list)    list_modules; exit 0 ;;
    -h|--help)    usage; exit 0 ;;
    -*)           add_selection "$arg" ;;   # legacy --desktop, --herdr, ...
    *)            add_selection "$arg" ;;
  esac
done

printf "\n${c_mauve}  ohmymac${c_off} ${c_dim}— macOS dev setup${c_off}\n"

# ---------- --update ----------
if [ "$UPDATE" = 1 ]; then
  ACTION=update
  log_init
  # Pull first, then re-run the new code: bash reads this file while it runs.
  if [ -z "${OHMYMAC_PULLED:-}" ] && [ "$DRY_RUN" = 0 ]; then
    step "ohmymac repo"
    if [ -n "$(git -C "$DOTFILES" status --porcelain)" ]; then
      warn "the repo has local changes; git pull skipped"
    else
      before=$(git -C "$DOTFILES" rev-parse HEAD)
      if task "git pull" git -C "$DOTFILES" pull --ff-only -q; then
        if [ "$(git -C "$DOTFILES" rev-parse HEAD)" != "$before" ]; then
          ok "repo updated, restarting with the new version"
          exec env OHMYMAC_PULLED=1 "$DOTFILES/install.sh" "$@"
        fi
      else
        warn "git pull failed; updating with the current version"
      fi
    fi
  fi
  brew_cache_reset
  if [ -z "${SELECTED// /}" ]; then   # default: every installed module
    for m in $MODULES; do
      if "status_$m" >/dev/null 2>&1; then SELECTED="$SELECTED $m"; fi
    done
  fi
  list=""
  for m in $(ordered "$SELECTED"); do
    type "update_$m" >/dev/null 2>&1 && list="$list $m"
  done
  list="${list# }"
  [ -n "$list" ] || { echo "nothing to update"; exit 0; }
  step "Plan"
  info "update: ${c_bold}$list${c_off}"
  [ "$DRY_RUN" = 1 ] && warn "dry run: nothing will be changed"
  rc=0
  run_modules "$list" || rc=$?
  printf "\n"
  exit "$rc"
fi

if [ -z "${SELECTED// /}" ]; then
  if [ -t 0 ] && [ -t 1 ] && [ "$ASSUME_YES" = 0 ]; then
    SELECTED="core"
    menu "What should be installed?"
  else
    SELECTED="core"
  fi
elif ! in_list core "$SELECTED" && ! status_core; then
  SELECTED="core $SELECTED"
  info "core isn't installed yet, so it is added"
fi

SELECTED=$(ordered "$SELECTED")
[ -n "$SELECTED" ] || { echo "nothing selected"; exit 0; }

step "Plan"
info "install: ${c_bold}$SELECTED${c_off}"
[ "$DRY_RUN" = 1 ] && warn "dry run: nothing will be changed"

log_init
ensure_brew
rc=0
run_modules "$SELECTED" || rc=$?

if [ "$DRY_RUN" = 0 ] && [ "$rc" = 0 ]; then
  printf "\n${c_green}Done!${c_off} Open a new terminal, or run: ${c_dim}exec zsh${c_off}\n"
  rest=""
  for m in $MODULES; do in_list "$m" "$SELECTED" || status_line "$m" | grep -q '^installed' || rest="$rest $m"; done
  [ -n "$rest" ] && printf "${c_dim}Not installed:%s (install.sh --list)${c_off}\n" "$rest"
fi
printf "\n"
exit "$rc"
