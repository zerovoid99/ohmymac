# Argument parsing, module menu and runner shared by install.sh and uninstall.sh.
# Sourced after lib/common.sh and lib/modules.sh. ACTION is "install" or "uninstall".

SELECTED=""

in_list() { case " $2 " in *" $1 "*) return 0 ;; *) return 1 ;; esac; }
is_module() { in_list "$1" "$MODULES"; }

# Keep the canonical order (core first) whatever order modules were given in.
ordered() {
  local m out=""
  for m in $MODULES; do in_list "$m" "$1" && out="$out $m"; done
  printf '%s' "${out# }"
}

# add_selection <name>: a module, a group (dev, all) or a legacy --flag
add_selection() {
  local name="${1#--}"
  case "$name" in
    all) SELECTED="$MODULES" ;;
    dev) SELECTED="$SELECTED $GROUP_dev" ;;
    *)
      is_module "$name" || die "unknown module: $1 (see --list)"
      SELECTED="$SELECTED $name" ;;
  esac
}

# ---------- brew status cache (brew list is slow; one call instead of dozens) ----------
BREW_FORMULAE=""; BREW_CASKS=""
brew_cache_reset() {
  if has brew; then
    BREW_FORMULAE=$'\n'"$(brew list --formula -1 2>/dev/null)"$'\n'
    BREW_CASKS=$'\n'"$(brew list --cask -1 2>/dev/null)"$'\n'
  fi
}
brew_has()      { case "$BREW_FORMULAE" in *$'\n'"$1"$'\n'*) return 0 ;; *) return 1 ;; esac; }
brew_has_cask() { case "$BREW_CASKS"    in *$'\n'"$1"$'\n'*) return 0 ;; *) return 1 ;; esac; }

# status_line <module> -> "installed (detail)" or "-"
status_line() {
  local detail
  if detail=$("status_$1" 2>/dev/null); then
    printf 'installed%s' "${detail:+ ($detail)}"
  else
    printf -- '-'
  fi
}

list_modules() {
  brew_cache_reset
  printf "\n  ${c_bold}%-10s %-12s %s${c_off}\n" "MODULE" "STATUS" "DESCRIPTION"
  local m st
  for m in $MODULES; do
    st=$(status_line "$m")
    if [ "$st" = "-" ]; then
      printf "  %-10s ${c_dim}%-12s${c_off} %s\n" "$m" "-" "$("desc_$m")"
    else
      printf "  %-10s ${c_green}%-12s${c_off} %s ${c_dim}%s${c_off}\n" "$m" "installed" "$("desc_$m")" "${st#installed}"
    fi
  done
  printf "\n  Groups: ${c_bold}dev${c_off} = %s · ${c_bold}all${c_off} = every module\n\n" "$GROUP_dev"
}

# Interactive checklist. Numbers toggle, a = all, n = none, Enter = go, q = quit.
menu() {
  local title="$1" mods=($MODULES) statuses=() i m input tok notes="" first=1
  brew_cache_reset
  for m in "${mods[@]}"; do statuses+=("$(status_line "$m")"); done
  while :; do
    [ "$first" = 0 ] && [ "$IS_TTY" = 1 ] && printf '\033[2J\033[H'
    first=0
    header "$title"
    printf "  ${c_dim}type numbers to toggle (e.g. 3 5 7), a = all, n = none, Enter = continue, q = quit${c_off}\n\n"
    for i in "${!mods[@]}"; do
      m=${mods[$i]}
      local box="[ ]" st="${statuses[$i]}" st_txt
      in_list "$m" "$SELECTED" && box="${c_green}[x]${c_off}"
      if [ "$st" = "-" ]; then st_txt=""; else st_txt="${c_green}✓ ${st}${c_off}"; fi
      printf "  %2d %b %-10s %s  %b\n" "$((i + 1))" "$box" "$m" "$("desc_$m")" "$st_txt"
    done
    [ -n "$notes" ] && printf "\n%b" "$notes"
    notes=""
    printf "\n${c_bold}>${c_off} "
    read -r input || exit 1
    case "$input" in
      "") break ;;
      q|Q) echo "cancelled"; exit 0 ;;
      a|A) SELECTED="$MODULES"; continue ;;
      n|N) SELECTED=""; continue ;;
    esac
    for tok in ${input//,/ }; do
      case "$tok" in
        *[!0-9]*) notes="$notes  ${c_yellow}!${c_off} ignored: $tok\n"; continue ;;
      esac
      if [ "$tok" -ge 1 ] && [ "$tok" -le ${#mods[@]} ]; then
        m=${mods[$((tok - 1))]}
        if in_list "$m" "$SELECTED"; then SELECTED=$(printf '%s' " $SELECTED " | sed "s/ $m / /"); else SELECTED="$SELECTED $m"; fi
      else
        notes="$notes  ${c_yellow}!${c_off} no module number $tok\n"
      fi
    done
  done
}

# run_modules <list>: run ACTION for each module in its own subshell, so one failure
# doesn't stop the rest. Prints a summary at the end.
run_modules() {
  local list="$1" total=0 n=0 m rc start=$SECONDS done_list="" failed_list=""
  for m in $list; do total=$((total + 1)); done
  for m in $list; do
    n=$((n + 1))
    header "[$n/$total] ${ACTION} ${m} ${c_dim}— $("desc_$m")"
    brew_cache_reset
    TASK_FAILURES=$(mktemp); export TASK_FAILURES
    set +e
    ( set -e; "${ACTION}_$m" )
    rc=$?
    set -e
    [ -s "$TASK_FAILURES" ] && [ "$rc" = 0 ] && rc=1
    rm -f "$TASK_FAILURES"; TASK_FAILURES=
    if [ "$rc" = 0 ]; then done_list="$done_list $m"; else failed_list="$failed_list $m"; fi
  done

  local verb="installed"
  case "$ACTION" in uninstall) verb="removed" ;; update) verb="updated" ;; esac
  [ "$DRY_RUN" = 1 ] && verb="planned"
  header "Summary ${c_dim}($((SECONDS - start))s)"
  [ -n "$done_list" ]   && ok "$verb:${done_list}"
  if [ -n "$failed_list" ]; then
    err "failed:${failed_list}"
    printf "    ${c_dim}full output: %s${c_off}\n" "$(tilde "$LOG")"
    printf "    ${c_dim}fix the cause and re-run; finished modules are skipped quickly${c_off}\n"
    return 1
  fi
  [ "$DRY_RUN" = 0 ] && info "log: $(tilde "$LOG")"
  return 0
}
