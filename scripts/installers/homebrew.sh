#!/usr/bin/env bash

# ------------------------------------------------------------------------------
# homebrew.sh - Homebrew installer for macOS and Linux
# ------------------------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Source library files.
# 各 lib は include guard を持つため多重 source しても安全。
# `declare -f log_info` で判定すると、install.sh が同名の簡易版を先に定義して
# いるケースで lib が読み込まれず、command_exists / log_debug が未定義になる。
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/../lib/log.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/../lib/utils.sh"

# Pass WORK_MODE through to the Brewfile.
#
# Homebrew は Brewfile を評価する前に HOMEBREW_ 接頭辞のない環境変数を除去する
# ため、Brewfile 内の ENV['WORK_MODE'] は export していても常に nil になる。
# 接頭辞付きの名前で改めて export することで Brewfile から参照できるようにする。
export_brew_work_mode() {
  export HOMEBREW_WORK_MODE="${WORK_MODE:-false}"
}

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

  # Prepare Linuxbrew directory on Linux
  local os
  os=$(detect_os)
  if [[ "$os" == "ubuntu" || "$os" == "mint" || "$os" == "linux" ]]; then
    local brew_prefix="/home/linuxbrew/.linuxbrew"
    if [[ ! -d "$brew_prefix" ]]; then
      log_info "Creating Linuxbrew directory: $brew_prefix"
      sudo mkdir -p "$brew_prefix"
      sudo chmod 777 "$brew_prefix"
    fi
  fi

  # Install Homebrew
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Setup PATH for current session
  local os
  os=$(detect_os)
  if [[ "$os" == "macos" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ "$os" == "ubuntu" ]] || [[ "$os" == "mint" ]] || [[ "$os" == "linux" ]]; then
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

  export_brew_work_mode

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
  # Capture output to detect critical errors (deprecated taps, etc.)
  local bundle_output
  local bundle_exit=0
  bundle_output=$(brew bundle --file="$brewfile" 2>&1) || bundle_exit=$?

  # Always show output
  echo "$bundle_output"

  # Check for deprecated tap errors (configuration issues that must be fixed)
  if echo "$bundle_output" | grep -q "was deprecated"; then
    log_error "Deprecated tap found in Brewfile. Please remove it."
    return 1
  fi

  # Handle bundle exit code
  if [[ $bundle_exit -ne 0 ]]; then
    if [[ "${CI_MODE:-false}" == "true" ]]; then
      # In CI mode, allow package install failures (e.g., GUI apps that can't install in CI)
      log_warn "Some packages failed to install (CI mode, continuing)"
    else
      return 1
    fi
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

  # cleanup も Brewfile を評価するため、install 時と同じ判定になるよう渡す。
  # 渡さないと work 用パッケージが「Brewfile 外」とみなされ削除対象になる。
  export_brew_work_mode

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
