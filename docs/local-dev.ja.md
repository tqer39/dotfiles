# ローカル開発環境セットアップ

[🇺🇸 English](./local-dev.md)

このリポジトリの開発環境セットアップ手順です。

## 前提条件

- macOS または Linux
- Git

## セットアップ

### 1. 開発ツールのインストール

```bash
make bootstrap
```

これにより以下がインストールされます:

- Homebrew
- mise (バージョン管理)
- just (タスクランナー)
- direnv (環境変数管理)
- prek (pre-commit フック)
- aws-vault
- cf-vault

### 2. 開発環境の設定

シェルを再起動後:

```bash
just setup
```

## Terraform の実行

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
# Terraform plan
just tf plan

# 特定の環境を指定
just tf -chdir=prod/bootstrap init
just tf -chdir=prod/dns plan
```

### Bootstrap (初回のみ)

GitHub Actions の OIDC 認証用 IAM Role は初回のみローカルから作成が必要です:

```bash
just tf -chdir=prod/bootstrap init
just tf -chdir=prod/bootstrap apply
```

## よく使うコマンド

| コマンド     | 説明                     |
| ------------ | ------------------------ |
| `just help`  | 利用可能なコマンド一覧   |
| `just setup` | 開発環境のセットアップ   |
| `just lint`  | Linter の実行            |
| `just tf`    | Terraform の実行         |
