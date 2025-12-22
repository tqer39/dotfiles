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

  echo "deb ${repo_url} /" | sudo tee /etc/apt/sources.list.d/home_manuelschneid3r.list > /dev/null
  curl -fsSL "${key_url}" | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/home_manuelschneid3r.gpg > /dev/null

  sudo apt update
  sudo apt install -y albert

  log_success "Albert launcher installed"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  install_apt_packages
fi
