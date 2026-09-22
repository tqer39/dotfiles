#!/usr/bin/env bash
set -euo pipefail

# Terminal の「コピー」メニューに Control+C を割り当てる（日本語 / 英語）。
# 他のアプリ用ショートカットは保持する。
if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This setting requires macOS." >&2
  exit 1
fi

defaults write com.apple.Terminal NSUserKeyEquivalents -dict-add \
  'コピー' '^c' \
  'Copy' '^c'

echo "Terminal copy shortcut configured. Reopen Terminal to apply."
