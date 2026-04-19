# ref-version-files Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `mise.toml` を tool version の SoT に集約する。`.python-version` / `.terraform-version` を削除し、GitHub Actions terraform workflow を `jdx/mise-action` 経由に移行する。

**Architecture:** ルート `mise.toml` の `[tools]` テーブルに python を追記する。これにより 4 ツール (python / terraform / trivy / biome) の唯一の宣言場所となる。CI も同 SoT を使うよう terraform workflow に `jdx/mise-action@v4.0.1` を追加する。`hashicorp/setup-terraform` および `.terraform-version` を `cat` する step は削除する。dead env の `TF_VERSION` と未参照の `AWS_ACCOUNT_ID` export も同時に撤去する。anyenv 自体の廃止は `ref-anyenv-removal` で別 spec として扱い、本 plan の scope 外とする。

**Tech Stack:** mise (`mise.toml`) / GitHub Actions (`jdx/mise-action@v4.0.1`) / bash / Terraform 1.14.8 / Python 3.13.0

**Spec:** `docs/superpowers/specs/2026-04-19-ref-version-files-design.md`

---

## File Structure

| Path | 操作 | 責務 |
| --- | --- | --- |
| `mise.toml` | Modify | tool version の SoT。python を追加 |
| `.python-version` | Delete | 二重管理解消 |
| `.terraform-version` | Delete | 二重管理解消 |
| `.github/workflows/terraform.yml` | Modify | mise 経由で terraform install するよう書き換え |
| `.cspell/project-words.txt` | Modify (条件付き) | 削除ファイル名に紐づく辞書語があれば除去 |
| `docs/**/*.md` | Modify (条件付き) | `.python-version` / `.terraform-version` 言及があれば更新 |

---

## Task 1: `mise.toml` に Python を追加

**Files:**

- Modify: `mise.toml`

- [ ] **Step 1.1: 現状の `mise.toml` を読む**

Run: `cat mise.toml`

Expected:

```toml
[tools]
terraform = "1.14.8"
trivy = "0.69.3"
biome = "2.3.11"
```

- [ ] **Step 1.2: `python = "3.13.0"` を `[tools]` の先頭行に追記**

Edit `mise.toml` so it becomes exactly:

```toml
[tools]
python = "3.13.0"
terraform = "1.14.8"
trivy = "0.69.3"
biome = "2.3.11"
```

- [ ] **Step 1.3: 検証 — mise install が通る**

Run: `mise install`

Expected: 全ツール install 済み or 新規 install。エラーなし。

Run: `mise current`

Expected output (順不同):

```text
biome     2.3.11
python    3.13.0
terraform 1.14.8
trivy     0.69.3
```

- [ ] **Step 1.4: 検証 — python が解決される**

Run: `python --version`

Expected: `Python 3.13.0`

- [ ] **Step 1.5: lint 回帰確認**

Run: `just lint`

Expected: 全 hook PASS。`mise.toml` を biome / cspell が触るが既存と同等。

- [ ] **Step 1.6: Commit**

```bash
git add mise.toml
git commit -m "🔧 mise.toml に Python を集約

.python-version と二重管理になっていた Python 3.13.0 を
mise.toml に追記。次タスクで .python-version を削除する。"
```

---

## Task 2: `.python-version` / `.terraform-version` を削除

**Files:**

- Delete: `.python-version`
- Delete: `.terraform-version`

- [ ] **Step 2.1: 削除前の事前確認 — mise が両方解決できる**

Run: `mise current python terraform`

Expected:

```text
python    3.13.0
terraform 1.14.8
```

- [ ] **Step 2.2: ファイル削除**

```bash
git rm .python-version .terraform-version
```

Expected: 両 file が staged 削除状態。

- [ ] **Step 2.3: 検証 — mise が引き続き解決する (fallback がないこと)**

Run: `mise current python terraform`

Expected:

```text
python    3.13.0
terraform 1.14.8
```

Run: `python --version && terraform version | head -1`

Expected:

```text
Python 3.13.0
Terraform v1.14.8
```

- [ ] **Step 2.4: anyenv.sh が skip する確認 (dry-run)**

Run: `DRY_RUN=true bash scripts/installers/anyenv.sh 2>&1 | grep -A1 -i 'python'`

Expected: `Installing pyenv...` までは出る。`.python-version` 不在のため `pyenv install` の log は出ない。`if [[ -f "$python_version_file" ]]` で skip される。

- [ ] **Step 2.5: lint 回帰確認**

Run: `just lint`

Expected: 全 hook PASS。

- [ ] **Step 2.6: Commit**

```bash
git commit -m "🗑️ .python-version / .terraform-version を削除（mise.toml に集約）

tool version の single source of truth を mise.toml に統一。
anyenv.sh の install_python_env は .python-version 不在時に
自然 skip するため暫定対応は不要（anyenv 自体の廃止は
ref-anyenv-removal で別途対応）。"
```

---

## Task 3: GitHub Actions terraform workflow を mise 化

**Files:**

- Modify: `.github/workflows/terraform.yml:22-61`

このタスクで 3 箇所を変更する。

1. `env.TF_VERSION` 削除 (24 行目、dead code、drift 元)
2. `Get current Terraform version` step 削除 (52-56 行目)。`AWS_ACCOUNT_ID` export も dead code なので同時削除
3. `Setup Terraform` step を `Setup mise` に置換 (38-39 行目の Checkout 直後に配置)

- [ ] **Step 3.1: dead code の最終確認**

Run: `rg -n 'TF_VERSION|AWS_ACCOUNT_ID' .github`

Expected: `terraform.yml:24` の `TF_VERSION:` 定義と `terraform.yml:55` の `echo "AWS_ACCOUNT_ID=..."` のみ。他に **参照なし**。

両方とも環境変数を定義 / 出力するだけです。後続 step がどこも `${{ env.TF_VERSION }}` / `${{ env.AWS_ACCOUNT_ID }}` を読まないことを目視確認します。

- [ ] **Step 3.2: `env.TF_VERSION` を削除**

Edit `.github/workflows/terraform.yml`. 22-25 行目を:

```yaml
env:
  WORKING_DIRECTORY: infra/terraform/envs/prod/dns
  TF_VERSION: '1.14.3'
  AWS_REGION: ap-northeast-1
```

から:

```yaml
env:
  WORKING_DIRECTORY: infra/terraform/envs/prod/dns
  AWS_REGION: ap-northeast-1
```

に変更 (`TF_VERSION` 行を削除)。

- [ ] **Step 3.3: `Get current Terraform version` step を削除**

52-56 行目の以下 step 全体を削除:

```yaml
      # Setup Terraform
      - name: Get current Terraform version
        run: |
          echo "TERRAFORM_VERSION=$(cat .terraform-version)" >> $GITHUB_ENV
          echo "AWS_ACCOUNT_ID=${{ env.AWS_ACCOUNT_ID }}" >> $GITHUB_ENV
        shell: bash
```

- [ ] **Step 3.4: `Setup Terraform` step を削除**

58-61 行目の以下 step 全体を削除:

```yaml
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@5e8dbf3c6d9deaf4193ca7a8fb23f2ac83bb6c85 # v4
        with:
          terraform_version: ${{ env.TERRAFORM_VERSION }}
```

- [ ] **Step 3.5: `Setup mise` step を Checkout 直後に追加**

`Checkout` step の **直後** (`Configure AWS Credentials` の前) に以下を挿入する。Checkout の `uses:` は `actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6` です。

```yaml
      - name: Setup mise
        uses: jdx/mise-action@1648a7812b9aeae629881980618f079932869151 # v4.0.1
        with:
          cache: true
```

- [ ] **Step 3.6: 変更後の workflow 全体を確認**

Run: `cat .github/workflows/terraform.yml`

期待される steps の並びは以下の通り。

1. Checkout
2. Setup mise (新規)
3. Configure AWS Credentials
4. Verify AWS Credentials
5. Terraform Format Check
6. Terraform Init
7. Terraform Validate
8. Cache TFLint Plugins
9. Setup TFLint
10. TFLint Init
11. TFLint Run
12. Terraform Plan
13. Comment Plan on PR
14. Start Deployment
15. Terraform Apply
16. Finish Deployment

`env:` ブロックは:

```yaml
env:
  WORKING_DIRECTORY: infra/terraform/envs/prod/dns
  AWS_REGION: ap-northeast-1
```

- [ ] **Step 3.7: ローカル lint で workflow YAML の syntax 確認**

Run: `just lint`

Expected: 全 hook PASS。prettier が YAML を formatting check し、PASS することを確認する。

- [ ] **Step 3.8: Commit**

```bash
git add .github/workflows/terraform.yml
git commit -m "👷 terraform workflow を mise-action 経由に移行

- jdx/mise-action@v4.0.1 で mise.toml の terraform バージョン
  を CI でも使うよう統一
- hashicorp/setup-terraform を削除（mise が install 担当）
- dead env TF_VERSION (drift 元) を削除
- 参照のなかった AWS_ACCOUNT_ID export も同時に撤去"
```

---

## Task 4: ドキュメント / 辞書整合

**Files:**

- Modify (条件付き): `docs/**/*.md`
- Modify (条件付き): `.cspell/project-words.txt`

- [ ] **Step 4.1: ドキュメントの残参照を grep**

Run: `rg -n '\.python-version|\.terraform-version' docs/ README.md AGENTS.md 2>/dev/null`

該当が **0 件** なら Step 4.2 へ skip。該当があれば各ファイルを読んで、内容に応じて以下のいずれかを行う。

- 「`mise.toml` で管理」と書き換え
- 単に削除 (古い手順の残骸の場合)
- そのまま残す (履歴 / ADR で過去の状態を説明している場合)

- [ ] **Step 4.2: cspell 辞書の不要語確認**

Run: `rg -n 'pythonversion|terraformversion|tfenv|pyenv' .cspell/project-words.txt 2>/dev/null`

該当が **0 件** なら Step 4.3 へ skip。該当があり、リポ全体 (`rg -iw '<word>' --hidden`) でも参照されない場合は削除する。

その後辞書を整列:

```bash
sort -uf .cspell/project-words.txt -o .cspell/project-words.txt
```

- [ ] **Step 4.3: lint 回帰確認**

Run: `just lint`

Expected: 全 hook PASS。

- [ ] **Step 4.4: Commit (変更があった場合のみ)**

変更がなければこの step は skip。あった場合:

```bash
git add -A docs/ README.md AGENTS.md .cspell/project-words.txt
git commit -m "📝 .python-version / .terraform-version 削除に伴うドキュメント更新"
```

---

## Task 5: PR 作成

- [ ] **Step 5.1: ブランチを push**

Run: `git push -u origin feature/ref-version-files`

Expected: push 成功。

- [ ] **Step 5.2: PR を作成**

```bash
gh pr create --title "🔧 tool version を mise.toml に集約（.python-version / .terraform-version 削除）" --body "$(cat <<'EOF'
## Summary

- `mise.toml` を tool version の single source of truth に統一
- `.python-version` / `.terraform-version` を削除
- GitHub Actions terraform workflow を `jdx/mise-action@v4.0.1` 経由に移行
- dead env `TF_VERSION` (drift 元) と未参照の `AWS_ACCOUNT_ID` export を撤去

Spec: `docs/superpowers/specs/2026-04-19-ref-version-files-design.md`
Plan: `docs/superpowers/plans/2026-04-19-ref-version-files.md`

## Test plan

- [ ] ローカルで `mise install && mise current` が python 3.13.0 / terraform 1.14.8 を返す
- [ ] `python --version` / `terraform version` がそれぞれ正しいバージョン
- [ ] `just lint` が PASS
- [ ] PR の terraform workflow が green (mise-action でインストールした terraform で fmt / validate / plan / tflint が通る)
- [ ] `DRY_RUN=true bash scripts/installers/anyenv.sh` が `.python-version` 不在で自然 skip

## Out of scope

- anyenv 自体の廃止 → `ref-anyenv-removal` で別 spec
- user-level mise 設定 (`src/.config/mise/`) の再編

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

- [ ] **Step 5.3: PR の CI 監視**

PR ページで GitHub Actions terraform workflow が green になることを確認する。失敗した場合は失敗 step の log を確認し、必要なら本 plan に修正タスクを追加して対応する。

---

## Verification Checklist (全 Task 完了後)

- [ ] `mise current` が python 3.13.0 / terraform 1.14.8 / trivy 0.69.3 / biome 2.3.11 をすべて返す
- [ ] リポジトリに `.python-version` / `.terraform-version` が存在しない (`ls .python-version .terraform-version 2>&1` で No such file)
- [ ] `mise.toml` に 4 ツール全てが宣言されている
- [ ] `.github/workflows/terraform.yml` に `hashicorp/setup-terraform` が **存在しない** (`rg 'setup-terraform' .github/workflows/`)
- [ ] `.github/workflows/terraform.yml` に `TF_VERSION` / `AWS_ACCOUNT_ID` が **存在しない**
- [ ] `.github/workflows/terraform.yml` に `jdx/mise-action@1648a7812b9aeae629881980618f079932869151` が存在
- [ ] `just lint` が PASS
- [ ] PR の terraform workflow が green
- [ ] commit が 3〜4 個 (Task 1, 2, 3, 必要なら 4) に分割されている
