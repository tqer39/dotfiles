# ref-lefthook: prek から lefthook への移行

- 作成日: 2026-04-19
- Topic: ref-lefthook
- ブランチ: `feature/ref-lefthook`
- 参考リポ: `tqer39/terraform-github` (lefthook + pnpm + scripts/lint パターン)

## Context

現状の lint 基盤は `prek` (pre-commit 互換ランタイム) と `.pre-commit-config.yaml` で構成されている。`prek` は十分に高速だが、以下の課題がある。

- 別プロジェクト (`terraform-github`) では既に `lefthook` ベースに統一済みである。
- `lefthook` は `parallel: true` で commit 時の wall-clock を短縮できる。
- `prek` は brew と scoop で別ルートで管理しているが `mise` に寄せられる。

本 spec では `terraform-github` と同じ構成を採用し、`prek` 系を全面的に lefthook へ置換する。

## Goals

- `.pre-commit-config.yaml` の全 hook を `lefthook.yml` に同等再現する。
- Node 系 lint 依存を `package.json` で pin し再現性を確保する。
- `pre-commit-hooks` 由来のセーフティ系 hook を `scripts/lint/*.sh` で自前実装する。
- `just lint`, `just lint-hook <hook>`, `just setup-hooks` が lefthook で動作する。
- CI (`prek.yml`) を `lint.yml` に置換する。
- `prek` への brew / scoop 依存を削除し `mise` で一元管理する。

## Non-Goals

- `betterleaks` 追加 (参照リポにはあるが現行 dotfiles に未導入。別 spec)
- hook そのものの追加・削除 (`yamllint`, `actionlint`, `terraform fmt` 等)
- cspell 辞書の構成変更 (`ref-cspell` で完了済み)
- `infra/terraform/` 配下の Terraform fmt 統合 (既存 CI が担当)
- `pre-commit` 本体パッケージ (`config/packages/Brewfile` の `brew "pre-commit"`) の扱いは現状維持の方針 — `prek` のみ削除する
- バッジ画像の刷新以外の README リライト

## Design Decisions

| 決定 | 選択 |
| --- | --- |
| Hook ランタイム | **lefthook** (mise 管理、`parallel: true`) |
| Node deps 管理 | **pnpm** + `package.json` + `pnpm-lock.yaml` |
| pnpm 自身の管理 | **mise** で版固定 (`packageManager` と一致) |
| pre-commit-hooks 互換 | **`scripts/lint/*.sh` で自前実装** (terraform-github 流用) |
| auto-fix 系の re-stage | **`stage_fixed: true`** で fix → 自動 re-stage |
| staged-only 実行 | **`{staged_files}` を全 hook に渡す** (CI は `--all-files`) |
| CI workflow 名 | **`lint.yml`** (job 名 `lint`) |
| Windows lefthook 取得 | **mise** に統一 (scoop の `prek` は削除) |
| ロールバック粒度 | **1 PR 単位の `git revert`** で原状復帰 |

## Architecture

```text
.
├── lefthook.yml                          # 新規: hook 定義 (parallel)
├── package.json                          # 新規: Node devDeps 宣言
├── pnpm-lock.yaml                        # 新規: pnpm install で生成
├── scripts/lint/                         # 新規: pre-commit-hooks 相当
│   ├── check-added-large-files.sh
│   ├── detect-aws-credentials.sh
│   ├── detect-private-key.sh
│   ├── end-of-file-fixer.sh
│   ├── mixed-line-ending.sh
│   └── trailing-whitespace.sh
├── mise.toml                             # 変更: lefthook / pnpm を追加
├── Brewfile                              # 変更: prek を削除
├── config/packages/Brewfile              # 変更: prek を削除
├── install.ps1                           # 変更: scoop の prek を削除
├── justfile                              # 変更: prek → lefthook、setup-node 追加
├── .gitignore                            # 変更: node_modules/, .lefthook/ 追加
├── .cspell/project-words.txt             # 変更: lefthook / prettier 等を追加
├── README.md / docs/README.ja.md         # 変更: バッジ URL 差し替え
├── docs/local-dev.md / .ja.md            # 変更: prek 記述を lefthook へ
├── .pre-commit-config.yaml               # 削除
└── .github/workflows/
    ├── prek.yml                          # 削除
    └── lint.yml                          # 新規: mise + pnpm + lefthook
```

### Hook マッピング (`.pre-commit-config.yaml` → `lefthook.yml`)

| 現行 hook | lefthook 実装 | glob | stage_fixed |
| --- | --- | --- | --- |
| `check-added-large-files` (`--maxkb=512`) | `scripts/lint/check-added-large-files.sh --max-kb=512 {staged_files}` | — | — |
| `detect-aws-credentials` (`--allow-missing-credentials`) | `scripts/lint/detect-aws-credentials.sh --allow-missing-credentials {staged_files}` | — | — |
| `detect-private-key` | `scripts/lint/detect-private-key.sh {staged_files}` | — | — |
| `end-of-file-fixer` | `scripts/lint/end-of-file-fixer.sh {staged_files}` | — | ✓ |
| `mixed-line-ending` (`--fix=lf`) | `scripts/lint/mixed-line-ending.sh --fix=lf {staged_files}` | — | ✓ |
| `trailing-whitespace` | `scripts/lint/trailing-whitespace.sh {staged_files}` | — | ✓ |
| `cspell` | `pnpm exec cspell lint --no-progress --no-must-find-files {staged_files}` | — | — |
| `markdownlint-cli2` | `pnpm exec markdownlint-cli2 --fix {staged_files}` | `*.{md,markdown}` | ✓ |
| `textlint` | `pnpm exec textlint {staged_files}` | `*.{md,markdown,txt}` | — |
| `shellcheck` (system) | `shellcheck {staged_files}` | `*.sh` | — |
| `biome-check` (json) | `pnpm exec biome check --write --no-errors-on-unmatched {staged_files}` | `*.json` | ✓ |
| `prettier` (yaml) | `pnpm exec prettier --write {staged_files}` | `*.{yml,yaml}` | ✓ |
| `renovate-config-validator` | `pnpm exec --package=renovate -- renovate-config-validator {staged_files}` | `renovate.json5` | — |

### `lefthook.yml` (本体)

```yaml
# Lefthook configuration.
# See https://lefthook.dev/configuration/ for details.
pre-commit:
  parallel: true
  commands:
    # ── セーフティ系 (pre-commit-hooks 相当) ──
    check-added-large-files:
      run: scripts/lint/check-added-large-files.sh --max-kb=512 {staged_files}
    detect-aws-credentials:
      run: scripts/lint/detect-aws-credentials.sh --allow-missing-credentials {staged_files}
    detect-private-key:
      run: scripts/lint/detect-private-key.sh {staged_files}
    end-of-file-fixer:
      run: scripts/lint/end-of-file-fixer.sh {staged_files}
      stage_fixed: true
    mixed-line-ending:
      run: scripts/lint/mixed-line-ending.sh --fix=lf {staged_files}
      stage_fixed: true
    trailing-whitespace:
      run: scripts/lint/trailing-whitespace.sh {staged_files}
      stage_fixed: true

    # ── リンタ系 ──
    shellcheck:
      glob: "*.sh"
      run: shellcheck {staged_files}
    markdownlint:
      glob: "*.{md,markdown}"
      run: pnpm exec markdownlint-cli2 --fix {staged_files}
      stage_fixed: true
    textlint:
      glob: "*.{md,markdown,txt}"
      run: pnpm exec textlint {staged_files}
    cspell:
      run: pnpm exec cspell lint --no-progress --no-must-find-files {staged_files}
    renovate-config-validator:
      glob: "renovate.json5"
      run: pnpm exec --package=renovate -- renovate-config-validator {staged_files}

    # ── フォーマッタ系 ──
    biome-check:
      glob: "*.json"
      run: pnpm exec biome check --write --no-errors-on-unmatched {staged_files}
      stage_fixed: true
    prettier-yaml:
      glob: "*.{yml,yaml}"
      run: pnpm exec prettier --write {staged_files}
      stage_fixed: true

# commit-msg / pre-push は現状不要。必要時にここへ追加。
```

### `package.json`

```json
{
  "name": "dotfiles-devtools",
  "private": true,
  "description": "Development tool dependencies for dotfiles (run via lefthook).",
  "packageManager": "pnpm@10.33.0",
  "devDependencies": {
    "@biomejs/biome": "1.9.4",
    "cspell": "10.0.0",
    "markdownlint-cli2": "0.22.0",
    "prettier": "3.1.0",
    "textlint": "15.5.4",
    "textlint-filter-rule-comments": "1.3.0",
    "textlint-rule-preset-smarthr": "1.37.0",
    "textlint-rule-preset-ja-technical-writing": "12.0.2"
  }
}
```

バージョンは現行 `.pre-commit-config.yaml` の `additional_dependencies` / `rev` から踏襲。

### `mise.toml`

```toml
[tools]
terraform = "1.14.8"
trivy = "0.69.3"
biome = "2.3.11"
lefthook = "1.8.4"
pnpm = "10.33.0"
```

### `justfile` (差分)

```diff
-setup: setup-mise setup-hooks
+setup: setup-mise setup-node setup-hooks
     @echo "Setup completed"

 setup-mise:
     @mise install

+setup-node:
+    @pnpm install --frozen-lockfile
+
 setup-hooks:
-    @prek install
+    @lefthook install

 lint:
-    @prek run --all-files
+    @lefthook run pre-commit --all-files

 lint-hook hook:
-    @prek run {{hook}}
+    @lefthook run pre-commit --commands {{hook}} --all-files

-# Clean pre-commit cache
+# Clean lefthook cache
 lint-clean:
-    @prek clean
+    @rm -rf .lefthook
```

### `.github/workflows/lint.yml`

```yaml
name: lint

on:
  push:
    branches:
      - main
  pull_request:

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  lint:
    runs-on: ubuntu-latest
    timeout-minutes: 10
    steps:
      - uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6
        with:
          ref: ${{ github.head_ref }}

      - name: Setup mise
        uses: jdx/mise-action@c37c93293d6b742fc901e1406b8f764f6fb19dac # v2
        with:
          install: true

      - name: Install node dependencies
        run: pnpm install --frozen-lockfile

      - name: Run lefthook
        run: lefthook run pre-commit --all-files
```

### Brewfile / install.ps1 (差分)

`Brewfile` (root):

```diff
-brew "prek"
```

`config/packages/Brewfile`: `brew "prek"  # pre-commit hooks` 行を削除。`brew "pre-commit"` は今回触らない (Non-Goal)。

`install.ps1` の scoop パッケージ配列から `"prek",` を削除。lefthook は mise 経由で取得する。

### `.gitignore` 追記

```text
node_modules/
.lefthook/
```

## 実装手順

### Step 1: Node 環境準備

- `package.json` を作成 (上記内容)
- `pnpm install` で `pnpm-lock.yaml` 生成
- `.gitignore` に `node_modules/`, `.lefthook/` 追加
- Commit: `🔧 Node 開発依存を pnpm で固定`

### Step 2: lefthook 設定

- `lefthook.yml` を作成
- `scripts/lint/*.sh` 6 本を `terraform-github` から流用 (権限 755 / shebang 確認)
- `mise.toml` に `lefthook` / `pnpm` 追加 → `mise install`
- Commit: `🔧 lefthook 設定とセーフティ系 hook を追加`

### Step 3: 動作 gate (元 prek と同等性検証)

- `lefthook install`
- `lefthook run pre-commit --all-files` で 0 issues を確認
- 不一致があれば glob / script を調整
- 旧 `prek run --all-files` と diff が無いこと

### Step 4: justfile 切替

- `setup-hooks` / `lint` / `lint-hook` / `lint-clean` を lefthook 化
- `setup-node` を追加し `setup` に組込
- `just lint` / `just lint-hook cspell` で 0 issues
- Commit: `🔧 justfile を lefthook ベースに更新`

### Step 5: CI 切替

- `.github/workflows/lint.yml` を新規作成
- `.github/workflows/prek.yml` を削除
- `README.md` / `docs/README.ja.md` のバッジ URL を `lint.yml` に差し替え
- Commit: `🔧 CI を lefthook ワークフローに置換`

### Step 6: インストーラ更新

- `Brewfile`, `config/packages/Brewfile` から `prek` 削除
- `install.ps1` の scoop 配列から `prek` 削除
- `docs/local-dev.md` / `docs/local-dev.ja.md` の prek 記述を lefthook に差し替え
- `.cspell/project-words.txt` に `lefthook` / `prettier` 等を追加 (cspell が必要と判定したもの)
- Commit: `🧹 prek 関連の install/doc 記述を lefthook に置換`

### Step 7: 旧 file 削除

- `.pre-commit-config.yaml` を削除
- `just lint` 最終確認
- Commit: `🔥 .pre-commit-config.yaml を削除`

### Step 8: PR

- title: `🔧 lint 基盤を prek から lefthook に移行`
- base: `main`, branch: `feature/ref-lefthook`
- 説明に「ローカル開発者は `mise install` と `lefthook install` の再実行が必要」と明記

## 検証

```bash
# 1. 全 hook を全 file で実行 (CI 等価)
just lint                                       # → 0 issues

# 2. 単独 hook の動作確認
just lint-hook cspell                           # → 0 issues
just lint-hook shellcheck

# 3. staged-files モード再現 (ローカル commit シミュレーション)
git add -A && lefthook run pre-commit

# 4. auto-fix が re-stage されることを確認
printf 'no newline' > /tmp/test.md && cp /tmp/test.md test.md
git add test.md
lefthook run pre-commit --commands end-of-file-fixer
git diff --cached --quiet || echo "re-staged ✓"
git restore --staged test.md && rm test.md

# 5. CI workflow を act でドライラン (任意)
act -W .github/workflows/lint.yml
```

**Pass 条件**: 1〜4 がすべて exit 0、`prek run --all-files` と同じ違反数 (= 0)。

## ロールバック

`git revert <merge-commit>` のみで原状復帰。外部 hook repo / 他リポへの破壊的変更なし。

ローカル復旧手順:

```bash
git revert <merge-commit>
prek install     # 旧 hook 再導入 (brew/scoop で prek を再取得)
```

## リスク

| リスク | 影響 | 緩和策 |
| --- | --- | --- |
| `{staged_files}` をバイナリに渡してスクリプトが誤動作 | hook が誤って失敗 | `scripts/lint/*.sh` 内で `grep -Iq .` などテキスト判定を行う (terraform-github 実装に準拠) |
| pnpm install が CI で遅い | lint job 時間増 | 当面は `--frozen-lockfile` のみ。将来 `actions/cache` で `~/.local/share/pnpm/store` をキャッシュ |
| ローカル開発者の `prek` 残存 hook が新 lefthook と競合 | 二重実行 | PR 説明と `docs/local-dev.md` で `lefthook install` 再実行を案内 |
| Windows 開発者が pnpm/lefthook 未導入 | ローカル hook が走らない | `mise` に両者を集約、`install.ps1` で `mise` を保証 |
| `renovate-config-validator` が pnpm 経由で解決遅延 | 体感低下 | local node_modules から `pnpm exec --package=renovate` で解決 (renovate を direct dep に追加するかは Step 3 で判断) |
| バッジ URL 差し替え漏れ | README 表示崩れ | `rg 'prek\.yml'` で全削除確認 |
| `prek` ↔ `pre-commit` の混同 | `config/packages/Brewfile` の `brew "pre-commit"` を誤削除 | Non-Goal 明記、grep 時は単語境界 (`\bprek\b`) を使用 |

## Critical Files

新規:

- `lefthook.yml`
- `package.json`
- `pnpm-lock.yaml`
- `scripts/lint/check-added-large-files.sh`
- `scripts/lint/detect-aws-credentials.sh`
- `scripts/lint/detect-private-key.sh`
- `scripts/lint/end-of-file-fixer.sh`
- `scripts/lint/mixed-line-ending.sh`
- `scripts/lint/trailing-whitespace.sh`
- `.github/workflows/lint.yml`

変更:

- `mise.toml`
- `Brewfile`
- `config/packages/Brewfile`
- `install.ps1`
- `justfile`
- `.gitignore`
- `README.md`
- `docs/README.ja.md`
- `docs/local-dev.md`
- `docs/local-dev.ja.md`
- `.cspell/project-words.txt`

削除:

- `.pre-commit-config.yaml`
- `.github/workflows/prek.yml`
