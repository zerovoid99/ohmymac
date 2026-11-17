# PATH for every zsh (managed by ~/Code/ohmymac).
# Sourced by ~/.zshenv, so scripts and non-interactive tools (Claude Code hooks, MCP
# servers, editors) see the same tools as your terminal, and again by ~/.zshrc,
# because macOS's /etc/zprofile (path_helper) moves system dirs back to the front in
# login shells. Keep it fast: no subprocesses.

typeset -U path PATH   # no duplicates; the first occurrence wins

# nvm: put the default Node on PATH without loading nvm (which is slow).
# Resolves aliases such as `lts/*` -> `lts/krypton` -> `v24.11.1`.
_nvm_bin=
if [[ -r ${NVM_DIR:=$HOME/.nvm}/alias/default ]]; then
  _v=$(<$NVM_DIR/alias/default)
  for _i in 1 2 3; do
    [[ -r $NVM_DIR/alias/$_v ]] && _v=$(<$NVM_DIR/alias/$_v) || break
  done
  _v=${_v#v}
  # newest installed version matching the (possibly partial) default, e.g. "26" or "24.11"
  _nvm_bins=($NVM_DIR/versions/node/v${_v}(|.*)/bin(N/nOn))
  _nvm_bin=${_nvm_bins[1]}
  unset _v _i _nvm_bins
fi

path=(
  $HOME/bin
  $HOME/.local/bin                 # uv, pipx, herdr-core, misc installers
  $HOME/.cargo/bin                 # rustup / cargo
  $_nvm_bin
  $HOME/.rbenv/shims               # rbenv
  ${GOPATH:-$HOME/go}/bin          # go install
  /opt/homebrew/opt/curl/bin       # keg-only curl, ahead of /usr/bin/curl
  /opt/homebrew/bin
  /opt/homebrew/sbin
  $path
)
path=(${^path}(N-/))   # drop entries that don't exist on this machine
unset _nvm_bin
export PATH
