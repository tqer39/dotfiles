#!/usr/bin/env bash
# Append a trailing newline if the file does not already end with one. Modifies in place.
set -euo pipefail

for f in "$@"; do
  [[ -f "$f" ]] || continue
  # symlink は実体を別途 lint するのでスキップする。
  # 追記は symlink を辿って staged でない実体を書き換えてしまうため。
  [[ ! -L "$f" ]] || continue
  grep -Iq . "$f" || continue
  if [[ -n "$(tail -c 1 "$f")" ]]; then
    printf '\n' >>"$f"
  fi
done
