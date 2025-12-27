#!/usr/bin/env bash

# ------------------------------------------------------------------------------
# doctor.sh - Health check utilities for dotfiles setup
# ------------------------------------------------------------------------------

# Include guard to prevent multiple sourcing
if [[ -n "${_DOCTOR_SH_LOADED:-}" ]]; then
  return 0
fi
readonly _DOCTOR_SH_LOADED=1

# Global counters for tracking health status
_DOCTOR_ISSUES=0
_DOCTOR_WARNINGS=0

# ------------------------------------------------------------------------------
# Helper functions for check results
# ------------------------------------------------------------------------------

doctor_check_ok() {
  local component="$1"
  local details="${2:-}"
  printf "%-25s ${LOG_GREEN}%-10s${LOG_NC} %s\n" "$component" "OK" "$details"
}

doctor_check_warn() {
  local component="$1"
  local details="${2:-}"
  printf "%-25s ${LOG_YELLOW}%-10s${LOG_NC} %s\n" "$component" "WARN" "$details"
  _DOCTOR_WARNINGS=$((_DOCTOR_WARNINGS + 1))
}

doctor_check_fail() {
  local component="$1"
  local details="${2:-}"
  printf "%-25s ${LOG_RED}%-10s${LOG_NC} %s\n" "$component" "FAIL" "$details"
  _DOCTOR_ISSUES=$((_DOCTOR_ISSUES + 1))
}

doctor_check_skip() {
  local component="$1"
  local details="${2:-Not applicable}"
  printf "%-25s %-10s %s\n" "$component" "SKIP" "$details"
}

_doctor_section_header() {
  local title="$1"
  echo ""
  echo "$title"
  printf '%s\n' "$(printf -- '-%.0s' {1..50})"
  printf "%-25s %-10s %s\n" "COMPONENT" "STATUS" "DETAILS"
  printf "%-25s %-10s %s\n" "---------" "------" "-------"
}

# ------------------------------------------------------------------------------
# Check functions
# ------------------------------------------------------------------------------

doctor_check_dependencies() {
  local os
  os=$(detect_os)

  _doctor_section_header "Dependencies"

  # Required on all platforms
  for cmd in git curl; do
    if command_exists "$cmd"; then
      local version
      version=$("$cmd" --version 2>/dev/null | head -1)
      doctor_check_ok "$cmd" "$version"
    else
      doctor_check_fail "$cmd" "Not installed"
    fi
  done

  # zsh - required on macos/linux
  if [[ "$os" != "windows" ]]; then
    if command_exists zsh; then
      local version
      version=$(zsh --version 2>/dev/null | head -1)
      doctor_check_ok "zsh" "$version"
    else
      doctor_check_fail "zsh" "Not installed"
    fi
  fi
}

doctor_check_package_manager() {
  local os
  os=$(detect_os)

  _doctor_section_header "Package Manager"

  case "$os" in
    macos)
      if command_exists brew; then
        local version
        version=$(brew --version 2>/dev/null | head -1)
        doctor_check_ok "homebrew" "$version"
      else
        doctor_check_warn "homebrew" "Not installed"
      fi

      local brewfile="${DOTFILES_DIR}/config/packages/Brewfile"
      if [[ -f "$brewfile" ]]; then
        doctor_check_ok "Brewfile" "Found"
      else
        doctor_check_warn "Brewfile" "Not found"
      fi
      ;;
    ubuntu|linux)
      if command_exists apt; then
        doctor_check_ok "apt" "Available"
      else
        doctor_check_fail "apt" "Not available"
      fi

      local packages_file="${DOTFILES_DIR}/config/packages/apt-packages.txt"
      if [[ -f "$packages_file" ]]; then
        doctor_check_ok "apt-packages.txt" "Found"
      else
        doctor_check_warn "apt-packages.txt" "Not found"
      fi
      ;;
    windows)
      if command_exists scoop; then
        doctor_check_ok "scoop" "Available"
      elif command_exists winget; then
        doctor_check_ok "winget" "Available"
      else
        doctor_check_warn "Package Manager" "Neither scoop nor winget found"
      fi
      ;;
    *)
      doctor_check_skip "Package Manager" "Unknown OS"
      ;;
  esac
}

doctor_check_symlinks() {
  local config_file="${DOTFILES_DIR}/config/platform-files.conf"

  _doctor_section_header "Symlinks"

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

    if [[ ! -e "$full_src" ]]; then
      doctor_check_fail "$src" "Source not found"
    elif [[ -L "$full_dest" ]]; then
      local target
      target=$(readlink "$full_dest")
      if [[ "$target" == "$full_src" ]]; then
        doctor_check_ok "$src" "Linked correctly"
      else
        doctor_check_fail "$src" "Wrong target"
      fi
    elif [[ -e "$full_dest" ]]; then
      doctor_check_fail "$src" "Exists but not a symlink"
    else
      doctor_check_warn "$src" "Not installed"
    fi
  done < "$config_file"
}

doctor_check_runtimes() {
  _doctor_section_header "Language Runtimes"

  # Check mise first (preferred)
  if command_exists mise; then
    local mise_version
    mise_version=$(mise --version 2>/dev/null | head -1)
    doctor_check_ok "mise" "$mise_version"

    # Check Node.js via mise
    local node_version
    node_version=$(mise current node 2>/dev/null)
    if [[ -n "$node_version" && "$node_version" != "missing" ]]; then
      doctor_check_ok "node (mise)" "$node_version"
    else
      doctor_check_warn "node" "Run: mise install node"
    fi

    # Check Python via mise (if configured)
    local py_version
    py_version=$(mise current python 2>/dev/null)
    if [[ -n "$py_version" && "$py_version" != "missing" ]]; then
      doctor_check_ok "python (mise)" "$py_version"
    else
      doctor_check_skip "python" "Not configured in mise"
    fi
  # Fallback to anyenv
  else
    local anyenv_root="${ANYENV_ROOT:-${HOME}/.anyenv}"

    if [[ -d "$anyenv_root" ]]; then
      doctor_check_ok "anyenv" "$anyenv_root"

      # Check nodenv
      if [[ -d "${anyenv_root}/envs/nodenv" ]]; then
        doctor_check_ok "nodenv" "Installed"

        if command_exists nodenv; then
          local node_version
          node_version=$(nodenv version 2>/dev/null | awk '{print $1}')
          if [[ -n "$node_version" && "$node_version" != "system" ]]; then
            doctor_check_ok "node" "$node_version"
          else
            doctor_check_warn "node" "No version installed"
          fi
        fi
      else
        doctor_check_warn "nodenv" "Not installed"
      fi

      # Check pyenv
      if [[ -d "${anyenv_root}/envs/pyenv" ]]; then
        doctor_check_ok "pyenv" "Installed"

        if command_exists pyenv; then
          local py_version
          py_version=$(pyenv version 2>/dev/null | awk '{print $1}')
          if [[ -n "$py_version" && "$py_version" != "system" ]]; then
            doctor_check_ok "python" "$py_version"
          else
            doctor_check_warn "python" "No version installed"
          fi
        fi
      else
        doctor_check_warn "pyenv" "Not installed"
      fi
    else
      doctor_check_warn "Runtime Manager" "Neither mise nor anyenv found"
    fi
  fi
}

doctor_check_vscode() {
  _doctor_section_header "VS Code"

  local vscode_cmd=""
  if command_exists code; then
    vscode_cmd="code"
  elif command_exists code-insiders; then
    vscode_cmd="code-insiders"
  fi

  if [[ -n "$vscode_cmd" ]]; then
    local version
    version=$("$vscode_cmd" --version 2>/dev/null | head -1)
    doctor_check_ok "VS Code" "$vscode_cmd ($version)"
  else
    doctor_check_warn "VS Code" "Not installed"
  fi

  local settings_dir
  settings_dir=$(get_vscode_user_dir)
  if [[ -d "$settings_dir" ]]; then
    doctor_check_ok "Settings directory" "Found"
  else
    doctor_check_warn "Settings directory" "Not found"
  fi
}

# ------------------------------------------------------------------------------
# Summary and main entry point
# ------------------------------------------------------------------------------

doctor_print_summary() {
  log_header "Summary"

  if [[ $_DOCTOR_ISSUES -eq 0 ]]; then
    if [[ $_DOCTOR_WARNINGS -eq 0 ]]; then
      log_success "All checks passed!"
    else
      log_success "No critical issues found"
    fi
  else
    log_error "Issues found that require attention"
  fi

  echo ""
  log_info "Issues: $_DOCTOR_ISSUES, Warnings: $_DOCTOR_WARNINGS"
}

run_doctor() {
  local current_os
  current_os=$(detect_os)

  # Reset counters
  _DOCTOR_ISSUES=0
  _DOCTOR_WARNINGS=0

  log_header "Dotfiles Doctor"
  log_info "Detected OS: $current_os"

  # Run all checks
  doctor_check_dependencies
  doctor_check_package_manager
  doctor_check_symlinks
  doctor_check_runtimes
  doctor_check_vscode

  # Print summary
  doctor_print_summary

  # Exit with appropriate code
  if [[ $_DOCTOR_ISSUES -gt 0 ]]; then
    return 1
  fi
  return 0
}
