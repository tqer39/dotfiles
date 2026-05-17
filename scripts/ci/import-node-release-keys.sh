#!/usr/bin/env bash
# Node.js リリース署名鍵を GnuPG キーリングへ pre-import する。
# mise が node をインストールする際に行う tarball の GPG 検証で利用される。
# 参考: https://github.com/nodejs/release-keys
#
# ===============================================================
# メンテナンス手順 (issue #406)
# ===============================================================
# 下記 `keys` 配列は nodejs/release-keys の keys.list と同期して
# 手動で更新する。CI で node のインストール / 検証が
# 「gpg: Can't check signature: No public key」等で fail した場合は
# 鍵が追加 / rotate された可能性があるため、以下のコマンドで最新の
# long key id 一覧を取得し、本スクリプトの配列を差し替える:
#
#   curl -fsSL https://raw.githubusercontent.com/nodejs/release-keys/main/keys.list
#
# 差分があれば PR を作成して merge する。fail 頻度が増えてきたら
# issue #406 で検討した案 A (動的取得) や案 B (Renovate / scheduled
# job による自動 PR) への移行を検討する。
# ===============================================================
set -euo pipefail

# 現行 / 直近の node リリース署名者の long key id。
# nodejs/release-keys の keys.list と同期して更新する。
# 最終同期日: 2026-05-17 (issue #406)
keys=(
  4ED778F539E3634C779C87C6D7062848A1AB005C
  141F07595B7B3FFE74309A937405533BE57C7D57
  74F12602B6F1C4E913FAA37AD3A89613643B6201
  DD792F5973C6DE52C432CBDAC77ABFA00DDBF2B7
  CC68F5A3106FF448322E48ED27F5E38D5B0A215F
  8FCCA13FEF1D0C2E91008E09770F7A9A5AE15600
  890C08DB8579162FEE0DF9DB8BEAB4DFCF555EF4
  C82FA3AE1CBEDC6BE46B9360C43CEC45C17AB93C
  108F52B48DB57BB0CC439B2997B01419BD92F80A
  A363A499291CBBC940DD62E41F10027AF002F8B0
)

# CI ランナーの DNS / firewall 事情に左右されないよう複数 keyserver を順に試す。
keyservers=(
  hkps://keys.openpgp.org
  hkps://keyserver.ubuntu.com
  hkp://pgp.mit.edu
)

failed=()
for key in "${keys[@]}"; do
  imported=0
  for ks in "${keyservers[@]}"; do
    if gpg --batch --keyserver "$ks" --recv-keys "$key" >/dev/null 2>&1; then
      echo "imported: $key (from $ks)"
      imported=1
      break
    fi
  done
  if [ "$imported" -eq 0 ]; then
    echo "failed: $key (all keyservers exhausted)" >&2
    failed+=("$key")
  fi
done

if [ "${#failed[@]}" -gt 0 ]; then
  echo "ERROR: ${#failed[@]} 鍵のインポートに失敗しました" >&2
  printf '  - %s\n' "${failed[@]}" >&2
  echo "ヒント: nodejs/release-keys の keys.list と差分がないか確認してください" >&2
  echo "  curl -fsSL https://raw.githubusercontent.com/nodejs/release-keys/main/keys.list" >&2
  exit 1
fi

echo "全 ${#keys[@]} 鍵のインポートに成功しました"
