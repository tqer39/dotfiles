# CLAUDE.md

[🇺🇸 English](../CLAUDE.md)

Claude Code 向けのガイダンス。

## リポジトリの目的

dotfiles リポジトリ。symlink でファイルをインストール。
macOS, Linux (Ubuntu), Windows をサポート。

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

## コーディングガイドライン

- Shell: `#!/usr/bin/env bash` with `set -euo pipefail`
- 変数/関数名: snake_case
- 算術演算: `count=$((count + 1))` (`((count++))` ではない)

## ファイル制限

- `.vscode/settings.json` を**作成しない** - VS Code の設定はこのリポジトリで管理しない

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
