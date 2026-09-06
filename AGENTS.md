# AGENTS.md

[🇯🇵 日本語版](docs/AGENTS.ja.md)

Shared repository guidance for Codex and Claude Code. `CLAUDE.md` is a symlink
to this file. All sections apply to both tools except
**Implementation Delegation (Claude Code Only)**.

## Repository Purpose

This repository installs dotfiles through symlinks.
It supports macOS, Linux (Ubuntu, Linux Mint), and Windows.

## Commands

```bash
# Lint
just lint

# Dotfiles
./scripts/dotfiles.sh status
./scripts/dotfiles.sh install
./scripts/dotfiles.sh uninstall
./scripts/dotfiles.sh doctor

# Independent concurrent work (creates a new branch and worktree)
just wt-new <name>
just wt-list

# Terraform
just tf plan
just tf -chdir=prod/bootstrap apply
```

## Key Design Decisions

- **Idempotency**: Re-running is always safe
- **Backup**: Existing files are moved to `~/.dotfiles_backup/`
- **Platform filtering**: Controlled by `config/platform-files.conf`
- **Server mode**: `--server` skips desktop/GUI application installation

## Coding Guidelines

- Shell: `#!/usr/bin/env bash` with `set -euo pipefail`
- Variable/function names: snake_case
- Arithmetic: `count=$((count + 1))` (not `((count++))`)

## File Restrictions

- **Do NOT create** `.vscode/settings.json` - VS Code settings are not managed in this repository

## Shared Workflow

- Establish the goal, target files or behavior, constraints, and completion
  criteria before editing. Include concrete expected behavior or examples for
  complex changes. Read the applicable instructions and relevant code first.
- Resolve questions that affect the specification before implementing the
  dependent changes. For large, ambiguous Codex tasks, use Plan mode to agree on
  the approach first. Carry an agreed plan through implementation and verification
  without asking for the same approval again.
- Preserve unrelated user changes. Keep separate objectives in separate threads;
  use `just wt-new <name>` for concurrent editing. Assign file ownership to avoid
  overlapping changes. Coordinate file ownership when integrating worktrees.
- Reuse applicable existing skills for routine work. When a failure repeats, address its cause.
  Use a regression test, a script, or a short instruction in the relevant scope.

See [the Codex workflow guide](docs/codex.md#daily-workflow) for the request
template and a record for assessing rework.

## Completion and Verification (Both Tools)

- Confirm the requested behavior and constraints. For bug fixes, reproduce the
  original failure where feasible and verify that it no longer occurs. Add
  regression coverage for meaningful behavior changes.
- Run `just lint` and checks appropriate to the change. Review the final diff for
  regressions, missed requirements, and unrelated changes. Include automatic lint fixes.
- Report the changes, commands or checks actually run, their results, and anything
  unverified with its reason. Do not report checks as passed unless they were run.
  Required checks must pass before completion.
- **Check the files cspell actually scans.** Do not combine `--files` and
  `--gitignore` for targeted verification; this has returned success with zero
  files checked. Use `pnpm exec cspell lint --no-progress <file>` and confirm that
  `Files checked:` matches the expected count.
- Check the final `just lint` summary (✔️ or 🥊), not only individual hook output.
- Run `git fetch` before building a verification sandbox, and confirm that it
  contains the intended revision and changes. Stale checkouts have led to
  incorrect conclusions.

## Implementation Delegation (Claude Code Only)

This section applies only when Claude Code coordinates implementation through
agmsg. Codex implements its assigned work directly.
This procedure does not instruct Codex to launch or delegate to another Codex instance.

Claude Code delegates implementation to Codex CLI through agmsg.
It handles task instructions, review, verification, and PR creation.

Procedure:

```bash
# 1. dotfiles 専用の team に join (既存の family-tasks / media-server は使わない)
~/.agents/skills/agmsg/scripts/join.sh dotfiles <agent名> claude-code "$(pwd)"

# 2. Codex CLI を起動する
#    --terminal は値(テンプレート文字列)が必須。省略すると設定の既定値が使われるが、
#    既定値はエージェント名が agmsg-codex でハードコードされており、他プロジェクトの
#    Codex が動いていると agent_name_taken で失敗する。名前を明示して回避する。
~/.agents/skills/agmsg/scripts/spawn.sh codex <名前> --project "$(pwd)" \
  --terminal "herdr agent start agmsg-codex-dotfiles --split right --focus -- {cmd}"

# 3. タスクを送る
~/.agents/skills/agmsg/scripts/send.sh dotfiles <agent名> <名前> "<タスク>"

# 4. 送信前に Codex の状態を確認する
#    更新プロンプトが出ている状態で指示を送ると Enter が既定の「Update now」を
#    確定させてしまうため、先に検出する(出ていなければ exit 1 で抜ける)
if herdr wait output <pane_id> --match "Update now" --timeout 2000 >/dev/null 2>&1; then
  echo "更新プロンプトが出ている。手動で対処すること"
fi

# 5. Codex は inbox を自動で見ないので促す。/agmsg は認識しないため自然言語で送る
herdr pane run <pane_id> "agmsg の inbox を確認して、届いているタスクを実行してください。"

# 6. 完了までブロックする(ポーリング不要)
herdr wait agent-status <pane_id> --status idle --timeout 600000
```

Notes:

- **Codex does not check the inbox automatically.** Check its state in step 4 and prompt it in step 5 after every task.
- `/agmsg` is Claude Code syntax and is not recognized by Codex.
- **Use `herdr wait` to wait.** There is no need to poll `agent read`.
  Run `herdr wait agent-status <pane_id> --status idle --timeout <ms>` to wait for completion.
  It returns immediately if already idle and exits with 1 on timeout.
- Use `herdr wait output <pane_id> --match <text>` to detect specific output,
  including the update prompt. `--regex` supports regular expressions.
- **Codex can show an interactive update prompt at startup:**
  `1. Update now / 2. Skip / 3. Skip until next version`.
  Sending instructions then can select the default update, after which Codex
  prints `Please restart Codex.` and exits. Check for the prompt with
  `herdr agent read <pane_id> --source visible` before sending instructions.
- **`herdr pane run` sends text and Enter.** It cannot select TUI menu options;
  sending `2` can still confirm the default. Before sending, check `agent=codex`
  with `herdr pane list`. If the pane has returned to a shell, restart Codex with
  `herdr pane run <pane_id> codex`.
- `herdr agent read` can return empty output with the default `--source recent`,
  especially just after startup. Use `--source visible` in that case.
- Quote literal agmsg message bodies safely in shell commands. Expanding `$` or
  backticks can corrupt reports. A previous `$PATH` expansion inserted thousands
  of characters into a report.
- Codex has no Monitor, so `spawn.sh` skips the ready wait. Confirm receipt with
  `history.sh` / `inbox.sh`.
- Spawning with a custom `--terminal` leaves no placement record for
  `despawn.sh --force`. Reuse the pane or restart with
  `herdr pane run <pane_id> codex`.
- For small changes, direct implementation can be faster than this delegation
  procedure.
- **Verify Codex's report independently.** Read the diff and execute the relevant checks yourself.
  Follow the shared completion and verification requirements.

## Context Optimization

### Priority Directories (Read First)

- `scripts/` - Core shell scripts
- `config/` - Platform configuration
- `src/` - Dotfile sources

### Low Priority (Lazy Load)

- `infra/terraform/` - Only for infrastructure tasks
- `docs/adr/` - Only when making architectural decisions

## Documentation

- [docs/local-dev.md](docs/local-dev.md) - Local development setup
- [docs/architecture.md](docs/architecture.md) - Architecture details
- [docs/codex.md](docs/codex.md) - Codex setup, workflow, and request template
