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
| `docs/README.ja.md`            | Quick Start, コマンドラインオプション（対応箇所） |
| `install.sh` 内 `show_help()`  | ヘルプテキスト                                    |
| `install.ps1` 内 `Show-Help`   | ヘルプテキスト                                    |

## チェック項目

### 1. コマンドラインオプションの整合性

- `install.sh` のオプションの追加・削除・変更が `docs/README.ja.md` の Unix 用オプション表に反映され、`show_help()` と一致しているか
- `install.ps1` の `Show-Help` が同 README の Windows 向け案内・使用例と整合しているか
- Windows のオプション確認先は `./install.ps1 -Help` とし、Unix 用オプション表に Windows の項目を追加しない
- `install.sh` と `install.ps1` で同名オプションの説明が一致しているか

### 2. Quick Start セクション

- 使用例（コマンド例）が現在のスクリプトの実際の動作と一致しているか
- 前提条件（必要なツール等）に変更がないか

### 3. 日本語のドキュメントを正本として更新

- 日本語の設計・運用ドキュメントに変更を反映する
- 英語版の作成・同期は不要とする

## 手順

1. `install.sh` / `install.ps1` の変更内容を確認（`git diff` で差分を確認）
2. `show_help()` / `Show-Help` 関数のヘルプテキストを読み取る
3. `show_help()` を `docs/README.ja.md` の Unix 用オプション表と比較
4. `Show-Help` を同 README の Windows 向け案内・使用例と照合し、`./install.ps1 -Help` への案内を確認
5. 差分があれば対象 OS の日本語ドキュメントを更新
6. `mise run lint` を実行してリントエラーがないか確認
7. エラーがあれば修正し、再度 `mise run lint` で確認

## 検証

```bash
mise run lint
```

すべてのチェックが Passed になるまで修正を繰り返す。
