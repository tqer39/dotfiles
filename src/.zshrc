#!/bin/bash

# ------------------------------------------------------------------------------
# Load shared configuration
# ------------------------------------------------------------------------------
# shellcheck source=/dev/null
if [ -f "$HOME/.shell_common" ]; then
  . "$HOME/.shell_common"
fi

# ------------------------------------------------------------------------------
# sheldon (plugin manager)
# ------------------------------------------------------------------------------
if command -v sheldon &> /dev/null; then
  if sheldon_init="$(sheldon source 2>/dev/null)"; then
    eval "$sheldon_init"
  fi
  unset sheldon_init
fi

# ------------------------------------------------------------------------------
# History
# ------------------------------------------------------------------------------
export HISTFILE="$HOME/.zsh_history"
export HISTSIZE=100000
export SAVEHIST=100000
setopt extended_history

# zellij: set terminal title to cwd (shows in tab-bar)
if [ -n "${ZELLIJ:-}" ]; then
  _zj_set_title() {
    printf '\033]0;%s\007' "${PWD/#$HOME/~}"
  }
  autoload -U add-zsh-hook
  add-zsh-hook precmd _zj_set_title
  add-zsh-hook chpwd _zj_set_title
fi
