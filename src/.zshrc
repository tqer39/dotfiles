#!/bin/bash

# ------------------------------------------------------------------------------
# Mode detection (personal / work)
# ------------------------------------------------------------------------------
if [ -z "${DOTFILES_MODE:-}" ]; then
  DOTFILES_MODE="personal"
fi

if [ "$#" -gt 0 ]; then
  typeset -a _dotfiles_args=()
  for _arg in "$@"; do
    if [ "$_arg" = "--work" ]; then
      DOTFILES_MODE="work"
    else
      _dotfiles_args+=("$_arg")
    fi
  done
  set -- "${_dotfiles_args[@]}"
  unset _arg _dotfiles_args
fi
export DOTFILES_MODE

# ------------------------------------------------------------------------------
# Git config selection
# ------------------------------------------------------------------------------
if [ "$DOTFILES_MODE" = "work" ]; then
  export GIT_CONFIG_GLOBAL="$HOME/.gitconfig.work"
else
  export GIT_CONFIG_GLOBAL="$HOME/.gitconfig"
fi

# ------------------------------------------------------------------------------
# Homebrew (must be before sheldon and other brew-installed tools)
# ------------------------------------------------------------------------------
if [[ "$(uname)" = "Linux" ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
elif [[ "$(uname)" = "Darwin" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# ------------------------------------------------------------------------------
# sheldon (plugin manager)
# ------------------------------------------------------------------------------
if command -v sheldon &> /dev/null; then
  eval "$(sheldon source)"
fi

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
  if fzf_init="$(fzf --zsh 2>/dev/null)" && [ -n "$fzf_init" ]; then
    eval "$fzf_init"
  else
    # shellcheck source=/dev/null
    [ -f "$HOME/.fzf.zsh" ] && . "$HOME/.fzf.zsh"
  fi
  unset fzf_init
fi

# mise
if [ "$DOTFILES_MODE" = "work" ]; then
  export MISE_CONFIG_FILE="$HOME/.config/mise/config.work.toml"
else
  export MISE_CONFIG_FILE="$HOME/.config/mise/config.personal.toml"
fi
if [ "$DOTFILES_MODE" != "work" ] && command -v mise &> /dev/null; then
  # npm 警告を避けるには一度 `mise install node` を実行しておく
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

### MANAGED BY RANCHER DESKTOP START (DO NOT EDIT)
export PATH="/Users/takeru_ooyama/.rd/bin:$PATH"
### MANAGED BY RANCHER DESKTOP END (DO NOT EDIT)
