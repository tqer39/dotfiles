# ⚡ Dotfiles

[🇺🇸 English](../README.md)

[![Test Install](https://img.shields.io/github/actions/workflow/status/tqer39/dotfiles/test-install.yml?branch=main&style=for-the-badge&logo=github&label=install)](https://github.com/tqer39/dotfiles/actions/workflows/test-install.yml)
[![Lint](https://img.shields.io/github/actions/workflow/status/tqer39/dotfiles/lint.yml?branch=main&style=for-the-badge&logo=precommit&label=lint)](https://github.com/tqer39/dotfiles/actions/workflows/lint.yml)
[![Terraform](https://img.shields.io/github/actions/workflow/status/tqer39/dotfiles/terraform.yml?branch=main&style=for-the-badge&logo=terraform&label=terraform)](https://github.com/tqer39/dotfiles/actions/workflows/terraform.yml)
[![Security](https://img.shields.io/github/actions/workflow/status/tqer39/dotfiles/trivy-terraform.yml?branch=main&style=for-the-badge&logo=trivy&label=security)](https://github.com/tqer39/dotfiles/actions/workflows/trivy-terraform.yml)

[![macOS](https://img.shields.io/badge/macOS-supported-000000?style=for-the-badge&logo=apple&logoColor=white)](https://www.apple.com/macos/)
[![Linux](https://img.shields.io/badge/Linux-supported-FCC624?style=for-the-badge&logo=linux&logoColor=black)](https://www.linux.org/)
[![Windows](https://img.shields.io/badge/Windows-supported-0078D6?style=for-the-badge&logo=windows&logoColor=white)](https://www.microsoft.com/windows/)

[![Bash](https://img.shields.io/badge/Bash-5.x-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Python](https://img.shields.io/badge/Python-3.14-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://www.python.org/)
[![Terraform](https://img.shields.io/badge/Terraform-1.15-844FBA?style=for-the-badge&logo=terraform&logoColor=white)](https://www.terraform.io/)
[![MIT License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](../LICENSE)

このリポジトリは、自動セットアップスクリプト付きの公開用 dotfiles を含んでいます。これらの設定ファイルは、macOS、Linux (Ubuntu, Linux Mint)、Windows 間で一貫した開発環境を維持するのに役立ちます。

## 🚀 クイックスタート

### macOS / Linux (Ubuntu, Linux Mint)

```bash
# 最小限のインストール（dotfiles のみ）
curl -fsSL https://install.tqer39.dev | bash

# フルインストール（dotfiles + 開発環境）
curl -fsSL https://install.tqer39.dev | bash -s -- --full

# サーバー向けフルインストール（下記の --server の制限を参照）
curl -fsSL https://install.tqer39.dev | bash -s -- --full --server

# CI 環境向け（非対話型、一部のインストールエラー時は続行）
curl -fsSL https://install.tqer39.dev | bash -s -- --full --ci

# 実行せずに変更内容をプレビュー
curl -fsSL https://install.tqer39.dev | bash -s -- --dry-run
```

### Windows (PowerShell)

```powershell
# 最小限のインストール
irm https://install.tqer39.dev/windows | iex

# クローン先に移動してフルインストール
Set-Location "$env:USERPROFILE\.dotfiles"
.\install.ps1 -Full

# 実行ポリシーでブロックされる場合は次を使用:
powershell -ExecutionPolicy Bypass -File .\install.ps1 -Full

# 変更内容をプレビュー
.\install.ps1 -DryRun
```

Windows でシンボリックリンクを作成するには、開発者モードまたは管理者権限が必要です。
`DOTFILES_DIR` を指定した場合は、そのディレクトリに移動してください。

## ✨ 特徴

- **冪等性**: 複数回実行しても安全 - 既存の正しいシンボリックリンクはスキップ
- **クロスプラットフォーム**: macOS、Linux (Ubuntu, Linux Mint)、Windows をサポート
- **クローン先**: リポジトリは `~/.dotfiles` にクローンされます
- **バックアップ**: 既存のファイルは `~/.dotfiles_backup/` にバックアップ
- **モジュラー**: 最小限（dotfiles のみ）またはフル（開発ツール付き）を選択可能

## ⚙️ コマンドラインオプション

次の表は Unix の `install.sh` 用です。Windows のオプションは
クローン先で `./install.ps1 -Help` を実行して確認できます。

| オプション | 説明 |
| --------- | ---- |
| `--full` | フルセットアップ（dotfiles + 開発環境） |
| `--minimal` | 最小限のセットアップ（dotfiles のみ、デフォルト） |
| `--skip-packages` | パッケージマネージャのインストールをスキップ |
| `--skip-languages` | 言語ランタイムのインストールをスキップ |
| `--dry-run` | 実行せずに変更内容を表示 |
| `-v, --verbose` | 詳細なログを出力 |
| `--uninstall` | dotfiles のシンボリックリンクを削除 |
| `--work` | 会社モード（個人用パッケージをスキップし、業務用パッケージを追加） |
| `--ci` | CI モード（非対話型） |
| `--server` | Linux の個別 GUI 導入、日本語フォント・入力環境、Obsidian、VS Code 拡張機能の導入をスキップ |
| `--os <value>` | OS 検出を上書き（macos, ubuntu, mint, linux, windows） |
| `--doctor` | 環境ヘルスチェックを実行 |

`--server` は Homebrew の Brewfile をフィルターしません。
macOS の GUI cask など、Brewfile 内のパッケージは引き続き導入対象です。
`--ci` もすべてのエラーを無視するわけではなく、既存クローンの `git pull` をスキップします。

## 🔄 日常操作（macOS / Linux）

リンクの管理は、インストールに使ったクローンから実行します。

```bash
cd ~/.dotfiles

# リンク先と状態を確認（リポジトリの更新なし）
./scripts/dotfiles.sh status

# 依存ツールとリンクを診断（問題がある場合は終了コード 1）
./scripts/dotfiles.sh doctor

# 現在のクローンの内容でリンクを作成・修復
./scripts/dotfiles.sh install

# 削除対象をプレビュー
DRY_RUN=true ./scripts/dotfiles.sh uninstall

# このクローンを指すリンクを削除し、利用可能な最新バックアップを復元
./scripts/dotfiles.sh uninstall
```

`status` の `OK` は正しいリンク、`WRONG` は別のリンク先、
`EXISTS` は通常ファイル、`NONE` は未導入、`MISSING` はリンク元の欠落です。
会社モードの Claude Code 設定を扱う場合は、
`DOTFILES_MODE=work ./scripts/dotfiles.sh install` のように指定します。
`uninstall` はパッケージやクローン自体を削除しません。

リポジトリの更新も含めて再セットアップする場合は、クイックスタートの
`install.sh` を再実行します。既存クローンは `git pull --ff-only` で更新され、
未コミット変更は未追跡ファイルも含めて一時退避・復元されます。
復元が競合すると作業ツリーは更新後の状態になり、ローカル変更は stash に残ります。
表示された SHA と `git stash list` を確認してから手動で復元してください。

開発用のセットアップ・lint は [ローカル開発環境](local-dev.ja.md)、
構成は [アーキテクチャ](architecture.ja.md)、
OS ごとの導入経路は [プラットフォーム互換性](platform-compatibility.ja.md)を参照してください。

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

主な dotfiles を以下に示します。リンク対象の全一覧と OS 条件は
[config/platform-files.conf](../config/platform-files.conf) を参照してください。
Unix では加えて `scripts/dotfiles.sh` が Claude Code のモード別設定と
共有スキルのリンクを管理します。

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

| ファイル | インストール先 | 説明 | プラットフォーム |
| --- | --- | --- | --- |
| `.config/mise/config.toml` | `~/.config/mise/config.toml` | mise バージョン管理（Node.js 等） | 🍎 🐧 🪟 |

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
- **Ubuntu/Mint**: `config/packages/apt-packages.txt` の APT パッケージ
- **Windows**: Scoop（CLI ツール）+ winget（GUI アプリ）

### 🛠️ 開発ツール

- **anyenv**: 言語ランタイム管理（pyenv、nodenv など）
- **mise**: mise 設定ファイルで定義されたツール（Node.js など）
- **Herdr**: 本体と Claude Code 連携
- **VS Code 拡張機能**: `src/.vscode/extensions.json` から

## 📋 必要条件

- **Git**: リポジトリのクローンに必要
- **curl** (Unix) または **PowerShell 5.1+** (Windows)

## 📄 ライセンス

このプロジェクトは MIT ライセンスの下で公開されています。詳細は [LICENSE](../LICENSE) ファイルを参照してください。
