# ref-version-files: tool version を mise.toml に集約

- 作成日: 2026-04-19
- Topic: ref-version-files
- ブランチ: `feature/ref-version-files`

## Context

リポジトリ ルートに tool version を宣言するファイルが 3 つ並存している。

| ファイル | 内容 | 参照元 |
| --- | --- | --- |
| `.python-version` | `3.13.0` | `scripts/installers/anyenv.sh:108`（pyenv install） |
| `.terraform-version` | `1.14.8` | `.github/workflows/terraform.yml:54`（`cat` で env 化） |
| `mise.toml` | `terraform = "1.14.8"`, `trivy = "0.69.3"`, `biome = "2.3.11"` | mise（ローカル開発） |

`terraform = 1.14.8` は `.terraform-version` と `mise.toml` の **二重管理** で drift リスクを抱える。さらに `.github/workflows/terraform.yml:24` には `TF_VERSION: '1.14.3'` という **dead env** が残っている。実際の terraform バージョン (1.14.8) と乖離しているうえに、同 env はどこからも参照されない。

`ref-cspell` spec の Non-Goals で「`.python-version` と `mise.toml` の統合 (`ref-mise` として別 spec)」とした課題があった。これを terraform も含めた version file 全体の整合として本 spec で扱う。

## Goals

- `mise.toml` を tool version の **single source of truth** にする
- `.python-version` / `.terraform-version` を削除し、二重管理 / drift を解消する
- `.github/workflows/terraform.yml` を `jdx/mise-action` 経由に移行し、CI でも同じ SoT を使う
- dead env (`TF_VERSION: '1.14.3'`) を削除する

## Non-Goals

- **anyenv 自体の廃止**（`ref-anyenv-removal` として別 spec）
- `src/.config/mise/config.{toml,personal,work}.toml`（user-level mise 設定）の再編
- mise 以外のツール（pyenv / tfenv / asdf）への切替
- Python / Terraform 自体のバージョン アップ（純粋に統合のみ）
- `infra/terraform/**/versions.tf` の `required_version` 改修
- `setup-terraform` 以外の GH Actions 改修（`setup-tflint` 等は据え置き）

## Design Decisions

| 決定 | 選択 |
| --- | --- |
| version SoT | **`mise.toml`**（ルート） |
| `.python-version` | **削除** |
| `.terraform-version` | **削除** |
| Python の追加先 | `mise.toml` の `[tools]` に `python = "3.13.0"` を追記 |
| GH Actions terraform | **`jdx/mise-action@v2`**（commit SHA pin） |
| `setup-terraform` action | **削除**（mise 経由で install） |
| `TF_VERSION` env (terraform.yml:24) | **削除**（dead code、drift あり） |
| `Get current Terraform version` step (terraform.yml:52-56) | **削除**（mise が自動解決） |
| `AWS_ACCOUNT_ID` export 行（同 step 内） | step 削除に伴い別 step へ分離 / 不要なら削除（実装時に確認） |
| anyenv.sh の python install | **暫定対応なし**（`if -f` で自然 skip、`ref-anyenv-removal` で除去） |
| Renovate 対応 | `mise.toml` 単一 SoT のため追加設定なし（既存ルールで mise 管理対象） |
| ドキュメント / cspell 辞書 | 関連語の言及があれば実装時に grep で精査して更新 |

## Architecture

```text
.
├── mise.toml                          # SoT: python, terraform, trivy, biome
├── .python-version                    # 削除
├── .terraform-version                 # 削除
├── .github/workflows/terraform.yml    # setup-terraform → jdx/mise-action
└── scripts/installers/anyenv.sh       # 変更なし（.python-version 不在で自然 skip）
```

### `mise.toml`（変更後）

```toml
[tools]
python = "3.13.0"
terraform = "1.14.8"
trivy = "0.69.3"
biome = "2.3.11"
```

### `.github/workflows/terraform.yml` の差分要点

```yaml
env:
  WORKING_DIRECTORY: infra/terraform/envs/prod/dns
  AWS_REGION: ap-northeast-1
  # TF_VERSION: '1.14.3'  ← 削除

steps:
  - name: Checkout
    uses: actions/checkout@<sha> # v6

  - name: Setup mise
    uses: jdx/mise-action@<commit-sha> # v2.x — 実装時に最新 SHA を確定
    with:
      cache: true

  # AWS Credentials（変更なし）
  # 「Get current Terraform version」step 削除
  #   AWS_ACCOUNT_ID export が他 step で必要なら別 step に分離、不要なら削除
  # 「Setup Terraform」step 削除（mise が install 済み、PATH も解決）

  # 以降の Format / Init / Validate / TFLint / Plan / Apply は変更なし
```

## 実装手順

### Step 1: `mise.toml` に Python 追加

- `mise.toml` の `[tools]` に `python = "3.13.0"` を追記
- ローカルで `mise install` → `mise current python` が `3.13.0` を返すことを確認
- Commit: `🔧 mise.toml に Python を集約`

### Step 2: `.python-version` / `.terraform-version` 削除

- 両ファイルを `git rm`
- `mise current` が `python 3.13.0` / `terraform 1.14.8` を返すことを確認
- `python --version` / `terraform version` がそれぞれ正しい version を返すことを確認
- Commit: `🗑️ .python-version / .terraform-version を削除（mise.toml に集約）`

### Step 3: GitHub Actions terraform.yml を mise 化

- `env.TF_VERSION` を削除
- `Get current Terraform version` step を削除（`AWS_ACCOUNT_ID` export を別 step に分離 or 不要確認）
- `Setup Terraform`（`hashicorp/setup-terraform`）を削除
- `Checkout` の直後に `jdx/mise-action@<commit-sha>` を追加（`cache: true`）
- Commit: `👷 terraform workflow を mise-action 経由に移行`

### Step 4: ドキュメント / 辞書整合

- `rg -w '\.python-version|\.terraform-version'` で残参照を確認、ドキュメントの言及を更新
- `.cspell/project-words.txt` に不要語があれば削除
- Commit: `📝 .python-version / .terraform-version 削除に伴うドキュメント更新`

### Step 5: PR

- title: `🔧 tool version を mise.toml に集約（.python-version / .terraform-version 削除）`
- base: `main`, branch: `feature/ref-version-files`

## 検証

```bash
# 1. ローカル: mise が正しく解決
mise install
mise current                            # python 3.13.0 / terraform 1.14.8 / trivy / biome

# 2. python / terraform が PATH 解決される
python --version                        # Python 3.13.0
terraform version                       # Terraform v1.14.8

# 3. lint / hook 回帰
just lint                               # 全 hook pass

# 4. CI: terraform workflow を PR で実行
#    - mise-action が cache hit / install 成功
#    - terraform fmt / validate / plan / tflint が現状同等に pass

# 5. anyenv.sh の skip 確認（python install が走らないこと）
DRY_RUN=true bash scripts/installers/anyenv.sh
```

## ロールバック

`git revert` のみで原状復帰可能。`.python-version` / `.terraform-version` を復元する。`terraform.yml` の旧 step (`Get current Terraform version` + `Setup Terraform`) と `TF_VERSION` env を戻すだけ。`jdx/mise-action` 追加も同 commit に含まれるため副作用なし。

## リスク

| リスク | 影響 | 緩和策 |
| --- | --- | --- |
| `jdx/mise-action` の cache miss / install 失敗 | CI 落ちる | Step 3 を PR で先に走らせ、main マージ前に green を確認 |
| anyenv 使用中の他環境で `.python-version` 喪失による pyenv install スキップ | 新規セットアップで Python が入らない | `ref-anyenv-removal` で mise 経由に切替予定。暫定は `mise install` で代替 |
| `terraform fmt`/`validate` の実行 path が mise PATH に依存 | mise-action 後で PATH が通らない | `jdx/mise-action` は `GITHUB_PATH` を更新するため後続 step で透過 |
| `infra/terraform/**/versions.tf` の `required_version` 制約と乖離 | provider / terraform エラー | Non-Goal だが Step 3 検証で plan が pass することを確認 |
| `AWS_ACCOUNT_ID` export 行が他 step で必要だった場合の喪失 | apply / plan が `AWS_ACCOUNT_ID` 未定義で失敗 | Step 3 で grep で全参照を確認、必要なら別 step に分離 |

## Critical Files

- `mise.toml`（変更）
- `.python-version`（削除）
- `.terraform-version`（削除）
- `.github/workflows/terraform.yml`（変更）
- `scripts/installers/anyenv.sh`（**変更なし**、`.python-version` 不在で自然 skip）
- `.cspell/project-words.txt`（必要に応じて削除）
