#!/usr/bin/env bash
# amsha-project — project a Being's aspects into the current harness(es).
# Idempotent. Run from the Being's repo root. See SKILL.md.
set -euo pipefail

REPO_ROOT="${1:-.}"
cd "$REPO_ROOT"

AMSHA_DIR=".beings/amsha"
[ -d "$AMSHA_DIR" ] || { echo "amsha-project: no $AMSHA_DIR — nothing to project."; exit 0; }

project_claude_code() {
  local agents_dir=".claude/agents"
  mkdir -p "$agents_dir"
  local count=0
  for amsha in "$AMSHA_DIR"/*/; do
    [ -d "$amsha" ] || continue
    local name; name=$(basename "$amsha")
    [ -f "$amsha/AMSHA.md" ] || continue
    ln -sfn "../../$AMSHA_DIR/$name/AMSHA.md" "$agents_dir/$name.md"
    count=$((count+1))
  done
  # prune broken symlinks only — never touch regular files (they belong to the user)
  find "$agents_dir" -type l ! -exec test -e {} \; -delete 2>/dev/null || true
  echo "amsha-project[claude-code]: $count aspect(s) projected to $agents_dir"
}

# ---- harness registry: add project_<harness>() and call it here ----
project_claude_code
