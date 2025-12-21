#!/usr/bin/env bash
# shellcheck disable=SC2034

# ------------------------------------------------------------------------------
# log.sh - Logging utilities for dotfiles setup
# ------------------------------------------------------------------------------

# Color codes
readonly LOG_RED='\033[0;31m'
readonly LOG_GREEN='\033[0;32m'
readonly LOG_YELLOW='\033[0;33m'
readonly LOG_BLUE='\033[0;34m'
readonly LOG_CYAN='\033[0;36m'
readonly LOG_NC='\033[0m' # No Color

# Log level (DEBUG, INFO, WARN, ERROR)
LOG_LEVEL="${LOG_LEVEL:-INFO}"

# Log file path
LOG_FILE="${LOG_FILE:-}"

# Internal function to write to log file
_log_to_file() {
  if [[ -n "$LOG_FILE" ]]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"
  fi
}

# Debug message (only shown when LOG_LEVEL=DEBUG)
log_debug() {
  _log_to_file "[DEBUG] $*"
  if [[ "$LOG_LEVEL" == "DEBUG" ]]; then
    echo -e "${LOG_CYAN}[DEBUG]${LOG_NC} $*"
  fi
}

# Info message
log_info() {
  _log_to_file "[INFO] $*"
  echo -e "${LOG_BLUE}[INFO]${LOG_NC} $*"
}

# Success message
log_success() {
  _log_to_file "[SUCCESS] $*"
  echo -e "${LOG_GREEN}[SUCCESS]${LOG_NC} $*"
}

# Warning message (output to stderr)
log_warn() {
  _log_to_file "[WARN] $*"
  echo -e "${LOG_YELLOW}[WARN]${LOG_NC} $*" >&2
}

# Error message (output to stderr)
log_error() {
  _log_to_file "[ERROR] $*"
  echo -e "${LOG_RED}[ERROR]${LOG_NC} $*" >&2
}

# Step progress message
# Usage: log_step 1 5 "Installing packages"
log_step() {
  local step="$1"
  local total="$2"
  local message="$3"
  _log_to_file "[STEP $step/$total] $message"
  echo -e "${LOG_BLUE}[$step/$total]${LOG_NC} $message"
}

# Header message for sections
log_header() {
  local message="$1"
  local line
  line=$(printf '=%.0s' {1..50})
  echo ""
  echo -e "${LOG_CYAN}${line}${LOG_NC}"
  echo -e "${LOG_CYAN}  $message${LOG_NC}"
  echo -e "${LOG_CYAN}${line}${LOG_NC}"
  echo ""
  _log_to_file "=== $message ==="
}
