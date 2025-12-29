# ⚡ Dotfiles

[🇯🇵 日本語版](docs/README.ja.md)

[![Test Install](https://img.shields.io/github/actions/workflow/status/tqer39/dotfiles/test-install.yml?branch=main&style=for-the-badge&logo=github&label=install)](https://github.com/tqer39/dotfiles/actions/workflows/test-install.yml)
[![Pre-commit](https://img.shields.io/github/actions/workflow/status/tqer39/dotfiles/prek.yml?branch=main&style=for-the-badge&logo=precommit&label=lint)](https://github.com/tqer39/dotfiles/actions/workflows/prek.yml)
[![Terraform](https://img.shields.io/github/actions/workflow/status/tqer39/dotfiles/terraform.yml?branch=main&style=for-the-badge&logo=terraform&label=terraform)](https://github.com/tqer39/dotfiles/actions/workflows/terraform.yml)
[![Security](https://img.shields.io/github/actions/workflow/status/tqer39/dotfiles/trivy-terraform.yml?branch=main&style=for-the-badge&logo=trivy&label=security)](https://github.com/tqer39/dotfiles/actions/workflows/trivy-terraform.yml)

[![macOS](https://img.shields.io/badge/macOS-supported-000000?style=for-the-badge&logo=apple&logoColor=white)](https://www.apple.com/macos/)
[![Linux](https://img.shields.io/badge/Linux-supported-FCC624?style=for-the-badge&logo=linux&logoColor=black)](https://www.linux.org/)
[![Windows](https://img.shields.io/badge/Windows-supported-0078D6?style=for-the-badge&logo=windows&logoColor=white)](https://www.microsoft.com/windows/)

[![Bash](https://img.shields.io/badge/Bash-5.x-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Python](https://img.shields.io/badge/Python-3.13-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://www.python.org/)
[![Terraform](https://img.shields.io/badge/Terraform-1.14-844FBA?style=for-the-badge&logo=terraform&logoColor=white)](https://www.terraform.io/)
[![MIT License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)

This repository contains my public dotfiles with an automated setup script. These configuration files help maintain a consistent development environment across macOS, Linux (Ubuntu), and Windows.

## 🚀 Quick Start

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

## ✨ Features

- **Idempotent**: Safe to run multiple times - existing correct symlinks are skipped
- **Cross-platform**: Supports macOS, Linux (Ubuntu), and Windows
- **Location**: Repository is cloned to `~/.dotfiles`
- **Backup**: Existing files are backed up to `~/.dotfiles_backup/`
- **Modular**: Choose between minimal (dotfiles only) or full (with dev tools) installation

## ⚙️ Command Line Options

| Option | Description |
| ------ | ----------- |
| `--full` | Full setup (dotfiles + development environment) |
| `--minimal` | Minimal setup (dotfiles only, default) |
| `--skip-packages` | Skip package manager installation |
| `--skip-languages` | Skip language runtime installation |
| `--dry-run` | Show what would be done without executing |
| `-v, --verbose` | Enable verbose output |
| `--uninstall` | Remove dotfiles symlinks |
| `--work` | Work/company mode (skip personal packages) |
| `--ci` | CI mode (non-interactive) |
| `--doctor` | Run environment health check |

## 📁 Repository Structure

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

## 📦 What's Inside

All dotfiles that get symlinked during installation:

### 🐚 Shell

| File                               | Destination                       | Description                                      | Platform  |
| ---------------------------------- | --------------------------------- | ------------------------------------------------ | --------- |
| `.shell_common`                    | `~/.shell_common`                 | Shared aliases & functions (git, ls, navigation) | 🍎 🐧     |
| `.zshrc`                           | `~/.zshrc`                        | Zsh configuration                                | 🍎 🐧     |
| `.bashrc`                          | `~/.bashrc`                       | Bash configuration                               | 🍎 🐧     |
| `.bash_profile`                    | `~/.bash_profile`                 | Bash login shell config                          | 🍎 🐧     |
| `Microsoft.PowerShell_profile.ps1` | `~/Documents/PowerShell/...`      | PowerShell profile                               | 🪟        |

### 🔀 Git

| File                  | Destination              | Description                           | Platform  |
| --------------------- | ------------------------ | ------------------------------------- | --------- |
| `.gitconfig`          | `~/.gitconfig`           | Git user config, GPG signing, aliases | 🍎 🐧 🪟  |
| `.gitignore`          | `~/.gitignore_global`    | Global ignore patterns                | 🍎 🐧 🪟  |
| `.config/git/ignore`  | `~/.config/git/ignore`   | Additional ignore rules               | 🍎 🐧 🪟  |

### 🎨 Terminal & Prompt

| File                            | Destination                          | Description                          | Platform  |
| ------------------------------- | ------------------------------------ | ------------------------------------ | --------- |
| `.config/starship.toml`         | `~/.config/starship.toml`            | Starship prompt (Tokyo Night theme)  | 🍎 🐧     |
| `.config/ghostty/config`        | `~/.config/ghostty/config`           | Ghostty terminal config              | 🍎 🐧     |
| `.config/sheldon/plugins.toml`  | `~/.config/sheldon/plugins.toml`     | Zsh plugin manager                   | 🍎 🐧     |

### 🔧 Tools

| File                        | Destination                      | Description                                      | Platform  |
| --------------------------- | -------------------------------- | ------------------------------------------------ | --------- |
| `.config/mise/config.toml`  | `~/.config/mise/config.toml`     | mise version manager (Node.js, Claude Code, etc.)| 🍎 🐧 🪟  |

### ⌨️ macOS Productivity

| File                                | Destination                              | Description                 | Platform  |
| ----------------------------------- | ---------------------------------------- | --------------------------- | --------- |
| `.hammerspoon/init.lua`             | `~/.hammerspoon/init.lua`                | Window management automation| 🍎        |
| `.config/karabiner/karabiner.json`  | `~/.config/karabiner/karabiner.json`     | Keyboard remapping          | 🍎        |

### 💻 VS Code

| File                     | Destination                       | Description            | Platform  |
| ------------------------ | --------------------------------- | ---------------------- | --------- |
| `.vscode/extensions.json`| `VSCODE_USER_DIR/extensions.json` | Recommended extensions | 🍎 🐧 🪟  |
| `.vscode/mcp.json`       | `VSCODE_USER_DIR/mcp.json`        | MCP server config      | 🍎 🐧 🪟  |

> **Legend**: 🍎 macOS · 🐧 Linux · 🪟 Windows

## 🔌 Full Installation Includes

When using `--full`, the following will also be installed:

### 📦 Package Managers

- **macOS/Linux**: Homebrew + packages from `config/packages/Brewfile`
- **Ubuntu**: APT packages from `config/packages/apt-packages.txt`
- **Windows**: Scoop (CLI tools) + winget (GUI apps)

### 🛠️ Development Tools

- **anyenv**: For managing language runtimes (pyenv, nodenv, etc.)
- **VS Code Extensions**: From `src/.vscode/extensions.json`

## 📋 Requirements

- **Git**: Required for cloning the repository
- **curl** (Unix) or **PowerShell 5.1+** (Windows)

## 🧑‍💻 Development

This repository uses tools that require macOS or Linux:

- `make bootstrap` - Install development dependencies
- `just setup` - Configure development environment
- `just lint` - Run linters
- `just tf` - Run Terraform commands

Windows is supported for **using** dotfiles, but **developing** this repository requires macOS or Linux.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
