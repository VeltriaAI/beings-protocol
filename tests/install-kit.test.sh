#!/usr/bin/env bash
# install-kit.test.sh: install.sh --with operations,teams-kit in throwaway homes (offline; uses this checkout).
# TEST_BASH=/path/to/bash-3.2 runs install.sh under that shell (macOS default).
# shellcheck disable=SC2015,SC2016  # ok/bad reporting chains; literal $ in owner fixtures is intended
set -euo pipefail
REPO="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
fails=0; ok() { echo "  ok  $1"; }; bad() { echo "  FAIL $1"; fails=$((fails + 1)); }
# Stub basic-memory so install.sh never bootstraps uv from the network.
mkdir -p "$TMP/stub"; printf '#!/bin/sh\nexit 0\n' >"$TMP/stub/basic-memory"; chmod +x "$TMP/stub/basic-memory"
inst() { (cd "$1" && shift && HOME="$TMP/home" PATH="$TMP/stub:$PATH" "${TEST_BASH:-bash}" "$REPO/install.sh" "$@" --yes --no-memory) >"$TMP/out" 2>&1; }
plain() { rm -rf "$1"; mkdir -p "$1/.beings"; git -C "$1" init -q; }
# Portable (GNU and BSD/macOS): no stat -c, sed -i or sha256sum.
sum() { if command -v sha256sum >/dev/null; then sha256sum; else shasum -a 256; fi; }
tree() { (cd "$1" && find . -path ./.git -prune -o -type f -print | LC_ALL=C sort | while IFS= read -r f; do printf '%s %s\n' "$(sum <"$f" | cut -c1-64)" "$f"; done); }
is600() { [[ -n "$(find "$1" -prune -perm 0600)" ]]; }   # exact mode, GNU and BSD find
drop_line() { grep -v "$1" "$2" >"$2.tmp" || true; cat "$2.tmp" >"$2"; rm -f "$2.tmp"; }

# 1. The curl file list matches the skill directory and its modes.
if git -C "$REPO" rev-parse --git-dir >/dev/null 2>&1; then
  listed=$(bash -c 'source <(sed -n "/^TEAMS_KIT_FILES=(/,/^)/p;/^TEAMS_KIT_EXEC=(/,/^)/p" "$1")
    for f in "${TEAMS_KIT_FILES[@]}"; do echo "100644 $f"; done; for f in "${TEAMS_KIT_EXEC[@]}"; do echo "100755 $f"; done' _ "$REPO/install.sh" | sort)
  actual=$(git -C "$REPO" ls-files -s skills/teams-kit | awk '{ sub("skills/teams-kit/", "", $4); print $1, $4 }' | sort)
  [[ "$listed" == "$actual" ]] && ok "TEAMS_KIT_FILES/EXEC match skills/teams-kit" || bad "kit file list drifted: $(diff <(echo "$listed") <(echo "$actual") | tr '\n' ' ')"
fi

# 2. Hostile owner names: .env sources cleanly, values survive, templates filled literally.
n=0
for owner in "your partner" "Sam O'Brien" "Sam O'Brien & Co" 'A "quoted" $HOME `x` \ name' "Ana/Lee | ops"; do
  home="$TMP/case$((++n))"; plain "$home"
  inst "$home" --update --name nova --with teams-kit --owner "$owner" || { bad "install for [$owner]: $(tail -3 "$TMP/out")"; continue; }
  env="$home/ops/teams-kit/.env"
  got=$(env -i PATH="$PATH" bash -c 'set -euo pipefail; set -a; . "$1"; set +a; printf "%s|%s|%s" "$OWNER_NAME" "$BEING_NAME" "$BEING_STATE_DIR"' _ "$env") \
    && [[ "$got" == "$owner|nova|$(cd "$home" && pwd -P)/ops/teams-kit/state" ]] && ok ".env sources, owner=[$owner]" || bad ".env for [$owner]: got [${got:-source failed}]"
  is600 "$env" && ok ".env is 0600" || bad ".env is not 0600"
  grep -qF -- "$owner" "$home/.beings/AUTONOMY-MATRIX.md" && ok "template owner filled literally" || bad "template owner for [$owner]"
done
awk -F= '/^[A-Z0-9_]+=/{ v=substr($0, index($0,"=")+1); sub(/[ \t]+#.*/, "", v)
  if (v ~ /^'"'"'.*'"'"'$/ || v ~ /^[^ \t'"'"'"$`\\]*$/) next; print "bad line: " $0; bad=1 } END { exit bad }' \
  "$TMP"/case*/ops/teams-kit/.env && ok "all .env lines audited" || bad ".env line audit"

# 3. Kit pieces and executables are in place.
h="$TMP/case1"
for f in .beings/GUARDRAILS.md .beings/AUTONOMY-MATRIX.md .beings/JOB-CHECKLIST.md .beings/facts/_TEMPLATE.md .beings/.kit-version bin/nova; do
  [[ -e "$h/$f" ]] || bad "missing $f"
done
[[ -x "$h/bin/nova" && -x "$h/ops/teams-kit/being-teams" && ! -x "$h/ops/teams-kit/fmt.mjs" ]] && ok "kit files and modes" || bad "kit modes"
grep -qxF "ops/teams-kit/.env" "$h/.gitignore" && ok ".env gitignored" || bad ".env not gitignored"

# 4. Re-run is idempotent; the name comes from the kit .env, not the directory.
before=$(tree "$h")
inst "$h" --update --with teams-kit && [[ "$(tree "$h")" == "$before" ]] && ok "re-run changes nothing (name read from .env)" || bad "re-run changed files: $(tail -3 "$TMP/out")"

# 5. Upgrade never overwrites: edited files stay, upstream versions go to .kit-upgrade/, new .env keys are merged.
echo "# my rule" >>"$h/.beings/GUARDRAILS.md"; echo "// local patch" >>"$h/ops/teams-kit/fmt.mjs"
drop_line '^BEING_DETECT_CHATS=' "$h/ops/teams-kit/.env"; echo "BEING_UPN=me@example.test" >>"$h/ops/teams-kit/.env"
inst "$h" --update --with teams-kit
grep -q "# my rule" "$h/.beings/GUARDRAILS.md" && grep -q "local patch" "$h/ops/teams-kit/fmt.mjs" && ok "user edits kept" || bad "user edits lost"
cmp -s "$h/ops/teams-kit/.kit-upgrade/fmt.mjs" "$REPO/skills/teams-kit/fmt.mjs" && ok "new version staged in .kit-upgrade/" || bad ".kit-upgrade missing"
grep -q '^BEING_DETECT_CHATS=' "$h/ops/teams-kit/.env" && grep -q '^BEING_UPN=me@example.test' "$h/ops/teams-kit/.env" && ok ".env merged, values kept" || bad ".env merge"
# A key that is new upstream (absent from the installed .env.example too) still reaches .env.
drop_line '^BEING_OWNER_DELEGATE=' "$h/ops/teams-kit/.env"; drop_line '^BEING_OWNER_DELEGATE=' "$h/ops/teams-kit/.env.example"
inst "$h" --update --with teams-kit
grep -q '^BEING_OWNER_DELEGATE=0' "$h/ops/teams-kit/.env" && ok "new upstream .env key merged (owner sign-in stays off)" || bad "new upstream key not merged"

# 6. Refusals happen before anything is written.
h="$TMP/noname"; plain "$h"; before=$(tree "$h")
inst "$h" --update --with operations && bad "--update --with without --name should fail" || { [[ "$(tree "$h")" == "$before" ]] && ok "no --name: refused, nothing written" || bad "no --name wrote files"; }
inst "$h" --with operations && bad "--with without --global/--update should fail" || ok "--with alone refused"
inst "$h" --update --name nova --with bogus && bad "unknown component accepted" || ok "unknown component refused"

# 7. --check reports and writes nothing.
before=$(tree "$TMP/case2"); inst "$TMP/case2" --check
grep -q "kit 0.1.0" "$TMP/out" && [[ "$(tree "$TMP/case2")" == "$before" ]] && ok "--check is read-only" || bad "--check"

(( fails == 0 )) && echo "install-kit: all checks passed" || { echo "install-kit: $fails failed"; exit 1; }
