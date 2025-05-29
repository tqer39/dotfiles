#!/bin/bash

# ------------------------------------------------------------------------------
# zinit
# ------------------------------------------------------------------------------
# Added by Zinit's installer
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
  print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
  command mkdir -p "$HOME/.local/share/zinit"
  command chmod g-rwX "$HOME/.local/share/zinit"
  command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git"
  print -P "%F{33} %F{34}Installation successful.%f%b" || \
  print -P "%F{160} The clone has failed.%f%b"
fi

# shellcheck source=/dev/null
. "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps["$(zinit)"]=_zinit

# Load a few important annexes, without Turbo
# (this is currently required for annexes)
zinit light-mode for \
  zdharma-continuum/zinit-annex-as-monitor \
  zdharma-continuum/zinit-annex-bin-gem-node \
  zdharma-continuum/zinit-annex-patch-dl \
  zdharma-continuum/zinit-annex-rust

### End of Zinit's installer chunk

# zinit: plugins
# 入力補完
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions

# シンタックスハイライト
zinit light zdharma-continuum/fast-syntax-highlighting

# 履歴ファイルの保存先
export HISTFILE="$HOME/.zsh_history"
export HISTSIZE=100000
export SAVEHIST=100000
setopt extended_history

# \shellcheck
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

# Rancher Desktop
### MANAGED BY RANCHER DESKTOP START (DO NOT EDIT)
export PATH="/home/tqer39/.rd/bin:$PATH"
### MANAGED BY RANCHER DESKTOP END (DO NOT EDIT)

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
# 挙動がおかしいときは chsh, $SHELL あたりを確認。$SHELL がちがう shell なら os reboot
export PATH="$HOME/.anyenv/bin:$PATH"
eval "$(anyenv init -)"

# direnv
eval "$(direnv hook zsh)"

# pbcopy/pbpaste
if command -v xsel &> /dev/null; then
  alias pbcopy='xsel --clipboard --input'
  alias pbpaste='xsel --clipboard --output'
fi

# fzf
if [[ $(command -v brew) ]]; then
  if [ "$(brew list | grep -c "^fzf@*.*$")" -gt 0 ]; then
    # shellcheck source=/dev/null
    [ -f "$HOME/.fzf.zsh" ] && . "$HOME/.fzf.zsh"
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
if command -v bat &> /dev/null; then
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

# Starship ... https://starship.rs/ja-jp/guide/
# ※ 一番最後の行に設定が必要
if command -v starship &> /dev/null; then
  eval "$(starship init zsh)"
fi
