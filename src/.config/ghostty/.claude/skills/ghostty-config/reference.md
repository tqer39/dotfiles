# Ghostty 設定リファレンス

このファイルは、Ghostty 設定時に参照すべき公式ドキュメントへのリンク集です。

## 公式ドキュメント

| カテゴリ | URL | 説明 |
|---------|-----|------|
| 設定概要 | https://ghostty.org/docs/config | 設定の基本 |
| オプションリファレンス | https://ghostty.org/docs/config/reference | 全設定項目一覧 |
| キーバインディング | https://ghostty.org/docs/config/keybind | キー割り当て |
| トリガーシーケンス | https://ghostty.org/docs/config/keybind/sequence | 複合キー |
| アクションリファレンス | https://ghostty.org/docs/config/keybind/reference | アクション一覧 |

## 主な設定カテゴリ

### テーマ・カラー
- `theme` - カラーテーマ名
- `background` - 背景色
- `foreground` - 前景色
- `palette` - カスタムパレット

### フォント
- `font-family` - フォント名
- `font-size` - フォントサイズ
- `font-thicken` - フォントを太くする

### 背景・透明度
- `background-opacity` - 背景の透明度
- `background-blur` - 背景ぼかし

### ウィンドウ
- `window-padding-x` - 水平パディング
- `window-padding-y` - 垂直パディング
- `window-save-state` - ウィンドウ状態の保存

### macOS 固有
- `macos-titlebar-style` - タイトルバースタイル

### キーバインディング
- `keybind` - キー割り当て（例: `super+r=text:\x12`）

## CLI コマンド

```bash
# デフォルト設定をドキュメント付きで表示
ghostty +show-config --default --docs

# 現在の設定を表示
ghostty +show-config
```
