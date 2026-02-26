# OpenClaw Integration

OpenClaw natively supports the Beings Protocol architecture. The mapping is:

| Beings Protocol | OpenClaw |
|----------------|----------|
| `.beings/SOUL.md` | `SOUL.md` |
| `.beings/AGENTS.md` | `AGENTS.md` |
| `.beings/MEMORY.md` | `MEMORY.md` |
| `.beings-local/USER.md` | `USER.md` |
| `.beings/memory/` | `memory/` |

## Setup

If you're already using OpenClaw, your workspace IS a Being. The Beings Protocol formalizes what OpenClaw already does.

To adopt the Beings Protocol structure in an existing OpenClaw workspace:

```bash
# Create the .beings directory structure
mkdir -p .beings/memory .beings-local

# Symlink or copy your existing files
cp SOUL.md .beings/SOUL.md
cp AGENTS.md .beings/AGENTS.md
cp MEMORY.md .beings/MEMORY.md
cp USER.md .beings-local/USER.md
```

Or keep using the OpenClaw-native layout — both are compatible.

## Why OpenClaw + Beings Protocol?

OpenClaw pioneered the concept of AI with persistent identity and memory.
The Beings Protocol packages that innovation into a portable standard
that works with ANY AI system — not just OpenClaw.

**OpenClaw is the reference implementation of the Beings Protocol.**
