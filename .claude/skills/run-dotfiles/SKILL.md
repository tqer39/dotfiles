---
name: run-dotfiles
description: この dotfiles リポジトリを実際に実行・検証する。install / uninstall / status / doctor の動作確認、symlink が正しく張られるかの確認、macOS / Ubuntu / Windows のプラットフォーム分岐の検証に使う。「dotfiles を実行して」「install.sh を試して」「symlink を確認して」「run the dotfiles」「test the installer」等で起動。
---

# run-dotfiles

このリポジトリの「アプリ」は `scripts/dotfiles.sh` と `install.sh` — 実 `$HOME` に
symlink を張るインストーラ。**素で実行すると開発機の dotfiles を書き換えてしまう。**

そのため driver 経由でのみ実行する。driver は `HOME` を使い捨てサンドボックスに
向けて全コマンドを実行する。リポジトリのコードは `expand_path` / `BACKUP_DIR` /
`create_symlink` / `doctor` すべてが `$HOME` 参照なので、`HOME` の差し替えだけで
完全なサンドボックスになる。

パスはすべてリポジトリルートからの相対。

## Prerequisites

macOS では追加インストール不要（bash / git / find のみ使用）。
lint を回す場合のみ `just` と `pnpm install` が必要。

## Run (agent path)

```bash
.claude/skills/run-dotfiles/driver.sh smoke
```

これが主経路。まっさらなサンドボックスに対して
status → install → symlink 検証 → 再 install（冪等性）→ uninstall → 削除検証
を通しで実行し、各ステップで assert する。最後に `smoke PASSED` が出れば成功。

個別コマンド:

```bash
.claude/skills/run-dotfiles/driver.sh status       # dotfiles.sh status
.claude/skills/run-dotfiles/driver.sh install      # dotfiles.sh install
.claude/skills/run-dotfiles/driver.sh uninstall    # dotfiles.sh uninstall
.claude/skills/run-dotfiles/driver.sh doctor       # dotfiles.sh doctor
.claude/skills/run-dotfiles/driver.sh links        # サンドボックス内の symlink 一覧
.claude/skills/run-dotfiles/driver.sh clean        # サンドボックス削除
```

トップレベルの `install.sh` を叩く場合（`--ci` は driver が常に付与する）:

```bash
.claude/skills/run-dotfiles/driver.sh install-sh --dry-run --verbose
.claude/skills/run-dotfiles/driver.sh install-sh --minimal
```

### プラットフォーム分岐の検証

`config/platform-files.conf` を触ったら macOS だけでなく 3 プラットフォーム全部を回す:

```bash
.claude/skills/run-dotfiles/driver.sh matrix
```

macos / ubuntu / windows それぞれで `smoke` を実行する（`DOTFILES_OS_OVERRIDE` を
使うので Mac 1 台で全分岐を通せる）。`matrix PASSED` で成功。

単一プラットフォームだけなら:

```bash
DOTFILES_OS_OVERRIDE=ubuntu .claude/skills/run-dotfiles/driver.sh smoke
```

### personal / work モード

```bash
DOTFILES_MODE=work .claude/skills/run-dotfiles/driver.sh install
```

`src/.claude/settings.work.json` 側がリンクされることを確認できる（既定は `personal`）。

### 環境変数

| 変数 | 意味 |
| --- | --- |
| `SANDBOX_HOME` | サンドボックス HOME（既定 `/tmp/dotfiles-sandbox/home`） |
| `DOTFILES_OS_OVERRIDE` | `macos` / `ubuntu` / `mint` / `linux` / `windows` |
| `DOTFILES_MODE` | `personal`（既定）/ `work` |
| `LOG_LEVEL` | `DEBUG` で詳細ログ |

## Run (human path)

実機に本当に入れる場合のみ:

```bash
./scripts/dotfiles.sh install
```

**エージェントはこれを実行しないこと。** 実 `$HOME` の既存ファイルを
`~/.dotfiles_backup/` に退避した上で symlink に置き換える。検証目的なら
上の driver で足りる。

## Test

このリポジトリにユニットテストは無い。実質のテストは `smoke` / `matrix` と lint:

```bash
just lint          # lefthook 経由で shellcheck / markdownlint / textlint / cspell 等
shellcheck .claude/skills/run-dotfiles/driver.sh
```

CI（`.github/workflows/test-install.yml`）は runner の実 HOME に対して
`bash install.sh --minimal --ci` を流している。ローカルで同じことをしてはいけない。

## Gotchas

実際に踏んだもののみ記載。

- **`HOME=... cmd` のインラインプレフィックスは worktree セッションでは弾かれる。**
  ハーネスが「HOME を差し替える git 設定注入」とみなして実行を拒否する。
  サンドボックス化をスクリプトファイル内に閉じ込めている理由がこれ。
  driver 経由なら通る。

- **`--ci` を付けないと `install.sh` が作業ツリーに `git pull` を打つ。**
  さらに未コミット変更があれば **勝手に `git stash push` する**
  (`install.sh:387-393`)。driver の `install-sh` は常に `--ci` を付けてこれを止める。
  なお `--dry-run` は `--ci` より先に評価されるので、dry-run 時は
 「Would run: git pull」と出るが実際には走らない。

- **サンドボックスでは mise が untrusted な設定を踏みやすい。** trust 情報は
  `$HOME` 配下に記録されるので、使い捨て HOME には何も trust されていない。
  さらに **mise の trust は「読み込んだパス」基準で symlink の実体側ではない**
  ため、`install` 後にサンドボックスの `~/.config/mise/config.toml`
  (リポジトリへの symlink) を trust するにはサンドボックス側のパスを指定する
  必要がある。driver はこれを `trust_mise_configs()` で処理し、あわせて CWD を
  サンドボックスに移して上位ディレクトリの `mise.toml` を拾わないようにしている。

  かつてはこれが原因で `doctor` が Language Runtimes の途中で落ちていたが、
  #482 で修正済み。現在は回避策なしでも完走する (WARN が出るだけ)。
  driver 側の処理は出力を綺麗に保つために残している。

- **`DOTFILES_OS_OVERRIDE=windows` を使うなら `APPDATA` も設定すること。**
  `get_vscode_user_dir()` の windows 分岐は `APPDATA` を見る。#484 で未設定時は
  `${HOME}/AppData/Roaming` に落ちるようになったため HOME 外には出ないが、
  実 Windows と同じパスを再現したいなら明示的に設定する。
  driver はサンドボックス内に `APPDATA` を設定済み。

- **`Installed: N, Skipped: M` のカウントは `platform-files.conf` の行だけ。**
  Claude Code 設定と Codex skills の symlink は別途張られるがこのカウントに入らない。
  macOS では `Installed: 26` と出るが実際の symlink は 35 本
 （26 + Claude Code 設定 3 + Codex skills 6）。実数は `driver.sh links` で数えること。

- **`brew bundle` に環境変数を渡すには `HOMEBREW_` 接頭辞が要る。**
  Homebrew は Brewfile を評価する前に接頭辞のない環境変数を除去するため、
  `WORK_MODE` を export しても Brewfile 側の `ENV['WORK_MODE']` は nil になる。
  work/personal の切り替えを確認するときは `HOMEBREW_WORK_MODE` を見ること
 （`scripts/installers/homebrew.sh` の `export_brew_work_mode()` が変換する）。
  確認は `HOMEBREW_WORK_MODE=true brew bundle list --file=config/packages/Brewfile --casks`。

- **このスキル自体が `~/.codex/skills/run-dotfiles` に symlink される。**
  `list_claude_skill_dirs()` が `.claude/skills/*/SKILL.md` を拾うため。
  `status` / `doctor` の CODEX SKILLS セクションに増えるのは正常。

### 修正済み（このスキルの調査で見つかったもの）

以前ここに記載していた以下は main で修正済み。再発時の参照用に残す。

| 症状 | 修正 |
| --- | --- |
| `doctor` が mise の失敗で summary を出さず exit 1 | #482 |
| `ln` 失敗時に `[SUCCESS]` と嘘のログ | #483 |
| `APPDATA` 未設定で symlink が `/` 直下へ | #484 |
| `uninstall` がバックアップを復元しない | #485 |
| `just lint` が `CLAUDE.md` の symlink を破壊 | #486 |
| `just lint` が `pnpm-lock.yaml` を整形して staged 化 | #487 |
| `--work` が personal パッケージを除外できていない | #488 |

## Troubleshooting

| 症状 | 原因 / 対処 |
| --- | --- |
| `Refusing to run it — ... sets HOME` | ハーネスの worktree ガード。`HOME=` を直接書かず driver を使う |
| `mise ERROR ... are not trusted` | サンドボックス HOME に trust 情報が無い。driver の `doctor` が `mise trust` を先に打つ |
| `command_exists: command not found` | `install.sh --dry-run` は lib を source しないため `homebrew.sh` で出る既知の警告。処理は継続する |
| サンドボックスが壊れた | `.claude/skills/run-dotfiles/driver.sh clean` で作り直す |
| `REFUSING: SANDBOX_HOME ... is unsafe` | `SANDBOX_HOME` が実 HOME を指している。安全装置なので指定を直す |
