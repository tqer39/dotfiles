# ref-lefthook Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** lint 基盤を `prek` + `.pre-commit-config.yaml` から `lefthook` + `lefthook.yml` に置換し、Node 依存を `pnpm` で pin する。

**Architecture:** `terraform-github` リポと同じ構成を採用する。`parallel: true` と `{staged_files}` で commit を高速化する。`lefthook` / `pnpm` は `mise` で版固定する。CI は `prek.yml` を `lint.yml` に置換する。

**Tech Stack:**

- lefthook 1.8.4 / pnpm 10.33.0
- cspell 10 / markdownlint-cli2 0.22 / prettier 3.1 / textlint 15.5 / biome 1.9
- shellcheck (system) / GitHub Actions (mise-action)

**Spec:** `docs/superpowers/specs/2026-04-19-ref-lefthook-design.md`

---

## File Structure

新規 (10 ファイル):

- `lefthook.yml` — hook 定義 (parallel)
- `package.json` — Node devDeps 宣言 (pnpm)
- `pnpm-lock.yaml` — `pnpm install` で生成
- `scripts/lint/check-added-large-files.sh`
- `scripts/lint/detect-aws-credentials.sh`
- `scripts/lint/detect-private-key.sh`
- `scripts/lint/end-of-file-fixer.sh`
- `scripts/lint/mixed-line-ending.sh`
- `scripts/lint/trailing-whitespace.sh`
- `.github/workflows/lint.yml` — mise + pnpm + lefthook

変更:

- `mise.toml` — `lefthook`, `pnpm` 追加
- `Brewfile` (root) — `prek` 削除
- `config/packages/Brewfile` — `prek` 削除 (`pre-commit` は据え置き)
- `install.ps1` — scoop の `prek` 削除
- `justfile` — `prek` → `lefthook`、`setup-node` 追加
- `.gitignore` — `node_modules/`, `.lefthook/` 追加
- `.cspell/project-words.txt` — `lefthook` / `prettier` 等を必要に応じ追加
- `README.md` / `docs/README.ja.md` — バッジ URL を `prek.yml` → `lint.yml`
- `docs/local-dev.md` / `docs/local-dev.ja.md` — `prek` を `lefthook` に

削除:

- `.pre-commit-config.yaml`
- `.github/workflows/prek.yml`

---

## Task 1: ブランチ作成

**Files:** N/A (git のみ)

- [ ] **Step 1: 現在のブランチを確認**

```bash
git status
git branch --show-current
```

Expected: clean, ブランチ名は worktree 名。

- [ ] **Step 2: feature ブランチを切る (worktree 内のため必要なら名前変更だけ)**

```bash
# worktree の現行ブランチを feature/ref-lefthook にリネーム (推奨)
git branch -m feature/ref-lefthook
git branch --show-current
```

Expected: `feature/ref-lefthook`

---

## Task 2: scripts/lint/*.sh を作成 (セーフティ系 hook 6 本)

**Files:**

- Create: `scripts/lint/check-added-large-files.sh`
- Create: `scripts/lint/detect-aws-credentials.sh`
- Create: `scripts/lint/detect-private-key.sh`
- Create: `scripts/lint/end-of-file-fixer.sh`
- Create: `scripts/lint/mixed-line-ending.sh`
- Create: `scripts/lint/trailing-whitespace.sh`

- [ ] **Step 1: `scripts/lint/` ディレクトリ作成**

```bash
mkdir -p scripts/lint
```

- [ ] **Step 2: `check-added-large-files.sh` を作成**

```bash
cat > scripts/lint/check-added-large-files.sh <<'EOF'
#!/usr/bin/env bash
# Fail if any staged file exceeds --max-kb (default 512).
set -euo pipefail

max_kb=512
files=()
for arg in "$@"; do
  case "$arg" in
    --max-kb=*) max_kb="${arg#--max-kb=}" ;;
    *) files+=("$arg") ;;
  esac
done

exit_code=0
for f in "${files[@]}"; do
  [[ -f "$f" ]] || continue
  size_bytes=$(wc -c <"$f")
  size_kb=$(( size_bytes / 1024 ))
  if (( size_kb > max_kb )); then
    printf '%s: %d KB (exceeds %d KB)\n' "$f" "$size_kb" "$max_kb" >&2
    exit_code=1
  fi
done
exit "$exit_code"
EOF
```

- [ ] **Step 3: `detect-aws-credentials.sh` を作成**

```bash
cat > scripts/lint/detect-aws-credentials.sh <<'EOF'
#!/usr/bin/env bash
# Detect AWS Access Key IDs in staged files.
# cspell:ignore AKIA ASIA
# --allow-missing-credentials: kept for compatibility; we do not read ~/.aws.
set -euo pipefail

files=()
for arg in "$@"; do
  case "$arg" in
    --allow-missing-credentials) ;;
    *) files+=("$arg") ;;
  esac
done

exit_code=0
pattern='(AKIA|ASIA)[0-9A-Z]{16}'
for f in "${files[@]}"; do
  [[ -f "$f" ]] || continue
  if grep -En "$pattern" "$f" >/dev/null 2>&1; then
    printf '%s: possible AWS Access Key ID\n' "$f" >&2
    grep -En "$pattern" "$f" >&2 || true
    exit_code=1
  fi
done
exit "$exit_code"
EOF
```

- [ ] **Step 4: `detect-private-key.sh` を作成**

```bash
cat > scripts/lint/detect-private-key.sh <<'EOF'
#!/usr/bin/env bash
# Detect private key headers (PEM / OpenSSH).
set -euo pipefail

exit_code=0
pattern='-----BEGIN [A-Z ]*PRIVATE KEY-----'
for f in "$@"; do
  [[ -f "$f" ]] || continue
  if grep -En -e "$pattern" "$f" >/dev/null 2>&1; then
    printf '%s: private key detected\n' "$f" >&2
    exit_code=1
  fi
done
exit "$exit_code"
EOF
```

- [ ] **Step 5: `end-of-file-fixer.sh` を作成**

```bash
cat > scripts/lint/end-of-file-fixer.sh <<'EOF'
#!/usr/bin/env bash
# Append a trailing newline if the file does not already end with one. Modifies in place.
set -euo pipefail

for f in "$@"; do
  [[ -f "$f" ]] || continue
  grep -Iq . "$f" || continue
  if [[ -n "$(tail -c 1 "$f")" ]]; then
    printf '\n' >>"$f"
  fi
done
EOF
```

- [ ] **Step 6: `mixed-line-ending.sh` を作成**

```bash
cat > scripts/lint/mixed-line-ending.sh <<'EOF'
#!/usr/bin/env bash
# Normalize line endings to LF. --fix=lf is required.
set -euo pipefail

mode=""
files=()
for arg in "$@"; do
  case "$arg" in
    --fix=*) mode="${arg#--fix=}" ;;
    *) files+=("$arg") ;;
  esac
done

if [[ "$mode" != "lf" ]]; then
  echo "mixed-line-ending.sh: only --fix=lf is supported" >&2
  exit 2
fi

for f in "${files[@]}"; do
  [[ -f "$f" ]] || continue
  grep -Iq . "$f" || continue
  if grep -q $'\r' "$f"; then
    tr -d '\r' <"$f" >"$f.tmp"
    cat "$f.tmp" >"$f"
    rm -f "$f.tmp"
  fi
done
EOF
```

- [ ] **Step 7: `trailing-whitespace.sh` を作成**

```bash
cat > scripts/lint/trailing-whitespace.sh <<'EOF'
#!/usr/bin/env bash
# Remove trailing whitespace from text files. Modifies in place.
set -euo pipefail

for f in "$@"; do
  [[ -f "$f" ]] || continue
  grep -Iq . "$f" || continue
  sed -E 's/[[:space:]]+$//' "$f" >"$f.tmp"
  cat "$f.tmp" >"$f"
  rm -f "$f.tmp"
done
EOF
```

- [ ] **Step 8: 実行権限を付与**

```bash
chmod +x scripts/lint/*.sh
ls -l scripts/lint/
```

Expected: 6 ファイル全てが `-rwxr-xr-x`。

- [ ] **Step 9: shellcheck で検証**

```bash
shellcheck scripts/lint/*.sh
```

Expected: exit 0、警告なし。

- [ ] **Step 10: 動作テスト (大ファイル検出)**

```bash
# 600 KB のダミーファイル → fail
dd if=/dev/zero of=/tmp/big.bin bs=1024 count=600 2>/dev/null
./scripts/lint/check-added-large-files.sh --max-kb=512 /tmp/big.bin
echo "exit=$?"
rm -f /tmp/big.bin
```

Expected: `/tmp/big.bin: 600 KB (exceeds 512 KB)` と `exit=1`。

- [ ] **Step 11: Commit**

```bash
git add scripts/lint/
git commit -m "$(cat <<'MSG'
🔧 lefthook 用セーフティ系 lint スクリプトを追加

terraform-github と同じ pre-commit-hooks 互換実装を scripts/lint/ に追加。
lefthook から {staged_files} 引数で呼び出される前提。

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
MSG
)"
```

---

## Task 3: package.json と pnpm-lock.yaml を作成

**Files:**

- Create: `package.json`
- Create: `pnpm-lock.yaml`

- [ ] **Step 1: `pnpm` が利用可能か確認**

```bash
which pnpm || corepack enable pnpm
pnpm --version
```

Expected: 10.x が表示。なければ `mise install pnpm@10.33.0` か `npm i -g pnpm`。

- [ ] **Step 2: `package.json` を作成**

```bash
cat > package.json <<'EOF'
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
EOF
```

- [ ] **Step 3: `pnpm install` で `pnpm-lock.yaml` 生成**

```bash
pnpm install
ls pnpm-lock.yaml node_modules/.pnpm > /dev/null && echo OK
```

Expected: `pnpm-lock.yaml` 生成、`node_modules/` に依存解決済み。

- [ ] **Step 4: 各ツールが起動できることを確認**

```bash
pnpm exec cspell --version
pnpm exec markdownlint-cli2 --help >/dev/null && echo "markdownlint OK"
pnpm exec prettier --version
pnpm exec textlint --version
pnpm exec biome --version
```

Expected: それぞれバージョン表示 / OK。

- [ ] **Step 5: `.gitignore` に `node_modules/` と `.lefthook/` を追記**

末尾に追記:

```bash
cat >> .gitignore <<'EOF'

### Node ###
node_modules/

### Lefthook ###
.lefthook/
EOF
```

- [ ] **Step 6: Commit**

```bash
git add package.json pnpm-lock.yaml .gitignore
git commit -m "$(cat <<'MSG'
🔧 Node 開発依存を pnpm で固定

cspell / markdownlint-cli2 / prettier / textlint / biome / textlint プリセットを
package.json で pin。.pre-commit-config.yaml の additional_dependencies / rev から
バージョン踏襲。.gitignore に node_modules と .lefthook を追加。

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
MSG
)"
```

---

## Task 4: mise.toml に lefthook と pnpm を追加

**Files:**

- Modify: `mise.toml`

- [ ] **Step 1: `mise.toml` を更新**

```bash
cat > mise.toml <<'EOF'
[tools]
terraform = "1.14.8"
trivy = "0.69.3"
biome = "2.3.11"
lefthook = "1.8.4"
pnpm = "10.33.0"
EOF
```

- [ ] **Step 2: `mise install` を実行**

```bash
mise install
mise list | grep -E 'lefthook|pnpm'
```

Expected: `lefthook 1.8.4` と `pnpm 10.33.0` が installed。

- [ ] **Step 3: コマンドが解決できることを確認**

```bash
which lefthook && lefthook version
which pnpm && pnpm --version
```

Expected: `mise/installs/...` 配下のパス、それぞれバージョン表示。

- [ ] **Step 4: Commit**

```bash
git add mise.toml
git commit -m "$(cat <<'MSG'
🔧 mise.toml に lefthook と pnpm を追加

lefthook 1.8.4 と pnpm 10.33.0 を mise 管理下に置き、
ローカル/CI で版を統一する。

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
MSG
)"
```

---

## Task 5: lefthook.yml を作成

**Files:**

- Create: `lefthook.yml`

- [ ] **Step 1: `lefthook.yml` を作成**

```bash
cat > lefthook.yml <<'EOF'
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
      run: npx --yes --package=renovate -- renovate-config-validator {staged_files}

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
EOF
```

備考: `renovate-config-validator` は `npx --yes` で都度解決 (renovate を devDependency に入れない選択)。npx は Node に付属するため pnpm と独立に動作する。

- [ ] **Step 2: lefthook の設定検証**

```bash
lefthook validate
```

Expected: `Lefthook validation result: ✔ valid`。

- [ ] **Step 3: lefthook install で git hook を書き換え**

```bash
lefthook install
cat .git/hooks/pre-commit | head -3
```

Expected: lefthook 由来のスクリプト (`# LEFTHOOK ...`) が出力される。

- [ ] **Step 4: 全 file lint で動作確認 (gate)**

```bash
lefthook run pre-commit --all-files
```

Expected: 全 hook PASS、exit 0。失敗があれば glob/script を調整。

- [ ] **Step 5: 単独 hook で動作確認**

```bash
lefthook run pre-commit --commands cspell --all-files
lefthook run pre-commit --commands shellcheck --all-files
lefthook run pre-commit --commands markdownlint --all-files
```

Expected: それぞれ exit 0。

- [ ] **Step 6: Commit**

```bash
git add lefthook.yml
git commit -m "$(cat <<'MSG'
🔧 lefthook.yml を追加

.pre-commit-config.yaml の全 hook を parallel 実行で再現。
{staged_files} で commit 対象に限定し、auto-fix 系は stage_fixed で
re-stage する。terraform-github のパターンに準拠。

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
MSG
)"
```

---

## Task 6: justfile を lefthook ベースに書き換え

**Files:**

- Modify: `justfile`

- [ ] **Step 1: 現行 justfile の関連部分を確認**

```bash
sed -n '1,40p' justfile
```

Expected: setup 系および lint 系の各レシピが表示される。

- [ ] **Step 2: `setup` セクションを更新**

`setup: setup-mise setup-hooks` → `setup: setup-mise setup-node setup-hooks`、`setup-node` を追加。

```bash
# Edit ツール推奨。手動でも可。
```

更新後の該当ブロック (期待形):

```just
# Setup
setup: setup-mise setup-node setup-hooks
    @echo "Setup completed"

setup-mise:
    @mise install

setup-node:
    @pnpm install --frozen-lockfile

setup-hooks:
    @lefthook install
```

- [ ] **Step 3: `lint` セクションを更新**

```just
# Lint
lint:
    @lefthook run pre-commit --all-files

lint-hook hook:
    @lefthook run pre-commit --commands {{hook}} --all-files

# Clean lefthook cache
lint-clean:
    @rm -rf .lefthook
```

- [ ] **Step 4: 動作確認**

```bash
just --list | head -20
just lint
just lint-hook cspell
```

Expected: ヘルプ表示が出る。`just lint` / `just lint-hook cspell` がそれぞれ exit 0。

- [ ] **Step 5: Commit**

```bash
git add justfile
git commit -m "$(cat <<'MSG'
🔧 justfile を lefthook ベースに更新

setup → mise/node/hooks の 3 ステップ化、setup-node を追加して pnpm install。
lint / lint-hook / lint-clean を lefthook 呼び出しに差し替え。

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
MSG
)"
```

---

## Task 7: CI ワークフローを置換

**Files:**

- Create: `.github/workflows/lint.yml`
- Delete: `.github/workflows/prek.yml`

- [ ] **Step 1: `lint.yml` を作成**

```bash
cat > .github/workflows/lint.yml <<'EOF'
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
EOF
```

- [ ] **Step 2: `prek.yml` を削除**

```bash
git rm .github/workflows/prek.yml
```

- [ ] **Step 3: yamllint 相当の確認 (lefthook 経由)**

```bash
git add .github/workflows/lint.yml
lefthook run pre-commit --commands prettier-yaml --all-files
```

Expected: prettier が yaml をフォーマット (差分なし or 自動修正後 stage)。

- [ ] **Step 4: Commit**

```bash
git add .github/workflows/lint.yml .github/workflows/prek.yml
git commit -m "$(cat <<'MSG'
🔧 CI を lefthook ワークフローに置換

prek.yml を削除し lint.yml を新設。
mise + pnpm install + lefthook run pre-commit --all-files の 3 ステップ。

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
MSG
)"
```

---

## Task 8: README / docs バッジ URL とインストール手順を更新

**Files:**

- Modify: `README.md` (バッジ)
- Modify: `docs/README.ja.md` (バッジ)
- Modify: `docs/local-dev.md` (`prek` → `lefthook`)
- Modify: `docs/local-dev.ja.md` (`prek` → `lefthook`)

- [ ] **Step 1: `README.md` のバッジを差し替え**

該当行 (6 行目):

```markdown
[![Pre-commit](https://img.shields.io/github/actions/workflow/status/tqer39/dotfiles/prek.yml?branch=main&style=for-the-badge&logo=precommit&label=lint)](https://github.com/tqer39/dotfiles/actions/workflows/prek.yml)
```

を以下に置換:

```markdown
[![Lint](https://img.shields.io/github/actions/workflow/status/tqer39/dotfiles/lint.yml?branch=main&style=for-the-badge&logo=githubactions&label=lint)](https://github.com/tqer39/dotfiles/actions/workflows/lint.yml)
```

- [ ] **Step 2: `docs/README.ja.md` の同等行を差し替え**

`prek.yml` を `lint.yml` に、`Pre-commit` ラベルを `Lint` に。

- [ ] **Step 3: `docs/local-dev.md` の prek 行を更新**

該当 (26 行目):

```markdown
- prek (pre-commit hooks)
```

を以下に置換:

```markdown
- lefthook (git hooks runner, managed by mise)
- pnpm (Node tool runner, managed by mise)
```

- [ ] **Step 4: `docs/local-dev.ja.md` の prek 行を更新**

該当 (26 行目):

```markdown
- prek (pre-commit フック)
```

を以下に置換:

```markdown
- lefthook (git hooks ランナー、mise 管理)
- pnpm (Node ツールランナー、mise 管理)
```

- [ ] **Step 5: 残存 `prek` 参照を確認**

```bash
grep -rn '\bprek\b' README.md docs/ 2>/dev/null || echo "no prek references"
```

Expected: 1 件も出ないこと。残っていれば追加で修正する。

- [ ] **Step 6: Commit**

```bash
git add README.md docs/README.ja.md docs/local-dev.md docs/local-dev.ja.md
git commit -m "$(cat <<'MSG'
📝 README/docs の prek 参照を lefthook に差し替え

CI バッジを prek.yml → lint.yml に。
local-dev.{md,ja.md} の前提ツール一覧から prek を外し、lefthook と pnpm を記載。

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
MSG
)"
```

---

## Task 9: Brewfile / install.ps1 から prek を削除

**Files:**

- Modify: `Brewfile` (root)
- Modify: `config/packages/Brewfile`
- Modify: `install.ps1`

- [ ] **Step 1: root `Brewfile` から `prek` を削除**

```bash
sed -i.bak '/^brew "prek"$/d' Brewfile
diff Brewfile Brewfile.bak || true
rm Brewfile.bak
```

Expected: `brew "prek"` の 1 行が消えていること。

- [ ] **Step 2: `config/packages/Brewfile` から `prek` を削除 (`pre-commit` は据え置き)**

```bash
sed -i.bak '/^brew "prek"/d' config/packages/Brewfile
diff config/packages/Brewfile config/packages/Brewfile.bak || true
rm config/packages/Brewfile.bak
grep -n 'prek\|pre-commit' config/packages/Brewfile
```

Expected: `brew "pre-commit"` の行のみ残り、`brew "prek"` は消える。

- [ ] **Step 3: `install.ps1` の scoop 配列から `"prek",` を削除**

該当 (423 行目付近):

```powershell
"prek",
```

を削除。

```bash
sed -i.bak '/^[[:space:]]*"prek",[[:space:]]*$/d' install.ps1
diff install.ps1 install.ps1.bak || true
rm install.ps1.bak
grep -n '"prek"' install.ps1 || echo "no prek references"
```

Expected: `"prek",` が消え、grep で出力なし。

- [ ] **Step 4: 各ファイルの整合性確認**

```bash
# Brewfile が brew bundle としてパース可能 (構文チェック相当)
brew bundle list --file=Brewfile >/dev/null && echo "Brewfile OK"
brew bundle list --file=config/packages/Brewfile >/dev/null && echo "packages/Brewfile OK"

# install.ps1 構文 (pwsh があれば)
which pwsh && pwsh -NoProfile -Command "Get-Content install.ps1 | Out-Null" || echo "skip pwsh check"
```

Expected: それぞれ OK。pwsh が無ければスキップ可。

- [ ] **Step 5: Commit**

```bash
git add Brewfile config/packages/Brewfile install.ps1
git commit -m "$(cat <<'MSG'
🧹 prek を Brewfile / install.ps1 から削除

lefthook は mise 管理に移行したため、brew/scoop 経由の prek は不要。
config/packages/Brewfile の pre-commit は別ツールのため据え置き。

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
MSG
)"
```

---

## Task 10: .pre-commit-config.yaml を削除し最終回帰

**Files:**

- Delete: `.pre-commit-config.yaml`
- Modify: `.cspell/project-words.txt` (必要時)

- [ ] **Step 1: `.pre-commit-config.yaml` を削除**

```bash
git rm .pre-commit-config.yaml
```

- [ ] **Step 2: 全 hook 回帰**

```bash
just lint
```

Expected: 全 hook PASS、exit 0。`cspell` で `lefthook` / `prettier` / `pnpm` 等が unknown word として fail した場合、`.cspell/project-words.txt` に追記する。

- [ ] **Step 3: cspell 辞書追記 (Step 2 で fail した語のみ)**

例 (該当語があった場合):

```bash
# Step 2 出力の Unknown word を追記してソート整列
printf 'lefthook\npnpm\nprettier\n' >> .cspell/project-words.txt
sort -uf .cspell/project-words.txt -o .cspell/project-words.txt
just lint-hook cspell
```

Expected: cspell hook が 0 issues。

- [ ] **Step 4: staged-files モードでの動作確認 (commit シミュレーション)**

```bash
# 改行なしファイルが re-stage されるか
printf 'no newline' > test.md
git add test.md
lefthook run pre-commit --commands end-of-file-fixer
git diff --cached test.md | tail -3
git restore --staged test.md
rm test.md
```

Expected: stage 済み変更に末尾改行追加が反映されている。

- [ ] **Step 5: 最終 lint**

```bash
just lint
```

Expected: 全 hook PASS、exit 0。

- [ ] **Step 6: Commit**

```bash
git add .pre-commit-config.yaml .cspell/project-words.txt 2>/dev/null
git commit -m "$(cat <<'MSG'
🔥 .pre-commit-config.yaml を削除して lefthook 移行を完了

cspell 辞書に lefthook / pnpm / prettier 等を追記 (発生時のみ)。

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
MSG
)"
```

---

## Task 11: PR を作成

**Files:** N/A

- [ ] **Step 1: 残作業がないことを確認**

```bash
git status
grep -rn '\bprek\b' . --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=.lefthook --exclude=pnpm-lock.yaml --exclude=docs/superpowers/specs/2026-04-19-ref-cspell-design.md --exclude=docs/superpowers/specs/2026-04-19-ref-lefthook-design.md --exclude=docs/superpowers/plans/2026-04-19-ref-lefthook.md --exclude=docs/superpowers/plans/2026-04-19-ref-cspell.md --exclude=.cspell/project-words.txt 2>/dev/null || echo "no remaining prek references"
```

Expected: clean working tree。`prek` の残存は spec / plan の歴史記述と辞書のみ。

- [ ] **Step 2: ブランチを push**

```bash
git push -u origin feature/ref-lefthook
```

- [ ] **Step 3: PR を作成**

````bash
gh pr create --base main --head feature/ref-lefthook \
  --title "🔧 lint 基盤を prek から lefthook に移行" \
  --body "$(cat <<'EOF'
## Summary

- `.pre-commit-config.yaml` + `prek` を `lefthook.yml` + `lefthook` に置換
- Node 系 lint 依存を `package.json` (pnpm) で pin
- `pre-commit-hooks` 由来のセーフティ系 hook を `scripts/lint/*.sh` で自前実装
- CI: `prek.yml` → `lint.yml` (mise + pnpm + lefthook)
- `lefthook` / `pnpm` は `mise` 経由で版固定

参照リポ: `tqer39/terraform-github`

## Migration steps for local devs

```bash
mise install
pnpm install
lefthook install
```

## Test plan

- [ ] `just lint` が 0 issues で pass
- [ ] `just lint-hook cspell` 等の単独 hook 実行が pass
- [ ] commit 時に `pre-commit` が parallel 実行され auto-fix が re-stage される
- [ ] CI `lint` workflow が green

## Spec / Plan

- spec: `docs/superpowers/specs/2026-04-19-ref-lefthook-design.md`
- plan: `docs/superpowers/plans/2026-04-19-ref-lefthook.md`

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
````

Expected: PR URL が表示される。

- [ ] **Step 4: PR の CI 結果を確認**

```bash
gh pr checks
```

Expected: `lint` workflow が success。

---

## Verification (PR マージ後)

```bash
# main で再現
git checkout main && git pull
mise install
pnpm install --frozen-lockfile
lefthook install
just lint                 # → 0 issues
```

## Rollback

```bash
gh pr revert <merge-commit-sha>
# またはローカル
git revert <merge-commit-sha>
prek install              # 旧 hook を再導入
```
