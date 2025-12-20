#!/usr/bin/env bash

# ------------------------------------------------------------------------------
# utils.sh - Utility functions for dotfiles setup
# ------------------------------------------------------------------------------

# Detect operating system
# Returns: macos, ubuntu, linux, windows, unknown
detect_os() {
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

# Get VS Code user settings directory
get_vscode_user_dir() {
  local os
  os=$(detect_os)
  case "$os" in
    macos)
      echo "${HOME}/Library/Application Support/Code/User"
      ;;
    ubuntu|linux)
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
    platform=$(echo "$platform" | xargs)
    if [[ "$platform" == "$current_os" ]]; then
      return 0
    fi
    # "linux" should also match "ubuntu"
    if [[ "$platform" == "linux" && "$current_os" == "ubuntu" ]]; then
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
