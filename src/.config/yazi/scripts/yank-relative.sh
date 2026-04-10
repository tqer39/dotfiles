#!/usr/bin/env bash
# yank-relative.sh — copy a git-root-relative path to the system clipboard.
#
# Called from yazi keymap. The argument is yazi's hovered entry (%h).
# If the entry lives inside a git working tree, the path is made relative to
# the repository root; otherwise the absolute path is copied as a fallback.
#
# Clipboard backend is picked in this order: pbcopy (macOS), wl-copy (Wayland),
# xclip / xsel (X11), clip.exe (WSL).

set -euo pipefail

target="${1:-}"
if [[ -z "${target}" ]]; then
  exit 0
fi

lookup_dir="${target}"
if [[ ! -d "${lookup_dir}" ]]; then
  lookup_dir="$(dirname "${lookup_dir}")"
fi

git_root=""
if git_root="$(git -C "${lookup_dir}" rev-parse --show-toplevel 2>/dev/null)"; then
  abs_target="$(cd "$(dirname "${target}")" && printf '%s/%s' "$(pwd -P)" "$(basename "${target}")")"
  relative_path="${abs_target#"${git_root}"/}"
  if [[ "${relative_path}" == "${abs_target}" ]]; then
    relative_path="${abs_target}"
  fi
else
  relative_path="${target}"
fi

copy_to_clipboard() {
  local payload="$1"
  if command -v pbcopy >/dev/null 2>&1; then
    printf '%s' "${payload}" | pbcopy
  elif command -v wl-copy >/dev/null 2>&1; then
    printf '%s' "${payload}" | wl-copy
  elif command -v xclip >/dev/null 2>&1; then
    printf '%s' "${payload}" | xclip -selection clipboard
  elif command -v xsel >/dev/null 2>&1; then
    printf '%s' "${payload}" | xsel --clipboard --input
  elif command -v clip.exe >/dev/null 2>&1; then
    printf '%s' "${payload}" | clip.exe
  else
    printf 'yank-relative: no clipboard backend found\n' >&2
    return 1
  fi
}

copy_to_clipboard "${relative_path}"
