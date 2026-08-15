# AGENTS.md

[🇯🇵 日本語版](docs/AGENTS.ja.md)

Claude Code 向けのガイダンス。

## Repository Purpose

dotfiles リポジトリ。symlink でファイルをインストール。
macOS, Linux (Ubuntu, Linux Mint), Windows をサポート。

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
- **Server mode**: `--server` skips desktop/GUI application installation

## Coding Guidelines

- Shell: `#!/usr/bin/env bash` with `set -euo pipefail`
- Variable/function names: snake_case
- Arithmetic: `count=$((count + 1))` (not `((count++))`)

## File Restrictions

- **Do NOT create** `.vscode/settings.json` - VS Code settings are not managed in this repository

## Implementation Delegation

実装は agmsg 経由で Codex CLI に担当させる。Claude Code 側は指示出し・レビュー・
検証・PR 作成を担当する。

手順:

```bash
# 1. dotfiles 専用の team に join (既存の family-tasks / media-server は使わない)
~/.agents/skills/agmsg/scripts/join.sh dotfiles <agent名> claude-code "$(pwd)"

# 2. Codex CLI を新規ターミナルウィンドウで起動
~/.agents/skills/agmsg/scripts/spawn.sh codex <名前> --project "$(pwd)" --terminal

# 3. タスクを送る
~/.agents/skills/agmsg/scripts/send.sh dotfiles <agent名> <名前> "<タスク>"
```

注意点:

- **Codex は Monitor を持たない**ため `spawn.sh` の ready 待ちがスキップされる。
  送信直後に受信済みとは限らないので `history.sh` で確認する
- 同じ理由で `despawn.sh` の graceful 停止はタイムアウトしやすい。`--force` を使う
- tmux の外から実行すると新規ターミナルウィンドウが開く。herdr / tmux の中から
  実行した場合はペイン分割になる

## Context Optimization

### Priority Directories (Read First)

- `scripts/` - Core shell scripts
- `config/` - Platform configuration
- `src/` - Dotfile sources

### Low Priority (Lazy Load)

- `infra/terraform/` - Only for infrastructure tasks
- `docs/adr/` - Only when making architectural decisions

## Documentation

- [docs/local-dev.md](docs/local-dev.md) - 開発環境セットアップ
- [docs/architecture.md](docs/architecture.md) - アーキテクチャ詳細
