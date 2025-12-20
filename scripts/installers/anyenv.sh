#!/usr/bin/env bash

# ------------------------------------------------------------------------------
# anyenv.sh - anyenv and language runtime installer
# ------------------------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Source library files if not already sourced
if ! declare -f log_info &>/dev/null; then
  # shellcheck source=/dev/null
  source "${SCRIPT_DIR}/../lib/log.sh"
  # shellcheck source=/dev/null
  source "${SCRIPT_DIR}/../lib/utils.sh"
fi

# anyenv installation directory
ANYENV_ROOT="${ANYENV_ROOT:-${HOME}/.anyenv}"

# Install anyenv (idempotent)
install_anyenv() {
  log_info "Checking anyenv installation..."

  if [[ -d "$ANYENV_ROOT" ]]; then
    log_success "anyenv is already installed"

    # Initialize anyenv for this session
    export PATH="${ANYENV_ROOT}/bin:$PATH"
    eval "$(anyenv init -)"

    return 0
  fi

  log_info "Installing anyenv..."

  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_info "[DRY-RUN] Would install anyenv to $ANYENV_ROOT"
    return 0
  fi

  # Clone anyenv
  git clone https://github.com/anyenv/anyenv "$ANYENV_ROOT"

  # Setup PATH
  export PATH="${ANYENV_ROOT}/bin:$PATH"

  # Initialize anyenv
  anyenv install --force-init

  # Initialize for this session
  eval "$(anyenv init -)"

  log_success "anyenv installed successfully"
}

# Install anyenv plugin (anyenv-update)
install_anyenv_plugins() {
  local plugins_dir="${ANYENV_ROOT}/plugins"

  if [[ ! -d "$plugins_dir" ]]; then
    mkdir -p "$plugins_dir"
  fi

  # Install anyenv-update for easy updates
  if [[ ! -d "${plugins_dir}/anyenv-update" ]]; then
    log_info "Installing anyenv-update plugin..."
    if [[ "${DRY_RUN:-false}" != "true" ]]; then
      git clone https://github.com/znz/anyenv-update.git "${plugins_dir}/anyenv-update"
    fi
  fi

  log_success "anyenv plugins installed"
}

# Install a specific *env (pyenv, nodenv, rbenv, etc.)
install_env() {
  local env_name="$1"

  # Check if already installed
  if anyenv envs 2>/dev/null | grep -q "^${env_name}$"; then
    log_debug "${env_name} is already installed"
    return 0
  fi

  log_info "Installing ${env_name}..."

  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_info "[DRY-RUN] Would run: anyenv install ${env_name}"
    return 0
  fi

  anyenv install "$env_name"

  # Re-initialize anyenv to load new env
  eval "$(anyenv init -)"

  log_success "${env_name} installed successfully"
}

# Install pyenv and Python
install_python_env() {
  install_env "pyenv"

  # Check if Python version file exists in dotfiles
  local python_version_file="${DOTFILES_DIR}/.python-version"
  if [[ -f "$python_version_file" ]]; then
    local version
    version=$(cat "$python_version_file")
    log_info "Installing Python ${version}..."

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
      log_info "[DRY-RUN] Would install Python ${version}"
      return 0
    fi

    # Check if version is already installed
    if pyenv versions 2>/dev/null | grep -q "$version"; then
      log_debug "Python ${version} is already installed"
    else
      pyenv install "$version"
    fi

    # Set global version
    pyenv global "$version"
    log_success "Python ${version} installed and set as global"
  fi
}

# Install nodenv and Node.js
install_node_env() {
  install_env "nodenv"

  # Install node-build plugin if not present
  local nodenv_root="${ANYENV_ROOT}/envs/nodenv"
  if [[ -d "$nodenv_root" ]] && [[ ! -d "${nodenv_root}/plugins/node-build" ]]; then
    log_info "Installing node-build plugin..."
    if [[ "${DRY_RUN:-false}" != "true" ]]; then
      git clone https://github.com/nodenv/node-build.git "${nodenv_root}/plugins/node-build"
    fi
  fi
}

# Install all language environments
install_all_envs() {
  log_info "Installing language runtime environments..."

  # Install anyenv first
  install_anyenv
  install_anyenv_plugins

  # Install language environments
  install_python_env
  install_node_env

  log_success "All language environments installed"
}

# Update all envs
update_anyenv() {
  if ! command_exists anyenv; then
    log_warn "anyenv is not installed"
    return 0
  fi

  log_info "Updating anyenv and all environments..."

  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_info "[DRY-RUN] Would run: anyenv update"
    return 0
  fi

  anyenv update
  log_success "anyenv updated"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  install_all_envs
fi
