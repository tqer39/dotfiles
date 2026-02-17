# プラットフォーム互換性

[🇺🇸 English](./platform-compatibility.md)

macOS、Linux、Windows 間でのツール対応状況と代替手段を記載。

## CLI ツール

| ツール | macOS | Ubuntu/Mint | Windows | 備考 |
| ------ | :---: | :---------: | :-----: | ---- |
| zsh | Brew | Brew/apt | N/A | Windows は PowerShell |
| starship | Brew | Brew | Scoop | クロスプラットフォームプロンプト |
| git | Brew | Brew/apt | Scoop | |
| gh | Brew | Brew | Scoop | GitHub CLI |
| eza | Brew | Brew | Scoop | モダンな ls 代替 |
| bat | Brew | Brew | Scoop | モダンな cat 代替 |
| fzf | Brew | Brew/apt | Scoop | ファジーファインダー |
| ripgrep | Brew | Brew/apt | Scoop | モダンな grep 代替 |
| jq | Brew | Brew/apt | Scoop | JSON プロセッサ |
| direnv | Brew | Brew | N/A | 環境変数切り替え |
| mise | Brew | Brew | Scoop | ツールバージョン管理 |
| awscli | Brew | Brew | winget | AWS CLI |

## GUI アプリケーション

| アプリ | macOS | Ubuntu | Mint | Windows | 備考 |
| ------ | :---: | :----: | :--: | :-----: | ---- |
| VS Code | Cask | apt | apt | winget | |
| 1Password | Cask | apt | apt | winget | |
| Raycast | Cask | N/A | N/A | winget | ランチャー |
| VLC | Cask | apt | apt | N/A | メディアプレイヤー |
| Ghostty | Cask | snap | flatpak | N/A | ターミナルエミュレータ |
| Spotify | Cask | snap | flatpak | N/A | 音楽プレイヤー |

## macOS 専用（代替なし）

以下のツールは他プラットフォームに同等の代替がない:

| ツール | 用途 | 理由 |
| ------ | ---- | ---- |
| Karabiner-Elements | キーボードリマップ | macOS キーボード API 依存 |
| Hammerspoon | ウィンドウ管理 | macOS Lua スクリプティングブリッジ |
| Ghostty | ターミナルエミュレータ | Windows ビルドなし |

## プラットフォーム別代替

| 機能 | macOS | Ubuntu/Mint | Windows |
| ---- | ----- | ----------- | ------- |
| ランチャー | Raycast | Albert | Raycast |
| ターミナル | Ghostty | Ghostty (snap/flatpak) | MobaXterm |
| クリップボード CLI | pbcopy/pbpaste | xsel/xclip | clip.exe |
| キーボードリマップ | Karabiner | N/A | N/A |
| ウィンドウ管理 | Hammerspoon | N/A | N/A |

## パッケージマネージャー

| プラットフォーム | メイン | サブ | 備考 |
| ---------------- | ------ | ---- | ---- |
| macOS | Homebrew | - | |
| Ubuntu | Homebrew | apt | GUI アプリは snap |
| Mint | Homebrew | apt | GUI アプリは flatpak（snap はデフォルト無効） |
| Windows | Scoop | winget | |

Windows は CLI ツールに Scoop（ユーザー空間、管理者権限は不要）、GUI アプリに winget を使用。
Mint は GUI アプリ（Ghostty、Spotify）に snap の代わりに flatpak を使用（snap はデフォルト無効）。
