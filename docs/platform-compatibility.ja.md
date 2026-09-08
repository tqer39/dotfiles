# プラットフォーム互換性

[🇺🇸 English](./platform-compatibility.md)

このリポジトリのインストーラーが使う導入経路と代替手段を記載します。
導入済みかどうかを保証する表ではありません。
Unix のリンク対象は [platform-files.conf](../config/platform-files.conf)、
フルインストールの制限は [README](README.ja.md#️-コマンドラインオプション)を参照してください。

## CLI ツール

| ツール | macOS | Ubuntu/Mint | Windows | 備考 |
| ------ | :---: | :---------: | :-----: | ---- |
| zsh | Brew | Brew/apt | N/A | Windows は PowerShell |
| starship | Brew | Brew | Scoop | クロスプラットフォームプロンプト |
| git | Brew | Brew/apt | Scoop | |
| gh | Brew | Brew | Scoop | GitHub CLI |
| eza | Brew | Brew | Scoop | モダンな ls 代替 |
| bat | Brew | Brew | Scoop | モダンな cat 代替 |
| fzf | Brew | Brew | Scoop | ファジーファインダー |
| ripgrep | Brew | Brew | Scoop | モダンな grep 代替 |
| jq | Brew | Brew/apt | Scoop | JSON プロセッサ |
| direnv | Brew | Brew | N/A | 環境変数切り替え |
| mise | Brew | Brew | Scoop | ツールバージョン管理 |
| awscli | Brew | Brew | winget | AWS CLI |

## GUI アプリケーション

| アプリ | macOS | Ubuntu | Mint | Windows | 備考 |
| ------ | :---: | :----: | :--: | :-----: | ---- |
| VS Code | Cask | apt | apt | winget | |
| 1Password | Cask | apt | apt | winget | |
| Raycast | Cask | N/A | N/A | 手動 | Windows では導入案内のみ |
| VLC | Cask | N/A | N/A | N/A | メディアプレイヤー |
| Ghostty | Cask | snap / .deb | snap / .deb | N/A | snap がなければ .deb 用スクリプトを実行 |
| Spotify | Cask | snap / flatpak | snap / flatpak | winget | Windows は個人モードで導入 |

## macOS 専用設定

以下は、このリポジトリで macOS 向けに設定を管理するツールです。

| ツール | 用途 | 理由 |
| ------ | ---- | ---- |
| Karabiner-Elements | キーボードリマップ | macOS キーボード API 依存 |
| Hammerspoon | ウィンドウ管理 | macOS Lua スクリプティングブリッジ |

## プラットフォーム別代替

| 機能 | macOS | Ubuntu/Mint | Windows |
| ---- | ----- | ----------- | ------- |
| ランチャー | Raycast | Albert | Raycast |
| ターミナル | Ghostty | Ghostty (snap/.deb) | MobaXterm |
| クリップボード CLI | pbcopy/pbpaste | xsel/xclip | clip.exe |
| キーボードリマップ | Karabiner | N/A | N/A |
| ウィンドウ管理 | Hammerspoon | N/A | N/A |

## パッケージマネージャー

| プラットフォーム | メイン | サブ | 備考 |
| ---------------- | ------ | ---- | ---- |
| macOS | Homebrew | - | |
| Ubuntu | Homebrew | apt | GUI アプリは snap |
| Mint | Homebrew | apt | アプリごとに .deb / flatpak などを使用 |
| Windows | Scoop | winget | |

Windows は CLI ツールに Scoop（ユーザー空間、管理者権限は不要）、GUI アプリに winget を使用。
Ghostty は snap がなければ .deb 用スクリプトを実行します。
Spotify は snap、flatpak の順に利用可能か確認し、どちらもなければ導入をスキップします。
