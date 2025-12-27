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

# Cargo/Rust
# shellcheck source=/dev/null
if [ -f "$HOME/.cargo/env" ]; then
  . "$HOME/.cargo/env"
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
