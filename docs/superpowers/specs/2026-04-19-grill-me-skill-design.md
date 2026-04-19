# grill-me skill 導入設計

- 日付: 2026-04-19
- トピック: grill-me-skill
- 対象リポジトリ: `tqer39/claude-code-marketplace` + `tqer39/.dotfiles`

## 背景

mattpocock/skills の `grill-me` skill は、計画や設計について決定木の各分岐を 1 問ずつ徹底インタビューして共通理解に至らせる Socratic 型 skill。要件未確定のまま実装に突入する事故を防ぐ目的で導入する。upstream は MIT License。

再現性を確保するため、自身の marketplace `tqer39/claude-code-marketplace` に新規 plugin として登録する。
そのうえで `tqer39/.dotfiles` の `installed_plugins.personal.json` で管理する。
既存の「1 plugin = 1 skill」構成に揃える。

## 目的と成功基準

- `grill me` や「計画を stress-test してほしい」等の発話で skill が自動起動する
- `./scripts/dotfiles.sh install` を clean 環境で実行したとき、grill-me が冪等に反映される
- MIT License の帰属要件 (著作権表示 + ライセンス全文の同梱) を満たす

## アーキテクチャ

既存 plugin (`security`, `agent-config` 等) と同型の「1 plugin = 1 skill」構成。2 リポジトリ横断で変更するため 2 段階ワークフロー:

1. marketplace 側に PR を作成してマージ
2. dotfiles 側で `installed_plugins.personal.json` を更新

```text
upstream (mattpocock/skills, MIT)
        │ 逐語コピー + LICENSE 同梱
        ▼
marketplace/plugins/grill-me/
        │ git push → PR merge
        ▼
dotfiles/installed_plugins.personal.json に記録
        │ ./scripts/dotfiles.sh install で symlink 反映
        ▼
~/.claude/plugins/ にインストール → Skill として利用可能
```

## 変更内容

### A. `tqer39/claude-code-marketplace`

ローカル clone: `/Users/takeruooyama/workspace/tqer39/claude-code-marketplace/`
ブランチ: `feat/add-grill-me-plugin`

- `plugins/grill-me/.claude-plugin/plugin.json` (新規): `name`, `description`, `version: 0.1.0`
- `plugins/grill-me/skills/grill-me/SKILL.md` (新規): upstream 逐語コピー + 末尾に出典コメント
- `plugins/grill-me/LICENSE` (新規): MIT License 全文 (Copyright (c) 2026 Matt Pocock)
- `.claude-plugin/marketplace.json` (編集): `plugins` 配列末尾に grill-me エントリ追加
- `README.md` (編集): plugin 一覧に `### grill-me` セクション追加
- `docs/README.ja.md` (編集): 日本語版に同様の節追加

#### plugin.json

```json
{
  "name": "grill-me",
  "description": "Socratic interviewer skill that grills you on plans/designs until shared understanding is reached",
  "version": "0.1.0"
}
```

#### SKILL.md

upstream `https://github.com/mattpocock/skills/blob/main/grill-me/SKILL.md` を逐語コピー。frontmatter の `description` は英語のまま (既存 skill に合わせる)。末尾に出典コメント:

```html
<!-- Source: https://github.com/mattpocock/skills/blob/main/grill-me/SKILL.md (MIT License, Copyright (c) 2026 Matt Pocock) -->
```

#### LICENSE

upstream の LICENSE ファイルを逐語コピー (MIT + 著作権表示)。

#### marketplace.json 追加エントリ

```json
{
  "name": "grill-me",
  "source": "./plugins/grill-me",
  "description": "Socratic interviewer skill that grills you on plans/designs until shared understanding is reached"
}
```

### B. `tqer39/.dotfiles`

Marketplace PR マージ **後** に実施。

- `src/.claude/plugins/installed_plugins.personal.json` (編集): `grill-me@tqer39-plugins` エントリ追加

```json
"grill-me@tqer39-plugins": [
  {
    "scope": "user",
    "version": "0.1.0",
    "lastUpdated": "2026-04-19T00:00:00.000Z"
  }
]
```

## 検証手順

1. **Marketplace PR 前**
   - `just lint` がパス
   - `.claude-plugin/marketplace.json` が妥当な JSON
   - `plugins/grill-me/` の構造が既存 plugin と同型 (`plugin.json`, `skills/<name>/SKILL.md`, `LICENSE`)

2. **Marketplace PR マージ後**
   - `claude plugin install grill-me@tqer39-plugins` で手動インストール
   - 任意セッションで「grill me してほしい」と発話 → skill が起動することを確認

3. **Dotfiles コミット後**
   - clean な `~/.claude/plugins/` で `./scripts/dotfiles.sh install` を実行し、grill-me が反映されること

## スコープ外

- Jekudy/grillme-skill (代替案) の採用
- `~/.claude/skills/` 直配置 (同期不能のため)
- `npx skills@latest add` 等の外部 CLI 経由インストール
- upstream 更新の自動追従 (手動 bump で運用)

## 依存関係と前提

- marketplace リポジトリへの push 権限 (tqer39 所有)
- upstream `mattpocock/skills` の grill-me SKILL.md が現存すること
- 既存 plugin installer (`dotfiles.sh`) が `installed_plugins.personal.json` を読み取って反映する挙動

## ライセンス帰属

upstream `mattpocock/skills` は MIT License。`plugins/grill-me/LICENSE` にライセンス全文と著作権表示を同梱し、SKILL.md 末尾にも出典コメントを残すことで、MIT の帰属要件を二重に満たす。
