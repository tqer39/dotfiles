#!/usr/bin/env bash
set -euo pipefail

# PreToolUse hook: worktree 外での Edit/Write/NotebookEdit を deny する
# Input: stdin JSON { cwd, tool_name, ... }
# Output (allow): exit 0, empty stdout
# Output (deny): exit 0, stdout = { hookSpecificOutput: {...} }

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
