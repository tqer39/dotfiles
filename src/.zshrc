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
# Completion
# ------------------------------------------------------------------------------
# herdr の補完はファイルに生成して fpath 経由で読む(毎回 eval すると起動が遅い)。
# herdr 本体より古ければ再生成し、あわせて compinit のキャッシュを捨てる。
if command -v herdr &> /dev/null; then
  _comp_dir="$HOME/.zsh/completions"
  _herdr_comp="$_comp_dir/_herdr"
  if [[ ! -f "$_herdr_comp" ]] || [[ "$(command -v herdr)" -nt "$_herdr_comp" ]]; then
    mkdir -p "$_comp_dir"
    if herdr completion zsh > "$_herdr_comp" 2>/dev/null; then
      rm -f "${ZDOTDIR:-$HOME}/.zcompdump"
    fi
  fi
  fpath=("$_comp_dir" $fpath)
  unset _comp_dir _herdr_comp
fi

# compinit は fpath への追加をすべて終えてから呼ぶ。
# 毎回フルチェックすると遅いので、キャッシュが 24 時間以上古い場合のみ再構築する。
autoload -Uz compinit
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
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
