# Codex quality setup

[🇯🇵 日本語版](codex.ja.md)

## Managed files

The dotfiles installer links these files on macOS, Linux, and Windows:

- `src/.codex/AGENTS.md`: guidance for Japanese responses, implementation,
  verification, and review.
- `src/.codex/quality.config.toml`: GPT-6 Astra with Max reasoning for normal
  and Plan mode, plus live web search.

Run `./scripts/dotfiles.sh install` using the existing installation workflow.
Existing destination files are backed up under `~/.dotfiles_backup/`.
Authentication, MCP settings, project trust, and the base `~/.codex/config.toml`
remain machine-local.

## Usage

This profile was checked with Codex CLI 0.153.4. It requires access to
`gpt-6-astra` with `max` reasoning.

```bash
codex --profile quality
codex exec --profile quality "Review the current changes"
```

For the same defaults without a CLI profile, merge the four values into
`~/.codex/config.toml`.
Copy them from `quality.config.toml`, before any TOML table.
Preserve the other settings. The desktop app and IDE extension share the base
configuration; check the model picker when starting a new conversation.
Project settings and explicit CLI options can override these defaults.

Max prioritizes reasoning depth and can increase latency and usage. Ultra is
available separately for work that benefits from parallel subagents; select it
explicitly when needed. Neither setting guarantees better results on every task.
Context limits and compaction thresholds use the model defaults.

## Verification

```bash
codex --strict-config doctor --summary
```

Start `codex --profile quality` and use `/status` to inspect the runtime settings.
Check the reported model, config loading, authentication, and connectivity.
Inspect MCP warnings for missing executables. Disable obsolete servers in the
machine-local config or repair their installation before enabling them again.
Use a representative task and its tests to assess output quality.

## Daily workflow

Start with the existing GPT-6 Astra / `max` setup. Improve instructions,
completion criteria, and verification first.
Assess model or reasoning changes after collecting the results below.

### Instruction scope

Keep personal Codex preferences in `src/.codex/AGENTS.md`, installed as
`~/.codex/AGENTS.md`. Keep repository rules in [AGENTS.md](../AGENTS.md), which
`CLAUDE.md` also references through a symlink. Common workflow and verification
rules apply to both Codex and Claude Code. The delegation section applies only
to Claude Code; Codex implements assigned work directly.

Codex reads global guidance before repository guidance.
More specific project instructions can override earlier guidance. If unexpected rules apply, check for
`AGENTS.override.md` at the global and project levels. Start a new Codex session
after updating instruction files to confirm the loaded guidance.
See [the official instruction discovery rules](https://learn.chatgpt.com/docs/agent-configuration/agents-md).

### Request template

Copy this template for daily requests. Include expected inputs and outputs or a
concrete example when behavior matters. For large changes with unclear specifications, use Plan mode.
Agree on the behavior and checks before implementation. Once the plan is agreed, proceed through verification.

```text
Goal: What should improve?
Target: Relevant files, features, or errors
Constraints: Behavior to preserve and boundaries of the change
Done when: Expected behavior and required checks

Carry the work through implementation, necessary tests, verification, and diff review.
Clarify unknowns that affect the specification.
Finish by reporting changes, verification results, and anything left unverified.
```

For example, define an installer idempotency task with a test home containing an existing file.
After two installations, the destination remains the same symlink.
The backup preserves the original file. The second run creates no extra backup.
These are observable completion criteria.

### Completion checks

For this repository, include `just lint`, checks suited to the change, and a final
diff review in the completion criteria. A bug fix also needs confirmation that
the original reproduction no longer fails. Add regression coverage when the
behavior change warrants it. Documentation changes need checks of links,
documented commands, and English/Japanese consistency.

Check the final lint summary and the files actually scanned. The shared
[verification rules](../AGENTS.md#completion-and-verification-both-tools) explain
the targeted cspell check that avoids a misleading zero-file success.
The final report should name the commands or checks run, their results, and any
unverified items with reasons. Review the final diff after automatic lint fixes.

### Independent work

Keep separate objectives in separate threads. For concurrent editing, create a
worktree from the repository root:

```bash
just wt-new codex-workflow
just wt-list
```

The recipe creates a new branch and directory under `../dotfiles-worktrees/`
named `codex-workflow-<yymmdd>-<random>`. Start the corresponding thread in the
printed worktree directory. Decide which files each task owns before editing,
and coordinate any overlap when integrating changes.

### Reusable improvements

Use existing skills for routine work, such as `markdown-lint` for Markdown and
`sync-install-docs` after installer changes. When the same failure recurs, record its cause.
Use the smallest useful prevention. Add a regression test for a behavioral bug, or a script for a repeatable check.
Use a short scoped instruction for a recurring decision. Update relevant English and Japanese guidance together.

### Assess the results

For the next three to five tasks, copy this record into each task's final report
or work log. Keep actual observations; use "unrecorded" when data is missing.

```text
Task / date:
Additional correction rounds:
Missed verification items:
Follow-up exchanges until completion:
Verification results / unverified items:
Recurring cause / preventive change:
```

Count additional correction rounds after the first completion report for the
original scope. Exclude new feature requests.
Verification omissions are required checks found missing after that report.
Count each user follow-up and agent response as one exchange.
Exclude the initial request, tool calls, and progress updates.
If later corrections occur, update the same task record.

Compare tasks of similar scope with recent recorded work. If there is no earlier
record, use the first few tasks as a baseline.
Success means fewer correction rounds, verification omissions, and exchanges.
The behavior and verification criteria must still be met.
Decide whether to adjust the model or reasoning level after reviewing these observations.
The workflow's effect has not yet been measured.

## Official references

- [Instruction scope and discovery](https://learn.chatgpt.com/docs/agent-configuration/agents-md)
- [Models and reasoning effort](https://learn.chatgpt.com/docs/models)
- [Configuration profiles](https://learn.chatgpt.com/docs/config-file/config-advanced#profiles)
- [Practical setup and verification](https://learn.chatgpt.com/guides/best-practices)
