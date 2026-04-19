# ref-cspell Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `cspell.json` の `words[]` を `.cspell/project-words.txt` に切り出し、未使用語をクリーンアップする。

**Architecture:** `dictionaryDefinitions` で外部辞書を参照する構成に変更する。辞書を一時退避した状態で `cspell --unique --words-only` を実行して必要語を抽出する。三方向 diff で未使用語を特定してユーザー承認後に削除する。

**Tech Stack:** `cspell` v10 (streetsidesoftware/cspell-cli via prek) / `jq` / `comm` / `sort` / `ripgrep`

**Spec:** `docs/superpowers/specs/2026-04-19-ref-cspell-design.md`

---

## File Structure

| File | 役割 | Action |
| --- | --- | --- |
| `cspell.json` | cspell 設定 (words は持たない) | Modify |
| `.cspell/project-words.txt` | プロジェクト辞書 (1 語/行) | Create |
| `docs/superpowers/plans/2026-04-19-ref-cspell.md` | 本プラン | Create |

---

## Task 1: 辞書ファイルの切り出し

**Files:**

- Create: `.cspell/project-words.txt`

- [ ] **Step 1: `.cspell/` ディレクトリを作成**

```bash
mkdir -p .cspell
```

- [ ] **Step 2: 現行 `words[]` を抽出して辞書ファイル化**

```bash
jq -r '.words[]' cspell.json | sort -uf > .cspell/project-words.txt
```

- [ ] **Step 3: 語数を確認 (baseline)**

```bash
wc -l .cspell/project-words.txt
jq '.words | length' cspell.json
```

期待値: 辞書ファイル行数は `jq` で得た元の語数以下 (`sort -uf` で重複除去されるため)。

---

## Task 2: `cspell.json` の構造変更

**Files:**

- Modify: `cspell.json`

- [ ] **Step 1: `cspell.json` を書き換え**

新しい内容 (既存の `files` / `ignorePaths` は保持、`words[]` を削除、`dictionaryDefinitions` と `dictionaries` を追加):

```json
{
  "$schema": "https://raw.githubusercontent.com/streetsidesoftware/cspell/main/cspell.schema.json",
  "files": ["**", ".*/**"],
  "ignorePaths": [
    ".git",
    ".gitignore",
    ".claude",
    "**/.terraform.lock.hcl",
    "**/*.drawio.svg"
  ],
  "dictionaryDefinitions": [
    {
      "name": "project-words",
      "path": ".cspell/project-words.txt",
      "addWords": true
    }
  ],
  "dictionaries": ["project-words"]
}
```

- [ ] **Step 2: JSON valid 確認**

```bash
jq . cspell.json > /dev/null && echo OK
```

期待値: `OK` が表示される。

---

## Task 3: 現行同等 pass の確認 (gate)

**Files:** 確認のみ、変更なし。

- [ ] **Step 1: cspell を直接実行**

```bash
cspell lint --no-progress '**' '.*/**'
```

期待値: `0 issues`。

- [ ] **Step 2: prek 経由で cspell hook を実行**

```bash
just lint-hook cspell
```

期待値: `0 issues`。

**Gate 条件:** どちらかが fail する場合、`cspell.json` の `dictionaryDefinitions` パスか `.cspell/project-words.txt` の内容に問題がある。進行せず修正する。

---

## Task 4: 切り出しの commit

**Files:** git 操作のみ。

- [ ] **Step 1: 変更内容を確認**

```bash
git status
git diff cspell.json
git diff --stat
```

期待値: `cspell.json` が変更され、`.cspell/project-words.txt` が新規追加される。

- [ ] **Step 2: add + commit**

```bash
git add cspell.json .cspell/project-words.txt
git commit -m "🔧 cspell 辞書を .cspell/project-words.txt に外出し"
```

---

## Task 5: 未使用語検出ワークフロー

**Files:** 一時ファイルのみ、リポジトリに commit しない。

- [ ] **Step 1: ベースライン (現行辞書) を保存**

```bash
sort -uf .cspell/project-words.txt > /tmp/cspell-current.txt
wc -l /tmp/cspell-current.txt
```

- [ ] **Step 2: 辞書を一時退避して空ファイルに置換**

```bash
mv .cspell/project-words.txt .cspell/project-words.txt.bak
: > .cspell/project-words.txt
```

- [ ] **Step 3: 空辞書状態で cspell を実行して必要語を抽出**

```bash
cspell --unique --words-only --no-progress '**' '.*/**' 2>/dev/null \
  | sort -uf > /tmp/cspell-needed.txt
wc -l /tmp/cspell-needed.txt
```

期待値: 数十から百数十の語が抽出される。

- [ ] **Step 4: 辞書を復元**

```bash
mv .cspell/project-words.txt.bak .cspell/project-words.txt
```

**中断時の復旧**: `.bak` が残った場合は上記 `mv` を手動実行する。

- [ ] **Step 5: 三方向 diff**

```bash
comm -23 /tmp/cspell-current.txt /tmp/cspell-needed.txt > /tmp/cspell-unused.txt
comm -12 /tmp/cspell-current.txt /tmp/cspell-needed.txt > /tmp/cspell-keep.txt
comm -13 /tmp/cspell-current.txt /tmp/cspell-needed.txt > /tmp/cspell-missing.txt
wc -l /tmp/cspell-unused.txt /tmp/cspell-keep.txt /tmp/cspell-missing.txt
```

各ファイルの意味: unused = 削除候補 / keep = 保持 (検証用) / missing = 欠落語 (参考のみで今回追加はしない)。

- [ ] **Step 6: 各削除候補を `rg` で全 file 検索して真に未使用か確認**

```bash
while read -r word; do
  count=$(rg -iwc --no-messages "$word" | wc -l | tr -d ' ')
  echo "$count $word"
done < /tmp/cspell-unused.txt | sort -n > /tmp/cspell-unused-with-count.txt
cat /tmp/cspell-unused-with-count.txt
```

期待値: 各行に `<file 数> <word>` が出力される。0 の語が真の削除候補となる。

---

## Task 6: 削除候補のユーザー承認

**Files:** レビューのみ、変更なし。

- [ ] **Step 1: 削除候補一覧をユーザーに提示**

`/tmp/cspell-unused-with-count.txt` を表形式でユーザーに提示する。判定基準:

| 判定 | 例 | 扱い |
| --- | --- | --- |
| タイポ疑い | `esktop`, `dearu`, `donotpresent` | 削除 |
| 現在未使用の固有名詞 | `Keypirinha`, `mobaxterm` | 削除 |
| 判断つかない | — | 保持 |

- [ ] **Step 2: 承認済み削除リストを `/tmp/cspell-remove.txt` に作成**

```bash
$EDITOR /tmp/cspell-remove.txt
wc -l /tmp/cspell-remove.txt
```

---

## Task 7: 辞書クリーンアップ

**Files:**

- Modify: `.cspell/project-words.txt`

- [ ] **Step 1: 削除対象を除外した辞書を生成**

```bash
sort -uf /tmp/cspell-remove.txt > /tmp/cspell-remove-sorted.txt
comm -23 <(sort -uf .cspell/project-words.txt) /tmp/cspell-remove-sorted.txt \
  > .cspell/project-words.txt.new
mv .cspell/project-words.txt.new .cspell/project-words.txt
```

- [ ] **Step 2: 再整列 + 末尾 newline 確認**

```bash
sort -uf .cspell/project-words.txt > .cspell/project-words.txt.sorted
mv .cspell/project-words.txt.sorted .cspell/project-words.txt
tail -c 1 .cspell/project-words.txt | xxd
wc -l .cspell/project-words.txt
```

期待値: 末尾バイトが `0a` (newline) であり、語数は元の語数から削除分を引いた値になる。

---

## Task 8: クリーンアップ後の回帰確認

**Files:** 確認のみ。

- [ ] **Step 1: cspell 単体で 0 issues 確認**

```bash
cspell lint --no-progress '**' '.*/**'
```

期待値: `0 issues`。

- [ ] **Step 2: prek 経由の cspell hook で確認**

```bash
just lint-hook cspell
```

期待値: `0 issues`。

- [ ] **Step 3: 全 prek hook で回帰確認 (cspell 以外に影響がないこと)**

```bash
just lint
```

期待値: cspell 以外の hook 結果が `main` ブランチと同じ。

**Gate 条件:** 1 つでも fail する場合、削除した語が実際には必要だった可能性を疑う。`git diff .cspell/project-words.txt` で除いた語を確認して復活させる。

---

## Task 9: クリーンアップの commit

**Files:** git 操作のみ。

- [ ] **Step 1: 変更内容を確認**

```bash
git diff --stat
git diff .cspell/project-words.txt | head -50
```

- [ ] **Step 2: commit**

```bash
git add .cspell/project-words.txt
git commit -m "🧹 未使用の cspell 辞書エントリを削除"
```

---

## Task 10: PR 作成

**Files:** git 操作のみ。

- [ ] **Step 1: branch を push**

```bash
git push -u origin feature/ref-cspell
```

- [ ] **Step 2: PR を作成**

```bash
gh pr create --title "🧹 cspell 辞書を .cspell/ に外出しして未使用語を整理" --body "$(cat <<'BODY'
## Summary

- `cspell.json` の `words[]` を `.cspell/project-words.txt` に外出し
- `cspell --unique --words-only` で得た必要語と diff して未使用語を削除

Spec: `docs/superpowers/specs/2026-04-19-ref-cspell-design.md`

## Test plan

- [ ] `just lint-hook cspell` → 0 issues
- [ ] `just lint` → 回帰なし
- [ ] `cspell lint --no-progress '**' '.*/**'` → 0 issues
BODY
)"
```

- [ ] **Step 3: PR URL を確認**

```bash
gh pr view --json url -q .url
```

---

## 検証 (全体)

全 Task 完了後、`main` ブランチとの diff が以下に収まっていることを確認する。

```bash
git diff main..feature/ref-cspell --stat
```

期待される変更:

- `cspell.json` (変更: `words[]` 削除、`dictionaryDefinitions` 追加)
- `.cspell/project-words.txt` (新規)
- `docs/superpowers/specs/2026-04-19-ref-cspell-design.md` (新規)
- `docs/superpowers/plans/2026-04-19-ref-cspell.md` (新規)

他のファイル (`.pre-commit-config.yaml`, `justfile`, `scripts/` 等) に変更がないこと。
