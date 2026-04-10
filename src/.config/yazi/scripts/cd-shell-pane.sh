#!/usr/bin/env bash
# cd-shell-pane.sh — cd the neighbouring zellij shell pane to a given path.
#
# Called from yazi keymap. The argument is yazi's hovered entry (%h).
# If it is a file, the containing directory is used instead.
#
# Requires: zellij available on PATH, invoked from inside a zellij session
# where the shell pane is to the right of the yazi pane.

set -euo pipefail

target="${1:-}"
if [[ -z "${target}" ]]; then
  exit 0
fi

if [[ ! -d "${target}" ]]; then
  target="$(dirname "${target}")"
fi

# Shell-quote the path for safe pasting into the shell pane.
printf -v quoted_target '%q' "${target}"

zellij action move-focus right
zellij action write-chars "cd ${quoted_target}"
zellij action write 13
