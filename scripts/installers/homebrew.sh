#!/usr/bin/env bash

# ------------------------------------------------------------------------------
# homebrew.sh - Homebrew installer for macOS and Linux
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

# Install Homebrew (idempotent)
install_homebrew() {
  log_info "Checking Homebrew installation..."

  if command_exists brew; then
    log_success "Homebrew is already installed"
    return 0
  fi

  log_info "Installing Homebrew..."

  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_info "[DRY-RUN] Would install Homebrew"
    return 0
  fi

  # Install Homebrew
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Setup PATH for current session
  local os
  os=$(detect_os)
  if [[ "$os" == "macos" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ "$os" == "ubuntu" ]] || [[ "$os" == "linux" ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  fi

  log_success "Homebrew installed successfully"
}

# Install packages from Brewfile
install_homebrew_packages() {
  local brewfile="${DOTFILES_DIR}/config/packages/Brewfile"

  if [[ ! -f "$brewfile" ]]; then
    log_warn "Brewfile not found: $brewfile"
    return 0
  fi

  log_info "Installing packages from Brewfile..."

  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_info "[DRY-RUN] Would run: brew bundle --file=$brewfile"
    return 0
  fi

  # Ensure brew is available
  if ! command_exists brew; then
    log_error "Homebrew is not installed"
    return 1
  fi

  # Update Homebrew
  log_info "Updating Homebrew..."
  brew update

  # Install from Brewfile
  # In CI mode, continue even if some packages fail (e.g., GUI apps)
  if [[ "${CI_MODE:-false}" == "true" ]]; then
    # Try to install, but don't fail if some packages can't be installed
    if ! brew bundle --file="$brewfile" --no-lock; then
      log_warn "Some packages failed to install (CI mode, continuing)"
    fi
  else
    brew bundle --file="$brewfile" --no-lock
  fi

  log_success "Homebrew packages installed successfully"
}

# Install a single brew package (idempotent)
install_brew_package() {
  local package="$1"
  local cask="${2:-false}"

  if [[ "$cask" == "true" ]]; then
    if brew list --cask "$package" &>/dev/null; then
      log_debug "Cask already installed: $package"
      return 0
    fi
    log_info "Installing cask: $package"
    if [[ "${DRY_RUN:-false}" != "true" ]]; then
      brew install --cask "$package"
    fi
  else
    if brew list "$package" &>/dev/null; then
      log_debug "Package already installed: $package"
      return 0
    fi
    log_info "Installing package: $package"
    if [[ "${DRY_RUN:-false}" != "true" ]]; then
      brew install "$package"
    fi
  fi
}

# Uninstall Homebrew packages
uninstall_homebrew_packages() {
  local brewfile="${DOTFILES_DIR}/config/packages/Brewfile"

  if [[ ! -f "$brewfile" ]]; then
    return 0
  fi

  log_info "Uninstalling packages from Brewfile..."

  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_info "[DRY-RUN] Would run: brew bundle cleanup --file=$brewfile --force"
    return 0
  fi

  brew bundle cleanup --file="$brewfile" --force

  log_success "Homebrew packages uninstalled"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  install_homebrew
  install_homebrew_packages
fi
