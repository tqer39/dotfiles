# Dotfiles

[🇯🇵 日本語版](docs/README.ja.md)

This repository contains my public dotfiles with an automated setup script. These configuration files help maintain a consistent development environment across macOS, Linux (Ubuntu), and Windows.

## Quick Start

### macOS / Linux (Ubuntu)

```bash
# Minimal install (dotfiles only)
curl -fsSL https://install.tqer39.dev | bash

# Full install (dotfiles + development environment)
curl -fsSL https://install.tqer39.dev | bash -s -- --full

# Preview changes without executing
curl -fsSL https://install.tqer39.dev | bash -s -- --dry-run
```

### Windows (PowerShell)

```powershell
# Minimal install
irm https://install.tqer39.dev/windows | iex

# Full install
.\install.ps1 -Full

# Preview changes
.\install.ps1 -DryRun
```

## Features

- **Idempotent**: Safe to run multiple times - existing correct symlinks are skipped
- **Cross-platform**: Supports macOS, Linux (Ubuntu), and Windows
- **Backup**: Existing files are backed up to `~/.dotfiles_backup/`
- **Modular**: Choose between minimal (dotfiles only) or full (with dev tools) installation

## Command Line Options

| Option | Description |
| ------ | ----------- |
| `--full` | Full setup (dotfiles + development environment) |
| `--minimal` | Minimal setup (dotfiles only, default) |
| `--skip-packages` | Skip package manager installation |
| `--skip-languages` | Skip language runtime installation |
| `--dry-run` | Show what would be done without executing |
| `-v, --verbose` | Enable verbose output |
| `--uninstall` | Remove dotfiles symlinks |

## Repository Structure

```text
dotfiles/
├── install.sh              # Unix entry point
├── install.ps1             # Windows PowerShell entry point
├── src/                    # Dotfiles
│   ├── .zshrc              # Zsh configuration
│   ├── .bashrc             # Bash configuration
│   ├── .gitconfig          # Git configuration
│   ├── .hammerspoon/       # Window management (macOS)
│   ├── .vscode/            # VS Code settings
│   └── .config/
│       ├── starship.toml   # Starship prompt
│       ├── karabiner/      # Keyboard customization (macOS)
│       └── git/            # Git ignore patterns
├── scripts/
│   ├── lib/                # Shared utilities
│   ├── installers/         # Package installers
│   └── dotfiles.sh         # Symlink management
└── config/
    ├── platform-files.conf # File -> symlink mapping
    └── packages/           # Package lists (Brewfile, etc.)
```

## Platform-Specific Files

Some dotfiles are only installed on specific platforms:

| File | macOS | Linux | Windows |
| ---- | :---: | :---: | :-----: |
| `.zshrc`, `.bashrc` | ✓ | ✓ | - |
| `.gitconfig` | ✓ | ✓ | ✓ |
| `.hammerspoon/` | ✓ | - | - |
| `.config/karabiner/` | ✓ | - | - |
| `.vscode/` | ✓ | ✓ | ✓ |
| `.config/starship.toml` | ✓ | ✓ | - |

## Full Installation Includes

When using `--full`, the following will also be installed:

### Package Managers

- **macOS/Linux**: Homebrew + packages from `config/packages/Brewfile`
- **Ubuntu**: APT packages from `config/packages/apt-packages.txt`
- **Windows**: winget packages

### Development Tools

- **anyenv**: For managing language runtimes (pyenv, nodenv, etc.)
- **VS Code Extensions**: From `src/.vscode/extensions.json`

## Requirements

- **Git**: Required for cloning the repository
- **curl** (Unix) or **PowerShell 5.1+** (Windows)

## Development

This repository uses tools that require macOS or Linux:

- `make bootstrap` - Install development dependencies
- `just setup` - Configure development environment
- `just lint` - Run linters
- `just tf` - Run Terraform commands

Windows is supported for **using** dotfiles, but **developing** this repository requires macOS or Linux.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
