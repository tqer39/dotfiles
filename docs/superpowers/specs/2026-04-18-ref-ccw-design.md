# ref-ccw: Claude Code を必ず git worktree で走らせる仕組み

- 作成日: 2026-04-18
- Topic: ref-ccw
- ブランチ: `feature/ref-ccw`

## Context

Claude Code に main ブランチ直編集をさせず、常に隔離された git worktree 上で作業させたい。現状の `ccw`（`src/.shell_common:97-109`）はプロンプトで skill を誘導する弱い強制であり、プロンプト無視や素 `claude` 起動で main が汚染されうる。

Claude Code 2.1.x に `-w, --worktree [name]` が実装済み、かつ `PreToolUse` hook で編集系ツールを deny できる。この 2 つを組み合わせれば、**起動経路が ccw でなくても書き込みを物理的に止められる**。本 spec はその最小構成を dotfiles に組み込む設計を定める。

## Goals

- `ccw [topic...]` で Claude Code が必ず新規 worktree 内で起動する
- worktree 外のセッションでは `Edit` / `Write` / `NotebookEdit` が deny される（`Bash` は素通し）
- セッション起動時は auto permission mode（素 `claude` は従来 `plan` モード）
- 設定・hook スクリプト・シェル関数すべて dotfiles で管理（symlink 配布）

## Non-Goals

- Windows PowerShell 版の提供
- managed settings による上書き不能化
- `Bash` ツールの個別コマンド deny（`git commit` 等）
- `.worktreeinclude` / `worktree.symlinkDirectories` / `worktree.sparsePaths` のカスタム設定
- worktree の自動クリーンアップ

## Design Decisions

| 決定 | 選択 |
| --- | --- |
| 既存 `ccw` の扱い | **完全置換**（プロンプト誘導方式 → `--worktree` + hook） |
| hook の deny 範囲 | **`Edit` / `Write` / `NotebookEdit` のみ**（`Bash` は素通し） |
| automode の適用範囲 | **`ccw` 起動時のみ** (`--permission-mode auto`)。素 `claude` は `settings.personal.json` の `defaultMode: "plan"` のまま |
| 対象プラットフォーム | **macOS + Linux**（`.shell_common` 経路） |
| 引数ポリシー | **引数=topic、worktree 名は Claude Code 自動命名** |
| `origin/HEAD` 同期 | **`ccw` 先頭で毎回 `git remote set-head origin -a`** |

## Architecture

```text
~/.zshrc → ~/.shell_common (symlink)
                  │
                  └── ccw()  ──► claude --permission-mode auto --worktree -- "$prompt"
                                      │
                                      ▼
                              新規 worktree 作成 + セッション開始
                                      │
                                      ▼
                  ┌─── (worktree 内) PreToolUse hook: allow
                  │
                  └─── (worktree 外) PreToolUse hook: deny Edit/Write/NotebookEdit
                                                     with 誘導メッセージ
```

### Components

#### 1. `ccw` 関数 — `src/.shell_common`

既存定義（97–109 行）を次の実装で置換する。

```bash
# Claude Code を worktree sandbox + automode で起動
# Usage: ccw [topic...]
ccw() {
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "ccw: not inside a git repository" >&2
    return 1
  fi
  if ! command -v claude >/dev/null 2>&1; then
    echo "ccw: claude command not found" >&2
    return 1
  fi

  local root
  root="$(git rev-parse --show-toplevel)"
  cd "$root" || return 1

  git remote set-head origin -a >/dev/null 2>&1 || true

  local topic="${*:-（トピックはこれから相談する）}"
  local prompt
  prompt="superpowers:using-git-worktrees スキルの Start フェーズを実行し、作成した worktree に移動してください。その worktree 内で superpowers:brainstorming スキルを起動し、次のトピックでブレストを始めてください: ${topic}"

  exec claude --permission-mode auto --worktree -- "$prompt"
}
```

注意点:

- `--worktree` に name を渡さない（自動命名）。`-- "$prompt"` の `--` は `--worktree [name]` の optional-value 解釈を打ち切り、`$prompt` を positional として確定させるため必須
- `exec` でシェル関数を抜ける
- `set-head` 失敗時は警告なしで通す（オフライン実行可）

#### 2. hook スクリプト — `src/.claude/hooks/require-worktree.sh`

新規作成（dotfiles 配下、実行ビット付き）。

```bash
#!/usr/bin/env bash
set -euo pipefail

input="$(cat)"
cwd="$(printf '%s' "$input" | jq -r '.cwd // empty')"
tool="$(printf '%s' "$input" | jq -r '.tool_name // empty')"

case "$cwd" in
  */.worktrees/*|*/.worktrees)
    exit 0
    ;;
esac

case "$tool" in
  Edit|Write|NotebookEdit)
    jq -n --arg reason "This session is not running inside a git worktree (.worktrees/*). Exit and relaunch with: ccw <topic>, or ask Claude to start a worktree before editing." '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "deny",
        permissionDecisionReason: $reason
      }
    }'
    ;;
  *)
    exit 0
    ;;
esac
```

注意点:

- `.worktrees/` のみ対象（superpowers skill のデフォルト配置）
- jq 依存（dotfiles の既存前提）
- shebang `#!/usr/bin/env bash` + `set -euo pipefail` は dotfiles の規約準拠

#### 3. `src/.claude/settings.personal.json` 差分

既存の `hooks` ブロックに `PreToolUse` 配列を追加。

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write|NotebookEdit",
        "hooks": [
          {
            "type": "command",
            "command": "$HOME/.claude/hooks/require-worktree.sh"
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "afplay /System/Library/Sounds/Glass.aiff"
          }
        ]
      }
    ]
  }
}
```

`defaultMode: "plan"` は現状維持。

#### 4. `config/platform-files.conf` 追加行

```text
.claude/hooks/require-worktree.sh:~/.claude/hooks/require-worktree.sh:macos,linux
```

既存 symlink 機構（`scripts/dotfiles.sh install`）で配布される。

#### 5. `CLAUDE.md` 追記（補助）

```md
## Worktree Workflow

- 実装を伴う作業では `ccw <topic>` で Claude Code を起動すること
- `.worktrees/` 外のセッションでは Edit/Write/NotebookEdit が deny される（hook による保護）
- 素 `claude` で起動した場合、編集したくなったら `ccw` で切り直すか、セッション中に worktree の作成を依頼する
```

## Data Flow

### ccw 起動時

```text
user $ ccw "ref-ccw ブレスト"
  └─ git remote set-head origin -a   (100–500ms)
  └─ exec claude --permission-mode auto --worktree -- "…topic…"
       └─ Claude Code: worktree 作成 (origin/HEAD 基準)
       └─ Claude Code: worktree cwd でセッション開始 (auto mode)
       └─ Claude: skill Start フェーズ → brainstorming
```

### 素 claude での誤起動時

```text
user $ claude  # repo root
  └─ Claude Code: cwd = repo root (NOT .worktrees/*)
       └─ Claude: Edit を試行
            └─ PreToolUse → require-worktree.sh → deny
                 └─ Claude は救済メッセージを受け、ユーザーに ccw 再起動を促す or
                    セッション中に worktree 作成を依頼
```

## Error Handling

| シナリオ | 挙動 |
| --- | --- |
| `ccw` を非 git ディレクトリで実行 | 標準エラー + `return 1` |
| `claude` コマンド未導入 | 標準エラー + `return 1` |
| `git remote set-head` が失敗（オフライン等） | 警告なし続行（`\|\| true`） |
| hook 内 jq 失敗 | `set -euo pipefail` で非 0 終了 → Claude Code は hook エラーを表示、tool 呼び出しは安全側で中断 |
| `~/.claude/hooks/` 未作成（初回） | platform-files.conf に基づき `dotfiles.sh install` が symlink 作成時に親ディレクトリを自動作成 |

## Testing

### ユニットレベル

- `shellcheck src/.shell_common` — ccw 定義が通ること（既存 `just lint` に含まれる）
- `shellcheck src/.claude/hooks/require-worktree.sh` — 新規追加ファイルも通ること

### 結合

1. `./scripts/dotfiles.sh install` を実行し、`~/.claude/hooks/require-worktree.sh` が symlink されること
2. repo root で `claude` 起動 → `Edit` 試行 → `deny` 応答とメッセージ表示を目視確認
3. `ccw "テスト"` 起動 → 新規 worktree 作成 + auto mode + 編集可能を確認
4. 新規 worktree 内で `Edit` 試行 → 通ること

### ベースライン

`just lint` 成功（実行済み、全 13 チェック通過）

## Implementation Order

1. `src/.claude/hooks/require-worktree.sh` 新規作成 + chmod +x
2. `config/platform-files.conf` に symlink エントリ追加
3. `src/.claude/settings.personal.json` に `PreToolUse` 追加
4. `src/.shell_common` の `ccw` 定義置換
5. `CLAUDE.md` に Worktree Workflow セクション追記
6. `./scripts/dotfiles.sh install` 実行 → 結合テスト
7. `just lint` 再実行

## Critical Files

- `src/.shell_common` — 既存 `ccw` 置換
- `src/.claude/hooks/require-worktree.sh` — 新規
- `src/.claude/settings.personal.json` — `PreToolUse` 追加
- `config/platform-files.conf` — symlink エントリ追加
- `CLAUDE.md` — 運用ルール追記

## References

- `claude --help` → `-w, --worktree [name]`, `--permission-mode auto`（v2.1.113 で確認）
- Claude Code docs — Hooks reference の `PreToolUse.permissionDecision`
- `superpowers:using-git-worktrees` skill（本 worktree 作成に使用）
- 既存の `hooks.Stop` 実装（`src/.claude/settings.personal.json`）
