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

Remove things again with ./uninstall.sh.
EOF
}

for arg in "$@"; do
  case "$arg" in
    -a|--all)     add_selection all ;;
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
