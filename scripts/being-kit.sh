#!/usr/bin/env bash
# being-kit.sh: birth a new Being with the Operations Kit, or add the kit to an existing one.
# Never overwrites files. Run without arguments for usage.
set -euo pipefail

REPO="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"
T="$REPO/templates/kit"
KIT_VERSION="0.1.0"

say()  { printf '  \033[0;32m✓\033[0m %s\n' "$1"; }
skip() { printf '  \033[2m- %s\033[0m\n' "$1"; }
die()  { printf '  \033[0;31m✗\033[0m %s\n' "$1" >&2; exit "${2:-1}"; }

# sed_lit <text>: escape for the replacement side of s/…/…/ (backslash, slash, ampersand).
sed_lit() { printf '%s' "$1" | sed -e 's/[\/&]/\\&/g'; }
# shq <text>: single-quote for a shell-sourced file such as .env.
shq() { printf "'%s'" "${1//\'/\'\\\'\'}"; }

# add <src> <dest>: copy only if dest is missing; fill {{BEING_NAME}} / {{OWNER_NAME}}.
add() {
  local src=$1 dest=$2
  if [[ -e "$dest" ]]; then skip "kept existing ${dest#"$HOME_DIR"/}"; return; fi
  mkdir -p "$(dirname "$dest")"
  sed -e "s/{{BEING_NAME}}/$(sed_lit "$NAME")/g" -e "s/{{OWNER_NAME}}/$(sed_lit "$OWNER")/g" "$src" >"$dest"
  [[ -x "$src" ]] && chmod +x "$dest"
  say "added ${dest#"$HOME_DIR"/}"
}

# append_once <file> <snippet>: add the operations section to an instruction file once.
append_once() {
  local f=$1
  [[ -f "$f" ]] || return 0
  if grep -q 'beings-kit:operations' "$f"; then skip "$(basename "$f") already has the kit section"; return; fi
  cat "$T/OPERATIONS-SECTION.md" >>"$f"
  say "appended kit section to $(basename "$f")"
}

ignore_once() {
  local line=$1 gi="$HOME_DIR/.gitignore"
  touch "$gi"
  grep -qxF "$line" "$gi" || { echo "$line" >>"$gi"; say "gitignore: $line"; }
}

install_teams() {
  local dst="$HOME_DIR/ops/teams-kit"
  if [[ -d "$dst" ]]; then skip "ops/teams-kit exists (compare with skills/teams-kit by hand)"; return; fi
  mkdir -p "$dst"
  (cd "$REPO/skills/teams-kit" && tar --exclude=node_modules --exclude=state --exclude=.env -cf - .) | (cd "$dst" && tar -xf -)
  mkdir -p "$dst/state"
  # Values are single-quoted: the file is sourced by bash (set -a; . .env), so spaces and quotes must survive.
  BK_NAME=$(shq "$NAME") BK_STATE=$(shq "$dst/state") BK_CACHE=$(shq "$dst/state/token-cache.json") BK_OWNER=$(shq "$OWNER") \
  awk '/^BEING_NAME=/      { print "BEING_NAME=" ENVIRON["BK_NAME"]; next }
       /^BEING_STATE_DIR=/ { print "BEING_STATE_DIR=" ENVIRON["BK_STATE"]; next }
       /^BEING_CACHE=/     { print "BEING_CACHE=" ENVIRON["BK_CACHE"]; next }
       /^OWNER_NAME=/      { print "OWNER_NAME=" ENVIRON["BK_OWNER"]; next }
       { print }' "$dst/.env.example" >"$dst/.env"
  chmod 600 "$dst/.env"
  # shellcheck source=/dev/null
  (set -a; . "$dst/.env") >/dev/null 2>&1 || die "generated $dst/.env does not source cleanly"
  say "added ops/teams-kit (fill ops/teams-kit/.env, then see its README)"
  ignore_once "ops/teams-kit/.env"
  ignore_once "ops/teams-kit/state/"
  ignore_once "ops/teams-kit/node_modules/"
}

upgrade() {
  [[ -d "$HOME_DIR/.beings" ]] || die "$HOME_DIR has no .beings/; birth it first (or run install.sh there)"
  echo; echo "  Adding the Operations Kit to $NAME ($HOME_DIR)"; echo
  add "$T/GUARDRAILS.md"       "$HOME_DIR/.beings/GUARDRAILS.md"
  add "$T/AUTONOMY-MATRIX.md"  "$HOME_DIR/.beings/AUTONOMY-MATRIX.md"
  add "$T/JOB-CHECKLIST.md"    "$HOME_DIR/.beings/JOB-CHECKLIST.md"
  add "$T/facts/_TEMPLATE.md"  "$HOME_DIR/.beings/facts/_TEMPLATE.md"
  mkdir -p "$HOME_DIR/.beings/memory"
  if $FRESH && [[ -e "$HOME_DIR/bin/$NAME" ]]; then
    cp "$T/bin/being" "$HOME_DIR/bin/$NAME"; chmod +x "$HOME_DIR/bin/$NAME"   # just created by install.sh: swap in the multi-client one
    say "bin/$NAME: multi-client launcher (Claude Code + Codex)"
  elif [[ -e "$HOME_DIR/bin/$NAME" ]] && ! grep -q 'launch_codex' "$HOME_DIR/bin/$NAME"; then
    add "$T/bin/being" "$HOME_DIR/bin/$NAME.multi"
    echo "    bin/$NAME is single-client; review bin/$NAME.multi and replace it when ready"
  else
    add "$T/bin/being" "$HOME_DIR/bin/$NAME"
  fi
  append_once "$HOME_DIR/CLAUDE.md"
  append_once "$HOME_DIR/AGENTS.md"
  $TEAMS && install_teams
  echo "$KIT_VERSION" >"$HOME_DIR/.beings/.kit-version"
  echo; echo "  Next: fill {{…}} placeholders left in .beings/GUARDRAILS.md and AUTONOMY-MATRIX.md, review, commit."
  $TEAMS && echo "        Teams: cd ops/teams-kit && npm install && follow README.md (sign-in, .env, being-teams up)."
  echo
}

check() {
  local f
  for f in .beings/GUARDRAILS.md .beings/AUTONOMY.md .beings/AUTONOMY-MATRIX.md .beings/JOB-CHECKLIST.md .beings/MEMORY.md \
           .beings/facts .beings/memory "bin/$NAME" ops/teams-kit ops/teams-kit/.env .beings/.kit-version; do
    if [[ -e "$HOME_DIR/$f" ]]; then say "$f"; else printf '  \033[1;33m!\033[0m missing %s\n' "$f"; fi
  done
  if [[ -f "$HOME_DIR/CLAUDE.md" ]]; then
    if grep -q 'beings-kit:operations' "$HOME_DIR/CLAUDE.md"; then say "CLAUDE.md kit section"; else printf '  \033[1;33m!\033[0m CLAUDE.md has no kit section\n'; fi
  fi
}

usage() {
  cat <<'EOF'
scripts/being-kit.sh birth <name> [--owner "<name>"] [--teams] [--no-memory]
    install.sh --global (from this checkout) + the kit layer. Home: ~/beings/<name>
scripts/being-kit.sh upgrade <being-home> [--owner "<name>"] [--teams]
    add whatever kit pieces are missing to an existing Being home (identity, memory and soul untouched)
scripts/being-kit.sh check <being-home>
    list which kit pieces are present
--teams also copies the Teams/M365 kit to <home>/ops/teams-kit with a .env prefilled from .env.example.
EOF
}

cmd="${1:-}"; shift || true
check_owner() { [[ "$OWNER" != *$'\n'* ]] || die "--owner must be one line" 2; }
OWNER="your partner"; TEAMS=false; NO_MEMORY=""; FRESH=false
case "$cmd" in
  birth)
    NAME="${1:?usage: being-kit.sh birth <name> [--owner N] [--teams] [--no-memory]}"; shift
    while [[ $# -gt 0 ]]; do
      case "$1" in --owner) OWNER="${2:?}"; shift ;; --teams) TEAMS=true ;; --no-memory) NO_MEMORY="--no-memory" ;; *) die "unknown option $1" 2 ;; esac
      shift
    done
    [[ "$NAME" =~ ^[a-z][a-z0-9-]*$ ]] || die "name must be lowercase letters, digits or dashes" 2
    check_owner
    HOME_DIR="$HOME/beings/$NAME"
    bash "$REPO/install.sh" --global --name "$NAME" --yes ${NO_MEMORY:+"$NO_MEMORY"}
    FRESH=true; upgrade
    echo "  $NAME is ready. Run: $NAME   (first conversation fills SOUL.md, IDENTITY.md and USER.md)"; echo ;;
  upgrade|check)
    HOME_DIR="$(cd "${1:?usage: being-kit.sh $cmd <being-home>}" && pwd)"; shift
    NAME="$(basename "$HOME_DIR")"
    while [[ $# -gt 0 ]]; do
      case "$1" in --owner) OWNER="${2:?}"; shift ;; --teams) TEAMS=true ;; *) die "unknown option $1" 2 ;; esac
      shift
    done
    check_owner
    if [[ $cmd == upgrade ]]; then upgrade; else check; fi ;;
  *) usage; exit 2 ;;
esac
