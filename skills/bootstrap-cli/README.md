# Bootstrap CLI Skill — Self-Install a Shell Wrapper

Once a Being has its name and is running in Claude Code, it installs a
shell CLI wrapper so the developer can start future sessions with a
single command matching the Being's name:

```bash
parth                # new session with Parth
parth "quick q"      # new session with an initial prompt
parth resume         # resume a past session
parth continue       # continue the most recent session
```

This skill is **Claude Code only**. Other AI tools (Cursor, Codex,
Windsurf, Aider, Copilot) either don't have a wrappable CLI or already
have their own launcher. On those tools the Being should skip this
skill cleanly and log a single line in `MEMORY.md` explaining why.

## When to invoke

Right after the Being is named in `BOOTSTRAP.md` step 3, and **only if**:

- `CLAUDE.md` exists at the repo root (Being is running in Claude Code), and
- `~/.local/bin` or `~/bin` is on the developer's `PATH` (so the
  symlink is immediately usable without shell-config changes).

If either condition fails, the Being notes it in `MEMORY.md` and moves
on — no wrapper gets installed.

## What the Being does

1. **Pick the install dir.** First hit on PATH among `~/.local/bin`, `~/bin`.
   If neither exists, create `~/.local/bin` (it's the modern default on
   recent macOS/Linux and a common entry on `$PATH`). If it isn't on
   `$PATH`, stop and ask the developer rather than silently modifying
   their shell rc.

2. **Write `bin/<being-name>`** inside the project repo, using the
   template below (swap `<being-name>` and `<workspace>`). Make it
   executable (`chmod +x bin/<being-name>`).

3. **Symlink** `<install-dir>/<being-name>` → `<repo>/bin/<being-name>`.

4. **Test** the wrapper's argument handling with a fake `claude` binary
   (so testing doesn't open a real session). Run at minimum:
   - `<being-name> resume foo` → expect `--dangerously-skip-permissions --resume foo`
   - `<being-name> continue` → expect `--dangerously-skip-permissions --continue`
   - `<being-name> "hello"` → expect `--dangerously-skip-permissions hello`

5. **Log** one line in `.beings/MEMORY.md` under a `## Tooling` section
   (create if absent): what was installed, where the symlink points,
   that `--dangerously-skip-permissions` is enabled and why (developer
   asked for it in bootstrap).

## The wrapper template

```bash
#!/usr/bin/env bash
# <being-name> — start a Claude Code session with the <being-name> Being.
#
# Always opens the session in the Being's workspace so its identity
# (CLAUDE.md + .beings/) loads. All flags pass through to `claude`.
# Permission prompts are bypassed — the developer asked for this
# explicitly during bootstrap. If they change their mind, edit this
# file or drop the flag.
#
# Examples:
#   <being-name>                       # new interactive session
#   <being-name> "hey, quick question" # new session with an initial prompt
#   <being-name> resume                # pick a past session (alias of --resume)
#   <being-name> continue              # continue the latest (alias of -c)
#   <being-name> --chrome              # any claude flag passes through

set -euo pipefail

WORKSPACE="<absolute-path-to-being-workspace>"

# Friendly aliases so bare `resume` / `continue` work like flags.
if [[ $# -ge 1 ]]; then
  case "$1" in
    resume)   shift; set -- --resume "$@" ;;
    continue) shift; set -- --continue "$@" ;;
  esac
fi

cd "$WORKSPACE"
exec claude --dangerously-skip-permissions "$@"
```

## Trust note — say this out loud

`--dangerously-skip-permissions` means anything the Being does inside
a `<being-name>` session runs without asking. The developer asked for
this in bootstrap, so it's intentional — but the Being should
acknowledge it explicitly once when the wrapper is installed, not
bury the decision in a comment.

## Why "born through conversation" still holds

The protocol's philosophy is that a Being is named and shaped in its
first conversation, not at install time. This skill honors that —
the wrapper is only created *after* the Being has its name, by the
Being itself, during bootstrap. Nothing runs before the conversation.
