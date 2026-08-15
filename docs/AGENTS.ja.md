# AGENTS.md

[🇺🇸 English](../AGENTS.md)

Claude Code 向けのガイダンス。

## リポジトリの目的

dotfiles リポジトリ。symlink でファイルをインストール。
macOS, Linux (Ubuntu, Linux Mint), Windows をサポート。

## コマンド

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

## 主要な設計方針

- **冪等性**: 再実行しても常に安全
- **バックアップ**: 既存ファイルは `~/.dotfiles_backup/` に移動
- **プラットフォームフィルタリング**: `config/platform-files.conf` で制御
- **サーバーモード**: `--server` ではデスクトップ/GUI アプリをインストールしない

## コーディングガイドライン

- Shell: `#!/usr/bin/env bash` with `set -euo pipefail`
- 変数/関数名: snake_case
- 算術演算: `count=$((count + 1))` (`((count++))` ではない)

## ファイル制限

- `.vscode/settings.json` を**作成しない** - VS Code の設定はこのリポジトリで管理しない

## 実装の委譲

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

## コンテキスト最適化

### 優先ディレクトリ（最初に読む）

- `scripts/` - コアシェルスクリプト
- `config/` - プラットフォーム設定
- `src/` - Dotfile ソース

### 低優先度（遅延読み込み）

- `infra/terraform/` - インフラタスクの場合のみ
- `docs/adr/` - アーキテクチャ決定時のみ

## ドキュメント

- [docs/local-dev.ja.md](local-dev.ja.md) - 開発環境セットアップ
- [docs/architecture.ja.md](architecture.ja.md) - アーキテクチャ詳細
