# ============================================================
#  ~/.zshrc — Oh My Zsh + Starship  (managed by ~/Code/ohmymac)
# ============================================================

# --- PATH ---
export PATH="$HOME/bin:$HOME/.local/bin:/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"

# --- Oh My Zsh ---
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""                       # prompt is handled by Starship
zstyle ':omz:update' mode reminder
HYPHEN_INSENSITIVE="true"
COMPLETION_WAITING_DOTS="true"
DISABLE_UNTRACKED_FILES_DIRTY="true"

# Homebrew zsh-completions must be in fpath before compinit runs
[ -d /opt/homebrew/share/zsh-completions ] && fpath=(/opt/homebrew/share/zsh-completions $fpath)

# nvm: lazy-load so the shell starts fast
zstyle ':omz:plugins:nvm' lazy yes
zstyle ':omz:plugins:nvm' lazy-cmd nvim vim node npm npx pnpm yarn

plugins=(
  git
  gh
  npm
  node
  nvm
  docker
  docker-compose
  brew
  macos
  sudo
  extract
  colored-man-pages
)

source "$ZSH/oh-my-zsh.sh"

# --- Plugins from Homebrew ---
[ -f /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ] && \
  source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#6c7086"

# --- History ---
HISTSIZE=50000
SAVEHIST=50000
setopt HIST_IGNORE_ALL_DUPS HIST_REDUCE_BLANKS SHARE_HISTORY INC_APPEND_HISTORY

# --- Defaults ---
export EDITOR="nvim"
export VISUAL="$EDITOR"
export LANG="en_US.UTF-8"
export BAT_THEME="Catppuccin Mocha"
export MANPAGER="sh -c 'col -bx | bat -l man -p'"

# --- Tool init ---
command -v fzf      >/dev/null && source <(fzf --zsh)
command -v zoxide   >/dev/null && eval "$(zoxide init zsh --cmd cd)"   # cd = smart jump, cdi = interactive
alias z="cd"
alias zi="cdi"
command -v starship >/dev/null && eval "$(starship init zsh)"

# Blank line between commands, but not at the top of a fresh or cleared screen
_prompt_spacer() { [[ -n $_PROMPT_SEEN ]] && print; _PROMPT_SEEN=1 }
(( ${precmd_functions[(I)_prompt_spacer]} )) || precmd_functions+=(_prompt_spacer)   # idempotent for `reload`
clear() { command clear; unset _PROMPT_SEEN; }

# fzf: fd as the finder, bat/eza previews, Catppuccin Mocha colors
export FZF_DEFAULT_COMMAND="fd --type f --hidden --follow --exclude .git --exclude node_modules"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type d --hidden --follow --exclude .git --exclude node_modules"
export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:300 {}'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --level=2 --color=always --icons {}'"
export FZF_DEFAULT_OPTS="--height 50% --layout=reverse --border --info=inline \
--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
--color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 \
--color=selected-bg:#45475a,border:#6c7086,label:#cdd6f4"

# --- Aliases: modern replacements for ls / cat / find / grep ---
export EZA_COLORS="bu=33:da=90:uu=90:gu=90"   # no underline on build files, dim dates/owners
if command -v eza >/dev/null; then
  alias ls="eza --icons --group-directories-first"
  alias ll="eza -lah --icons --group-directories-first --git"
  alias la="eza -a --icons --group-directories-first"
  alias lt="eza --tree --level=2 --icons --group-directories-first"
  alias ltt="eza --tree --level=3 --icons --group-directories-first"
fi
command -v bat     >/dev/null && alias cat="bat --paging=never"
command -v fd      >/dev/null && alias find="fd"
command -v rg      >/dev/null && alias grep="rg"
command -v dust    >/dev/null && alias du="dust"
command -v duf     >/dev/null && alias df="duf"
command -v btop    >/dev/null && alias top="btop"
command -v lazygit >/dev/null && alias lg="lazygit"
command -v nvim    >/dev/null && alias vim="nvim" vi="nvim" v="nvim"

# --- Aliases: navigation & misc ---
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias c="clear"
alias reload="source ~/.zshrc && echo '✓ zshrc reloaded'"
alias zshrc='$EDITOR ~/.zshrc'
alias nvimrc='$EDITOR ~/.config/nvim'
alias ghostty-config='$EDITOR "$HOME/Library/Application Support/com.mitchellh.ghostty/config.ghostty"'
alias ip="curl -s ifconfig.me && echo"
alias localip="ipconfig getifaddr en0"
alias ports="lsof -iTCP -sTCP:LISTEN -n -P"
alias path='echo -e ${PATH//:/\\n}'

# --- Aliases: git ---
alias gs="git status -sb"
alias ga="git add"
alias gaa="git add -A"
alias gc="git commit -m"
alias gca="git commit --amend --no-edit"
alias gp="git push"
alias gpl="git pull --rebase"
alias gco="git checkout"
alias gsw="git switch"
alias gb="git branch -vv"
alias gd="git diff"
alias gds="git diff --staged"
alias gl="git log --oneline --graph --decorate -20"
alias gla="git log --oneline --graph --decorate --all"

# --- Aliases: dev ---
alias ni="npm install"
alias nr="npm run"
alias nd="npm run dev"
alias nb="npm run build"
alias pn="pnpm"
alias py="python3"
alias dc="docker compose"
alias dps="docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"

# --- Functions ---
mkcd()    { mkdir -p "$1" && cd "$1"; }                       # make dir and enter it
take()    { mkcd "$@"; }
killport(){ lsof -ti tcp:"$1" | xargs kill -9 2>/dev/null && echo "✓ port $1 killed" || echo "nothing on port $1"; }
fcd()     { local d; d=$(fd --type d --hidden --exclude .git | fzf --preview 'eza --tree --level=2 --icons --color=always {}') && cd "$d"; }   # fuzzy cd
fe()      { local f; f=$(fzf --preview 'bat --color=always --style=numbers {}') && [ -n "$f" ] && $EDITOR "$f"; }                            # fuzzy edit
fkill()   { local pid; pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}'); [ -n "$pid" ] && echo "$pid" | xargs kill -9; }                    # fuzzy kill
gfb()     { git branch --all | grep -v HEAD | fzf --preview 'git log --oneline --graph --color=always {1}' | sed 's/.* //;s#remotes/origin/##' | xargs git switch; }  # fuzzy git branch

# --- Syntax highlighting (MUST be sourced last) ---
[ -f /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && \
  source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# --- Splash ---
[[ -o interactive ]] && command -v fastfetch >/dev/null && fastfetch
