#!/usr/bin/env bash

# ------------------------------------------------------------------------------
# install.sh - Dotfiles setup entry point
# ------------------------------------------------------------------------------
# Usage:
#   curl -fsSL https://install.tqer39.dev | bash
#   curl -fsSL https://install.tqer39.dev | bash -s -- --full
#   curl -fsSL https://install.tqer39.dev | bash -s -- --dry-run
# ------------------------------------------------------------------------------

set -euo pipefail

# ------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------
DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/tqer39/dotfiles.git}"
DOTFILES_BRANCH="${DOTFILES_BRANCH:-main}"
DOTFILES_DIR="${DOTFILES_DIR:-${HOME}/.dotfiles}"

# ------------------------------------------------------------------------------
# Default options
# ------------------------------------------------------------------------------
INSTALL_MODE="minimal"  # minimal | full
SKIP_PACKAGES=false
SKIP_LANGUAGES=false
DRY_RUN=false
VERBOSE=false
UNINSTALL=false
CI_MODE=false
WORK_MODE=false
DOCTOR=false

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ------------------------------------------------------------------------------
# Helper functions (before sourcing libs)
# Naming follows log_* convention for consistency with scripts/lib/log.sh
# ------------------------------------------------------------------------------
log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*" >&2; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

show_banner() {
  echo -e "${BLUE}"
  cat << 'EOF'
        __      __  _____ __
   ____/ /___  / /_/ __(_) /__  _____
  / __  / __ \/ __/ /_/ / / _ \/ ___/
 / /_/ / /_/ / /_/ __/ / /  __(__  )
 \__,_/\____/\__/_/ /_/_/\___/____/
EOF
  echo -e "${NC}"
}

# ------------------------------------------------------------------------------
# Parse command line arguments
# ------------------------------------------------------------------------------
parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --full)
        INSTALL_MODE="full"
        ;;
      --minimal)
        INSTALL_MODE="minimal"
        ;;
      --skip-packages)
        SKIP_PACKAGES=true
        ;;
      --skip-languages)
        SKIP_LANGUAGES=true
        ;;
      --dry-run)
        DRY_RUN=true
        ;;
      -v|--verbose)
        VERBOSE=true
        ;;
      --uninstall)
        UNINSTALL=true
        ;;
      --ci)
        CI_MODE=true
        ;;
      --work)
        WORK_MODE=true
        ;;
      --doctor)
        DOCTOR=true
        ;;
      -h|--help)
        show_help
        exit 0
        ;;
      *)
        log_error "Unknown option: $1"
        show_help
        exit 1
        ;;
    esac
    shift
  done
}

show_help() {
  cat << EOF
Dotfiles Setup Script

Usage:
  install.sh [OPTIONS]

Options:
  --full              Full setup (dotfiles + development environment)
  --minimal           Minimal setup (dotfiles only, default)
  --skip-packages     Skip package manager installation
  --skip-languages    Skip language runtime installation
  --dry-run           Show what would be done without executing
  -v, --verbose       Enable verbose output
  --uninstall         Remove dotfiles symlinks
  --ci                CI mode (non-interactive, continue on errors)
  --work              Work/company mode (skip personal packages)
  --doctor            Run environment health check
  -h, --help          Show this help message

Examples:
  # Minimal install (dotfiles only)
  curl -fsSL URL | bash

  # Full install (dotfiles + dev tools)
  curl -fsSL URL | bash -s -- --full

  # Preview changes without executing
  curl -fsSL URL | bash -s -- --dry-run

  # Uninstall
  curl -fsSL URL | bash -s -- --uninstall

Environment Variables:
  DOTFILES_REPO       Git repository URL (default: github.com/tqer39/dotfiles)
  DOTFILES_BRANCH     Git branch to use (default: main)
  DOTFILES_DIR        Installation directory (default: ~/.dotfiles)
EOF
}

# ------------------------------------------------------------------------------
# Detect OS
# ------------------------------------------------------------------------------
detect_os() {
  case "$(uname -s)" in
    Darwin) echo "macos" ;;
    Linux)
      if [[ -f /etc/os-release ]]; then
        # shellcheck source=/dev/null
        . /etc/os-release
        case "$ID" in
          ubuntu|debian) echo "ubuntu" ;;
          *) echo "linux" ;;
        esac
      else
        echo "linux"
      fi
      ;;
    *) echo "unknown" ;;
  esac
}

# ------------------------------------------------------------------------------
# Check prerequisites
# ------------------------------------------------------------------------------
check_prerequisites() {
  local missing_deps=()

  if ! command -v git &>/dev/null; then
    missing_deps+=("git")
  fi

  if [[ ${#missing_deps[@]} -gt 0 ]]; then
    log_error "Missing required dependencies: ${missing_deps[*]}"
    log_info "Please install them first:"

    local os
    os=$(detect_os)
    case "$os" in
      macos)
        log_info "  xcode-select --install"
        ;;
      ubuntu)
        log_info "  sudo apt update && sudo apt install -y ${missing_deps[*]}"
        ;;
      *)
        log_info "  Install: ${missing_deps[*]}"
        ;;
    esac
    exit 1
  fi
}

# ------------------------------------------------------------------------------
# Clone or update dotfiles repository
# ------------------------------------------------------------------------------
setup_repository() {
  # Update if dotfiles scripts already exist
  if [[ -f "${DOTFILES_DIR}/scripts/dotfiles.sh" ]]; then
    log_info "Updating existing dotfiles at $DOTFILES_DIR"
    if [[ "$DRY_RUN" == "true" ]]; then
      log_info "[DRY-RUN] Would run: git -C $DOTFILES_DIR pull"
    elif [[ "$CI_MODE" == "true" ]]; then
      # Skip pull in CI mode - CI has already checked out the correct code
      log_info "Skipping git pull in CI mode (code already checked out)"
    else
      # Check for uncommitted changes (tracked files)
      if ! git -C "$DOTFILES_DIR" diff --quiet 2>/dev/null || \
         ! git -C "$DOTFILES_DIR" diff --cached --quiet 2>/dev/null; then
        log_warn "Local changes detected in $DOTFILES_DIR"
        log_warn "Stashing local changes before pulling..."
        git -C "$DOTFILES_DIR" stash push -m "Auto-stash by install.sh $(date +%Y%m%d_%H%M%S)"
        log_info "Your changes have been stashed. Run 'git -C $DOTFILES_DIR stash pop' to restore."
      fi

      if git -C "$DOTFILES_DIR" pull --quiet; then
        log_success "Updated dotfiles repository"
      else
        log_error "Failed to update dotfiles repository"
        log_info "Please resolve conflicts manually:"
        log_info "  cd $DOTFILES_DIR && git status"
        exit 1
      fi
    fi
    return 0
  fi

  if [[ -d "$DOTFILES_DIR" ]]; then
    log_info "Dotfiles directory exists, updating..."
    if [[ "$DRY_RUN" == "true" ]]; then
      log_info "[DRY-RUN] Would run: git -C $DOTFILES_DIR pull"
    elif [[ "$CI_MODE" == "true" ]]; then
      # Skip pull in CI mode - CI has already checked out the correct code
      log_info "Skipping git pull in CI mode (code already checked out)"
    else
      # Check for uncommitted changes (tracked files)
      if ! git -C "$DOTFILES_DIR" diff --quiet 2>/dev/null || \
         ! git -C "$DOTFILES_DIR" diff --cached --quiet 2>/dev/null; then
        log_warn "Local changes detected in $DOTFILES_DIR"
        log_warn "Stashing local changes before pulling..."
        git -C "$DOTFILES_DIR" stash push -m "Auto-stash by install.sh $(date +%Y%m%d_%H%M%S)"
        log_info "Your changes have been stashed. Run 'git -C $DOTFILES_DIR stash pop' to restore."
      fi

      if git -C "$DOTFILES_DIR" pull --quiet; then
        log_success "Updated dotfiles repository"
      else
        log_error "Failed to update dotfiles repository"
        log_info "Please resolve conflicts manually:"
        log_info "  cd $DOTFILES_DIR && git status"
        exit 1
      fi
    fi
  else
    log_info "Cloning dotfiles repository..."
    if [[ "$DRY_RUN" == "true" ]]; then
      log_info "[DRY-RUN] Would run: git clone $DOTFILES_REPO $DOTFILES_DIR"
    else
      git clone --branch "$DOTFILES_BRANCH" "$DOTFILES_REPO" "$DOTFILES_DIR"
      log_success "Cloned dotfiles repository to $DOTFILES_DIR"
    fi
  fi
}

# ------------------------------------------------------------------------------
# Main installation
# ------------------------------------------------------------------------------
main() {
  parse_args "$@"

  # Export for child scripts
  export DRY_RUN
  export VERBOSE
  export CI_MODE
  export WORK_MODE
  if [[ "$WORK_MODE" == "true" ]]; then
    export DOTFILES_MODE="work"
    export GIT_CONFIG_GLOBAL="${GIT_CONFIG_GLOBAL:-${HOME}/.gitconfig.work}"
  else
    export DOTFILES_MODE="${DOTFILES_MODE:-personal}"
    export GIT_CONFIG_GLOBAL="${GIT_CONFIG_GLOBAL:-${HOME}/.gitconfig}"
  fi
  if [[ "$VERBOSE" == "true" ]]; then
    export LOG_LEVEL="DEBUG"
  fi

  # Header
  show_banner
  echo "  Mode: $INSTALL_MODE"
  echo "  OS: $(detect_os)"
  echo "  Dry run: $DRY_RUN"
  echo "  CI mode: $CI_MODE"
  echo "  Work mode: $WORK_MODE"
  echo ""

  # Check prerequisites
  check_prerequisites

  # Setup repository
  setup_repository

  # Source library files (now available after clone)
  if [[ -d "$DOTFILES_DIR" ]] && [[ "$DRY_RUN" != "true" ]]; then
    # shellcheck source=/dev/null
    source "${DOTFILES_DIR}/scripts/lib/log.sh"
    # shellcheck source=/dev/null
    source "${DOTFILES_DIR}/scripts/lib/utils.sh"
    # shellcheck source=/dev/null
    source "${DOTFILES_DIR}/scripts/lib/symlink.sh"
  fi

  # Uninstall mode
  if [[ "$UNINSTALL" == "true" ]]; then
    if [[ "$DRY_RUN" == "true" ]]; then
      log_info "[DRY-RUN] Would uninstall dotfiles"
    else
      # shellcheck source=/dev/null
      source "${DOTFILES_DIR}/scripts/dotfiles.sh"
      uninstall_dotfiles
    fi
    exit 0
  fi

  # Doctor mode
  if [[ "$DOCTOR" == "true" ]]; then
    if [[ -d "$DOTFILES_DIR" ]] && [[ -f "${DOTFILES_DIR}/scripts/dotfiles.sh" ]]; then
      # shellcheck source=/dev/null
      source "${DOTFILES_DIR}/scripts/dotfiles.sh"
      run_doctor
    else
      log_error "Dotfiles not installed. Run install first."
      exit 1
    fi
    exit 0
  fi

  # Step 1: Install dotfiles (symlinks)
  log_info "Step 1: Installing dotfiles..."
  if [[ "$DRY_RUN" == "true" ]]; then
    log_info "[DRY-RUN] Would create symlinks for dotfiles"
  else
    # shellcheck source=/dev/null
    source "${DOTFILES_DIR}/scripts/dotfiles.sh"
    install_dotfiles
  fi

  # Full installation mode
  if [[ "$INSTALL_MODE" == "full" ]]; then
    # Step 2: Install packages
    if [[ "$SKIP_PACKAGES" != "true" ]]; then
      log_info "Step 2: Installing packages..."
      if [[ -f "${DOTFILES_DIR}/scripts/installers/homebrew.sh" ]]; then
        # shellcheck source=/dev/null
        source "${DOTFILES_DIR}/scripts/installers/homebrew.sh"
        install_homebrew
        install_homebrew_packages
      fi
      if [[ -f "${DOTFILES_DIR}/scripts/installers/apt.sh" ]]; then
        local os
        os=$(detect_os)
        if [[ "$os" == "ubuntu" ]]; then
          # shellcheck source=/dev/null
          source "${DOTFILES_DIR}/scripts/installers/apt.sh"
          install_apt_packages
          install_albert
          install_1password
          install_vscode
          install_ghostty
        fi
      fi
    else
      log_info "Step 2: Skipping packages (--skip-packages)"
    fi

    # Step 3: Install language runtimes
    if [[ "$SKIP_LANGUAGES" != "true" ]]; then
      log_info "Step 3: Installing language runtimes..."
      if [[ -f "${DOTFILES_DIR}/scripts/installers/anyenv.sh" ]]; then
        # shellcheck source=/dev/null
        source "${DOTFILES_DIR}/scripts/installers/anyenv.sh"
        install_anyenv
      fi
    else
      log_info "Step 3: Skipping languages (--skip-languages)"
    fi

    # Step 4: Install VS Code extensions
    log_info "Step 4: Installing VS Code extensions..."
    if [[ -f "${DOTFILES_DIR}/scripts/installers/vscode.sh" ]]; then
      # shellcheck source=/dev/null
      source "${DOTFILES_DIR}/scripts/installers/vscode.sh"
      install_vscode_extensions
    fi
  fi

  # Complete
  echo ""
  echo "=========================================="
  echo "  Setup Complete!"
  echo "=========================================="
  echo ""
  log_info "Please restart your shell or run:"
  log_info "  source ~/.zshrc"
  echo ""
}

main "$@"
