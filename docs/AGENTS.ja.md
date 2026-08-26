# AGENTS.md

[🇺🇸 English](../AGENTS.md)

Claude Code 向けのガイダンス。

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

## 実装の委譲

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
if herdr wait output <pane_id> --match "Update now" --source visible --timeout 2000 >/dev/null 2>&1; then
  echo "更新プロンプトが出ている。手動で対処すること"
fi

# 5. Codex は inbox を自動で見ないので促す。/agmsg は認識しないため自然言語で送る
herdr pane run <pane_id> "agmsg の inbox を確認して、届いているタスクを実行してください。"

# 6. 完了までブロックする(ポーリング不要)
herdr wait agent-status <pane_id> --status done --timeout 600000
```

注意点:

- **Codex は inbox を自動で見ない。** 送信のたびに手順4で促す必要がある。
  `/agmsg` は Claude Code の記法で Codex は認識しない
- **待機には `herdr wait` を使う。** `agent read` のポーリングは不要。
  `herdr wait agent-status <pane_id> --status done --timeout <ms>` で完了までブロックできる。
  **完了後の status は `done` であって `idle` ではない。**
  `idle` は何も作業していない待機状態を指すため、完了検知には使えない。
  現在値が条件を満たしていれば即座に exit 0、タイムアウト時は exit 1 になる
- **`herdr wait output <pane_id> --match <text> --source visible` で特定の出力を待てる。**
  更新プロンプトの検出に使う。**`--source visible` は必須。**
  既定の `recent` はスクロールバックを検索する。
  そのため、過去に流れた同じ文字列を拾い、誤検知する。`--regex` で正規表現も可
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
- **agmsg のメッセージ本文はシェル展開される。** `$` やバッククォートを含む
  報告は壊れる。実際に `$PATH` が展開されて数千文字の PATH が報告に混入した
- **Codex は Monitor を持たない**ため `spawn.sh` の ready 待ちがスキップされる。
  受信確認は `history.sh` / `inbox.sh` で行う
- カスタム `--terminal` で spawn した場合 `despawn.sh --force` は placement record が
  無く使えない。ペインを再利用するか `herdr pane run <pane_id> codex` で起動し直す
- 委譲には上記の手間がかかる。小さな変更では直接実装したほうが速い場合もある

検証時の注意:

- **Codex の報告を鵜呑みにしない。** 差分を読むだけでなく実際に実行して確認する
- **cspell の検証で `--files` と `--gitignore` を併用しない。** 0 ファイルしか
  検査されず exit 0 になる。`pnpm exec cspell lint --no-progress <file>` を使い
  出力の `Files checked:` が期待どおりかを必ず確認する。
  この見落としで CI を 1 日壊した
- `just lint` の結果は成功マーク(✔️)か失敗マーク(🥊)かまで見る
- 検証用のサンドボックスを作るときは毎回 `git fetch` してから構築する。
  古い版を検証して誤った結論を出した事例がある

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
