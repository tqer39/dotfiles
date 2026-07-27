#!/usr/bin/env bash
# Normalize line endings to LF. --fix=lf is required.
set -euo pipefail

mode=""
files=()
for arg in "$@"; do
  case "$arg" in
    --fix=*) mode="${arg#--fix=}" ;;
    *) files+=("$arg") ;;
  esac
done

if [[ "$mode" != "lf" ]]; then
  echo "mixed-line-ending.sh: only --fix=lf is supported" >&2
  exit 2
fi

for f in "${files[@]}"; do
  [[ -f "$f" ]] || continue
  grep -Iq . "$f" || continue
  if grep -q $'\r' "$f"; then
    # cp -p でパーミッションを引き継いでから mv で atomic に置換する。
    # truncate して書き戻すと parallel 実行中の linter が書き込み途中を読む。
    cp -p "$f" "$f.tmp"
    tr -d '\r' <"$f" >"$f.tmp"
    mv -f "$f.tmp" "$f"
  fi
done
