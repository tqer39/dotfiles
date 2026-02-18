---
name: sync-install-docs
description: install.sh / install.ps1 を編集した後、関連ドキュメント（README.md 等）の整合性を確認・更新する。インストールスクリプトを変更したら必ず実行。
---

# Sync Install Docs

インストールスクリプト (`install.sh` / `install.ps1`) を変更した後、関連ドキュメントとの整合性を確認・更新するスキル。

## 重要

**`install.sh` または `install.ps1` を編集した場合は、必ずこのスキルに従ってドキュメントの整合性を確認・更新すること。**

## 対象ファイル

### トリガー（変更を検知するファイル）

- `install.sh` - メインのインストールスクリプト (Bash)
- `install.ps1` - Windows 用インストールスクリプト (PowerShell)

### チェック対象ドキュメント

| ファイル                       | チェック対象セクション                            |
| ------------------------------ | ------------------------------------------------- |
| `README.md`                    | Quick Start, Command Line Options                 |
| `docs/README.ja.md`            | Quick Start, コマンドラインオプション（対応箇所） |
| `install.sh` 内 `show_help()`  | ヘルプテキスト                                    |
| `install.ps1` 内 `Show-Help`   | ヘルプテキスト                                    |

## チェック項目

### 1. コマンドラインオプションの整合性

- オプションの追加・削除・変更が README の Options テーブルに反映されているか
- `show_help()` / `Show-Help` 内のヘルプテキストと README の記述が一致しているか
- `install.sh` と `install.ps1` で同名オプションの説明が一致しているか

### 2. Quick Start セクション

- 使用例（コマンド例）が現在のスクリプトの実際の動作と一致しているか
- 前提条件（必要なツール等）に変更がないか

### 3. 英語版・日本語版の同期

- `README.md` (英語) と `docs/README.ja.md` (日本語) の両方が更新されているか
- オプションテーブルの構造と内容が両言語で一致しているか

## 手順

1. `install.sh` / `install.ps1` の変更内容を確認（`git diff` で差分を確認）
2. `show_help()` / `Show-Help` 関数のヘルプテキストを読み取る
3. `README.md` の Command Line Options セクションと比較
4. `docs/README.ja.md` の対応セクションと比較
5. 差分があればドキュメントを更新
6. `just lint` を実行してリントエラーがないか確認
7. エラーがあれば修正し、再度 `just lint` で確認

## 検証

```bash
just lint
```

すべてのチェックが Passed になるまで修正を繰り返す。
