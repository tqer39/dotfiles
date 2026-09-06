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

## Official references

- [Models and reasoning effort](https://learn.chatgpt.com/docs/models)
- [Configuration profiles](https://learn.chatgpt.com/docs/config-file/config-advanced#profiles)
- [Practical setup and verification](https://learn.chatgpt.com/guides/best-practices)
