#!/usr/bin/env bash

# ------------------------------------------------------------------------------
# apt.sh - APT package installer for Ubuntu/Debian
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

# Update apt package list
update_apt() {
  log_info "Updating apt package list..."

  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_info "[DRY-RUN] Would run: sudo apt update"
    return 0
  fi

  sudo apt update
  log_success "Package list updated"
}

# Install a single apt package (idempotent)
install_apt_package() {
  local package="$1"

  if dpkg -l "$package" 2>/dev/null | grep -q "^ii"; then
    log_debug "Package already installed: $package"
    return 0
  fi

  log_info "Installing package: $package"

  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_info "[DRY-RUN] Would run: sudo apt install -y $package"
    return 0
  fi

  sudo apt install -y "$package"
}

# Install packages from apt-packages.txt
install_apt_packages() {
  local packages_file="${DOTFILES_DIR}/config/packages/apt-packages.txt"

  # Check if running on Ubuntu/Debian
  local os
  os=$(detect_os)
  if [[ "$os" != "ubuntu" && "$os" != "linux" ]]; then
    log_warn "APT is only available on Ubuntu/Debian. Skipping..."
    return 0
  fi

  if [[ ! -f "$packages_file" ]]; then
    log_warn "apt-packages.txt not found: $packages_file"
    return 0
  fi

  log_info "Installing packages from apt-packages.txt..."

  # Update package list first
  update_apt

  # Read and install packages
  while IFS= read -r line || [[ -n "$line" ]]; do
    # Skip empty lines and comments
    [[ -z "$line" ]] && continue
    [[ "$line" =~ ^[[:space:]]*# ]] && continue

    # Trim whitespace
    local package
    package=$(echo "$line" | xargs)

    install_apt_package "$package"
  done < "$packages_file"

  log_success "APT packages installed successfully"
}

# Install essential build dependencies
install_build_essentials() {
  log_info "Installing build essentials..."

  local packages=(
    "build-essential"
    "curl"
    "wget"
    "git"
    "software-properties-common"
    "apt-transport-https"
    "ca-certificates"
    "gnupg"
    "lsb-release"
  )

  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_info "[DRY-RUN] Would install: ${packages[*]}"
    return 0
  fi

  update_apt

  for package in "${packages[@]}"; do
    install_apt_package "$package"
  done

  log_success "Build essentials installed"
}

# Install Albert launcher
install_albert() {
  log_info "Installing Albert launcher..."

  # Check if running on Ubuntu/Debian
  local os
  os=$(detect_os)
  if [[ "$os" != "ubuntu" && "$os" != "linux" ]]; then
    log_warn "Albert is only available on Ubuntu/Debian. Skipping..."
    return 0
  fi

  # Check if already installed
  if command -v albert &>/dev/null; then
    log_debug "Albert is already installed"
    return 0
  fi

  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_info "[DRY-RUN] Would install Albert launcher"
    return 0
  fi

  # Get Ubuntu version
  local ubuntu_version
  if [[ -f /etc/os-release ]]; then
    # shellcheck source=/dev/null
    . /etc/os-release
    ubuntu_version="${VERSION_ID}"
  else
    log_warn "Cannot detect Ubuntu version. Skipping Albert installation."
    return 0
  fi

  # Add Albert repository
  local repo_url="https://download.opensuse.org/repositories/home:/manuelschneid3r/xUbuntu_${ubuntu_version}/"
  local key_url="https://download.opensuse.org/repositories/home:manuelschneid3r/xUbuntu_${ubuntu_version}/Release.key"

  log_info "Adding Albert repository for Ubuntu ${ubuntu_version}..."

  # In CI mode, continue even if Albert installation fails
  # (repository might not be available for all Ubuntu versions)
  if [[ "${CI_MODE:-false}" == "true" ]]; then
    if ! (
      echo "deb ${repo_url} /" | sudo tee /etc/apt/sources.list.d/home_manuelschneid3r.list > /dev/null &&
      curl -fsSL "${key_url}" | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/home_manuelschneid3r.gpg > /dev/null &&
      sudo apt update &&
      sudo apt install -y albert
    ); then
      log_warn "Failed to install Albert (CI mode, continuing)"
      return 0
    fi
  else
    echo "deb ${repo_url} /" | sudo tee /etc/apt/sources.list.d/home_manuelschneid3r.list > /dev/null
    curl -fsSL "${key_url}" | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/home_manuelschneid3r.gpg > /dev/null

    sudo apt update
    sudo apt install -y albert
  fi

  log_success "Albert launcher installed"
}

# Install 1Password
install_1password() {
  log_info "Installing 1Password..."

  # Check if running on Ubuntu/Debian
  local os
  os=$(detect_os)
  if [[ "$os" != "ubuntu" && "$os" != "linux" ]]; then
    log_warn "1Password apt installation is only available on Ubuntu/Debian. Skipping..."
    return 0
  fi

  # Check if already installed
  if command -v 1password &>/dev/null; then
    log_debug "1Password is already installed"
    return 0
  fi

  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_info "[DRY-RUN] Would install 1Password"
    return 0
  fi

  # Add 1Password GPG key
  log_info "Adding 1Password repository..."

  # In CI mode, continue even if 1Password installation fails
  if [[ "${CI_MODE:-false}" == "true" ]]; then
    if ! (
      curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
        sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg &&
      echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/amd64 stable main' | \
        sudo tee /etc/apt/sources.list.d/1password.list > /dev/null &&
      sudo mkdir -p /etc/debsig/policies/AC2D62742012EA22/ &&
      curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol | \
        sudo tee /etc/debsig/policies/AC2D62742012EA22/1password.pol > /dev/null &&
      sudo mkdir -p /usr/share/debsig/keyrings/AC2D62742012EA22 &&
      curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
        sudo gpg --dearmor --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg &&
      sudo apt update &&
      sudo apt install -y 1password
    ); then
      log_warn "Failed to install 1Password (CI mode, continuing)"
      return 0
    fi
  else
    curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
      sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg

    echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/amd64 stable main' | \
      sudo tee /etc/apt/sources.list.d/1password.list > /dev/null

    # Add debsig-verify policy
    sudo mkdir -p /etc/debsig/policies/AC2D62742012EA22/
    curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol | \
      sudo tee /etc/debsig/policies/AC2D62742012EA22/1password.pol > /dev/null
    sudo mkdir -p /usr/share/debsig/keyrings/AC2D62742012EA22
    curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
      sudo gpg --dearmor --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg

    sudo apt update
    sudo apt install -y 1password
  fi

  log_success "1Password installed"
}

# Install VS Code
install_vscode() {
  log_info "Installing VS Code..."

  # Check if running on Ubuntu/Debian
  local os
  os=$(detect_os)
  if [[ "$os" != "ubuntu" && "$os" != "linux" ]]; then
    log_warn "VS Code apt installation is only available on Ubuntu/Debian. Skipping..."
    return 0
  fi

  # Check if already installed
  if command -v code &>/dev/null; then
    log_debug "VS Code is already installed"
    return 0
  fi

  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_info "[DRY-RUN] Would install VS Code"
    return 0
  fi

  log_info "Adding Microsoft VS Code repository..."

  # In CI mode, continue even if VS Code installation fails
  if [[ "${CI_MODE:-false}" == "true" ]]; then
    if ! (
      sudo apt-get install -y wget gpg &&
      wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /tmp/microsoft.gpg &&
      sudo install -D -o root -g root -m 644 /tmp/microsoft.gpg /usr/share/keyrings/microsoft.gpg &&
      rm -f /tmp/microsoft.gpg &&
      echo "deb [arch=amd64,arm64,armhf signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | \
        sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null &&
      sudo apt-get install -y apt-transport-https &&
      sudo apt-get update &&
      sudo apt-get install -y code
    ); then
      log_warn "Failed to install VS Code (CI mode, continuing)"
      return 0
    fi
  else
    sudo apt-get install -y wget gpg
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /tmp/microsoft.gpg
    sudo install -D -o root -g root -m 644 /tmp/microsoft.gpg /usr/share/keyrings/microsoft.gpg
    rm -f /tmp/microsoft.gpg

    echo "deb [arch=amd64,arm64,armhf signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | \
      sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null

    sudo apt-get install -y apt-transport-https
    sudo apt-get update
    sudo apt-get install -y code
  fi

  log_success "VS Code installed"
}

# Install Ghostty terminal
install_ghostty() {
  log_info "Installing Ghostty terminal..."

  # Check if running on Ubuntu/Debian
  local os
  os=$(detect_os)
  if [[ "$os" != "ubuntu" && "$os" != "linux" ]]; then
    log_warn "Ghostty apt installation is only available on Ubuntu/Debian. Skipping..."
    return 0
  fi

  # Check if already installed
  if command -v ghostty &>/dev/null; then
    log_debug "Ghostty is already installed"
    return 0
  fi

  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_info "[DRY-RUN] Would install Ghostty"
    return 0
  fi

  # Check if snap is available
  if ! command -v snap &>/dev/null; then
    log_warn "Snap is not available. Skipping Ghostty installation."
    return 0
  fi

  log_info "Installing Ghostty via Snap..."

  if [[ "${CI_MODE:-false}" == "true" ]]; then
    if ! sudo snap install ghostty --classic; then
      log_warn "Failed to install Ghostty (CI mode, continuing)"
      return 0
    fi
  else
    sudo snap install ghostty --classic
  fi

  log_success "Ghostty terminal installed"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  install_apt_packages
fi
