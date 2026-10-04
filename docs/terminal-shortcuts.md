# macOS の共通ショートカット

## 共通仕様と現在の設定

物理キーの呼称、4環境共通のキーマップ、未確定事項は
[キー入力ルールの正本](rules/keyboard-input.md)で管理します。
この文書はターミナル側の設定箇所を説明するもので、共通仕様の実装完了を示すものではありません。

macOS の汎用ルールでは Control 入力を Command に変換します。
除外リストに登録したターミナルでは汎用ルールで変換せず、個別のキー設定を使います。
以下の `Ctrl` はアプリが受け取る Control を表し、物理的な A左キーとは区別します。

## ターミナルの設定箇所

Ghostty は `src/.config/ghostty/config` で設定する。
コピーは `performable` を使い、選択範囲がない場合は Ctrl+C を CLI に渡す。
設定変更後は Command+Shift+, で再読み込みする。

cmux のコピーと貼り付けは Ghostty 設定を共有する。
タブ操作と終了は `src/.config/cmux/settings.json` でも設定する。
`~/.config/cmux/cmux.json` に同じ項目がある場合は、そちらが優先されるため両方を揃える。
`cmux reload-config` で再読み込みする。
ここでのタブはペイン内のタブを指し、サイドバーのワークスペースとは異なる。

標準ターミナルは汎用の Control-to-Command 変換から除外されている。
貼り付け、新規タブ、タブ終了、アプリ終了をまとめて変換する旧 Karabiner ルールも無効であり、
共通仕様を満たすかは個別に確認する。
コピーを日本語・英語のメニューに割り当てるスクリプトは次のとおり。

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
