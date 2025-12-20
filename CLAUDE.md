# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

This is a dotfiles repository with automated setup scripts. It installs configuration files via symlinks to maintain consistent development environments across macOS, Linux (Ubuntu), and Windows.

**Goal**: Provide nearly identical developer experience (DX) across macOS, Linux, and Windows.

## Common Commands

### Testing the setup script

```bash
# Dry-run to preview what would be installed (no changes made)
DRY_RUN=true ./scripts/dotfiles.sh install

# Run the full install script locally
./install.sh --dry-run
./install.sh --minimal
./install.sh --full
```

### Linting

```bash
# Run all pre-commit hooks
pre-commit run -a

# Individual checks
shellcheck scripts/**/*.sh
```

### Managing dotfiles

```bash
# Check symlink status
./scripts/dotfiles.sh status

# Install symlinks
./scripts/dotfiles.sh install

# Remove symlinks (restores backups)
./scripts/dotfiles.sh uninstall
```

## Architecture

### Entry Points

- `install.sh` - Unix (macOS/Linux) entry point, can be piped from curl
- `install.ps1` - Windows PowerShell entry point

### Script Library (`scripts/lib/`)

Shared utilities sourced by all scripts:

- `log.sh` - Colored logging functions (`log_info`, `log_success`, `log_error`, etc.)
- `utils.sh` - OS detection (`detect_os`), path expansion, command checking
- `symlink.sh` - Idempotent symlink creation with backup support

### Configuration

- `config/platform-files.conf` - Defines SOURCE:DESTINATION:PLATFORMS mappings
  - Format: `.zshrc:~/.zshrc:macos,linux`
  - Platforms: `all`, `macos`, `linux`, `ubuntu`, `windows`
- `config/packages/Brewfile` - Homebrew packages
- `config/packages/apt-packages.txt` - APT packages for Ubuntu

### Installers (`scripts/installers/`)

Modular installers called during `--full` installation:

- `homebrew.sh` - Homebrew and Brewfile packages
- `apt.sh` - APT packages (Ubuntu only)
- `anyenv.sh` - Language runtime manager
- `vscode.sh` - VS Code extensions from `src/.vscode/extensions.json`

## Key Design Decisions

- **Idempotency**: Scripts check existing state before making changes. Re-running is always safe.
- **Backup**: Existing files are moved to `~/.dotfiles_backup/YYYYMMDD_HHMMSS/` before symlink creation.
- **Platform filtering**: Each dotfile specifies which platforms it applies to in `platform-files.conf`.
- **Arithmetic safety**: Use `count=$((count + 1))` instead of `((count++))` to avoid `set -e` issues.

## Coding Guidelines

- Shell: zsh-compatible, use `#!/usr/bin/env bash` with `set -euo pipefail`
- Variable/function names: English, snake_case for shell scripts
- Always run `shellcheck` on shell scripts
