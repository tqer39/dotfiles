# ルール管理

dotfiles リポジトリ内で RuleSync を使い、日本語の正本を参照する入口を生成します。

| ファイル | 役割 |
| --- | --- |
| `docs/rules/keyboard-input.md` | キー入力ルールの正本 |
| `docs/rules/documentation.md` | Markdown の言語・命名規約の正本 |
| `docs/AGENTS.md` | 既存のリポジトリ共通ガイダンス |
| `.rulesync/rules/overview.md` | 正本を読むよう指示する生成元 |
| `rulesync.jsonc` | リポジトリ内の生成設定 |
| `AGENTS.md` | RuleSync が生成する参照用の入口 |
| `CLAUDE.md` | `AGENTS.md` への既存リンク |

ルール本文は正本だけを編集します。本文を生成物へ複製しません。
参照先を追加・変更するときは `.rulesync/rules/overview.md` を編集して再生成します。

RuleSync 8.24.0 をリポジトリの `mise.toml` で固定しています。
macOS・Linux・Windows 共通の開発ツールとして mise で管理します。
リポジトリのルートで実行してください。

```bash
mise install npm:rulesync
mise run rules-generate
mise run lint
git diff --check
```

`global: false`、`features: ["rules"]`、`targets: ["codexcli"]` を使用します。
生成対象はこのリポジトリの `AGENTS.md` です。
`--global` を付けず、ホームディレクトリの設定には出力しません。
`CLAUDE.md` はリンクなので、同じ入口を Claude Code も読みます。

生成物も Git で管理します。再生成後に差分を確認し、正本へのリンクが有効であることと、
再度生成しても内容が変わらないことを確認してください。
