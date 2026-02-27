# Cursor Integration

The installer automatically creates two files for Cursor:

## 1. `AGENTS.md` (Universal — always created)

Cursor natively reads `AGENTS.md` from your project root. This file contains the full
Beings Protocol instructions and works out of the box — no extra configuration needed.

## 2. `.cursor/rules/beings-protocol.mdc` (Tool-specific — optional)

For the modern Cursor rules system, the installer creates an `.mdc` file with YAML
frontmatter set to `alwaysApply: true`. This ensures the Beings Protocol is active
in every Cursor conversation.

```yaml
---
description: "Beings Protocol — persistent AI identity, memory, and soul for this project"
alwaysApply: true
---
```

## Precedence

Cursor applies rules in this order (highest priority first):

1. Team Rules (Team/Enterprise plans)
2. Project Rules (`.cursor/rules/*.mdc`)
3. User Rules (Cursor Settings)
4. Legacy Rules (`.cursorrules` — deprecated)
5. `AGENTS.md`

Both `AGENTS.md` and `.cursor/rules/beings-protocol.mdc` will be active, giving you
double coverage. The `.mdc` file takes precedence if there's any conflict.

## Manual Setup

If you didn't use the installer:

```bash
# Option A: Just use AGENTS.md (simplest)
# Copy the contents of templates/tool-configs/AGENTS.md to your project root

# Option B: Modern Cursor rules
mkdir -p .cursor/rules
# Copy templates/tool-configs/cursor-rules.mdc to .cursor/rules/beings-protocol.mdc
```
