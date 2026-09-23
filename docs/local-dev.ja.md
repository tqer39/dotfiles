# ローカル開発環境セットアップ

[🇺🇸 English](./local-dev.md)

このリポジトリの開発環境セットアップ手順です。

## 前提条件

- macOS または Linux
- Git、make
- 以下のコマンドはリポジトリのルートで実行

## セットアップ

### 1. 開発ツールのインストール

```bash
make bootstrap
```

Homebrew を導入し、ルートの [Brewfile](../Brewfile) のパッケージをインストールします。
`install.sh --full` が使う `config/packages/Brewfile` とは別です。

主な開発ツール:

- Homebrew
- mise (バージョン管理・タスクランナー)
- Git
- Herdr
- direnv (環境変数管理)
- lefthook (git フック)
- aws-vault
- cf-vault

### 2. 開発環境の設定

シェルを再起動後、リポジトリの設定を信頼してセットアップします:

```bash
mise trust
mise run setup
```

`mise run setup` は [mise.toml](../mise.toml) のツール導入、
`pnpm install --frozen-lockfile`、`lefthook install` の順に実行します。

タスクの定義は [mise.toml](../mise.toml) の `[tasks]` に集約しています。
`mise run <task>` を使用してください（`mise install` などの組み込みコマンドと区別します）。

## 日常の開発操作

```bash
# コミット前の全ファイル検証（自動修正を含む）
mise run lint

# Markdown のフックのみ実行
mise run lint-hook markdownlint

# 対象ファイルのスペルチェック
pnpm exec cspell lint --no-progress docs/README.ja.md

# 独立した作業用のブランチと worktree を作成
mise run wt-new docs-fix
mise run wt-list
```

`mise run lint` の最終サマリーを確認し、自動修正も `git diff` と
`git diff --cached` でレビューします。cspell の対象指定では `--gitignore` を併用せず、
`Files checked:` が対象数と一致することを確認してください。
`mise run wt-new` は `../dotfiles-worktrees/` に日付・乱数付きの worktree を作成します。

`mise run status` / `mise run install` / `mise run update` はそれぞれ
`mise status` / `mise install` / `mise upgrade` を実行します。
dotfiles のリンク管理には [日常操作](README.ja.md#-日常操作macos--linux)の
`./scripts/dotfiles.sh` を使用してください。

## Terraform の実行

以下はインフラを扱う場合だけ必要です。ドキュメント編集や lint には不要です。

### 認証情報の設定

Terraform を実行するには以下のプロファイルが必要です:

```bash
# AWS 認証情報を追加
aws-vault add portfolio

# Cloudflare API Token を追加
cf-vault add dotfiles
```

### コマンド

```bash
# 本番 DNS 構成の plan
mise run tf -chdir=prod/dns plan

# 特定の環境を指定
mise run tf -chdir=prod/bootstrap init
mise run tf -chdir=prod/dns plan
```

`mise run tf` は `cf-vault exec dotfiles -- aws-vault exec portfolio -- terraform` を呼び出します。
`-chdir=prod/dns` は `infra/terraform/envs/prod/dns` に展開されます。
`-chdir` を省略すると現在のディレクトリで実行されるため、対象環境を明示してください。

### Bootstrap (初回のみ)

GitHub Actions の OIDC 認証用 IAM Role は初回のみローカルから作成が必要です:

```bash
mise run tf -chdir=prod/bootstrap init
mise run tf -chdir=prod/bootstrap apply
```

## よく使うコマンド

| コマンド         | 説明                   |
| ---------------- | ---------------------- |
| `mise run help`  | 利用可能なコマンド一覧 |
| `mise run setup` | 開発環境のセットアップ |
| `mise run lint`  | Linter の実行          |
| `mise run tf`    | Terraform の実行       |
