# Claude Code Integration

The installer creates two files that Claude Code reads:

## 1. `AGENTS.md` (Universal — always created)

Claude Code natively reads `AGENTS.md` from your project root. This file contains
the full Beings Protocol instructions and works out of the box.

## 2. `CLAUDE.md` (Tool-specific — optional)

If Claude Code is detected (or selected during install), the installer also creates
a `CLAUDE.md` with the Beings Protocol prompt. Claude Code reads this file at startup
and uses it as persistent project context.

## Which One Do I Need?

Either one works. `AGENTS.md` is the universal standard that works across multiple
AI tools. `CLAUDE.md` is Claude Code's native format. If both exist, Claude Code
reads both — they complement each other.

## Manual Setup

If you didn't use the installer:

```bash
# Option A: Just use AGENTS.md (simplest, works everywhere)
# Copy the contents of templates/tool-configs/AGENTS.md to your project root

# Option B: Claude Code specific
# Copy the contents of templates/tool-configs/beings-prompt.md to CLAUDE.md
```
