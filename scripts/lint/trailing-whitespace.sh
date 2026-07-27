#!/usr/bin/env bash
# Remove trailing whitespace from text files. Modifies in place.
set -euo pipefail

for f in "$@"; do
  [[ -f "$f" ]] || continue
  grep -Iq . "$f" || continue
  # cp -p でパーミッションを引き継いでから mv で atomic に置換する。
  # truncate して書き戻すと parallel 実行中の linter が書き込み途中を読む。
  cp -p "$f" "$f.tmp"
  sed -E 's/[[:space:]]+$//' "$f" >"$f.tmp"
  mv -f "$f.tmp" "$f"
done
