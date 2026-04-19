# ref-cspell: cspell 辞書の外出しと未使用語クリーンアップ

- 作成日: 2026-04-19
- Topic: ref-cspell
- ブランチ: `feature/ref-cspell`

## Context

現状の `cspell.json` には `words[]` が単一配列で ~180 語並んでおり管理性が低い。重複 (`direnv` / `direnvrc` など)、タイポ疑い (`esktop`, `donotpresent`, `dearu`)、無秩序な並びが混在し、新語追加の diff も config ノイズと絡む。

`tqer39/terraform-github` リポでは `.cspell/project-words.txt` へ辞書を切り出しており、レビュー性・保守性ともに優れる。本 spec では同パターンを採用しつつ、`cspell lint` の実行結果で実際に必要な語のみを残す実証的クリーンアップを行う設計を定める。

## Goals

- `cspell.json` の `words[]` を `.cspell/project-words.txt` に切り出して、`cspell.json` は設定のみ保持する
- 外部辞書に対して `cspell lint` の出力で必要語を検証し、未使用語を削除する
- 新語追加の diff を cspell 設定ノイズから分離してレビューしやすい状態にする

## Non-Goals

- **lefthook への移行** (`ref-lefthook` として別 spec)
- **`.python-version` と `mise.toml` の統合** (`ref-mise` として別 spec)
- カテゴリ別辞書分割 (今回は単一ファイル)
- `ignorePaths` / `files` など他の cspell 設定の変更
- `cspell` / `cspell-cli` バージョン更新、VS Code 拡張側の設定
- 既存になかった語 (`missing`) の自動追加

## Design Decisions

| 決定 | 選択 |
| --- | --- |
| 辞書配置 | **`.cspell/project-words.txt`** (terraform-github 方式) |
| ファイル分割 | **単一ファイル** (カテゴリ別分割はしない) |
| `cspell.json` 参照方式 | **`dictionaryDefinitions` + `dictionaries`** (`addWords: true`) |
| クリーンアップ方針 | **実証ベース** (`cspell --unique --words-only` 出力との diff) |
| 未使用語の最終判断 | **ユーザー レビュー必須** (自動削除はしない) |
| 欠落語の扱い | **本 spec では追加しない** (精査は別タスク) |
| ツール本体 | **prek 据え置き** (lefthook 移行は別 spec) |

## Architecture

```text
.
├── cspell.json                     # 設定のみ (words[] を削除)
└── .cspell/
    └── project-words.txt           # 1 語/行、アルファベット順、末尾 newline
```

### `cspell.json` (変更後)

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

### `.cspell/project-words.txt` のフォーマット

- 1 語/行、空行やコメントなし
- `sort -uf` 相当で整列 (大小区別なし、重複なし)
- UTF-8 (BOM なし)、末尾 newline あり

## 未使用語検出ワークフロー

実装 Step 1 完了後 (`.cspell/project-words.txt` が ~180 語を保持する状態) に実施する。

```bash
# 1. 切り出し直後の辞書をベースラインとして保存
sort -uf .cspell/project-words.txt > /tmp/cspell-current.txt

# 2. 辞書を一時退避し、空辞書状態で cspell を実行
#    flag される unknown words = 実際に必要な語
mv .cspell/project-words.txt .cspell/project-words.txt.bak
: > .cspell/project-words.txt

cspell --unique --words-only --no-progress '**' '.*/**' 2>/dev/null \
  | sort -uf > /tmp/cspell-needed.txt

# 3. 辞書を復元
mv .cspell/project-words.txt.bak .cspell/project-words.txt

# 4. 三方向 diff
comm -23 /tmp/cspell-current.txt /tmp/cspell-needed.txt > /tmp/cspell-unused.txt
comm -12 /tmp/cspell-current.txt /tmp/cspell-needed.txt > /tmp/cspell-keep.txt
comm -13 /tmp/cspell-current.txt /tmp/cspell-needed.txt > /tmp/cspell-missing.txt

# 5. 削除候補を目視し `rg -iw '<word>'` で確認、ユーザー承認後に最終版を生成
```

**中断時の復旧**: 手順 2-3 の間で中断した場合は `.bak` が残るため、手動で `mv .cspell/project-words.txt.bak .cspell/project-words.txt` を実行する。

### レビュー基準

| 判定 | 例 | 扱い |
| --- | --- | --- |
| タイポ疑い | `esktop`, `dearu`, `donotpresent` | 削除 |
| 現在未使用の固有名詞 | `Keypirinha`, `mobaxterm` | 削除 |
| 判断つかない | — | 保持 |

## 実装手順

### Step 1: 辞書切り出し (現行同等を担保)

- `.cspell/` 作成
- `jq -r '.words[]' cspell.json | sort -uf > .cspell/project-words.txt`
- `cspell.json` の `words[]` を削除し、`dictionaryDefinitions` と `dictionaries` を追加
- `just lint-hook cspell` と `cspell lint --no-progress '**' '.*/**'` が 0 issues で pass すること
- Commit: `🔧 cspell 辞書を .cspell/project-words.txt に外出し`

### Step 2: 未使用語検出

- 上記ワークフローを実行して `/tmp/cspell-unused.txt` を生成
- 各語を `rg -iw '<word>'` で全 file 確認
- 削除候補一覧をユーザーに提示して承認を得る

### Step 3: 辞書クリーンアップ

- `.cspell/project-words.txt` から承認済みエントリを削除
- `sort -uf` で再整列、末尾 newline
- `cspell lint` を再実行して 0 issues を確認
- Commit: `🧹 未使用の cspell 辞書エントリを削除`

### Step 4: ドキュメント

- 本 spec は既に commit 済み
- writing-plans スキルで `docs/superpowers/plans/2026-04-19-ref-cspell.md` を生成

### Step 5: PR

- title: `🧹 cspell 辞書を .cspell/ に外出しして未使用語を整理`
- base: `main`, branch: `feature/ref-cspell`

## 検証

```bash
# 1. prek 経由の cspell 単体
just lint-hook cspell                       # → 0 issues

# 2. prek の全 hook で回帰確認
just lint                                   # → cspell 以外に影響なし

# 3. cspell 直接呼び出し
cspell lint --no-progress '**' '.*/**'      # → 0 issues

# 4. 新語追加の動作確認
echo "newtestword" >> .cspell/project-words.txt
# 対象 md に "newtestword" を含めて一度 fail させ、辞書追加後に解決することを確認
```

## ロールバック

`git revert` のみで原状復帰できる。`.cspell/project-words.txt` を削除し `cspell.json` の `words[]` を復元するだけで済む。外部 (CI や pre-commit hook の repo / prek 設定 / cspell-cli バージョン) への変更はない。

## リスク

| リスク | 影響 | 緩和策 |
| --- | --- | --- |
| `dictionaryDefinitions` のパス誤認識 | cspell lint 失敗 | Step 1 で現行同等 pass を gate |
| 削除語がコメント・履歴・バイナリに残存 | 後日 unknown word 警告 | レビュー時に `rg -iw` で全 file 検索 |
| VS Code cspell 拡張が辞書を読まない | エディタ上の false positive | cspell v6+ 標準サポートあり、検証 Step 4 で確認 |

## Critical Files

- `cspell.json` (変更)
- `.cspell/project-words.txt` (新規)
- `.pre-commit-config.yaml` (**変更なし**、prek 経由で cspell-cli を呼ぶだけ)
- `justfile` (**変更なし**、`just lint-hook cspell` と `just lint` はそのまま動作)
