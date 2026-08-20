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
SERVER_MODE=false
DOCTOR=false
NEEDS_REBOOT=false

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
      --server)
        SERVER_MODE=true
        ;;
      --doctor)
        DOCTOR=true
        ;;
      --os)
        shift
        case "$1" in
          macos|ubuntu|mint|linux|windows)
            DOTFILES_OS_OVERRIDE="$1"
            export DOTFILES_OS_OVERRIDE
            ;;
          *)
            log_error "Invalid OS: $1. Valid values: macos, ubuntu, mint, linux, windows"
            exit 1
            ;;
        esac
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
  --work              Work/company mode (skip personal packages, add work packages)
  --server            Server mode (skip GUI applications)
  --doctor            Run environment health check
  --os <value>        Override OS detection (macos, ubuntu, mint, linux, windows)
  -h, --help          Show this help message

Examples:
  # Minimal install (dotfiles only)
  curl -fsSL URL | bash

  # Full install (dotfiles + dev tools)
  curl -fsSL URL | bash -s -- --full

  # Full install on Ubuntu Server (no GUI apps)
  curl -fsSL URL | bash -s -- --full --server

  # Preview changes without executing
  curl -fsSL URL | bash -s -- --dry-run

  # Uninstall
  curl -fsSL URL | bash -s -- --uninstall

Environment Variables:
  DOTFILES_REPO            Git repository URL (default: github.com/tqer39/dotfiles)
  DOTFILES_BRANCH          Git branch to use (default: main)
  DOTFILES_DIR             Installation directory (default: ~/.dotfiles)
  DOTFILES_OS_OVERRIDE     Override OS detection (same values as --os)
EOF
}

# ------------------------------------------------------------------------------
# Detect OS
# ------------------------------------------------------------------------------
detect_os() {
  if [[ -n "${DOTFILES_OS_OVERRIDE:-}" ]]; then
    echo "$DOTFILES_OS_OVERRIDE"
    return 0
  fi

  case "$(uname -s)" in
    Darwin) echo "macos" ;;
    Linux)
      if [[ -f /etc/os-release ]]; then
        # shellcheck source=/dev/null
        . /etc/os-release
        case "$ID" in
          ubuntu|debian) echo "ubuntu" ;;
          linuxmint) echo "mint" ;;
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
# Install Obsidian (idempotent)
# ------------------------------------------------------------------------------
install_obsidian() {
  local os
  os=$(detect_os)

  if [[ "${CI_MODE:-false}" == "true" ]]; then
    log_info "Skipping Obsidian installation in CI mode"
    return 0
  fi

  case "$os" in
    macos)
      if ! command -v brew &>/dev/null; then
        log_warn "Homebrew is not available. Skipping Obsidian installation."
        return 0
      fi

      if brew list --cask obsidian &>/dev/null; then
        log_success "Obsidian is already installed"
        return 0
      fi

      if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_info "[DRY-RUN] Would run: brew install --cask obsidian"
        return 0
      fi

      log_info "Installing Obsidian via Homebrew cask..."
      brew install --cask obsidian
      log_success "Obsidian installed"
      ;;
    ubuntu)
      if ! command -v snap &>/dev/null; then
        log_warn "snap is not available. Skipping Obsidian installation."
        return 0
      fi

      if snap list obsidian &>/dev/null; then
        log_success "Obsidian is already installed"
        return 0
      fi

      if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_info "[DRY-RUN] Would run: sudo snap install obsidian --classic"
        return 0
      fi

      log_info "Installing Obsidian via snap..."
      sudo snap install obsidian --classic
      log_success "Obsidian installed"
      ;;
    *)
      log_warn "Obsidian auto-install is not supported on this OS: $os"
      ;;
  esac
}

# ------------------------------------------------------------------------------
# Install Japanese locale (idempotent)
# ------------------------------------------------------------------------------
install_japanese_locale() {
  local os
  os=$(detect_os)

  if [[ "$os" != "ubuntu" && "$os" != "mint" ]]; then
    return 0
  fi

  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_info "[DRY-RUN] Would install Japanese locale and CJK fonts"
    return 0
  fi

  log_info "Installing Japanese language pack..."
  sudo apt install -y language-pack-ja

  log_info "Setting locale to ja_JP.UTF-8..."
  sudo update-locale LANG=ja_JP.UTF-8

  if [[ "${SERVER_MODE:-false}" == "true" ]]; then
    log_info "Server mode: Skipping CJK fonts"
  else
    log_info "Installing CJK fonts..."
    sudo apt install -y fonts-noto-cjk
  fi

  NEEDS_REBOOT=true
  log_success "Japanese locale configured"
}

# ------------------------------------------------------------------------------
# Install Herdr (idempotent)
# ------------------------------------------------------------------------------
install_herdr() {
  if command -v herdr &>/dev/null; then
    log_success "Herdr is already installed"
    return 0
  fi

  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_info "[DRY-RUN] Would install Herdr"
    return 0
  fi

  # herdr は homebrew-core の formula (tap 不要)。brew が使えるなら
  # パッケージ管理下に置きたいので brew を優先し、curl 版は brew が無い
  # 環境や brew でのインストールに失敗した場合の fallback に留める。
  if command -v brew &>/dev/null; then
    if brew list herdr &>/dev/null; then
      log_success "Herdr is already installed via Homebrew"
      return 0
    fi

    log_info "Installing Herdr via Homebrew..."
    if brew install herdr; then
      log_success "Herdr installed via Homebrew"
      return 0
    fi

    log_warn "Homebrew install failed. Falling back to the install script."
  fi

  log_info "Installing Herdr..."
  curl -fsSL https://herdr.dev/install.sh | sh
  log_success "Herdr installed"
}

# ------------------------------------------------------------------------------
# Install Herdr integrations (idempotent)
# ------------------------------------------------------------------------------
remove_herdr_absolute_claude_hook() {
  local settings_file="${HERDR_CLAUDE_SETTINGS_FILE:-$HOME/.claude/settings.json}"

  if [[ ! -f "$settings_file" ]]; then
    return 0
  fi

  if ! command -v python3 &>/dev/null; then
    log_warn "python3 is not available. Skipping Herdr Claude settings cleanup."
    return 0
  fi

  python3 - "$settings_file" <<'PY'
import json
import sys
from pathlib import Path

settings_path = Path(sys.argv[1])

with settings_path.open(encoding="utf-8") as f:
    data = json.load(f)

hooks = data.get("hooks")
if not isinstance(hooks, dict):
    sys.exit(0)

session_start = hooks.get("SessionStart")
if not isinstance(session_start, list):
    sys.exit(0)

changed = False
cleaned_session_start = []

for entry in session_start:
    if not isinstance(entry, dict):
        cleaned_session_start.append(entry)
        continue

    entry_hooks = entry.get("hooks")
    if not isinstance(entry_hooks, list):
        cleaned_session_start.append(entry)
        continue

    cleaned_hooks = []
    for hook in entry_hooks:
        command = hook.get("command") if isinstance(hook, dict) else None
        remove_hook = (
            isinstance(command, str)
            and "herdr-agent-state.sh" in command
            and "$HOME" not in command
        )
        if remove_hook:
            changed = True
            continue
        cleaned_hooks.append(hook)

    if cleaned_hooks:
        if len(cleaned_hooks) != len(entry_hooks):
            entry = dict(entry)
            entry["hooks"] = cleaned_hooks
        cleaned_session_start.append(entry)
    else:
        changed = True

if changed:
    if cleaned_session_start:
        hooks["SessionStart"] = cleaned_session_start
    else:
        hooks.pop("SessionStart", None)
    settings_path.write_text(
        json.dumps(data, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
PY
}

install_herdr_integrations() {
  if ! command -v herdr &>/dev/null; then
    log_warn "Herdr is not installed. Skipping integration setup."
    return 0
  fi

  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_info "[DRY-RUN] Would install Herdr integrations"
    return 0
  fi

  log_info "Installing Herdr Claude Code integration..."
  herdr integration install claude 2>/dev/null || log_warn "Failed to install Herdr Claude integration (may already exist)"
  remove_herdr_absolute_claude_hook
  log_success "Herdr integrations configured"
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
      ubuntu|mint)
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
# Drop a stash entry identified by SHA
#
# `git stash drop` only accepts a stash@{n} reflog reference, never a raw SHA,
# so the position has to be looked up. It is looked up here rather than
# remembered from the push because the stash stack is shared with every git
# worktree of this repository and another process may have pushed onto it in
# the meantime.
# ------------------------------------------------------------------------------
drop_stash() {
  local stash_sha="$1"
  local index=0
  local entry

  while [[ "$index" -lt 100 ]]; do
    entry="$(git -C "$DOTFILES_DIR" rev-parse --verify --quiet "stash@{${index}}" 2>/dev/null)" || return 1
    if [[ "$entry" == "$stash_sha" ]]; then
      git -C "$DOTFILES_DIR" stash drop --quiet "stash@{${index}}" >/dev/null 2>&1 || return 1
      return 0
    fi
    index=$((index + 1))
  done

  return 1
}

# ------------------------------------------------------------------------------
# Restore a stash entry created by update_repository
#
# The entry is applied by SHA rather than by stash@{n}: the stash stack is
# shared with every git worktree of this repository, so a positional ref can
# point at somebody else's entry by the time we get here.
#
# On conflict the entry is kept so no work is lost, and the working tree is
# rolled back to the freshly pulled state - leaving conflict markers behind
# would propagate them into every symlinked dotfile.
# ------------------------------------------------------------------------------
restore_stash() {
  local stash_sha="$1"

  if [[ -z "$stash_sha" ]]; then
    return 0
  fi

  if git -C "$DOTFILES_DIR" stash apply --quiet "$stash_sha" 2>/dev/null; then
    log_success "Restored your local changes"
    if ! drop_stash "$stash_sha"; then
      log_warn "Could not drop the now-redundant stash entry: $stash_sha"
    fi
    return 0
  fi

  git -C "$DOTFILES_DIR" reset --hard --quiet HEAD
  log_warn "Your local changes conflict with the updated files"
  log_warn "The working tree was reset to the updated state to avoid conflict markers"
  log_warn "Your changes are safe in the stash: $stash_sha"
  log_info "Inspect and resolve them with:"
  log_info "  cd $DOTFILES_DIR && git stash show -p $stash_sha"
  log_info "  cd $DOTFILES_DIR && git stash drop $stash_sha   # once resolved"
}

# ------------------------------------------------------------------------------
# Update an existing dotfiles checkout
#
# Local changes are stashed before pulling and restored right afterwards. Not
# restoring them is what used to pile up dozens of orphaned Auto-stash entries.
# ------------------------------------------------------------------------------
update_repository() {
  if [[ "$DRY_RUN" == "true" ]]; then
    log_info "[DRY-RUN] Would run: git -C $DOTFILES_DIR pull --ff-only"
    return 0
  fi

  if [[ "$CI_MODE" == "true" ]]; then
    # Skip pull in CI mode - CI has already checked out the correct code
    log_info "Skipping git pull in CI mode (code already checked out)"
    return 0
  fi

  local stash_sha=""
  # --porcelain also reports untracked files, which `git diff` misses. Those
  # make `git pull` abort when an incoming commit adds a file of the same name.
  if [[ -n "$(git -C "$DOTFILES_DIR" status --porcelain 2>/dev/null)" ]]; then
    log_warn "Local changes detected in $DOTFILES_DIR"
    log_warn "Stashing local changes before pulling..."
    if ! git -C "$DOTFILES_DIR" stash push -u -m "Auto-stash by install.sh $(date +%Y%m%d_%H%M%S)"; then
      log_error "Failed to stash local changes in $DOTFILES_DIR"
      log_info "Please resolve manually:"
      log_info "  cd $DOTFILES_DIR && git status"
      exit 1
    fi
    stash_sha="$(git -C "$DOTFILES_DIR" rev-parse refs/stash)"
  fi

  # --ff-only keeps a merge commit from being created behind the user's back;
  # a diverged checkout is reported instead of silently conflicting.
  if ! git -C "$DOTFILES_DIR" pull --ff-only --quiet; then
    log_error "Failed to update dotfiles repository"
    restore_stash "$stash_sha"
    log_info "The checkout may have local commits. Inspect it with:"
    log_info "  cd $DOTFILES_DIR && git status"
    log_info "  cd $DOTFILES_DIR && git log --oneline origin/main..HEAD"
    exit 1
  fi
  log_success "Updated dotfiles repository"

  restore_stash "$stash_sha"
}

# ------------------------------------------------------------------------------
# Clone or update dotfiles repository
# ------------------------------------------------------------------------------
setup_repository() {
  # Update if dotfiles scripts already exist
  if [[ -f "${DOTFILES_DIR}/scripts/dotfiles.sh" ]]; then
    log_info "Updating existing dotfiles at $DOTFILES_DIR"
    update_repository
    return 0
  fi

  if [[ -d "$DOTFILES_DIR" ]]; then
    log_info "Dotfiles directory exists, updating..."
    update_repository
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
  export SERVER_MODE
  if [[ "$WORK_MODE" == "true" ]]; then
    export DOTFILES_MODE="work"
    export GIT_CONFIG_GLOBAL="${GIT_CONFIG_GLOBAL:-${HOME}/.gitconfig.work}"
    export MISE_CONFIG_FILE="${MISE_CONFIG_FILE:-${HOME}/.config/mise/config.work.toml}"
  else
    export DOTFILES_MODE="${DOTFILES_MODE:-personal}"
    export GIT_CONFIG_GLOBAL="${GIT_CONFIG_GLOBAL:-${HOME}/.gitconfig}"
    export MISE_CONFIG_FILE="${MISE_CONFIG_FILE:-${HOME}/.config/mise/config.personal.toml}"
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
  echo "  Server mode: $SERVER_MODE"
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

  # Trust mise config files after symlinks are created
  if command -v mise &>/dev/null; then
    log_info "Trusting mise config files..."
    if [[ "$DRY_RUN" == "true" ]]; then
      log_info "[DRY-RUN] Would trust mise config files"
    else
      mise trust ~/.config/mise/config.toml 2>/dev/null || true
      mise trust ~/.config/mise/config.personal.toml 2>/dev/null || true
      mise trust ~/.config/mise/config.work.toml 2>/dev/null || true
      mise trust ~/.dotfiles 2>/dev/null || true
      mise trust ~/.dotfiles/mise.toml 2>/dev/null || true
    fi
  fi

  # Create symlink for work profile (after other symlinks are created)
  if [[ "$WORK_MODE" == "true" ]]; then
    local zprofile_src="${DOTFILES_DIR}/src/.zprofile.work"
    local zprofile_dest="$HOME/.zprofile"
    if [[ "$DRY_RUN" == "true" ]]; then
      log_info "[DRY-RUN] Would symlink ~/.zprofile -> .zprofile.work"
    else
      if [[ -e "$zprofile_dest" && ! -L "$zprofile_dest" ]]; then
        log_info "Backing up existing ~/.zprofile..."
        mv "$zprofile_dest" "${BACKUP_DIR}/.zprofile"
      fi
      log_info "Creating symlink ~/.zprofile -> .zprofile.work..."
      ln -sf "$zprofile_src" "$zprofile_dest"
    fi
  fi

  # Full installation mode
  if [[ "$INSTALL_MODE" == "full" ]]; then
    # Step 2: Install packages
    if [[ "$SKIP_PACKAGES" != "true" ]]; then
      log_info "Step 2: Installing packages..."
      local os
      os=$(detect_os)
      if [[ -f "${DOTFILES_DIR}/scripts/installers/homebrew.sh" ]]; then
        # shellcheck source=/dev/null
        source "${DOTFILES_DIR}/scripts/installers/homebrew.sh"
        install_homebrew
        install_homebrew_packages
      fi
      if [[ -f "${DOTFILES_DIR}/scripts/installers/apt.sh" ]]; then
        if [[ "$os" == "ubuntu" || "$os" == "mint" ]]; then
          # shellcheck source=/dev/null
          source "${DOTFILES_DIR}/scripts/installers/apt.sh"
          install_apt_packages
          if [[ "$SERVER_MODE" != "true" ]]; then
            install_albert
            install_1password
            install_vscode
            install_ghostty
            install_wezterm
            install_spotify
            install_discord
          else
            log_info "Server mode: Skipping GUI applications"
          fi
          install_podman
          install_japanese_locale
        fi
      fi

      if [[ "$SERVER_MODE" != "true" ]]; then
        install_obsidian
      else
        log_info "Server mode: Skipping Obsidian installation"
      fi

      install_herdr
      install_herdr_integrations
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
      # Install tools managed by mise (claude-code, gemini-cli, codex, node, etc.)
      if command -v mise &>/dev/null; then
        log_info "Installing mise tools..."
        if [[ "$DRY_RUN" == "true" ]]; then
          log_info "[DRY-RUN] Would install mise tools"
        else
          # Trust config files in case mise was newly installed in Step 2
          mise trust ~/.config/mise/config.toml 2>/dev/null || true
          mise trust ~/.config/mise/config.personal.toml 2>/dev/null || true
          mise trust ~/.config/mise/config.work.toml 2>/dev/null || true
          mise trust ~/.dotfiles 2>/dev/null || true
          mise trust ~/.dotfiles/mise.toml 2>/dev/null || true
          mise upgrade --yes 2>/dev/null || true  # 既存ツールを最新に更新
          mise install --yes
          mise reshim 2>/dev/null || true  # shims を最新に更新
        fi
      fi
    else
      log_info "Step 3: Skipping languages (--skip-languages)"
    fi

    # Step 4: Install VS Code extensions
    if [[ "${SERVER_MODE}" != "true" ]]; then
      log_info "Step 4: Installing VS Code extensions..."
      if [[ -f "${DOTFILES_DIR}/scripts/installers/vscode.sh" ]]; then
        # shellcheck source=/dev/null
        source "${DOTFILES_DIR}/scripts/installers/vscode.sh"
        install_vscode_extensions
      fi
    else
      log_info "Step 4: Skipping VS Code extensions (server mode)"
    fi
  fi

  # Complete
  echo ""
  echo "=========================================="
  echo "  Setup Complete!"
  echo "=========================================="
  echo ""
  if [[ "$(basename "${SHELL:-}")" != "zsh" ]]; then
    log_info "Your default shell is not zsh. To switch to zsh:"
    log_info "  chsh -s \$(which zsh)"
    log_info "Then log out and log back in, and run:"
    log_info "  exec \$SHELL"
  else
    log_info "Please restart your shell or run:"
    log_info "  exec \$SHELL"
  fi
  if [[ "${NEEDS_REBOOT}" == "true" ]]; then
    echo ""
    log_warn "Locale changes require a system reboot to take effect."
    log_info "  sudo reboot"
  fi
  echo ""
}

main "$@"
