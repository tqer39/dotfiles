# Dotfiles

[🇺🇸 English](../README.md)

このリポジトリは、自動セットアップスクリプト付きの公開用 dotfiles を含んでいます。これらの設定ファイルは、macOS、Linux (Ubuntu)、Windows 間で一貫した開発環境を維持するのに役立ちます。

## クイックスタート

### macOS / Linux (Ubuntu)

```bash
# 最小限のインストール（dotfiles のみ）
curl -fsSL https://install.tqer39.dev | bash

# フルインストール（dotfiles + 開発環境）
curl -fsSL https://install.tqer39.dev | bash -s -- --full

# 実行せずに変更内容をプレビュー
curl -fsSL https://install.tqer39.dev | bash -s -- --dry-run
```

### Windows (PowerShell)

```powershell
# 最小限のインストール
irm https://install.tqer39.dev/windows | iex

# フルインストール
.\install.ps1 -Full

# 変更内容をプレビュー
.\install.ps1 -DryRun
```

## 特徴

- **冪等性**: 複数回実行しても安全 - 既存の正しいシンボリックリンクはスキップ
- **クロスプラットフォーム**: macOS、Linux (Ubuntu)、Windows をサポート
- **バックアップ**: 既存のファイルは `~/.dotfiles_backup/` にバックアップ
- **モジュラー**: 最小限（dotfiles のみ）またはフル（開発ツール付き）を選択可能

## コマンドラインオプション

| オプション | 説明 |
| --------- | ---- |
| `--full` | フルセットアップ（dotfiles + 開発環境） |
| `--minimal` | 最小限のセットアップ（dotfiles のみ、デフォルト） |
| `--skip-packages` | パッケージマネージャのインストールをスキップ |
| `--skip-languages` | 言語ランタイムのインストールをスキップ |
| `--dry-run` | 実行せずに変更内容を表示 |
| `-v, --verbose` | 詳細なログを出力 |
| `--uninstall` | dotfiles のシンボリックリンクを削除 |
| `--work` | 会社モード（個人用パッケージをスキップ） |

## リポジトリ構造

```text
dotfiles/
├── install.sh              # Unix 用エントリーポイント
├── install.ps1             # Windows PowerShell 用エントリーポイント
├── src/                    # Dotfiles
│   ├── .zshrc              # Zsh 設定
│   ├── .bashrc             # Bash 設定
│   ├── .gitconfig          # Git 設定
│   ├── .hammerspoon/       # ウィンドウ管理 (macOS)
│   ├── .vscode/            # VS Code 設定
│   └── .config/
│       ├── starship.toml   # Starship プロンプト
│       ├── karabiner/      # キーボードカスタマイズ (macOS)
│       └── git/            # Git ignore パターン
├── scripts/
│   ├── lib/                # 共通ユーティリティ
│   ├── installers/         # パッケージインストーラー
│   └── dotfiles.sh         # シンボリックリンク管理
└── config/
    ├── platform-files.conf # ファイル → シンボリックリンク マッピング
    └── packages/           # パッケージリスト（Brewfile など）
```

## プラットフォーム別ファイル

一部の dotfiles は特定のプラットフォームでのみインストールされます：

| ファイル | macOS | Linux | Windows |
| ------- | :---: | :---: | :-----: |
| `.zshrc`, `.bashrc` | ✓ | ✓ | - |
| `.gitconfig` | ✓ | ✓ | ✓ |
| `.hammerspoon/` | ✓ | - | - |
| `.config/karabiner/` | ✓ | - | - |
| `.vscode/` | ✓ | ✓ | ✓ |
| `.config/starship.toml` | ✓ | ✓ | - |

## フルインストールの内容

`--full` オプションを使用すると、以下も一緒にインストールされます：

### パッケージマネージャ

- **macOS/Linux**: Homebrew + `config/packages/Brewfile` のパッケージ
- **Ubuntu**: `config/packages/apt-packages.txt` の APT パッケージ
- **Windows**: winget パッケージ

### 開発ツール

- **anyenv**: 言語ランタイム管理（pyenv、nodenv など）
- **VS Code 拡張機能**: `src/.vscode/extensions.json` から

## 必要条件

- **Git**: リポジトリのクローンに必要
- **curl** (Unix) または **PowerShell 5.1+** (Windows)

## ライセンス

このプロジェクトは MIT ライセンスの下で公開されています。詳細は [LICENSE](../LICENSE) ファイルを参照してください。
