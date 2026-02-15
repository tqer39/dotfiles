---
name: ghostty-config
description: Ghostty設定ファイルの修正。公式ドキュメントを参照してキーバインディング、フォント、テーマ、ウィンドウ設定などを支援
allowed-tools: Read, Grep, WebFetch
---

# Ghostty 設定アシスタント

Ghostty の公式ドキュメントを参照しながら、設定ファイルを修正します。

## 参照すべき公式ドキュメント

設定修正時には WebFetch で以下の公式リファレンスを参照すること：

1. **設定概要**: https://ghostty.org/docs/config
2. **設定オプションリファレンス**: https://ghostty.org/docs/config/reference
3. **キーバインディング概要**: https://ghostty.org/docs/config/keybind
4. **キーバインディング トリガーシーケンス**: https://ghostty.org/docs/config/keybind/sequence
5. **キーバインディング アクションリファレンス**: https://ghostty.org/docs/config/keybind/reference

## 修正手順

1. WebFetch で関連する公式ドキュメントを参照
2. 現在の設定ファイル (`~/.config/ghostty/config`) を読み込む
3. 公式ドキュメントに基づいて修正内容を提案
4. ユーザーの了承を得て修正を適用

## 注意事項

- 設定形式は `key = value` 形式
- 設定ファイルの場所: `~/.config/ghostty/config`
- 公式ドキュメントで最新の設定項目を確認すること
- 設定変更前に必ず公式リファレンスで正確な設定名と値を確認
