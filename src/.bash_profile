#!/bin/bash

# ------------------------------------------------------------------------------
# brew
# ------------------------------------------------------------------------------
detect_os() {
  if [ "$(uname)" == "Darwin" ]; then
    PLATFORM=mac
  elif [ "$(uname -s)" == "MINGW" ]; then
    PLATFORM=windows
  elif [ "$(uname -s)" == "Linux" ]; then
    PLATFORM=linux
  else
    PLATFORM="Unknown OS"
    abort "Your platform ($(uname -a)) is not supported."
  fi
}

is_exists() {
  which "$1" >/dev/null 2>&1
  return $?
}

is_linux() {
  if [ "$PLATFORM" == 'linux' ]; then
    return 0
  else
    return 1
  fi
}

is_mac() {
  if [ "$PLATFORM" == 'mac' ]; then
    return 0
  else
    return 1
  fi
}

if [[ $(command -v brew) ]]; then
  if is_linux; then
    if [ -r "/home/linuxbrew/.linuxbrew/etc/profile.d/bash_completion.sh" ]; then
      # shellcheck source=/dev/null
      . "/home/linuxbrew/.linuxbrew/etc/profile.d/bash_completion.sh"
    fi
  fi

  if is_mac; then
    if [ -r "/opt/homebrew/etc/profile.d/bash_completion.sh" ]; then
      # shellcheck source=/dev/null
      . "/opt/homebrew/etc/profile.d/bash_completion.sh"
    fi
  fi
fi

# anyenv
export PATH="$HOME/.anyenv/bin:$PATH"
eval "$(anyenv init -)"

# ruff
# shellcheck source=/dev/null
. "$HOME/.cargo/env"

# Rancher Desktop
### MANAGED BY RANCHER DESKTOP START (DO NOT EDIT)
export PATH="/home/tqer39/.rd/bin:$PATH"
### MANAGED BY RANCHER DESKTOP END (DO NOT EDIT)
