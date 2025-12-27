#!/bin/bash

# ------------------------------------------------------------------------------
# sheldon (plugin manager)
# ------------------------------------------------------------------------------
eval "$(sheldon source)"

# ------------------------------------------------------------------------------
# History
# ------------------------------------------------------------------------------
export HISTFILE="$HOME/.zsh_history"
export HISTSIZE=100000
export SAVEHIST=100000
setopt extended_history

# ------------------------------------------------------------------------------
# Load shared configuration
# ------------------------------------------------------------------------------
# shellcheck source=/dev/null
if [ -f "$HOME/.shell_common" ]; then
  . "$HOME/.shell_common"
fi

# ------------------------------------------------------------------------------
# Shell-specific tool initialization
# ------------------------------------------------------------------------------

# direnv
if command -v direnv &> /dev/null; then
  eval "$(direnv hook zsh)"
fi

# fzf
if command -v fzf &> /dev/null; then
  # shellcheck source=/dev/null
  if ! eval "$(fzf --zsh 2>/dev/null)"; then
    # shellcheck source=/dev/null
    [ -f "$HOME/.fzf.zsh" ] && . "$HOME/.fzf.zsh"
  fi
fi

# mise
if command -v mise &> /dev/null; then
  eval "$(mise activate zsh)"
fi

# zoxide (smarter cd)
if command -v zoxide &> /dev/null; then
  eval "$(zoxide init zsh)"
fi

# Starship (must be at the end)
if command -v starship &> /dev/null; then
  eval "$(starship init zsh)"
fi
