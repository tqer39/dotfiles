# ルール管理

dotfiles リポジトリ内で RuleSync を使い、日本語の正本を参照する入口を生成します。

| ファイル | 役割 |
| --- | --- |
| `docs/rules/keyboard-input.md` | キー入力ルールの正本 |
| `docs/rules/documentation.md` | Markdown の言語・命名規約の正本 |
| `docs/AGENTS.md` | 既存のリポジトリ共通ガイダンス |
| `.rulesync/rules/overview.md` | 正本を読むよう指示する生成元 |
| `.rulesync/skills/<名前>/SKILL.md` | 共通スキルの正本 |
| `rulesync.jsonc` | リポジトリ内の生成設定 |
| `AGENTS.md` | RuleSync が生成する参照用の入口 |
| `CLAUDE.md` | `AGENTS.md` への既存リンク |
| `.claude/skills/<名前>/SKILL.md` | Claude Code 向けのスキル生成物 |
| `.codex/skills/<名前>/SKILL.md` | Codex 向けのスキル生成物 |

ルール本文は正本だけを編集します。本文を生成物へ複製しません。
参照先を追加・変更するときは `.rulesync/rules/overview.md` を編集して再生成します。

RuleSync 8.24.0 をリポジトリの `mise.toml` で固定しています。
macOS・Linux・Windows 共通の開発ツールとして mise で管理します。
リポジトリのルートで実行してください。

```bash
mise install npm:rulesync
mise run rules-generate
mise run rules-check
mise run lint
git diff --check
```

`global: false` とし、対象ごとに生成機能を指定します。
`codexcli` は `rules` と `skills`、`claudecode` は `skills` だけを生成します。
生成対象はこのリポジトリの `AGENTS.md` と両ツール向けのスキルです。
`--global` を付けず、ホームディレクトリの設定には出力しません。
`CLAUDE.md` はリンクなので、同じ入口を Claude Code も読みます。
Claude Code 向けの `rules` 生成を有効にせず、既存のリンクを維持します。

生成物も Git で管理します。再生成後に差分を確認し、正本へのリンクが有効であることと、
再度生成しても内容が変わらないことを確認してください。
`mise run rules-check` はファイルを書き換えずに生成漏れ・差分を検出します。
`mise run lint` にも組み込んでいるため、ローカルと CI の両方で検証します。
`delete: false` なので既存の未管理スキルは削除しません。
スキルの削除・改名時は、対応する両ツールの旧生成物も差分を確認して削除してください。
この設定では `rules-check` だけで旧生成物の残存は検出できません。

## 作業手順のスキル管理

常時適用するルールはこのディレクトリ、依頼に応じて使う手順は `.rulesync/skills/` に置きます。
旧 `.claude/commands/` の3つの手順は、同名のスキルへ移行しました。

| スキル | 用途 |
| --- | --- |
| `adr` | アーキテクチャ決定記録の作成 |
| `rebase-main` | 作業ブランチのリベースと競合解消 |
| `translate-docs` | Markdown の日本語化と正本への統合 |

各スキルは `name` と `description` を持つ `SKILL.md` で定義し、対象は依頼文から読み取ります。
共通の本文から RuleSync が `.claude/skills/` と `.codex/skills/` へ生成します。
本文の修正は `.rulesync/skills/` だけに反映し、再生成してください。
生成仕様は [RuleSync の設定](https://rulesync.dyoshikawa.com/guide/configuration) と
固定バージョンの実装に合わせています。

今回の移行対象は上記3つです。既存の `markdown-lint`、`run-dotfiles`、`sync-install-docs`、
`sync-packages` と `src/` 配下の `ghostty-config` は従来の場所に残しています。
これらはまだ RuleSync の生成物ではありません。

既存の Unix 用 `scripts/dotfiles.sh install` は、これらも検出して `~/.codex/skills/` にリンクします。
Windows の `install.ps1` にはこの共有スキルのリンク処理はありません。
ここでの移行はリポジトリの定義変更であり、ホームの設定へ自動で反映するものではありません。
