<!-- cspell:ignore HHKB -->

# macOS の共通ショートカット

macOS では Caps Lock を Command に設定します。Karabiner は物理 Control を Command として扱います。
Windows + HHKB では Caps Lock を Control に設定し、Windows 標準の Control ショートカットをそのまま使います。
ターミナルでは Control を本来のテキスト編集に使うため、Karabiner は変換しません。Codex を含むそれ以外のアプリでは、HHKB の元 Caps Lock として届く Control を Command に変換します。

| キー | 操作 |
| --- | --- |
| Ctrl+W | 現在のウィンドウまたはタブを閉じる |
| Ctrl+Q | アプリを終了する |
| Ctrl+Tab | 次のアプリへ切り替える |
| Ctrl+Shift+Tab | 前のアプリへ切り替える |
| Ctrl+N | 新規ウィンドウまたはタブを開く |
| Ctrl+Shift+N | 新規の別形態のウィンドウまたはタブを開く |
| Ctrl+クリック | Command+クリック相当の操作 |

各アプリが Command ショートカットを実装していれば、上記は同じアプリで同じ意味になる。Control+クリックは macOS 標準のコンテキストメニューではなく Command+クリックとして扱われる。

ターミナルでは次の Control 操作も使う。

| キー | 操作 |
| --- | --- |
| Ctrl+C | 選択範囲のコピー、または実行中コマンドの中断 |
| Ctrl+V | 貼り付け |
| Ctrl+T | 新規タブ |
| Ctrl+W | 現在のタブを閉じる |
| Ctrl+Q | アプリ全体を終了 |

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
