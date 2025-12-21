#!/usr/bin/env bash

# ------------------------------------------------------------------------------
# dotfiles.sh - Main dotfiles installation script
# ------------------------------------------------------------------------------

set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"

# Source library files
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/lib/log.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/lib/utils.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/lib/symlink.sh"

# Install dotfiles by creating symlinks
install_dotfiles() {
  local config_file="${DOTFILES_DIR}/config/platform-files.conf"
  local current_os
  local installed_count=0
  local skipped_count=0

  current_os=$(detect_os)
  log_header "Installing dotfiles"
  log_info "Detected OS: $current_os"
  log_info "Dotfiles directory: $DOTFILES_DIR"
  log_info "Backup directory: $BACKUP_DIR"
  echo ""

  # Read config file line by line
  while IFS= read -r line || [[ -n "$line" ]]; do
    # Skip empty lines and comments
    [[ -z "$line" ]] && continue
    [[ "$line" =~ ^[[:space:]]*# ]] && continue

    # Parse line: SOURCE:DESTINATION:PLATFORMS
    local src dest platforms
    IFS=':' read -r src dest platforms <<< "$line"

    # Trim whitespace
    src=$(echo "$src" | xargs)
    dest=$(echo "$dest" | xargs)
    platforms=$(echo "$platforms" | xargs)

    # Skip if required fields are missing
    if [[ -z "$src" ]] || [[ -z "$dest" ]] || [[ -z "$platforms" ]]; then
      log_warn "Invalid config line (skipping): $line"
      continue
    fi

    # Check platform support
    if ! is_platform_supported "$platforms"; then
      log_debug "Skipping (not supported on $current_os): $src"
      skipped_count=$((skipped_count + 1))
      continue
    fi

    # Expand paths
    local full_src="${DOTFILES_DIR}/src/${src}"
    local full_dest
    full_dest=$(expand_path "$dest")

    # Verify source exists
    if [[ ! -e "$full_src" ]]; then
      log_warn "Source file not found (skipping): $full_src"
      skipped_count=$((skipped_count + 1))
      continue
    fi

    # Create symlink
    if create_symlink "$full_src" "$full_dest"; then
      installed_count=$((installed_count + 1))
    fi

  done < "$config_file"

  echo ""
  log_success "Dotfiles installation complete!"
  log_info "Installed: $installed_count, Skipped: $skipped_count"
}

# Uninstall dotfiles by removing symlinks
uninstall_dotfiles() {
  local config_file="${DOTFILES_DIR}/config/platform-files.conf"
  local current_os
  local removed_count=0

  current_os=$(detect_os)
  log_header "Uninstalling dotfiles"
  log_info "Detected OS: $current_os"
  echo ""

  # Read config file line by line
  while IFS= read -r line || [[ -n "$line" ]]; do
    # Skip empty lines and comments
    [[ -z "$line" ]] && continue
    [[ "$line" =~ ^[[:space:]]*# ]] && continue

    # Parse line: SOURCE:DESTINATION:PLATFORMS
    local src dest platforms
    IFS=':' read -r src dest platforms <<< "$line"

    # Trim whitespace
    dest=$(echo "$dest" | xargs)
    platforms=$(echo "$platforms" | xargs)

    # Skip if platform not supported
    if ! is_platform_supported "$platforms"; then
      continue
    fi

    # Expand destination path
    local full_dest
    full_dest=$(expand_path "$dest")

    # Check if it's our symlink
    local expected_src="${DOTFILES_DIR}/src/${src}"
    expected_src=$(echo "$expected_src" | xargs)

    if is_symlink_valid "$full_dest" "$expected_src"; then
      remove_symlink "$full_dest" true
      removed_count=$((removed_count + 1))
    fi

  done < "$config_file"

  echo ""
  log_success "Dotfiles uninstallation complete!"
  log_info "Removed: $removed_count symlinks"
}

# Show status of dotfiles
status_dotfiles() {
  local config_file="${DOTFILES_DIR}/config/platform-files.conf"
  local current_os

  current_os=$(detect_os)
  log_header "Dotfiles Status"
  log_info "Detected OS: $current_os"
  echo ""

  printf "%-40s %-10s %s\n" "FILE" "STATUS" "DETAILS"
  printf "%-40s %-10s %s\n" "----" "------" "-------"

  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" ]] && continue
    [[ "$line" =~ ^[[:space:]]*# ]] && continue

    local src dest platforms
    IFS=':' read -r src dest platforms <<< "$line"

    src=$(echo "$src" | xargs)
    dest=$(echo "$dest" | xargs)
    platforms=$(echo "$platforms" | xargs)

    if ! is_platform_supported "$platforms"; then
      continue
    fi

    local full_src="${DOTFILES_DIR}/src/${src}"
    local full_dest
    full_dest=$(expand_path "$dest")
    local status details

    if [[ ! -e "$full_src" ]]; then
      status="MISSING"
      details="Source not found"
    elif [[ -L "$full_dest" ]]; then
      local target
      target=$(readlink "$full_dest")
      if [[ "$target" == "$full_src" ]]; then
        status="OK"
        details="Linked correctly"
      else
        status="WRONG"
        details="Links to: $target"
      fi
    elif [[ -e "$full_dest" ]]; then
      status="EXISTS"
      details="Not a symlink"
    else
      status="NONE"
      details="Not installed"
    fi

    printf "%-40s %-10s %s\n" "$src" "$status" "$details"

  done < "$config_file"
}

# Main entry point when script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  case "${1:-install}" in
    install)
      install_dotfiles
      ;;
    uninstall)
      uninstall_dotfiles
      ;;
    status)
      status_dotfiles
      ;;
    *)
      echo "Usage: $0 {install|uninstall|status}"
      exit 1
      ;;
  esac
fi
