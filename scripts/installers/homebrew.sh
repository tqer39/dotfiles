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

extract_third_party_brew_formulae() {
  local brewfile="$1"

  sed -nE 's/^[[:space:]]*brew[[:space:]]+"([^"/]+\/[^"/]+\/[^"]+)".*/\1/p' "$brewfile"
}

trust_brewfile_formulae() {
  local brewfile="$1"
  local formula
  local formulae=()

  while IFS= read -r formula; do
    [[ -n "$formula" ]] || continue
    formulae+=("$formula")
  done < <(extract_third_party_brew_formulae "$brewfile")

  if [[ ${#formulae[@]} -eq 0 ]]; then
    return 0
  fi

  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    for formula in "${formulae[@]}"; do
      log_info "[DRY-RUN] Would run: brew trust --formula $formula"
    done
    return 0
  fi

  if ! brew help trust &>/dev/null; then
    log_debug "brew trust is not available; skipping formula trust"
    return 0
  fi

  for formula in "${formulae[@]}"; do
    log_info "Trusting Homebrew formula: $formula"
    if ! brew trust --formula "$formula"; then
      log_warn "Failed to trust Homebrew formula: $formula"
    fi
  done
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
    log_info "[DRY-RUN] Would install Brewfile entries with live output and per-package timing: $brewfile"
    return 0
  fi

  # Ensure brew is available
  if ! command_exists brew; then
    log_error "Homebrew is not installed"
    return 1
  fi

  local log_dir="${DOTFILES_INSTALL_LOG_DIR:-${HOME}/.dotfiles_logs}"
  mkdir -p "$log_dir"
  local bundle_log
  bundle_log=$(mktemp "${log_dir}/homebrew-$(date '+%Y%m%d-%H%M%S').XXXXXX")
  log_info "Homebrew installation log: $bundle_log"

  # Update Homebrew
  log_info "Updating Homebrew..."
  brew update 2>&1 | tee -a "$bundle_log"

  trust_brewfile_formulae "$brewfile" 2>&1 | tee -a "$bundle_log"

  # Use Homebrew's own installer one entry at a time to measure actual package
  # operations, rather than inferring durations from batched console messages.
  local bundle_exit=0
  HOMEBREW_DEVELOPER=0 brew ruby "${SCRIPT_DIR}/timed-bundle.rb" "$brewfile" 2>&1 |
    while IFS= read -r line || [[ -n "$line" ]]; do
      printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$line"
    done | tee -a "$bundle_log" || bundle_exit=$?

  # Check for deprecated tap errors (configuration issues that must be fixed)
  if grep -q "was deprecated" "$bundle_log"; then
    log_error "Deprecated tap found in Brewfile. Please remove it."
    return 1
  fi

  # Handle bundle exit code
  if [[ $bundle_exit -ne 0 ]]; then
    if [[ "${CI_MODE:-false}" == "true" ]]; then
      # In CI mode, allow package install failures (e.g., GUI apps that can't install in CI)
      log_warn "Some packages failed to install (CI mode, continuing)"
      return 0
    else
      log_error "Package installation failed. See: $bundle_log"
      return "$bundle_exit"
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
