# grill-me skill 導入 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** mattpocock/skills の `grill-me` skill を `tqer39/claude-code-marketplace` に新規 plugin として登録する。
さらに `tqer39/.dotfiles` の `installed_plugins.personal.json` で再現性を確保する。

**Architecture:** 既存の「1 plugin = 1 skill」構成 (security, agent-config 等) に揃える。
2 リポジトリにまたがるため、marketplace PR → merge → dotfiles PR の 2 段階で進める。
MIT License の帰属要件は LICENSE ファイル同梱 + SKILL.md 末尾コメントで二重に満たす。

**Tech Stack:** Markdown。JSON。bash。GitHub CLI (`gh`)。pre-commit hooks (markdownlint-cli2 / textlint / cspell)。

**Spec:** [docs/superpowers/specs/2026-04-19-grill-me-skill-design.md](../specs/2026-04-19-grill-me-skill-design.md)

---

## File Structure

### Phase A: Marketplace (`/Users/takeruooyama/workspace/tqer39/claude-code-marketplace/`)

- Create: `plugins/grill-me/.claude-plugin/plugin.json` — plugin メタデータ
- Create: `plugins/grill-me/skills/grill-me/SKILL.md` — skill 定義 (upstream 逐語)
- Create: `plugins/grill-me/LICENSE` — MIT License 全文 (帰属要件)
- Modify: `.claude-plugin/marketplace.json` — `plugins` 配列末尾にエントリ追加
- Modify: `README.md` — install コマンド例 + plugin 一覧に grill-me を追加
- Modify: `docs/README.ja.md` — 日本語版に同様の追加

### Phase B: Dotfiles (本 worktree: `/Users/takeruooyama/.dotfiles/.claude/worktrees/transient-bubbling-octopus/`)

- Modify: `src/.claude/plugins/installed_plugins.personal.json` — grill-me@tqer39-plugins エントリ追加

---

## Phase A: Marketplace 変更

### Task A1: Marketplace worktree 準備 & ブランチ作成

**Files:**

- None (ブランチ作成のみ)

- [ ] **Step 1: 作業ディレクトリ移動 & 状態確認**

```bash
cd /Users/takeruooyama/workspace/tqer39/claude-code-marketplace
git status
git log -1 --oneline
```

Expected: `On branch main`, `Your branch is up to date with 'origin/main'`。`.claude/` が untracked として残っているが本タスクでは触らない。

- [ ] **Step 2: 新ブランチ作成**

```bash
git switch -c feat/add-grill-me-plugin
```

Expected: `Switched to a new branch 'feat/add-grill-me-plugin'`

---

### Task A2: plugin.json を作成

**Files:**

- Create: `/Users/takeruooyama/workspace/tqer39/claude-code-marketplace/plugins/grill-me/.claude-plugin/plugin.json`

- [ ] **Step 1: ディレクトリ作成**

```bash
mkdir -p /Users/takeruooyama/workspace/tqer39/claude-code-marketplace/plugins/grill-me/.claude-plugin
mkdir -p /Users/takeruooyama/workspace/tqer39/claude-code-marketplace/plugins/grill-me/skills/grill-me
```

- [ ] **Step 2: plugin.json を書き込む**

`plugins/grill-me/.claude-plugin/plugin.json` に以下を書き込む:

```json
{
  "name": "grill-me",
  "description": "Socratic interviewer skill that grills you on plans/designs until shared understanding is reached",
  "version": "0.1.0"
}
```

- [ ] **Step 3: JSON 構文を検証**

```bash
cd /Users/takeruooyama/workspace/tqer39/claude-code-marketplace
python3 -c "import json; json.load(open('plugins/grill-me/.claude-plugin/plugin.json'))"
```

Expected: エラーなし (stdout/stderr 両方空)

---

### Task A3: SKILL.md を作成

**Files:**

- Create: `/Users/takeruooyama/workspace/tqer39/claude-code-marketplace/plugins/grill-me/skills/grill-me/SKILL.md`

- [ ] **Step 1: SKILL.md を書き込む**

`plugins/grill-me/skills/grill-me/SKILL.md` に以下を書き込む (upstream 逐語 + 末尾出典コメント):

```markdown
---
name: grill-me
description: Interview the user relentlessly about a plan or design until reaching shared understanding, resolving each branch of the decision tree. Use when user wants to stress-test a plan, get grilled on their design, or mentions "grill me".
---

Interview me relentlessly about every aspect of this plan until we reach a shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one-by-one. For each question, provide your recommended answer.

Ask the questions one at a time.

If a question can be answered by exploring the codebase, explore the codebase instead.

<!-- Source: https://github.com/mattpocock/skills/blob/main/grill-me/SKILL.md (MIT License, Copyright (c) 2026 Matt Pocock) -->
```

- [ ] **Step 2: upstream と差分比較 (改行や空白のズレ確認)**

```bash
gh api repos/mattpocock/skills/contents/grill-me/SKILL.md --jq '.content' | base64 -d > /tmp/upstream-grill-me.md
diff /tmp/upstream-grill-me.md /Users/takeruooyama/workspace/tqer39/claude-code-marketplace/plugins/grill-me/skills/grill-me/SKILL.md
```

Expected: 末尾の `<!-- Source: ... -->` コメント行のみが差分として表示される (local に 1 行追加、それ以外は一致)。

---

### Task A4: LICENSE を作成

**Files:**

- Create: `/Users/takeruooyama/workspace/tqer39/claude-code-marketplace/plugins/grill-me/LICENSE`

- [ ] **Step 1: upstream LICENSE をダウンロードして配置**

```bash
gh api repos/mattpocock/skills/contents/LICENSE --jq '.content' | base64 -d > /Users/takeruooyama/workspace/tqer39/claude-code-marketplace/plugins/grill-me/LICENSE
```

- [ ] **Step 2: 内容確認**

```bash
head -3 /Users/takeruooyama/workspace/tqer39/claude-code-marketplace/plugins/grill-me/LICENSE
```

Expected:

```text
MIT License

Copyright (c) 2026 Matt Pocock
```

---

### Task A5: marketplace.json を更新

**Files:**

- Modify: `/Users/takeruooyama/workspace/tqer39/claude-code-marketplace/.claude-plugin/marketplace.json`

- [ ] **Step 1: 既存の最後のエントリ (skill-matcher) の直後に grill-me を追加**

`plugins` 配列の末尾 (`skill-matcher` エントリの後) に以下を追記。`skill-matcher` オブジェクトの閉じ `}` の後にカンマを追加し、新エントリを挿入:

変更前 (抜粋):

```json
    {
      "name": "skill-matcher",
      "source": "./plugins/skill-matcher",
      "description": "UserPromptSubmit hook that auto-invokes skills when user sends a bare skill name"
    }
  ]
}
```

変更後:

```json
    {
      "name": "skill-matcher",
      "source": "./plugins/skill-matcher",
      "description": "UserPromptSubmit hook that auto-invokes skills when user sends a bare skill name"
    },
    {
      "name": "grill-me",
      "source": "./plugins/grill-me",
      "description": "Socratic interviewer skill that grills you on plans/designs until shared understanding is reached"
    }
  ]
}
```

- [ ] **Step 2: JSON 構文を検証**

```bash
cd /Users/takeruooyama/workspace/tqer39/claude-code-marketplace
python3 -c "import json; d=json.load(open('.claude-plugin/marketplace.json')); assert any(p['name']=='grill-me' for p in d['plugins']), 'grill-me not found'; print('ok')"
```

Expected: `ok`

---

### Task A6: README.md (英語) を更新

**Files:**

- Modify: `/Users/takeruooyama/workspace/tqer39/claude-code-marketplace/README.md`

- [ ] **Step 1: 冒頭インストール例 (L20 付近) に grill-me 行を追加**

変更前 (L15-21):

```text
/plugin install git@tqer39-plugins
/plugin install architecture@tqer39-plugins
/plugin install marketplace@tqer39-plugins
/plugin install security@tqer39-plugins
/plugin install agent-config@tqer39-plugins
```

変更後 (末尾に 1 行追加):

```text
/plugin install git@tqer39-plugins
/plugin install architecture@tqer39-plugins
/plugin install marketplace@tqer39-plugins
/plugin install security@tqer39-plugins
/plugin install agent-config@tqer39-plugins
/plugin install grill-me@tqer39-plugins
```

- [ ] **Step 2: plugin 一覧セクション末尾 (agent-config の後) に grill-me セクションを追加**

L159 以降の `### agent-config` セクションの後ろ、`## Development` の前に以下を挿入:

```markdown
### grill-me

Socratic interviewer skill that grills you on plans/designs until shared understanding is reached.

| Skill | Description |
|-------|-------------|
| grill-me | Interview user relentlessly about a plan or design, walking down each branch of the decision tree to reach shared understanding |

Upstream: [mattpocock/skills](https://github.com/mattpocock/skills) (MIT License).

```

---

### Task A7: docs/README.ja.md (日本語) を更新

**Files:**

- Modify: `/Users/takeruooyama/workspace/tqer39/claude-code-marketplace/docs/README.ja.md`

- [ ] **Step 1: 冒頭インストール例に grill-me 行を追加**

変更前 (L15-21):

```text
/plugin install git@tqer39-plugins
/plugin install architecture@tqer39-plugins
/plugin install marketplace@tqer39-plugins
/plugin install security@tqer39-plugins
/plugin install agent-config@tqer39-plugins
```

変更後 (末尾に 1 行追加):

```text
/plugin install git@tqer39-plugins
/plugin install architecture@tqer39-plugins
/plugin install marketplace@tqer39-plugins
/plugin install security@tqer39-plugins
/plugin install agent-config@tqer39-plugins
/plugin install grill-me@tqer39-plugins
```

- [ ] **Step 2: plugin 一覧セクション末尾に grill-me 節を追加**

L159 以降の `### agent-config` セクションの後ろ、`## 開発` の前に以下を挿入:

```markdown
### grill-me

計画や設計を stress-test する Socratic 型インタビュースキル。決定木の各分岐について 1 問ずつ質問し、共通理解に到達させる。

| スキル | 説明 |
|--------|------|
| grill-me | ユーザーに計画や設計について徹底インタビューし、決定木の各分岐を辿って共通理解に至らせる |

Upstream: [mattpocock/skills](https://github.com/mattpocock/skills) (MIT License)。

```

---

### Task A8: lint & validate

**Files:**

- None (検証のみ)

- [ ] **Step 1: pre-commit lint を手動実行**

```bash
cd /Users/takeruooyama/workspace/tqer39/claude-code-marketplace
git add plugins/grill-me .claude-plugin/marketplace.json README.md docs/README.ja.md
pre-commit run --files plugins/grill-me/.claude-plugin/plugin.json plugins/grill-me/skills/grill-me/SKILL.md plugins/grill-me/LICENSE .claude-plugin/marketplace.json README.md docs/README.ja.md
```

Expected: すべて `Passed` または `Skipped`。Failed があれば該当メッセージに従って修正し、再実行。

- [ ] **Step 2: just lint があれば実行**

```bash
cd /Users/takeruooyama/workspace/tqer39/claude-code-marketplace
just lint 2>&1 | tail -30 || echo "just lint not available, skipping"
```

Expected: 成功 or skip。

---

### Task A9: commit & push & PR 作成

**Files:**

- None (git 操作のみ)

- [ ] **Step 1: commit**

```bash
cd /Users/takeruooyama/workspace/tqer39/claude-code-marketplace
git commit -m "$(cat <<'EOF'
✨ grill-me skill plugin を追加

mattpocock/skills の grill-me skill を新規 plugin として登録。
計画や設計を決定木の各分岐ごとに 1 問ずつ徹底インタビューする Socratic 型 skill。
MIT License 全文を plugins/grill-me/LICENSE に同梱し、SKILL.md 末尾に出典コメントを残すことで帰属要件を満たす。

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
```

Expected: pre-commit が再度走り、成功してコミット作成。

- [ ] **Step 2: push**

```bash
git push -u origin feat/add-grill-me-plugin
```

Expected: `Branch 'feat/add-grill-me-plugin' set up to track 'origin/feat/add-grill-me-plugin'`

- [ ] **Step 3: PR 作成**

```bash
gh pr create --repo tqer39/claude-code-marketplace --title "✨ grill-me skill plugin を追加" --body "$(cat <<'EOF'
## Summary

- mattpocock/skills の grill-me skill を新規 plugin として追加
- 計画や設計を決定木の各分岐ごとに 1 問ずつ徹底インタビューする Socratic 型 skill
- MIT License 全文を plugin 配下に同梱 (帰属要件)

## Test plan

- [ ] \`.claude-plugin/marketplace.json\` の JSON 構文 OK
- [ ] \`plugins/grill-me/skills/grill-me/SKILL.md\` が upstream と一致 (末尾コメント除く)
- [ ] \`plugins/grill-me/LICENSE\` が MIT 全文
- [ ] README.md / docs/README.ja.md に grill-me が追加されている
- [ ] merge 後に \`/plugin install grill-me@tqer39-plugins\` が成功する

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

Expected: PR URL が返る。

---

### Task A10: PR マージ

**Files:**

- None (GitHub 操作のみ)

- [ ] **Step 1: PR の CI 状態確認**

```bash
gh pr view --repo tqer39/claude-code-marketplace feat/add-grill-me-plugin --json statusCheckRollup,mergeable
```

Expected: `statusCheckRollup` がすべて `SUCCESS` (CI がない場合は空配列でも可)、`mergeable: "MERGEABLE"`。

- [ ] **Step 2: PR をマージ**

```bash
gh pr merge --repo tqer39/claude-code-marketplace feat/add-grill-me-plugin --squash --delete-branch
```

Expected: `Merged pull request ...` のメッセージ。

- [ ] **Step 3: ローカルを main に戻して pull**

```bash
cd /Users/takeruooyama/workspace/tqer39/claude-code-marketplace
git switch main
git pull --ff-only
```

Expected: merge commit が取り込まれる。

---

## Phase B: Dotfiles 変更

### Task B1: installed_plugins.personal.json を更新

**Files:**

- Modify: `src/.claude/plugins/installed_plugins.personal.json` (本 worktree 内)

- [ ] **Step 1: ファイル末尾の最後のエントリ (discord@claude-plugins-official) の後に grill-me@tqer39-plugins を追加**

変更前 (末尾):

```json
    "discord@claude-plugins-official": [
      {
        "scope": "user",
        "installPath": "/Users/takeruooyama/.claude/plugins/cache/claude-plugins-official/discord/0.0.4",
        "version": "0.0.4",
        "installedAt": "2026-04-11T22:56:29.277Z",
        "lastUpdated": "2026-04-12T23:13:07.476Z"
      }
    ]
  }
}
```

変更後 (末尾):

```json
    "discord@claude-plugins-official": [
      {
        "scope": "user",
        "installPath": "/Users/takeruooyama/.claude/plugins/cache/claude-plugins-official/discord/0.0.4",
        "version": "0.0.4",
        "installedAt": "2026-04-11T22:56:29.277Z",
        "lastUpdated": "2026-04-12T23:13:07.476Z"
      }
    ],
    "grill-me@tqer39-plugins": [
      {
        "scope": "user",
        "version": "0.1.0",
        "lastUpdated": "2026-04-19T00:00:00.000Z"
      }
    ]
  }
}
```

- [ ] **Step 2: JSON 構文を検証**

```bash
cd /Users/takeruooyama/.dotfiles/.claude/worktrees/transient-bubbling-octopus
python3 -c "import json; d=json.load(open('src/.claude/plugins/installed_plugins.personal.json')); assert 'grill-me@tqer39-plugins' in d['plugins'], 'missing'; print('ok')"
```

Expected: `ok`

---

### Task B2: dotfiles commit & PR

**Files:**

- None (git 操作のみ)

- [ ] **Step 1: commit**

```bash
cd /Users/takeruooyama/.dotfiles/.claude/worktrees/transient-bubbling-octopus
git add src/.claude/plugins/installed_plugins.personal.json docs/superpowers/specs/2026-04-19-grill-me-skill-design.md docs/superpowers/plans/2026-04-19-grill-me-skill.md
git commit -m "$(cat <<'EOF'
✨ grill-me@tqer39-plugins を installed_plugins に追加

tqer39/claude-code-marketplace に追加した grill-me plugin を再現性確保のため dotfiles 管理下に登録。併せて spec/plan ドキュメントも追加。

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
```

Expected: pre-commit 成功、commit 作成。

- [ ] **Step 2: push**

```bash
git push -u origin "$(git branch --show-current)"
```

Expected: push 成功。

- [ ] **Step 3: PR 作成**

```bash
gh pr create --title "✨ grill-me skill を installed_plugins に追加" --body "$(cat <<'EOF'
## Summary

- tqer39/claude-code-marketplace に追加した grill-me plugin を \`installed_plugins.personal.json\` に登録
- spec (docs/superpowers/specs/) と plan (docs/superpowers/plans/) も併せて追加

Upstream PR (marketplace 側): tqer39/claude-code-marketplace#<PR番号>

## Test plan

- [ ] clean な \`~/.claude/plugins/\` で \`./scripts/dotfiles.sh install\` 実行後、grill-me が反映される
- [ ] 任意セッションで「grill me してほしい」と発話 → skill が発火する

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

Expected: PR URL が返る。

---

### Task B3: 動作確認

**Files:**

- None (手動検証)

- [ ] **Step 1: PR マージ後、手動で plugin install**

マージ後、別 Claude Code セッション or 本セッションで:

```bash
claude plugin install grill-me@tqer39-plugins
```

Expected: インストール成功メッセージ。

- [ ] **Step 2: skill 発火確認**

任意の Claude Code セッションで「計画を grill me してほしい」等と発話し、grill-me skill が起動することを目視確認。

Expected: Socratic 型の質問が 1 問ずつ返ってくる。

---

## Self-Review Checklist

実装開始前に実行者が確認:

- [ ] Spec (docs/superpowers/specs/2026-04-19-grill-me-skill-design.md) のすべての変更項目が Phase A/B のタスクでカバーされている
- [ ] プレースホルダ (TBD, TODO 等) が本プランに存在しない
- [ ] Phase A の各タスクが marketplace リポジトリ、Phase B が dotfiles リポジトリで完結している
- [ ] JSON ファイル編集 (plugin.json, marketplace.json, installed_plugins.personal.json) の各タスクに構文検証ステップがある
- [ ] MIT License の帰属表示 (LICENSE ファイル + SKILL.md 末尾コメント) の両方が含まれる
