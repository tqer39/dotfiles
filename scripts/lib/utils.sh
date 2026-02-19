#!/usr/bin/env bash

# ------------------------------------------------------------------------------
# utils.sh - Utility functions for dotfiles setup
# ------------------------------------------------------------------------------

# Include guard to prevent multiple sourcing
if [[ -n "${_UTILS_SH_LOADED:-}" ]]; then
  return 0
fi
readonly _UTILS_SH_LOADED=1

# Trim leading and trailing whitespace from a string
# Usage: trim "  hello world  " -> "hello world"
trim() {
  local str="$1"
  # Remove leading whitespace
  str="${str#"${str%%[![:space:]]*}"}"
  # Remove trailing whitespace
  str="${str%"${str##*[![:space:]]}"}"
  echo "$str"
}

# Detect operating system
# Returns: macos, ubuntu, mint, linux, windows, unknown
# Can be overridden by DOTFILES_OS_OVERRIDE environment variable
detect_os() {
  if [[ -n "${DOTFILES_OS_OVERRIDE:-}" ]]; then
    echo "$DOTFILES_OS_OVERRIDE"
    return 0
  fi

  case "$(uname -s)" in
    Darwin)
      echo "macos"
      ;;
    Linux)
      if [[ -f /etc/os-release ]]; then
        # shellcheck source=/dev/null
        . /etc/os-release
        case "$ID" in
          ubuntu|debian)
            echo "ubuntu"
            ;;
          linuxmint)
            echo "mint"
            ;;
          *)
            echo "linux"
            ;;
        esac
      else
        echo "linux"
      fi
      ;;
    CYGWIN*|MINGW*|MSYS*)
      echo "windows"
      ;;
    *)
      echo "unknown"
      ;;
  esac
}

# Get Ubuntu codename for Ubuntu-based distributions
# On Mint, returns UBUNTU_CODENAME; on Ubuntu, returns VERSION_CODENAME
get_ubuntu_codename() {
  if [[ -f /etc/os-release ]]; then
    # shellcheck source=/dev/null
    . /etc/os-release
    # Mint provides UBUNTU_CODENAME pointing to the upstream Ubuntu release
    if [[ -n "${UBUNTU_CODENAME:-}" ]]; then
      echo "$UBUNTU_CODENAME"
    else
      echo "${VERSION_CODENAME:-}"
    fi
  fi
}

# Get Ubuntu VERSION_ID for Ubuntu-based distributions
# On Mint, maps UBUNTU_CODENAME to Ubuntu VERSION_ID
get_ubuntu_version_id() {
  if [[ -f /etc/os-release ]]; then
    # shellcheck source=/dev/null
    . /etc/os-release
    local os_id="${ID:-}"
    if [[ "$os_id" != "linuxmint" ]]; then
      echo "${VERSION_ID:-}"
      return 0
    fi
    # Map Ubuntu codename to VERSION_ID
    local codename
    codename="${UBUNTU_CODENAME:-}"
    case "$codename" in
      plucky)   echo "25.04" ;;
      oracular) echo "24.10" ;;
      noble)    echo "24.04" ;;
      mantic)   echo "23.10" ;;
      lunar)    echo "23.04" ;;
      kinetic)  echo "22.10" ;;
      jammy)    echo "22.04" ;;
      impish)   echo "21.10" ;;
      focal)    echo "20.04" ;;
      bionic)   echo "18.04" ;;
      *)
        log_warn "Unknown Ubuntu codename: $codename"
        echo ""
        ;;
    esac
  fi
}

# Get VS Code user settings directory
get_vscode_user_dir() {
  local os
  os=$(detect_os)
  case "$os" in
    macos)
      echo "${HOME}/Library/Application Support/Code/User"
      ;;
    ubuntu|mint|linux)
      echo "${HOME}/.config/Code/User"
      ;;
    windows)
      echo "${APPDATA}/Code/User"
      ;;
    *)
      echo "${HOME}/.config/Code/User"
      ;;
  esac
}

# Check if a platform is supported for a given file
# Usage: is_platform_supported "macos,linux" -> returns 0 if current OS matches
is_platform_supported() {
  local platforms="$1"
  local current_os
  current_os=$(detect_os)

  # "all" matches everything
  if [[ "$platforms" == "all" ]]; then
    return 0
  fi

  # Check each platform in the comma-separated list
  IFS=',' read -ra platform_list <<< "$platforms"
  for platform in "${platform_list[@]}"; do
    # Trim whitespace
    platform=$(trim "$platform")
    if [[ "$platform" == "$current_os" ]]; then
      return 0
    fi
    # "linux" should also match "ubuntu" and "mint"
    if [[ "$platform" == "linux" && ("$current_os" == "ubuntu" || "$current_os" == "mint") ]]; then
      return 0
    fi
    # "ubuntu" should also match "mint" (Ubuntu-based)
    if [[ "$platform" == "ubuntu" && "$current_os" == "mint" ]]; then
      return 0
    fi
  done

  return 1
}

# Expand path variables
# Supports: ~, VSCODE_USER_DIR
expand_path() {
  local path="$1"

  # Expand ~ to HOME
  path="${path/#\~/$HOME}"

  # Expand VSCODE_USER_DIR
  if [[ "$path" == *"VSCODE_USER_DIR"* ]]; then
    local vscode_dir
    vscode_dir=$(get_vscode_user_dir)
    path="${path/VSCODE_USER_DIR/$vscode_dir}"
  fi

  echo "$path"
}

# Check if a command exists
command_exists() {
  command -v "$1" &>/dev/null
}

# Require a command to be available, exit if not
require_command() {
  local cmd="$1"
  local install_hint="${2:-}"

  if ! command_exists "$cmd"; then
    log_error "Required command not found: $cmd"
    if [[ -n "$install_hint" ]]; then
      log_error "Install hint: $install_hint"
    fi
    exit 1
  fi
}

# Run a command with optional dry-run support
# Usage: run_cmd "command" "description" [dry_run]
run_cmd() {
  local cmd="$1"
  local description="${2:-Running command}"
  local dry_run="${3:-false}"

  if [[ "$dry_run" == "true" ]]; then
    log_info "[DRY-RUN] $description: $cmd"
    return 0
  fi

  log_debug "$description: $cmd"
  eval "$cmd"
}

# Get the script's directory (works even when sourced)
get_script_dir() {
  local source="${BASH_SOURCE[0]}"
  while [[ -L "$source" ]]; do
    local dir
    dir=$(cd -P "$(dirname "$source")" && pwd)
    source=$(readlink "$source")
    [[ $source != /* ]] && source="$dir/$source"
  done
  cd -P "$(dirname "$source")" && pwd
}
