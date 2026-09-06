# AGENTS.md

[🇺🇸 English](../AGENTS.md)

Codex と Claude Code に共通するリポジトリのガイダンスです。
`CLAUDE.md` はこの英語版 `AGENTS.md` への symlink です。
**「実装の委譲（Claude Code 専用）」を除くすべての節を、両方のツールに適用します。**

## リポジトリの目的

dotfiles リポジトリ。symlink でファイルをインストール。
macOS, Linux (Ubuntu, Linux Mint), Windows をサポート。

## コマンド

```bash
# Lint
just lint

# Dotfiles
./scripts/dotfiles.sh status
./scripts/dotfiles.sh install
./scripts/dotfiles.sh uninstall
./scripts/dotfiles.sh doctor

# Independent concurrent work (creates a new branch and worktree)
just wt-new <name>
just wt-list

# Terraform
just tf plan
just tf -chdir=prod/bootstrap apply
```

## 主要な設計方針

- **冪等性**: 再実行しても常に安全
- **バックアップ**: 既存ファイルは `~/.dotfiles_backup/` に移動
- **プラットフォームフィルタリング**: `config/platform-files.conf` で制御
- **サーバーモード**: `--server` ではデスクトップ/GUI アプリをインストールしない

## コーディングガイドライン

- Shell: `#!/usr/bin/env bash` with `set -euo pipefail`
- 変数/関数名: snake_case
- 算術演算: `count=$((count + 1))` (`((count++))` ではない)

## ファイル制限

- `.vscode/settings.json` を**作成しない** - VS Code の設定はこのリポジトリで管理しない

## 共通の作業手順

- 編集前に、目的・対象のファイルや動作・制約・完了条件を整理します。
  複雑な変更では、期待する具体的な動作や例も明確にします。
  適用される指示と関連コードを先に読みます。
- 仕様を左右する不明点は、依存する変更の実装前に確認します。
  Codex で大きく曖昧な変更を扱う場合は、Plan モードで方針を合わせます。
  合意済みの計画は同じ承認を求め直さず、実装から検証まで進めます。
- 無関係なユーザーの変更を保持します。別目的の作業は別スレッドに分け、
  同時に編集するときは `just wt-new <name>` を使います。
  worktree 間の変更を統合する際も含め、ファイルの担当範囲を決めて重複を避けます。
- 定型作業には適用可能な既存スキルを使います。失敗が繰り返されたら、原因に応じて
  回帰テスト・スクリプト・適用範囲を絞った短い指示に反映します。

依頼テンプレートと手戻りの記録方法は、[Codex の運用ガイド](codex.ja.md#日常の運用)を参照してください。

## 完了条件と検証（両ツール共通）

- 依頼された動作と制約を満たすことを確認します。不具合修正では、可能な範囲で
  元の問題を再現し、修正後に解消したことを確かめます。
  意味のある動作変更には回帰テストを追加します。
- `just lint` を実行し、変更内容に合う検証をします。最終差分をレビューし、
  回帰・要件漏れ・無関係な変更がないか、自動修正された差分も含めて確認します。
- 変更点、実際に実行したコマンドや確認、結果、未確認事項とその理由を報告します。
  未実行の検証を成功扱いにせず、必須の検証が失敗した状態を完了としません。
- **cspell の検査対象を確認します。** 個別の検証で `--files` と `--gitignore` を
  併用すると、0 ファイルの検査で成功した事例があります。
  `pnpm exec cspell lint --no-progress <file>` を使い、
  `Files checked:` が期待する件数か確認します。
- `just lint` は各フックの出力だけでなく、最後の結果（✔️ または 🥊）まで確認します。
- 検証用のサンドボックスを作る前に `git fetch` し、意図したリビジョンと変更内容が
  含まれることを確認します。古い版を検証して誤った結論を出した事例があります。

## 実装の委譲（Claude Code 専用）

この節は Claude Code が agmsg 経由で実装を委譲する場合だけに適用します。
Codex は割り当てられた実装を直接行います。この手順は、Codex に対して
別の Codex の起動や再委譲を指示するものではありません。

実装は agmsg 経由で Codex CLI に担当させる。Claude Code 側は指示出し・レビュー・
検証・PR 作成を担当する。

手順:

```bash
# 1. dotfiles 専用の team に join (既存の family-tasks / media-server は使わない)
~/.agents/skills/agmsg/scripts/join.sh dotfiles <agent名> claude-code "$(pwd)"

# 2. Codex CLI を起動する
#    --terminal は値(テンプレート文字列)が必須。省略すると設定の既定値が使われるが、
#    既定値はエージェント名が agmsg-codex でハードコードされており、他プロジェクトの
#    Codex が動いていると agent_name_taken で失敗する。名前を明示して回避する。
~/.agents/skills/agmsg/scripts/spawn.sh codex <名前> --project "$(pwd)" \
  --terminal "herdr agent start agmsg-codex-dotfiles --split right --focus -- {cmd}"

# 3. タスクを送る
~/.agents/skills/agmsg/scripts/send.sh dotfiles <agent名> <名前> "<タスク>"

# 4. 送信前に Codex の状態を確認する
#    更新プロンプトが出ている状態で指示を送ると Enter が既定の「Update now」を
#    確定させてしまうため、先に検出する(出ていなければ exit 1 で抜ける)
if herdr wait output <pane_id> --match "Update now" --timeout 2000 >/dev/null 2>&1; then
  echo "更新プロンプトが出ている。手動で対処すること"
fi

# 5. Codex は inbox を自動で見ないので促す。/agmsg は認識しないため自然言語で送る
herdr pane run <pane_id> "agmsg の inbox を確認して、届いているタスクを実行してください。"

# 6. 完了までブロックする(ポーリング不要)
herdr wait agent-status <pane_id> --status idle --timeout 600000
```

注意点:

- **Codex は inbox を自動で見ない。** タスクの送信ごとに手順4で状態を確認し、手順5で促す。
- `/agmsg` は Claude Code の記法で Codex は認識しない
- **待機には `herdr wait` を使う。** `agent read` のポーリングは不要。
  `herdr wait agent-status <pane_id> --status idle --timeout <ms>` で完了までブロックできる。
  条件を満たしていれば即座に返り、タイムアウト時は exit 1 になる
- **`herdr wait output <pane_id> --match <text>` で特定の出力を待てる。**
  更新プロンプトの検出に使う。`--regex` で正規表現も可
- **Codex は起動時に対話的な更新プロンプトを出すことがある。**
  `1. Update now / 2. Skip / 3. Skip until next version` が表示された状態です。
  この状態で次の指示を送ると、その Enter が既定の「1. Update now」を確定させ、
  更新後に `Please restart Codex.` を出して終了する。
  起動直後は `herdr agent read <pane_id> --source visible` でプロンプトの
  有無を確認してから指示を送ること。
- **`herdr pane run` はテキストと Enter を送る。** TUI のメニュー選択には使えない。
  `2` を送っても既定の選択が確定してしまう。
  送信前に `herdr pane list` で `agent=codex` を確認し、
  ペインがシェルに戻っていたら `herdr pane run <pane_id> codex` で起動し直す
- **`herdr agent read` は既定の `--source recent` が空を返すことがある。**
  起動直後は特に。状態が読めないときは `--source visible` を使う
- シェルコマンド内の agmsg のメッセージ本文は、文字列を安全に引用する。
  `$` やバッククォートが展開されると報告が壊れる。
  実際に `$PATH` が展開されて数千文字の PATH が報告に混入した
- **Codex は Monitor を持たない**ため `spawn.sh` の ready 待ちがスキップされる。
  受信確認は `history.sh` / `inbox.sh` で行う
- カスタム `--terminal` で spawn した場合 `despawn.sh --force` は placement record が
  無く使えない。ペインを再利用するか `herdr pane run <pane_id> codex` で起動し直す
- 委譲には上記の手間がかかる。小さな変更では直接実装したほうが速い場合もある
- **Codex の報告を鵜呑みにしない。** 差分を読み、共通の完了条件と検証に従って
  必要な確認を自分でも実行する。

## コンテキスト最適化

### 優先ディレクトリ（最初に読む）

- `scripts/` - コアシェルスクリプト
- `config/` - プラットフォーム設定
- `src/` - Dotfile ソース

### 低優先度（遅延読み込み）

- `infra/terraform/` - インフラタスクの場合のみ
- `docs/adr/` - アーキテクチャ決定時のみ

## ドキュメント

- [docs/local-dev.ja.md](local-dev.ja.md) - 開発環境セットアップ
- [docs/architecture.ja.md](architecture.ja.md) - アーキテクチャ詳細
- [docs/codex.ja.md](codex.ja.md) - Codex の設定・運用・依頼テンプレート
