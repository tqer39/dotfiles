# ターミナルの共通ショートカット

Ghostty、cmux、macOS 標準の「ターミナル」で Control を使う。
元 Caps Lock が Control として届く場合も同じ操作になる。

| キー | 操作 |
| --- | --- |
| Ctrl+C | 選択範囲のコピー |
| Ctrl+V | 貼り付け |
| Ctrl+T | 新規タブ |
| Ctrl+W | 現在のタブを閉じる |
| Ctrl+Q | アプリ全体を終了 |
| Ctrl+Tab | 次のタブへ移動 |
| Ctrl+Shift+Tab | 前のタブへ移動 |

Ghostty は `src/.config/ghostty/config` で設定する。
コピーは `performable` を使い、選択範囲がない場合は Ctrl+C を CLI に渡す。
設定変更後は Command+Shift+, で再読み込みする。

cmux のコピーと貼り付けは Ghostty 設定を共有する。
タブ操作と終了は `src/.config/cmux/settings.json` でも設定する。
`~/.config/cmux/cmux.json` に同じ項目がある場合は、そちらが優先されるため両方を揃える。
`cmux reload-config` で再読み込みする。
ここでのタブはペイン内のタブを指し、サイドバーのワークスペースとは異なる。

標準ターミナルの貼り付け、新規タブ、タブ終了、アプリ終了は Karabiner で
Control を Command に変換する。タブ移動はアプリの既定設定を使う。
コピーは次のコマンドで日本語・英語のメニューに割り当てる。

```bash
bash scripts/configure-terminal-copy.sh
```

実行後は作業を保存し、標準ターミナルを起動し直す。
コピーの割り当ては左右の Control に適用される。
標準ターミナルで選択範囲がない場合の Ctrl+C は実機で確認する。

## 参考

- [Ghostty のキー設定](https://ghostty.org/docs/config/keybind)
- [cmux の設定](https://cmux.com/docs/configuration)
- [標準ターミナルのショートカット](https://support.apple.com/guide/terminal/trmlshtcts/mac)
