---
name: ghostty-config
description: Ghostty設定ファイルの修正。公式ドキュメントを参照してキーバインディング、フォント、テーマ、ウィンドウ設定などを支援
allowed-tools: Read, Edit, Grep, WebFetch
---

# Ghostty 設定アシスタント

Ghostty の公式ドキュメントを参照しながら、設定ファイルを修正します。

## 公式ドキュメント

設定修正時には WebFetch で参照すること：

| カテゴリ | URL |
|---------|-----|
| 設定概要 | https://ghostty.org/docs/config |
| オプションリファレンス | https://ghostty.org/docs/config/reference |
| キーバインディング | https://ghostty.org/docs/config/keybind |
| トリガーシーケンス | https://ghostty.org/docs/config/keybind/sequence |
| アクションリファレンス | https://ghostty.org/docs/config/keybind/reference |

## 設定ファイル

- パス: `src/.config/ghostty/config`
- 形式: `key = value`

## CLI コマンド

```bash
# デフォルト設定をドキュメント付きで表示
ghostty +show-config --default --docs

# 現在の設定を表示
ghostty +show-config
```
