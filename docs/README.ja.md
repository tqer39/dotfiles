# ⚡ Dotfiles

[🇺🇸 English](../README.md)

[![Test Install](https://img.shields.io/github/actions/workflow/status/tqer39/dotfiles/test-install.yml?branch=main&style=for-the-badge&logo=github&label=install)](https://github.com/tqer39/dotfiles/actions/workflows/test-install.yml)
[![Pre-commit](https://img.shields.io/github/actions/workflow/status/tqer39/dotfiles/prek.yml?branch=main&style=for-the-badge&logo=precommit&label=lint)](https://github.com/tqer39/dotfiles/actions/workflows/prek.yml)
[![Terraform](https://img.shields.io/github/actions/workflow/status/tqer39/dotfiles/terraform.yml?branch=main&style=for-the-badge&logo=terraform&label=terraform)](https://github.com/tqer39/dotfiles/actions/workflows/terraform.yml)
[![Security](https://img.shields.io/github/actions/workflow/status/tqer39/dotfiles/trivy-terraform.yml?branch=main&style=for-the-badge&logo=trivy&label=security)](https://github.com/tqer39/dotfiles/actions/workflows/trivy-terraform.yml)

[![macOS](https://img.shields.io/badge/macOS-supported-000000?style=for-the-badge&logo=apple&logoColor=white)](https://www.apple.com/macos/)
[![Linux](https://img.shields.io/badge/Linux-supported-FCC624?style=for-the-badge&logo=linux&logoColor=black)](https://www.linux.org/)
[![Windows](https://img.shields.io/badge/Windows-supported-0078D6?style=for-the-badge&logo=windows&logoColor=white)](https://www.microsoft.com/windows/)

[![Bash](https://img.shields.io/badge/Bash-5.x-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Python](https://img.shields.io/badge/Python-3.13-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://www.python.org/)
[![Terraform](https://img.shields.io/badge/Terraform-1.14-844FBA?style=for-the-badge&logo=terraform&logoColor=white)](https://www.terraform.io/)
[![MIT License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](../LICENSE)

このリポジトリは、自動セットアップスクリプト付きの公開用 dotfiles を含んでいます。これらの設定ファイルは、macOS、Linux (Ubuntu)、Windows 間で一貫した開発環境を維持するのに役立ちます。

## 🚀 クイックスタート

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

# 実行ポリシーでブロックされる場合は次を使用:
powershell -ExecutionPolicy Bypass -File .\install.ps1 -Full

# 変更内容をプレビュー
.\install.ps1 -DryRun
```

## ✨ 特徴

- **冪等性**: 複数回実行しても安全 - 既存の正しいシンボリックリンクはスキップ
- **クロスプラットフォーム**: macOS、Linux (Ubuntu)、Windows をサポート
- **クローン先**: リポジトリは `~/.dotfiles` にクローンされます
- **バックアップ**: 既存のファイルは `~/.dotfiles_backup/` にバックアップ
- **モジュラー**: 最小限（dotfiles のみ）またはフル（開発ツール付き）を選択可能

## ⚙️ コマンドラインオプション

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
| `--ci` | CI モード（非対話型） |
| `--doctor` | 環境ヘルスチェックを実行 |

## 📁 リポジトリ構造

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

## 📦 同梱ファイル

インストール時に symlink されるすべての dotfiles：

### 🐚 シェル

| ファイル                           | インストール先                 | 説明                                       | プラットフォーム |
| ---------------------------------- | ------------------------------ | ------------------------------------------ | ---------------- |
| `.shell_common`                    | `~/.shell_common`              | 共通エイリアス・関数（git, ls, navigation）| 🍎 🐧            |
| `.zshrc`                           | `~/.zshrc`                     | Zsh 設定                                   | 🍎 🐧            |
| `.bashrc`                          | `~/.bashrc`                    | Bash 設定                                  | 🍎 🐧            |
| `.bash_profile`                    | `~/.bash_profile`              | Bash ログインシェル設定                    | 🍎 🐧            |
| `Microsoft.PowerShell_profile.ps1` | `~/Documents/PowerShell/...`   | PowerShell プロファイル                    | 🪟               |

### 🔀 Git

| ファイル             | インストール先           | 説明                                   | プラットフォーム |
| -------------------- | ------------------------ | -------------------------------------- | ---------------- |
| `.gitconfig`         | `~/.gitconfig`           | Git ユーザー設定、GPG 署名、エイリアス | 🍎 🐧 🪟         |
| `.gitignore`         | `~/.gitignore_global`    | グローバル ignore パターン             | 🍎 🐧 🪟         |
| `.config/git/ignore` | `~/.config/git/ignore`   | 追加 ignore ルール                     | 🍎 🐧 🪟         |

### 🎨 ターミナル & プロンプト

| ファイル                        | インストール先                       | 説明                                      | プラットフォーム |
| ------------------------------- | ------------------------------------ | ----------------------------------------- | ---------------- |
| `.config/starship.toml`         | `~/.config/starship.toml`            | Starship プロンプト（Tokyo Night テーマ） | 🍎 🐧            |
| `.config/ghostty/config`        | `~/.config/ghostty/config`           | Ghostty ターミナル設定                    | 🍎 🐧            |
| `.config/sheldon/plugins.toml`  | `~/.config/sheldon/plugins.toml`     | Zsh プラグインマネージャー                | 🍎 🐧            |

### 🔧 ツール

| ファイル                       | インストール先                   | 説明                                          | プラットフォーム |
| ------------------------------ | -------------------------------- | --------------------------------------------- | ---------------- |
| `.config/mise/config.toml`     | `~/.config/mise/config.toml`     | mise バージョン管理（Node.js, Claude Code 等）| 🍎 🐧 🪟         |

### ⌨️ macOS 生産性ツール

| ファイル                               | インストール先                           | 説明                   | プラットフォーム |
| -------------------------------------- | ---------------------------------------- | ---------------------- | ---------------- |
| `.hammerspoon/init.lua`                | `~/.hammerspoon/init.lua`                | ウィンドウ管理自動化   | 🍎               |
| `.config/karabiner/karabiner.json`     | `~/.config/karabiner/karabiner.json`     | キーボードリマップ     | 🍎               |

### 💻 VS Code

| ファイル                  | インストール先                    | 説明               | プラットフォーム |
| ------------------------- | --------------------------------- | ------------------ | ---------------- |
| `.vscode/extensions.json` | `VSCODE_USER_DIR/extensions.json` | 推奨拡張機能       | 🍎 🐧 🪟         |
| `.vscode/mcp.json`        | `VSCODE_USER_DIR/mcp.json`        | MCP サーバー設定   | 🍎 🐧 🪟         |

> **凡例**: 🍎 macOS · 🐧 Linux · 🪟 Windows

## 🔌 フルインストールの内容

`--full` オプションを使用すると、以下も一緒にインストールされます：

### 📦 パッケージマネージャ

- **macOS/Linux**: Homebrew + `config/packages/Brewfile` のパッケージ
- **Ubuntu**: `config/packages/apt-packages.txt` の APT パッケージ
- **Windows**: Scoop（CLI ツール）+ winget（GUI アプリ）

### 🛠️ 開発ツール

- **anyenv**: 言語ランタイム管理（pyenv、nodenv など）
- **VS Code 拡張機能**: `src/.vscode/extensions.json` から

## 📋 必要条件

- **Git**: リポジトリのクローンに必要
- **curl** (Unix) または **PowerShell 5.1+** (Windows)

## 📄 ライセンス

このプロジェクトは MIT ライセンスの下で公開されています。詳細は [LICENSE](../LICENSE) ファイルを参照してください。
