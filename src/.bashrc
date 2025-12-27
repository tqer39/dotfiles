#!/bin/bash

# ~/.bashrc: executed by bash(1) for non-login shells.

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# ------------------------------------------------------------------------------
# History
# ------------------------------------------------------------------------------
HISTCONTROL=ignoredups:ignorespace
shopt -s histappend
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command
shopt -s checkwinsize

# make less more friendly for non-text input files
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in
if [ -z "$debian_chroot" ] && [ -r /etc/debian_chroot ]; then
  debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
  xterm-color) color_prompt=yes;;
esac

if [ -n "$force_color_prompt" ]; then
  if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
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

# enable color support
if [ -x /usr/bin/dircolors ]; then
  if test -r "$HOME/.dircolors"; then
    eval "$(dircolors -b ~/.dircolors)"
  else
    eval "$(dircolors -b)"
  fi
  alias grep='grep --color=auto'
  alias fgrep='fgrep --color=auto'
  alias egrep='egrep --color=auto'
fi

# enable programmable completion features
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
  # shellcheck source=/dev/null
  . /etc/bash_completion
fi

# ------------------------------------------------------------------------------
# Aliases
# ------------------------------------------------------------------------------

# Help function
alias-help() {
  cat << 'EOF'
Aliases:
  Navigation:
    ..        cd ..
    ...       cd ../..
    work      cd ~/workspace
    z         zoxide (smart cd)

  Git:
    g         git
    ga        git add
    gc        git commit
    gd        git diff
    gpl       git pull
    gps       git push
    gs        git status
    gsw       git switch
    gl        git log --oneline

  Files:
    ls        eza --icons
    ll        eza -la (long)
    lt        eza -T (tree)
    cat       bat
EOF
}

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias work='cd ~/workspace'

# Git
if command -v git &> /dev/null; then
  alias g='git'
  alias ga='git add'
  alias gc='git commit'
  alias gd='git diff'
  alias gpl='git pull'
  alias gps='git push'
  alias gs='git status'
  alias gsw='git switch'
  alias gl='git log --oneline -20'
fi

# eza (ls replacement)
if command -v eza &> /dev/null; then
  alias ls='eza --icons --git'
  alias ll='eza -la --icons --git'
  alias lt='eza -T -L 2 --icons'
fi

# bat (cat replacement)
if command -v bat &> /dev/null; then
  alias cat='bat'
fi

# pbcopy/pbpaste (Linux)
if command -v xsel &> /dev/null; then
  alias pbcopy='xsel --clipboard --input'
  alias pbpaste='xsel --clipboard --output'
fi

# ------------------------------------------------------------------------------
# Tools initialization
# ------------------------------------------------------------------------------

# Homebrew
if [[ "$(uname)" = "Linux" ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
elif [[ "$(uname)" = "Darwin" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# direnv
if command -v direnv &> /dev/null; then
  eval "$(direnv hook bash)"
fi

# fzf
if command -v fzf &> /dev/null; then
  # shellcheck source=/dev/null
  if ! eval "$(fzf --bash 2>/dev/null)"; then
    # shellcheck source=/dev/null
    [ -f "$HOME/.fzf.bash" ] && . "$HOME/.fzf.bash"
  fi
fi

# Cargo/Rust
# shellcheck source=/dev/null
if [ -f "$HOME/.cargo/env" ]; then
  . "$HOME/.cargo/env"
fi

# mise
if command -v mise &> /dev/null; then
  eval "$(mise activate bash)"
fi

# zoxide (smarter cd)
if command -v zoxide &> /dev/null; then
  eval "$(zoxide init bash)"
fi

# Starship (must be at the end)
if command -v starship &> /dev/null; then
  eval "$(starship init bash)"
fi
