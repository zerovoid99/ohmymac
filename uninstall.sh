#!/usr/bin/env bash
# ohmymac uninstaller — removes modules installed by install.sh.
# Symlinks are removed only when they point into this repo, and the newest backup
# from ~/.dotfiles-backup is put back. Nothing outside the chosen modules is touched.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ACTION=uninstall
. "$DOTFILES/lib/common.sh"
. "$DOTFILES/lib/modules.sh"
. "$DOTFILES/lib/cli.sh"

usage() {
  cat <<EOF
${c_bold}Usage:${c_off} uninstall.sh [options] [module ...]

With no modules, an interactive menu opens (nothing is preselected).

${c_bold}Modules:${c_off}  $MODULES
${c_bold}Groups:${c_off}   dev ($GROUP_dev), all

What "core" removes: the config symlinks (your previous files come back from
~/.dotfiles-backup). Packages, Oh My Zsh and tmux plugins stay unless --purge.

${c_bold}Options:${c_off}
  -a, --all       remove every module
  -p, --purge     also remove data and shared packages (Brewfile packages, Oh My Zsh,
                  herdr-core and its config, ...)
  -n, --dry-run   show what would happen, change nothing
  -y, --yes       don't ask for confirmation
  -v, --verbose   stream command output instead of a spinner
  -l, --list      list modules and what is installed
  -h, --help      show this help

${c_bold}Examples:${c_off}
  uninstall.sh desktop           remove AeroSpace and its settings
  uninstall.sh ruby --dry-run    preview removing rbenv and its Rubies
  uninstall.sh --all --purge     remove everything ohmymac installed
EOF
}

for arg in "$@"; do
  case "$arg" in
    -a|--all)     add_selection all ;;
    -p|--purge)   PURGE=1 ;;
    -n|--dry-run) DRY_RUN=1 ;;
    -y|--yes)     ASSUME_YES=1 ;;
    -v|--verbose) VERBOSE=1 ;;
    -l|--list)    list_modules; exit 0 ;;
    -h|--help)    usage; exit 0 ;;
    *)            add_selection "$arg" ;;
  esac
done

printf "\n${c_mauve}  ohmymac${c_off} ${c_dim}— uninstall${c_off}\n"

if [ -z "${SELECTED// /}" ]; then
  [ -t 0 ] && [ -t 1 ] || { usage; exit 1; }
  menu "What should be removed?"
fi
SELECTED=$(ordered "$SELECTED")
[ -n "$SELECTED" ] || { echo "nothing selected"; exit 0; }

step "Plan"
info "remove: ${c_bold}$SELECTED${c_off}"
[ "$PURGE" = 1 ] && warn "--purge: data and shared packages go too"
if [ "$DRY_RUN" = 1 ]; then
  warn "dry run: nothing will be changed"
elif ! confirm "Remove these modules?"; then
  echo "cancelled"; exit 0
fi

log_init
rc=0
run_modules "$SELECTED" || rc=$?
[ "$DRY_RUN" = 0 ] && [ "$rc" = 0 ] && printf "\n${c_green}Done.${c_off} Open a new terminal so the shell picks up the change.\n"
printf "\n"
exit "$rc"
