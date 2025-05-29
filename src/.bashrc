#!/bin/bash

# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# don't put duplicate lines in the history. See bash(1) for more options
# ... or force ignoredups and ignorespace
HISTCONTROL=ignoredups:ignorespace

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "$debian_chroot" ] && [ -r /etc/debian_chroot ]; then
  debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
  xterm-color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
  if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
  PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
  PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
  PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
  ;;
*)
  ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
  if test -r "$HOME/.dircolors";then
    eval "$(dircolors -b ~/.dircolors)"
  else
    eval "$(dircolors -b)"
  fi
  alias ls='ls --color=auto'
  #alias dir='dir --color=auto'
  #alias vdir='vdir --color=auto'

  alias grep='grep --color=auto'
  alias fgrep='fgrep --color=auto'
  alias egrep='egrep --color=auto'
fi

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f "$HOME/.bash_aliases" ]; then
  # shellcheck source=/dev/null
  . "$HOME/.bash_aliases"
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
  # shellcheck source=/dev/null
  . /etc/bash_completion
fi

# ------------------------------------------------------------------------------
# \shellcheck
# ------------------------------------------------------------------------------
if [[ $(command -v shellcheck) ]]; then
  alias sc='shellcheck'
  function schelp() {
    curl -s https://raw.githubusercontent.com/wiki/koalaman/shellcheck/"$1".md
  }
fi

alias help-me='echo "
ctrl+a\t\t:行頭に移動
ctrl+e\t\t:行末に移動
ctrl+h\t\t:後方に1文字削除
meta(esc)+b\t:一語後退
meta(esc)+f\t:一語前進
ctrl+u\t\t:行頭まで削除
ctrl+l\t\t:ターミナルの内容をクリア
ctrl+c\t\t:実行中のコマンドを終了
ctrl+r\t\t:コマンド履歴の検索
ctrl+insert\t:コピー
shift+insert\t:貼り付け
ctrl+d\t\t:ターミナルを強制終了
"'

# pre-commit
if [[ $(command -v pre-commit) ]]; then
  alias pcv="pre-commit -V"
  alias pcc="pre-commit clean"
  alias pci="pre-commit install --install-hooks"
  alias pcra="pre-commit run -a"
fi

# shortcut
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias dl='cd ~/Downloads'
alias d='cd ~/Desktop'
alias work='cd ~/workspace'
alias apt-u='sudo apt update && sudo apt upgrade -y'
alias brew-u='brew update && brew upgrade'

# brew
if [[ "$(uname)" = "Linux" ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
elif [ "$(uname)" = "Darwin" ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# git
if [[ $(command -v git) ]]; then
  alias g='git'
  alias gb='git branch'
  alias ga='git add'
  alias gc='git commit -am'
  alias gca='git commit --amend'
  alias gd='git diff'
  alias gds='git diff --staged'
  alias gf='git fetch'
  alias gm='git merge'
  alias gr="git rebase"
  alias grc="git rebase --continue"
  alias gra="git rebase --abort"
  alias gpl='git pull'
  alias gps='git push'
  alias gpso='git push origin'
  alias gpso-this='git push --set-upstream origin $(git branch --contains | cut -d " " -f 2)'
  alias gstt='git status'
  alias gsts='git stash'
  alias gsw='git switch'
  alias gswc='git switch -c'
  alias gl='git log --oneline'
  alias gbm='git branch --merged'
  alias gbm-all='git branch --merged|egrep -v "\*|develop|main"|xargs git branch' # -d で削除, -D で完全削除
  alias gch='git cherry-pick'
  alias gbn='git new-feature-branch'
fi

# anyenv
export PATH="$HOME/.anyenv/bin:$PATH"
eval "$(anyenv init -)"

# direnv
eval "$(direnv hook bash)"

# pbcopy/pbpaste
if command -v xsel &> /dev/null; then
  alias pbcopy='xsel --clipboard --input'
  alias pbpaste='xsel --clipboard --output'
fi

# fzf
if [[ $(command -v brew) ]]; then
  if [ "$(brew list | grep -c "^fzf@*.*$")" -gt 0 ]; then
    # shellcheck source=/dev/null
    [ -f "$HOME/.fzf.bash" ] && . "$HOME/.fzf.bash"
  fi
fi

# git
if command -v git &> /dev/null; then
  alias g='git'
  alias gb='git branch'
  alias ga='git add'
  alias gc='git commit -am'
  alias gca='git commit --amend'
  alias gd='git diff'
  alias gds='git diff --staged'
  alias gf='git fetch'
  alias gm='git merge'
  alias gr="git rebase"
  alias grc="git rebase --continue"
  alias gra="git rebase --abort"
  alias gpl='git pull'
  alias gps='git push'
  alias gpso='git push origin'
  alias gstt='git status'
  alias gsts='git stash'
  alias gsw='git switch'
  alias gswc='git switch -c'
  alias gl='git log --oneline'
  alias gbm='git branch --merged'
  alias gbm-all='git branch --merged|egrep -v "\*|develop|main"|xargs git branch' # -d で削除, -D で完全削除
fi

# bat
if command -v bat; then
  alias cat="bat"
fi

# eza
if [[ $(command -v eza) ]]; then
  alias e='eza --icons --git'
  alias l=e
  alias ls=e
  alias ea='eza -a --icons --git'
  alias la=ea
  alias ee='eza -aahl --icons --git'
  alias ll=ee
  alias et='eza -T -L 3 -a -I "node_modules|.git|.cache" --icons'
  alias lt=et
  alias eta='eza -T -a -I "node_modules|.git|.cache" --color=always --icons | less -r'
  alias lta=eta
  alias l='clear && ls'
fi

# openjdk
if [[ $(command -v brew) ]]; then
  if [ "$(brew list | grep -c "^openjdk@*.*$")" -gt 0 ]; then
    PATH="$(brew --prefix openjdk@11)/bin:$PATH"
    export PATH
  fi
fi

# mysql-client
if [[ $(command -v brew) ]]; then
  if [ "$(brew list | grep -c "^mysql-client@*.*$")" -gt 0 ]; then
    PATH="$(brew --prefix mysql-client)/bin:$PATH"
    export PATH
  fi
fi

# terraform
if [[ $(command -v terraform) ]]; then
  alias tf='terraform'
  alias tfi='terraform init'
  alias tfi='terraform init --auto-approve'
  alias tff='terraform fmt'
  alias tfp='terraform plan'
  alias tfa='terraform apply'
  alias tfi='terraform import'
  alias tfaa='terraform apply --auto-approve'
  alias tfsl='terraform state list'
fi

# ruff
# shellcheck source=/dev/null
if [ -f "$HOME/.cargo/env" ]; then
  . "$HOME/.cargo/env"
fi

# code-insiders
if command -v code-insiders &> /dev/null; then
  alias ci='code-insiders'
fi

### MANAGED BY RANCHER DESKTOP START (DO NOT EDIT)
export PATH="/home/tqer39/.rd/bin:$PATH"
### MANAGED BY RANCHER DESKTOP END (DO NOT EDIT)

# Starship ... # see https://starship.rs/ja-jp/guide/
# ※ 一番最後の行に設定が必要
if command -v starship &> /dev/null; then
  eval "$(starship init bash)"
fi
