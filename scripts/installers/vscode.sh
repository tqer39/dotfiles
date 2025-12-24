#!/usr/bin/env bash

# ------------------------------------------------------------------------------
# vscode.sh - VS Code extensions installer
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

# Get VS Code command (code or code-insiders)
get_vscode_cmd() {
  if command_exists code; then
    echo "code"
  elif command_exists code-insiders; then
    echo "code-insiders"
  else
    echo ""
  fi
}

# Install a single VS Code extension (idempotent)
install_vscode_extension() {
  local extension="$1"
  local vscode_cmd
  vscode_cmd=$(get_vscode_cmd)

  if [[ -z "$vscode_cmd" ]]; then
    log_warn "VS Code is not installed, skipping extension: $extension"
    return 0
  fi

  # Check if extension is already installed
  if "$vscode_cmd" --list-extensions 2>/dev/null | grep -qi "^${extension}$"; then
    log_debug "Extension already installed: $extension"
    return 0
  fi

  log_info "Installing extension: $extension"

  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_info "[DRY-RUN] Would run: $vscode_cmd --install-extension $extension"
    return 0
  fi

  "$vscode_cmd" --install-extension "$extension" --force
}

# Install VS Code extensions from extensions.json
install_vscode_extensions() {
  local extensions_file="${DOTFILES_DIR}/src/.vscode/extensions.json"

  log_info "Installing VS Code extensions..."

  # Skip in CI mode (headless environment cannot run VS Code CLI properly)
  if [[ "${CI_MODE:-false}" == "true" ]]; then
    log_info "CI mode detected. Skipping VS Code extension installation."
    return 0
  fi

  # Check if VS Code is installed
  local vscode_cmd
  vscode_cmd=$(get_vscode_cmd)
  if [[ -z "$vscode_cmd" ]]; then
    log_warn "VS Code is not installed. Skipping extension installation."
    log_info "Install VS Code first, then run this script again."
    return 0
  fi

  # Check if extensions.json exists
  if [[ ! -f "$extensions_file" ]]; then
    log_warn "extensions.json not found: $extensions_file"
    return 0
  fi

  # Parse extensions from JSON and install
  # Using grep/sed to avoid jq dependency
  local extensions
  extensions=$(grep -oE '"[a-zA-Z0-9._-]+\.[a-zA-Z0-9._-]+"' "$extensions_file" | tr -d '"' | sort -u)

  local count=0
  local total
  total=$(echo "$extensions" | wc -l | xargs)

  while IFS= read -r extension; do
    [[ -z "$extension" ]] && continue
    ((count++))
    log_step "$count" "$total" "Installing: $extension"
    install_vscode_extension "$extension"
  done <<< "$extensions"

  log_success "VS Code extensions installed successfully"
}

# List installed VS Code extensions
list_vscode_extensions() {
  local vscode_cmd
  vscode_cmd=$(get_vscode_cmd)

  if [[ -z "$vscode_cmd" ]]; then
    log_error "VS Code is not installed"
    return 1
  fi

  log_info "Installed VS Code extensions:"
  "$vscode_cmd" --list-extensions
}

# Export installed extensions to JSON format
export_vscode_extensions() {
  local vscode_cmd
  vscode_cmd=$(get_vscode_cmd)
  local output_file="${1:-extensions.json}"

  if [[ -z "$vscode_cmd" ]]; then
    log_error "VS Code is not installed"
    return 1
  fi

  log_info "Exporting extensions to $output_file..."

  {
    echo '{'
    echo '  "recommendations": ['
    "$vscode_cmd" --list-extensions | sort | sed 's/^/    "/;s/$/"/' | paste -sd ',' - | sed 's/,/,\n/g'
    echo '  ]'
    echo '}'
  } > "$output_file"

  log_success "Extensions exported to $output_file"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  install_vscode_extensions
fi
