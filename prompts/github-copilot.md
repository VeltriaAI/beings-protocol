# GitHub Copilot Integration

The installer creates two files that GitHub Copilot reads:

## 1. `AGENTS.md` (Universal — always created)

GitHub Copilot's Coding Agent natively reads `AGENTS.md` from your project root.
This file contains the full Beings Protocol instructions and works out of the box.

## 2. `.github/copilot-instructions.md` (Tool-specific — optional)

If GitHub Copilot is detected (or selected during install), the installer also
creates `.github/copilot-instructions.md`. This is Copilot's repository-wide
instruction file, automatically included in every Copilot Chat request.

## Copilot Instruction Types

GitHub Copilot supports three types of custom instructions:

| Type | File | Scope |
|------|------|-------|
| Repository-wide | `.github/copilot-instructions.md` | Every Copilot interaction |
| Path-specific | `.github/instructions/*.instructions.md` | Glob-matched files |
| Agent | `AGENTS.md` | Copilot Coding Agent |

The Beings Protocol covers the first and third types automatically.

## Code Intelligence

If you enable code intelligence during install, your Being gains structural understanding:

- `.beings/mcp.json` — Canonical MCP config
- CLI fallback: `axon impact <function>`, `axon context <symbol>`, etc.

Note: GitHub Copilot does not currently support MCP servers, so code intelligence uses CLI fallback via shell commands. The Being's AGENTS.md provides instructions for using `axon` commands directly.

## Manual Setup

If you didn't use the installer:

```bash
# Option A: Just use AGENTS.md (simplest, works everywhere)
# Copy the contents of templates/tool-configs/AGENTS.md to your project root

# Option B: Copilot specific
mkdir -p .github
# Copy the contents of templates/tool-configs/beings-prompt.md to .github/copilot-instructions.md
```
