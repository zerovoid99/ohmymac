#!/bin/bash
# ohmymac bootstrap — for a brand-new Mac, where git doesn't exist yet.
#
#   curl -fsSL https://raw.githubusercontent.com/zerovoid99/ohmymac/main/bootstrap.sh | bash
#   curl -fsSL .../bootstrap.sh | bash -s -- dev herdr     # arguments go to install.sh
#
# Installs the Xcode Command Line Tools (git, compilers), clones or updates the repo
# in ~/Code/ohmymac (override with OHMYMAC_DIR), then runs install.sh.
set -euo pipefail

REPO="${OHMYMAC_REPO:-https://github.com/zerovoid99/ohmymac.git}"
DIR="${OHMYMAC_DIR:-$HOME/Code/ohmymac}"

if [ -t 1 ]; then b=$'\033[1m' blue=$'\033[1;34m' red=$'\033[1;31m' off=$'\033[0m'; else b= blue= red= off=; fi
say()  { printf '%s==>%s %s%s%s\n' "$blue" "$off" "$b" "$*" "$off"; }
fail() { printf '%s✗%s %s\n' "$red" "$off" "$*" >&2; exit 1; }

[ "$(uname -s)" = Darwin ] || fail "ohmymac is for macOS"
[ "$(uname -m)" = arm64 ] || [ "$(sysctl -n sysctl.proc_translated 2>/dev/null || echo 0)" = 1 ] \
  || fail "ohmymac needs an Apple Silicon Mac"

# ---------- Command Line Tools ----------
if ! xcode-select -p >/dev/null 2>&1; then
  say "Installing the Xcode Command Line Tools"
  xcode-select --install >/dev/null 2>&1 || true
  printf '   A macOS dialog opened: click "Install" and wait for it to finish.\n'
  until xcode-select -p >/dev/null 2>&1; do sleep 5; done
  say "Command Line Tools installed"
fi

# ---------- repo ----------
if [ -d "$DIR/.git" ]; then
  say "Updating $DIR"
  git -C "$DIR" pull --ff-only -q || printf '   git pull failed; using the current checkout\n'
else
  say "Cloning ohmymac into $DIR"
  mkdir -p "$(dirname "$DIR")"
  # ignore any global git config: an https -> ssh rewrite would fail without a key
  GIT_CONFIG_GLOBAL=/dev/null git clone -q "$REPO" "$DIR"
fi

# ---------- installer ----------
# stdin is this script when piped from curl; give the installer the keyboard back.
if [ -r /dev/tty ] && [ -t 1 ]; then
  exec "$DIR/install.sh" "$@" < /dev/tty
else
  exec "$DIR/install.sh" "$@"
fi
