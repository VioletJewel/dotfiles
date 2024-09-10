# Author: Violet
# Last Change: 06 August 2023

[[ $- != *i* ]] && return

autoload -U edit-command-line
zle -N edit-command-line
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

function _installed {
  local pr;
  [ -d ~/.local/zsh/"$1" ] && return 0;
  read "pr?[34m$1[0m is not installed. Install? [Y/n] ";
  [ ${${pr:-y}[1]:l} != y ] && return 1;
  mkdir -p ~/.local/zsh || return 2;
  git clone "$2" ~/.local/zsh/"$1" || return 3;
  [ -d ~/.local/zsh/"$1" ] && return 0;
  return 4;
}

_installed pure 'https://github.com/sindresorhus/pure' && {
  autoload -U promptinit
  fpath+=("$HOME/.local/zsh/pure")
  promptinit
  PURE_PROMPT_SYMBOL='>'
  PURE_PROMPT_VICMD_SYMBOL='<'
  prompt pure
}

stty -ixon

zstyle ':completion:*' completer _complete
zstyle ':completion:*' matcher-list '' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' '+l:|=* r:|=*'

# fix ESC delay in insert mode (in zsh vi-mode)
# https://superuser.com/questions/476532/how-can-i-make-zshs-vi-mode-behave-more-like-bashs-vi-mode
KEYTIMEOUT=1

HISTFILE=~/.local/zsh_history
HISTSIZE=10000
SAVEHIST=10000
export GREP_COLOR='auto'

setopt hist_expire_dups_first
setopt hist_ignore_dups
setopt hist_ignore_space
setopt hist_verify
setopt inc_append_history
setopt share_history
setopt appendhistory
# setopt +o nomatch
setopt null_glob

eval "$(dircolors -b $HOME/.dircolors)"
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# https://wiki.archlinux.org/index.php/Dotfiles
# https://www.atlassian.com/git/tutorials/dotfiles
function dotfiles {
  /usr/bin/git --git-dir="$HOME/.config/dotfiles/" --work-tree="$HOME" $@
}
alias df=dotfiles

alias ls='ls --color=auto'
alias la='ls -a'
alias ll='ls -l'
alias lla='ls -la'

alias ,=nvim
alias ,c="nvim '+norm\\c'"
alias ,f="nvim '+norm1 f'"

bindkey -v
bindkey '^P' up-history
bindkey '^N' down-history
bindkey '^?' backward-delete-char
bindkey '^h' backward-delete-char

# edit line in vim with i_ctrl+{ctrl+x,x}_e or v
bindkey '^xe' edit-command-line
bindkey '^x^e' edit-command-line
bindkey -M vicmd V edit-command-line

# {up,down}  => search {backwards,forwards} thru hist
autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
bindkey "${terminfo[kcuu1]}" up-line-or-beginning-search
bindkey "^[[A" up-line-or-beginning-search
bindkey "${terminfo[kcud1]}" down-line-or-beginning-search
bindkey "^[[B" down-line-or-beginning-search

# {home,end} => {beginning,end} of line
bindkey "${terminfo[khome]}" beginning-of-line
bindkey "${terminfo[kend]}" end-of-line

# {left,right} => go {left,right} a char
bindkey "${terminfo[kcub1]}" backward-char
bindkey "${terminfo[kcuf1]}" forward-char

# ctrl+{left,right} => go {left,right} one word
if [[ $TERM =~ rxvt.* ]]; then
  bindkey "Od" backward-word
  bindkey "Oc" forward-word
else
  bindkey "[1;5D" backward-word
  bindkey "[1;5C" forward-word
fi

autoload -Uz compinit 
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
	compinit;
else
	compinit -C;
fi;

function _tmatt() {
  local -a sessions
  sessions=($(tmux ls 2>/dev/null | cut -d: -f1))
  _describe -t sessions 'tmux sessions' sessions
}
compdef _tmatt tmatt

# tmux:
#  ls if no args
#  attach if $1 exists as a session
#  new session if $1 is not a session
function tmatt() {
  if [[ $# -eq 0 ]]; then
    d="$(basename "$(pwd)")"
    tmux attach -t "$d" 2>/dev/null || tmux new -s "$d"
  elif [[ $# -eq 1 ]]; then
    tmux attach -t "$1" 2>/dev/null || tmux new -s "$1"
  else
    tmux attach -t "$1" 2>/dev/null || tmux new -s "$1" "$2"
  fi
}

# man + neovim = ♥
function man(){
  if ! [[ -t 0 && -t 1 && -t 2 ]]; then
    command man "$@"
    return
  fi
  if [ $# -eq 0 ]; then
    echo 'What manual page do you want?'
    return 0
  elif ! man -d "$@" &> /dev/null; then
    echo 'No manual entry for '"$*"
    return 1
  fi
  nvim +"silent Man $*" +'silent only'
}

function doc2pdf {
  if type libreoffice &>/dev/null; then
    local loffice="$(which libreoffice)"
  elif type soffice &>/dev/null; then
    local loffice="$(which soffice)"
  else
    >&2 echo 'neither libreoffice nor soffice detected'
    return 1
  fi
  "$loffice" --headless --convert-to pdf $1 --outdir ./
}

_installed autosuggestions 'https://github.com/zsh-users/zsh-autosuggestions' && {
  source ~/.local/zsh/autosuggestions/zsh-autosuggestions.zsh
  ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=240'
  bindkey '^[h' autosuggest-clear
  bindkey '^[l' autosuggest-accept
  bindkey '^[k' up-line-or-beginning-search
  bindkey '^[j' down-line-or-beginning-search
  bindkey '^[^m' autosuggest-execute
}

_installed syntax-highlighting 'https://github.com/zsh-users/zsh-syntax-highlighting' && {
  setopt interactivecomments
  source ~/.local/zsh/syntax-highlighting/zsh-syntax-highlighting.zsh
  typeset -A ZSH_HIGHLIGHT_STYLES
  ZSH_HIGHLIGHT_STYLES[path]='fg=73'
  ZSH_HIGHLIGHT_STYLES[comment]='fg=244'
}

zstyle ':completion:*' menu select
zmodload zsh/complist

bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char
bindkey -M menuselect 'j' vi-down-line-or-history

WORDCHARS='*?_-.[]~=/&;!#$%^(){}<>' # the default
WORDCHARS+=":"
WORDCHARS='${WORDCHARS:s@/@}'

# fzf

# export FZF_DEFAULT_OPTS='
#   --color fg:243,bg:-1,hl:73,fg+:251,bg+:240,hl+:80
#   --color info:251,prompt:251,spinner:73,pointer:73,marker:73
# '

__fzf_use_tmux__() {
  [ -n "$TMUX_PANE" ] && [ "${FZF_TMUX:-0}" != 0 ] && [ ${LINES:-40} -gt 15 ]
}

__fzfcmd() {
  __fzf_use_tmux__ &&
    echo "fzf-tmux -d${FZF_TMUX_HEIGHT:-40%}" || echo "fzf"
  }

# fix bug in zsh
TRAPWINCH() {
  zle && { zle reset-prompt; zle -R }
}

# ctrl+r => paste the selected command from history into the command line
fzf-history-widget() {
local selected num
setopt localoptions noglobsubst noposixbuiltins pipefail 2> /dev/null
selected=( $(fc -rl 1 |
  FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} $FZF_DEFAULT_OPTS -n2..,.. --tiebreak=index \
  --bind=ctrl-r:toggle-sort $FZF_CTRL_R_OPTS --query=${(qqq)LBUFFER} +m" $(__fzfcmd)) )
  local ret=$?
  if [ -n "$selected" ]; then
    num=$selected[1]
    if [ -n "$num" ]; then
      zle vi-fetch-history -n $num
    fi
  fi
  zle reset-prompt
  return $ret
}
zle     -N   fzf-history-widget
bindkey '^R' fzf-history-widget

# [ -f "$HOME/.ghcup/env" ] && source "$HOME/.ghcup/env" # ghcup-env
# alias luamake=$HOME/git/lua-language-server/3rd/luamake/luamake
# alias dash='exec dash -l'

unfunction _installed;

# initconda(){
#
# # >>> conda initialize >>>
# # !! Contents within this block are managed by 'conda init' !!
# __conda_setup="$('/opt/anaconda/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
# if [ $? -eq 0 ]; then
#     eval "$__conda_setup"
# else
#     if [ -f "/opt/anaconda/etc/profile.d/conda.sh" ]; then
#         . "/opt/anaconda/etc/profile.d/conda.sh"
#     else
#         export PATH="/opt/anaconda/bin:$PATH"
#     fi
# fi
# unset __conda_setup
# # <<< conda initialize <<<
#
# };

eval "$(zoxide init zsh)"

