# Codex の品質優先セットアップ

[🇺🇸 English](codex.md)

## 管理するファイル

dotfiles のインストーラーは macOS・Linux・Windows で次のファイルをリンクします。

- `src/.codex/AGENTS.md`: 日本語での応答、実装、検証、最終レビューに関する共通指示
- `src/.codex/quality.config.toml`: GPT-6 Astra、通常時と Plan モードの推論強度
  `max`、ライブ検索の設定

既存のインストール手順で `./scripts/dotfiles.sh install` を実行します。
リンク先にある既存ファイルは `~/.dotfiles_backup/` に退避されます。
認証情報、MCP 設定、プロジェクトの信頼設定、基本設定の `~/.codex/config.toml` は
端末ごとに管理します。

## 使い方

Codex CLI 0.153.4 で検証したプロファイルです。
`gpt-6-astra` と推論強度 `max` を利用できるアカウントが必要です。

```bash
codex --profile quality
codex exec --profile quality "現在の変更をレビューしてください"
```

プロファイルを指定せずに同じ設定を使う場合は、`quality.config.toml` の先頭にある
4 項目を `~/.codex/config.toml` に統合します。
TOML のテーブルより前に記載し、ほかの設定は保持してください。
デスクトップアプリと IDE 拡張も基本設定を共有します。新しい会話でモデルの選択を確認してください。
プロジェクト設定や CLI の明示指定は、これらの既定値より優先されます。

Max は推論の深さを優先するため、応答時間や利用量の増加に注意してください。
並列のサブエージェントを活用できる作業では、必要に応じて Ultra を明示的に選択します。
どちらも、すべての課題で品質の向上を保証する設定ではありません。
コンテキスト上限と圧縮のしきい値はモデルの既定値を使用します。

## 動作確認

```bash
codex --strict-config doctor --summary
```

`codex --profile quality` で起動し、`/status` で実行時の設定を確認します。
表示されたモデル、設定の読み込み、認証、接続の結果を確認します。
MCP の警告が出たら、実行ファイルの有無を確認してください。
古いサーバーは端末の設定で無効化するか、インストールを修復してから有効にします。
出力の品質は、代表的な作業とそのテストで評価してください。

## 公式資料

- [モデルと推論強度](https://learn.chatgpt.com/docs/models)
- [設定プロファイル](https://learn.chatgpt.com/docs/config-file/config-advanced#profiles)
- [セットアップと検証の指針](https://learn.chatgpt.com/guides/best-practices)
