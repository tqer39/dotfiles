# CLAUDE.md

[🇯🇵 日本語版](docs/CLAUDE.ja.md)

Claude Code 向けのガイダンス。

## Repository Purpose

dotfiles リポジトリ。symlink でファイルをインストール。
macOS, Linux (Ubuntu), Windows をサポート。

## Commands

```bash
# Lint
just lint

# Dotfiles
./scripts/dotfiles.sh status
./scripts/dotfiles.sh install
./scripts/dotfiles.sh uninstall
./scripts/dotfiles.sh doctor

# Terraform
just tf plan
just tf -chdir=prod/bootstrap apply
```

## Key Design Decisions

- **Idempotency**: Re-running is always safe
- **Backup**: Existing files are moved to `~/.dotfiles_backup/`
- **Platform filtering**: `config/platform-files.conf` で制御

## Coding Guidelines

- Shell: `#!/usr/bin/env bash` with `set -euo pipefail`
- Variable/function names: snake_case
- Arithmetic: `count=$((count + 1))` (not `((count++))`)

## File Restrictions

- **Do NOT create** `.vscode/settings.json` - VS Code settings are not managed in this repository

## Documentation

- [docs/local-dev.md](docs/local-dev.md) - 開発環境セットアップ
- [docs/architecture.md](docs/architecture.md) - アーキテクチャ詳細
