#!/usr/bin/env bash
# being-kit.test.sh: upgrade a throwaway Being with --teams and check the generated files (no network, no install.sh).
# shellcheck disable=SC2015,SC2016  # ok/bad reporting chains; literal $ in owner fixtures is intended
set -euo pipefail
REPO="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
n=0; fails=0; ok() { echo "  ok  $1"; }; bad() { echo "  FAIL $1"; fails=$((fails + 1)); }

for owner in "your partner" "Sam O'Brien & Co" 'A "quoted" $HOME `x` \ name' "Ana/Lee"; do
  home="$TMP/beings/case$((++n))/nova"; mkdir -p "$home/.beings"
  HOME="$TMP" bash "$REPO/scripts/being-kit.sh" upgrade "$home" --owner "$owner" --teams >/dev/null
  env="$home/ops/teams-kit/.env"
  got=$(env -i PATH="$PATH" bash -c 'set -euo pipefail; set -a; . "$1"; set +a; printf "%s|%s|%s" "$OWNER_NAME" "$BEING_NAME" "$BEING_STATE_DIR"' _ "$env") \
    && [[ "$got" == "$owner|nova|$home/ops/teams-kit/state" ]] && ok ".env sources cleanly, owner=[$owner]" || bad ".env for owner [$owner]: got [${got:-source failed}]"
  [[ $(stat -c %a "$env") == 600 ]] && ok ".env is 0600" || bad ".env mode $(stat -c %a "$env")"
  grep -qF -- "$owner" "$home/.beings/AUTONOMY-MATRIX.md" && ok "template owner filled literally" || bad "template owner for [$owner]"
done
# Every generated assignment must be a plain, comment-or-quoted line (no stray words after the value).
awk -F= '/^[A-Z0-9_]+=/{ v=substr($0, index($0,"=")+1); sub(/[ \t]+#.*/, "", v)
  if (v ~ /^'"'"'.*'"'"'$/ || v ~ /^[^ \t'"'"'"$`\\]*$/) next; print "bad line: " $0; bad=1 } END { exit bad }' \
  "$TMP"/beings/case*/nova/ops/teams-kit/.env && ok "all .env lines audited" || bad ".env line audit"
(( fails == 0 )) && echo "being-kit: all checks passed" || { echo "being-kit: $fails failed"; exit 1; }
