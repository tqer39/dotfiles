# Architecture

## Entry Points

- `install.sh` - Unix (macOS/Linux) entry point, can be piped from curl
- `install.ps1` - Windows PowerShell entry point

## Script Library (`scripts/lib/`)

Shared utilities sourced by all scripts:

- `log.sh` - Colored logging functions (`log_info`, `log_success`, `log_error`, etc.)
- `utils.sh` - OS detection (`detect_os`), path expansion, command checking
- `symlink.sh` - Idempotent symlink creation with backup support

## Configuration

- `config/platform-files.conf` - Defines SOURCE:DESTINATION:PLATFORMS mappings
  - Format: `.zshrc:~/.zshrc:macos,linux`
  - Platforms: `all` / `macos` / `linux` / `ubuntu` / `windows`
- `config/packages/Brewfile` - Homebrew packages
- `config/packages/apt-packages.txt` - APT packages for Ubuntu

## Installers (`scripts/installers/`)

Modular installers called during `--full` installation:

- `homebrew.sh` - Homebrew and Brewfile packages
- `apt.sh` - APT packages (Ubuntu only)
- `anyenv.sh` - Language runtime manager
- `vscode.sh` - VS Code extensions from `src/.vscode/extensions.json`

## Terraform (`infra/terraform/`)

- `modules/` - 再利用可能なモジュール
  - `cloudflare/` - CloudFlare DNS 設定
  - `deploy-role/` - GitHub Actions OIDC 用 IAM Role
- `envs/prod/` - 本番環境
  - `bootstrap/` - IAM Role (ローカル実行必須)
  - `dns/` - CloudFlare DNS レコード
