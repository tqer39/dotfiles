# AGENTS.md

[生成されたルールの入口](../AGENTS.md)

Codex と Claude Code に共通するリポジトリのガイダンスです。
この文書が共通ガイダンスの正本です。ルートの `AGENTS.md` は RuleSync が生成する参照用の入口です。
`CLAUDE.md` はルートの `AGENTS.md` への symlink です。
主担当は Claude Code です。すべての節を両方のツールに適用します。

## リポジトリの目的

dotfiles リポジトリ。symlink でファイルをインストール。
macOS, Linux (Ubuntu, Linux Mint), Windows をサポート。

## コマンド

```bash
# Lint
mise run lint

# Dotfiles
./scripts/dotfiles.sh status
./scripts/dotfiles.sh install
./scripts/dotfiles.sh uninstall
./scripts/dotfiles.sh doctor

# 独立した並行作業（新しいブランチと worktree を作成）
mise run wt-new <name>
mise run wt-list

# Terraform
mise run tf plan
mise run tf -chdir=prod/bootstrap apply
```

## 主要な設計方針

- **冪等性**: 再実行しても常に安全
- **バックアップ**: 既存ファイルは `~/.dotfiles_backup/` に移動
- **プラットフォームフィルタリング**: `config/platform-files.conf` で制御
- **サーバーモード**: `--server` ではデスクトップ/GUI アプリをインストールしない

## コーディングガイドライン

- シェル: `#!/usr/bin/env bash` と `set -euo pipefail` を使用
- 変数/関数名: snake_case
- 算術演算: `count=$((count + 1))` (`((count++))` ではない)

## ファイル制限

- `.vscode/settings.json` を**作成しない** - VS Code の設定はこのリポジトリで管理しない

## 共通の作業手順

- 編集前に、目的・対象のファイルや動作・制約・完了条件を整理します。
  複雑な変更では、期待する具体的な動作や例も明確にします。
  適用される指示と関連コードを先に読みます。
- 仕様を左右する不明点は、依存する変更の実装前に確認します。
  大きく曖昧な変更では、Plan モードで方針を合わせます。
  合意済みの計画は同じ承認を求め直さず、実装から検証まで進めます。
- 無関係なユーザーの変更を保持します。別目的の作業は別スレッドに分け、
  同時に編集するときは `mise run wt-new <name>` を使います。
  worktree 間の変更を統合する際も含め、ファイルの担当範囲を決めて重複を避けます。
- 定型作業には適用可能な既存スキルを使います。失敗が繰り返されたら、原因に応じて
  回帰テスト・スクリプト・適用範囲を絞った短い指示に反映します。
- 再利用する LLM 向けの作業手順は `.rulesync/skills/<名前>/SKILL.md` を正本として管理します。
  `.claude/commands/` に新しい定義を追加せず、スキルの見出し・説明・手順を日本語で記載します。
  識別子の `name` は既存スキルと同じ英小文字・数字・ハイフンを使います。
  `mise run rules-generate` で Claude Code・Codex 向けに生成し、生成物は直接編集しません。
  移行範囲と既存スキルの扱いは [ルール管理](rules/README.md) を参照してください。

依頼テンプレートと手戻りの記録方法は、[Codex の運用ガイド](codex.md#日常の運用)を参照してください。

## 完了条件と検証（両ツール共通）

- 依頼された動作と制約を満たすことを確認します。不具合修正では、可能な範囲で
  元の問題を再現し、修正後に解消したことを確かめます。
  意味のある動作変更には回帰テストを追加します。
- `mise run lint` を実行し、変更内容に合う検証をします。最終差分をレビューし、
  回帰・要件漏れ・無関係な変更がないか、自動修正された差分も含めて確認します。
- 変更点、実際に実行したコマンドや確認、結果、未確認事項とその理由を報告します。
  未実行の検証を成功扱いにせず、必須の検証が失敗した状態を完了としません。
- **cspell の検査対象を確認します。** 個別の検証で `--files` と `--gitignore` を
  併用すると、0 ファイルの検査で成功した事例があります。
  `pnpm exec cspell lint --no-progress <file>` を使い、
  `Files checked:` が期待する件数か確認します。
- `mise run lint` は各フックの出力だけでなく、最後の結果（✔️ または 🥊）まで確認します。
- 検証用のサンドボックスを作る前に `git fetch` し、意図したリビジョンと変更内容が
  含まれることを確認します。古い版を検証して誤った結論を出した事例があります。

## 実装の担当

Claude Code が実装から検証、PR 作成まで直接行います。
Codex への委譲は前提にしません。Codex で作業する場合も、同じ手順と完了条件に従います。

## コンテキスト最適化

### 優先ディレクトリ（最初に読む）

- `scripts/` - コアシェルスクリプト
- `config/` - プラットフォーム設定
- `src/` - Dotfile ソース

### 低優先度（遅延読み込み）

- `infra/terraform/` - インフラタスクの場合のみ
- `docs/adr/` - アーキテクチャ決定時のみ

## ドキュメント

- [docs/local-dev.md](local-dev.md) - 開発環境セットアップ
- [docs/architecture.md](architecture.md) - アーキテクチャ詳細
- [docs/codex.md](codex.md) - Codex の設定・運用・依頼テンプレート
