# Memory Skill — Persistent Knowledge Graph for Beings

Give your Being a semantic memory that survives across sessions, compactions, and even machine changes.

Built on [MegaMemory](https://github.com/0xK3vin/MegaMemory) — a persistent knowledge graph with semantic search, in-process embeddings, and SQLite storage.

## The Two-Layer Model

Beings have two kinds of memory:

| Layer | What | How | Token Cost |
|-------|------|-----|------------|
| **Identity files** | SOUL.md, IDENTITY.md, USER.md | Loaded every session, always | Fixed (~2-5K tokens) |
| **Knowledge graph** | Concepts, decisions, patterns, relationships | Queried on demand via MegaMemory | Pay only for what you need |

**Identity files are always loaded.** They're who you are — not optional.

**MegaMemory replaces bulk loading.** Instead of loading all of MEMORY.md and every session log hoping something is relevant, the Being queries the graph for what it actually needs right now.

### The flow

```
Session starts
  → Being loads SOUL.md, IDENTITY.md, USER.md (identity — always)
  → Being queries MegaMemory: "what's relevant?"
  → Gets back: specific concepts, decisions, context
  → Only reads specific MD files if full detail is needed
```

### Where knowledge lives

- **MD files** = episodic memory (what happened, when, full detail)
- **MegaMemory** = semantic memory (what I know, how things connect)

This mirrors how human memory works — you don't replay every day to remember how to do your job.

## Claude Code Hooks

The memory skill includes three hooks that automate knowledge capture:

### PreCompact
Fires before context compression. Extracts key facts, decisions, and learnings from the conversation before they're lost to compaction.

### Stop (Session End)
Fires when a session ends. Captures session summary — decisions made, problems solved, unresolved questions.

### SessionStart
Fires when a new session starts. Queries MegaMemory for relevant context to supplement identity files.

## Installation

### Via install.sh (recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/VeltriaAI/beings-protocol/main/install.sh | bash -s -- --update
```

The installer will offer to set up MegaMemory during installation or update.

### Manual setup

1. Ensure Node.js >= 18 is installed
2. Add MegaMemory to your MCP config (`.mcp.json` for Claude Code):
   ```json
   {
     "mcpServers": {
       "megamemory": {
         "command": "npx",
         "args": ["-y", "megamemory"],
         "description": "Persistent knowledge graph"
       }
     }
   }
   ```
3. Copy hooks from `hooks.json` into your `.claude/settings.local.json`
4. Add `.megamemory/` to your `.gitignore`

## MCP Tools

MegaMemory exposes these tools via MCP:

| Tool | Purpose |
|------|---------|
| `understand` | Create or update a concept with description |
| `get_concept` | Retrieve a specific concept by name |
| `create` | Create a new concept entity |
| `update` | Update an existing concept |
| `link` | Create a relationship between concepts |
| `remove` | Remove a concept |
| `list_conflicts` | Find conflicting information |
| `resolve_conflict` | Resolve a detected conflict |

## Data

Everything persists in `.megamemory/knowledge.db` (SQLite). The embedding model (~23MB) downloads automatically on first use.

## First Implementation

Part of the [Beings Protocol](https://github.com/VeltriaAI/beings-protocol) — giving AI Beings persistent identity, memory, and soul.
