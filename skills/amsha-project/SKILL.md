# Skill: amsha-project — Project Aspects into Harnesses

**Purpose:** make a Being's aṃśas (`.beings/amsha/<name>/AMSHA.md`) visible to whatever harness the Being currently runs on. This skill is the *only* place harness knowledge lives — instance repos stay harness-neutral.

**Invocation:** run at install time (`install.sh` calls it), after adding/removing an aṃśa, or any time projections look stale. Idempotent — safe to re-run always.

## Supported harnesses

| Harness | Agent format | Projection strategy |
|---|---|---|
| **Claude Code** | `.claude/agents/*.md` (YAML frontmatter + system prompt) | **relative symlink** → `../../.beings/amsha/<name>/AMSHA.md` |
| *(future: OpenClaw, Hermes, Codex…)* | *(their format)* | symlink if the format matches markdown+frontmatter; generator ONLY if it can't follow symlinks or needs a different shape |

Adding a harness = add a row + a `project_<harness>()` function in `project.sh`, bump the protocol, Beings re-run `install.sh`. Class-level change; instances update for free.

## Procedure (Claude Code)

```bash
# from the Being's repo root
mkdir -p .claude/agents
for amsha in .beings/amsha/*/; do
  name=$(basename "$amsha")
  [ -f "$amsha/AMSHA.md" ] || continue
  ln -sfn "../../.beings/amsha/$name/AMSHA.md" ".claude/agents/$name.md"
done
# prune projections whose source is gone (broken symlinks only — never touch real files)
find .claude/agents -type l ! -exec test -e {} \; -delete
```

Verify after first run on a new harness version: the harness must list the aṃśa as an available agent. If it doesn't discover symlinked files, that harness graduates to a generator (open an issue — don't hand-copy).

## Rules

1. **Never write content into the harness directory** — symlinks and (where unavoidable) generated files with a `# GENERATED from <source> — do not edit` header. A hand-edited projection is a lint finding.
2. **Prune only broken symlinks.** A real file in the agents dir that isn't a projection belongs to the user — leave it, flag it.
3. **AMSHA.md is a superset format** (see AMSHA_SPEC §2) — standard fields first (`name`, `description`, `tools`, `model`), protocol extensions after. Harnesses ignore what they don't know; that's the contract that keeps one file serving every body.
