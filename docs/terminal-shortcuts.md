# macOS の共通ショートカット

## 共通仕様と現在の設定

物理キーの呼称、4環境共通のキーマップ、未確定事項は
[キー入力ルールの正本](rules/keyboard-input.md)で管理します。
この文書はターミナル側の設定箇所を説明するもので、共通仕様の実装完了を示すものではありません。

macOS の汎用ルールでは Control 入力を Command に変換します。
除外リストに登録したターミナルでは汎用ルールで変換せず、個別のキー設定を使います。
以下の `Ctrl` はアプリが受け取る Control を表し、物理的な A左キーとは区別します。

## エディタの統合ターミナル

`A左キー+Shift+J` を VS Code・Cursor などの統合ターミナルを開く操作に使います。
追加用の共通定義は [config/editor-keybindings.json](../config/editor-keybindings.json) です。
`workbench.action.terminal.focus` に割り当て、既存のターミナルにフォーカスします。
まだターミナルがなければ作成します。パネルの表示切り替えや毎回の新規作成には割り当てません。

- macOS：アプリが受け取る `Command+Shift+J` に割り当てます。
  A左キーから Command への既存の汎用変換は維持し、VS Code・Cursor 専用の Karabiner 変換は追加しません。
- Windows・Ubuntu：`Control+Shift+J` に割り当てます。
  HHKB の A左キーが Control を送る前提です。端末固有のリマップや実際の出力は別途確認します。
- Codex：既存の Karabiner ルールによる `A左キー+Shift+J` から `Command+J` への変換を維持します。
  エディタ向けの `keybindings.json` は Codex に適用しません。

### コマンド履歴の検索

`A左キー+R` は、統合ターミナルにフォーカスしているときだけ fzf の履歴検索を呼び出します。
共通定義では macOS の `Command+R`、Windows・Ubuntu の `Control+R` に割り当てます。
`workbench.action.terminal.sendSequence` で Control+R（`\u0012`）をシェルに送ります。
Karabiner の追加変換は不要です。エディタ本文やチャット欄の操作は変更しません。

前提は、統合ターミナルのシェルで fzf の Control+R 連携が有効なことです。
zsh・bash は `src/.shell_common` の fzf 初期化を使います。
Windows の PowerShell は fzf と PSFzf の導入および履歴検索のキー設定が必要です。
SSH・コンテナ内では、接続先のシェルにも同じ連携が必要です。
連携がなければ通常のシェル履歴検索になり、fzf の画面にはなりません。

シェルのプロンプトで実行し、検索・選択後のコマンドを確認してから Enter で実行します。
キー設定から改行は送らず、自動実行しません。シェル以外のプログラムが動作中の場合は、
Control+R がそのプログラムに届くため、そのプログラム自身の動作になります。

### 適用方法

1. 各エディタの「基本設定: キーボード ショートカットを開く（JSON）」で、使用中のプロファイルの
   `keybindings.json` を開きます。
2. バックアップし、共通定義の要素を既存配列の末尾に追加します。ファイル全体を置き換えません。
   同じキーと条件の定義が既にある場合は、重複追加せず割り当て先を確認して更新します。
3. エディタ・統合ターミナル・チャット欄から `A左キー+Shift+J` を押して確認します。
   ターミナル未作成時・非表示時・表示中で試し、既存セッションが維持されることも確認します。
4. 統合ターミナルのプロンプトで `A左キー+R` を押し、fzf の履歴検索が表示されることを確認します。
   Esc でキャンセルできること、選択だけではコマンドを実行しないことも確認します。

この定義は追加用であり、dotfiles の通常インストールでは自動でリンク・上書きしません。
設定同期や他のプロファイルに既存の個別設定があるため、それぞれにマージしてください。
今回の適用対象は現在の Mac の VS Code・Cursor の既定ユーザー設定です。
別プロファイル・別エディタ・Windows・Ubuntu・別の Mac の実機動作は未確認です。
動かない場合は「Developer: Toggle Keyboard Shortcuts Troubleshooting」で受信キーと実行コマンドを確認します。

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

- [VS Code のキーバインド設定](https://code.visualstudio.com/docs/configure/keybindings)
- [VS Code のターミナルへのキー送信](https://code.visualstudio.com/docs/terminal/advanced#_custom-sequence-keyboard-shortcuts)
- [fzf のシェル連携](https://github.com/junegunn/fzf#setting-up-shell-integration)
- [Cursor のキーボードショートカット](https://cursor.com/docs/reference/keyboard-shortcuts)
- [Ghostty のキー設定](https://ghostty.org/docs/config/keybind)
- [cmux の設定](https://cmux.com/docs/configuration)
- [標準ターミナルのショートカット](https://support.apple.com/guide/terminal/trmlshtcts/mac)
