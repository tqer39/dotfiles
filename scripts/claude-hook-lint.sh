#!/usr/bin/env bash
set -euo pipefail

# PostToolUse hook: Run linter on the file that was just edited/written.
# Reads JSON from stdin with tool_name and tool_input.file_path.

input=$(cat)

tool_name=$(echo "$input" | jq -r '.tool_name // empty')
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')

# Only run for Edit/Write tools
if [[ "$tool_name" != "Edit" && "$tool_name" != "Write" ]]; then
  exit 0
fi

# Skip if file_path is empty or file doesn't exist
if [[ -z "$file_path" || ! -f "$file_path" ]]; then
  exit 0
fi

extension="${file_path##*.}"

case "$extension" in
  sh)
    shellcheck "$file_path" || true
    ;;
  json)
    biome check "$file_path" || true
    ;;
  md)
    markdownlint-cli2 "$file_path" || true
    ;;
  yaml | yml)
    prettier --check "$file_path" || true
    ;;
  tf)
    terraform fmt -check "$file_path" || true
    ;;
esac

exit 0
