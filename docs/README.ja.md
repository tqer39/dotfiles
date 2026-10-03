# ⚡ Dotfiles

[🇺🇸 English](../README.md)

[![CI](https://img.shields.io/github/actions/workflow/status/tqer39/dotfiles/ci.yml?branch=main&style=for-the-badge&logo=github&label=CI)](https://github.com/tqer39/dotfiles/actions/workflows/ci.yml)

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

### インストールの進行状況と所要時間

Homebrew のパッケージは1件ずつ処理し、詳細出力をリアルタイムに表示します。
開始時に `[START]`、終了時に `[OK]` または `[FAILED]` と所要秒数を出力します。
処理中は30秒ごとに `[RUNNING]` と経過秒数を表示します。
最後の `[TIME]` 一覧は所要時間の長い順です。
時間にはインストール済みかの確認、ダウンロード、依存パッケージの導入も含みます。

ログは `~/.dotfiles_logs/homebrew-*` に保存され、開始時に保存先を表示します。
`DOTFILES_INSTALL_LOG_DIR` 環境変数で保存先を変更できます。
失敗した場合もログを残し、通常モードではエラー終了します。
この計測の対象は Homebrew の formula、cask、Mac App Store アプリです。

macOS の `cf-vault` は mise から公式バイナリを取得し、Go のソースビルドを省きます。
バージョンと SHA-256 は mise 設定に固定しています。Linux は従来の Homebrew 方式です。
macOS では言語ランタイムと同じ mise の導入工程でインストールするため、
`--skip-languages` を指定した場合は `cf-vault` の導入もスキップします。

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

### ベースブランチの更新と設定の反映

競合の原因、修正前後の違い、開発から反映までの図は、
[PR #588 の原因と対策](dotfiles-update-safety.ja.md)を参照してください。

`~/.dotfiles` の `main` は環境反映用とし、開発は専用ブランチの worktree で行います。
ベースブランチに直接コミット・プッシュせず、変更は PR のマージ後に取り込みます。
ホームの設定ファイルが `~/.dotfiles/src/` へのリンクの場合、
ホーム側を編集してもベースブランチに差分が生じます。開発時は worktree 内の `src/` を編集してください。

通常の `git pull` でも自動 stash の復元による競合を防ぐため、初回に次を設定します。
この設定は dotfiles リポジトリと共有する worktree に適用されます。

```bash
git -C ~/.dotfiles config --local pull.ff only
git -C ~/.dotfiles config --local pull.rebase false
git -C ~/.dotfiles config --local pull.autoStash false
git -C ~/.dotfiles config --local rebase.autoStash false
git -C ~/.dotfiles config --local merge.autoStash false
```

日常の更新では、まず `git status --short` が空であることを確認します。

```bash
cd ~/.dotfiles
git status --short
git pull --ff-only --no-rebase --no-autostash &&
  ./scripts/dotfiles.sh status &&
  ./scripts/dotfiles.sh install
```

`pull` に失敗した場合は、設定を反映せず原因を確認してください。
Karabiner などの設定が `EXISTS` になっている場合、通常ファイルに置き換わっているため、
`pull` だけでは反映されません。`install` は既存ファイルをバックアップしてリンクを修復します。
アプリによる設定の書き換えで、リンク切れや `src/` の差分が生じることもあります。更新時に状態を確認します。

リポジトリの更新も含めて再セットアップする場合は、クイックスタートの
`install.sh` を再実行します。Windows の `install.ps1` も同じ更新方針です。
未コミット変更・未追跡ファイル・未解決の競合がある場合は、ファイルと stash を変更せず停止します。
作業ツリーがクリーンなら `git pull --ff-only --no-rebase --no-autostash` で更新します。
`--dry-run` / `--ci`（Windows は `-DryRun` / `-CI`）では従来どおり更新をスキップします。

既に競合している場合は、更新前に変更ファイル・未追跡ファイル・インデックスをバックアップし、
別の worktree へ保全してからベースブランチをクリーンにします。
退避済みの stash は `git stash list` で確認し、必要な変更を開発 worktree で復元・整理してください。
環境反映用の `main` に自動で戻さないでください。

[Git の公式説明](https://git-scm.com/docs/git-pull#Documentation/git-pull.txt---autostash)でも、
更新成功後の自動 stash 復元による競合について説明されています。

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
