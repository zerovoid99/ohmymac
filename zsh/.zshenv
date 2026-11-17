# ~/.zshenv (managed by ~/Code/ohmymac)
# Read by every zsh, interactive or not. Keep it quiet and fast: no output, no slow
# commands. Interactive setup belongs in ~/.zshrc.
#
# Personal exports and secrets (API keys, tokens) go in ~/.zshenv.local:
# not committed, chmod 600, loaded below.

source "${${(%):-%x}:A:h}/path.zsh"   # this file's real location -> repo/zsh/path.zsh

[[ -r $HOME/.zshenv.local ]] && source "$HOME/.zshenv.local"
