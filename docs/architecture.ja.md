# アーキテクチャ

[🇺🇸 English](./architecture.md)

## エントリーポイント

- `install.sh` - Unix (macOS/Linux) エントリーポイント、curl からパイプ可能
- `install.ps1` - Windows PowerShell エントリーポイント

## スクリプトライブラリ (`scripts/lib/`)

すべてのスクリプトから読み込まれる共通ユーティリティ:

- `log.sh` - カラー付きログ関数 (`log_info`, `log_success`, `log_error` など)
- `utils.sh` - OS 検出 (`detect_os`)、パス展開、コマンドチェック
- `symlink.sh` - バックアップ機能付き冪等シンボリックリンク作成

## 設定

- `config/platform-files.conf` - SOURCE:DESTINATION:PLATFORMS マッピングを定義
  - フォーマット: `.zshrc:~/.zshrc:macos,linux`
  - プラットフォーム: `all` / `macos` / `linux` / `ubuntu` / `windows`
- `config/packages/Brewfile` - Homebrew パッケージ
- `config/packages/apt-packages.txt` - Ubuntu 用 APT パッケージ

## インストーラー (`scripts/installers/`)

`--full` インストール時に呼び出されるモジュラーインストーラー:

- `homebrew.sh` - Homebrew と Brewfile パッケージ
- `apt.sh` - APT パッケージ (Ubuntu のみ)
- `anyenv.sh` - 言語ランタイムマネージャー
- `vscode.sh` - `src/.vscode/extensions.json` の VS Code 拡張機能

## Terraform (`infra/terraform/`)

- `modules/` - 再利用可能なモジュール
  - `cloudflare/` - CloudFlare DNS 設定
  - `deploy-role/` - GitHub Actions OIDC 用 IAM Role
- `envs/prod/` - 本番環境
  - `bootstrap/` - IAM Role (ローカル実行必須)
  - `dns/` - CloudFlare DNS レコード
