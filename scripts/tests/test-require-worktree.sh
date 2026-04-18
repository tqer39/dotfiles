#!/usr/bin/env bash
set -euo pipefail

# Usage: scripts/tests/test-require-worktree.sh
# Tests src/.claude/hooks/require-worktree.sh via canned stdin JSON.

HOOK="$(cd "$(dirname "$0")/../.." && pwd)/src/.claude/hooks/require-worktree.sh"
readonly HOOK

if [[ ! -x "$HOOK" ]]; then
  echo "FAIL: hook script not executable at $HOOK" >&2
  exit 1
fi

fail_count=0

assert_allow() {
  local label="$1" input="$2"
  local output rc
  output="$(printf '%s' "$input" | "$HOOK" 2>&1)" && rc=0 || rc=$?
  if [[ $rc -ne 0 ]]; then
    echo "FAIL [$label]: expected exit 0, got $rc (output: $output)" >&2
    fail_count=$((fail_count + 1))
    return
  fi
  if [[ -n "$output" ]]; then
    echo "FAIL [$label]: expected empty output, got: $output" >&2
    fail_count=$((fail_count + 1))
    return
  fi
  echo "PASS [$label]"
}

assert_deny() {
  local label="$1" input="$2"
  local output rc decision
  output="$(printf '%s' "$input" | "$HOOK")" && rc=0 || rc=$?
  if [[ $rc -ne 0 ]]; then
    echo "FAIL [$label]: expected exit 0, got $rc" >&2
    fail_count=$((fail_count + 1))
    return
  fi
  decision="$(printf '%s' "$output" | jq -r '.hookSpecificOutput.permissionDecision // empty')"
  if [[ "$decision" != "deny" ]]; then
    echo "FAIL [$label]: expected permissionDecision=deny, got: $decision (output: $output)" >&2
    fail_count=$((fail_count + 1))
    return
  fi
  echo "PASS [$label]"
}

# Case 1: cwd inside worktree + Edit → allow
assert_allow "inside-worktree-edit" \
  '{"cwd":"/Users/me/project/.worktrees/foo","tool_name":"Edit"}'

# Case 2: cwd outside worktree + Edit → deny
assert_deny "outside-edit" \
  '{"cwd":"/Users/me/project","tool_name":"Edit"}'

# Case 3: cwd outside worktree + Write → deny
assert_deny "outside-write" \
  '{"cwd":"/Users/me/project","tool_name":"Write"}'

# Case 4: cwd outside worktree + NotebookEdit → deny
assert_deny "outside-notebook-edit" \
  '{"cwd":"/Users/me/project","tool_name":"NotebookEdit"}'

# Case 5: cwd outside worktree + Bash → allow (Bash は素通し)
assert_allow "outside-bash" \
  '{"cwd":"/Users/me/project","tool_name":"Bash"}'

# Case 6: cwd outside worktree + Read → allow
assert_allow "outside-read" \
  '{"cwd":"/Users/me/project","tool_name":"Read"}'

if [[ $fail_count -gt 0 ]]; then
  echo "$fail_count test(s) failed" >&2
  exit 1
fi
echo "All tests passed"
