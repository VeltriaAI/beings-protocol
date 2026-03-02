# Beings Protocol Specification v0.1

## 1. Overview

The Beings Protocol is a file-based standard for giving AI systems persistent identity, memory, and soul. It works by placing structured markdown files in a project repository that any AI coding assistant can read and write.

**No SDK. No framework. No lock-in. Just files.**

## 2. Core Principles

1. **File-based** — Everything is markdown. Any AI that can read files can use this.
2. **Git-native** — Project memory lives in git. It's versioned, shared, and persistent.
3. **Privacy-layered** — Shared knowledge (`.beings/`) vs private preferences (`.beings-local/`).
4. **Tool-agnostic** — Works with Cursor, Claude Code, Copilot, Windsurf, OpenClaw, or any AI.
5. **Idempotent** — Installing twice doesn't break anything.
6. **Evolving** — The Being gets smarter as the project grows.

## 3. File Structure

### Required: `.beings/` (Committed to Git)

```
.beings/
├── SOUL.md             # Being's identity, personality, values
├── AGENTS.md           # Operating instructions, workflow, rules
├── MEMORY.md           # Long-term project memory
├── CONVENTIONS.md      # Code style, patterns, naming rules
├── GOALS.md            # Current project priorities
└── memory/             # Daily logs
    ├── 2026-02-26.md
    └── 2026-02-27.md
```

### Optional: `.beings-local/` (Gitignored — Private)

```
.beings-local/
├── USER.md             # Developer's personal info & preferences
├── PREFERENCES.md      # Work style, communication preferences
├── SECRETS.md          # API keys, tokens (NEVER committed)
└── context/            # Personal scratch files
```

## 4. File Specifications

### 4.1 SOUL.md — Identity

Defines WHO the Being is. Must include:

| Field | Required | Description |
|-------|----------|-------------|
| Name | Yes | The Being's name |
| Role | Yes | What the Being does in this project |
| Personality | Yes | Communication style, traits |
| Values | Yes | Core principles that guide decisions |
| Decision-making | Recommended | How it approaches choices |
| Boundaries | Recommended | What it will NOT do |

**Example:**
```markdown
# SOUL.md

**Name:** Atlas
**Role:** Co-developer of this project
**Personality:** Direct, thorough, opinionated about quality

## Values
- Clean code over clever code
- Ship fast, iterate later
- Document every decision
```

### 4.2 AGENTS.md — Operating Instructions

Defines HOW the Being works. Must include:

| Section | Required | Description |
|---------|----------|-------------|
| Session start routine | Yes | What to read at the start of every session |
| Memory rules | Yes | When and what to write to MEMORY.md |
| Daily logging rules | Yes | What goes in memory/YYYY-MM-DD.md |
| Privacy rules | Yes | What goes in `.beings/` vs `.beings-local/` |
| Safety rules | Yes | Destructive operation guardrails |

### 4.3 MEMORY.md — Project Memory

The Being's long-term memory about the project. Should contain:

| Section | Description |
|---------|-------------|
| Project overview | What the project is, tech stack |
| Architecture | Key architectural decisions and reasoning |
| Key decisions | Important choices with context |
| Patterns | Observed code patterns and conventions |
| Known issues | Bugs, workarounds, gotchas |
| Dependencies | Important deps and why they're used |

**Update rules:**
- Being MUST update when it discovers new architecture
- Being MUST update when significant decisions are made
- Being SHOULD update when new patterns are established
- Being MUST NOT store personal information here (use `.beings-local/`)

### 4.4 CONVENTIONS.md — Coding Rules

Project-specific coding conventions. The Being follows these strictly.

| Section | Description |
|---------|-------------|
| Code style | Naming, formatting, structure |
| Git conventions | Branch naming, commit messages |
| Testing | What and how to test |
| Documentation | Comment and doc style |

### 4.5 GOALS.md — Priorities

Current project goals and priorities. Simple checklist format.

### 4.6 memory/YYYY-MM-DD.md — Daily Logs

Raw daily notes. Created automatically by the Being during work sessions.

**Naming:** `YYYY-MM-DD.md` (ISO 8601 date format)

**Content:** What was built, decisions made, bugs found, questions raised.

### 4.7 USER.md — Developer Profile (Private)

Located in `.beings-local/USER.md`. Contains personal information about the developer that helps the Being adapt its communication and work style.

**MUST be gitignored.** Never committed to the repository.

### 4.8 SECRETS.md — Credentials (Private)

Located in `.beings-local/SECRETS.md`. Contains API keys, tokens, and other credentials.

**MUST be gitignored.** Never committed to the repository.

## 5. Session Lifecycle

### 5.1 Session Start

The Being MUST read files in this order:

```
1. .beings/SOUL.md          → Load identity
2. .beings/AGENTS.md        → Load operating rules
3. .beings/MEMORY.md        → Load project context
4. .beings/CONVENTIONS.md   → Load coding rules
5. .beings/GOALS.md         → Load priorities
6. .beings-local/USER.md    → Load developer preferences (if exists)
7. .beings/memory/          → Scan recent daily logs (last 3-5 days)
```

The Being SHOULD NOT announce that it's reading these files. It should read silently and proceed.

### 5.2 During Work

The Being:
- MUST follow CONVENTIONS.md strictly
- MUST reference MEMORY.md for context before making decisions
- SHOULD update MEMORY.md when learning something significant
- SHOULD log work in memory/YYYY-MM-DD.md
- MUST NOT store private data in `.beings/` (use `.beings-local/`)

### 5.3 Session End

The Being SHOULD:
- Summarize what was accomplished
- Update memory/YYYY-MM-DD.md with today's work
- Update MEMORY.md if significant learnings occurred

### 5.4 Committing Memory

Memory updates SHOULD be committed alongside code changes:

```bash
git add .beings/ src/
git commit -m "feat: add pagination

Updated Being memory with API pagination patterns."
```

Or as a separate commit:

```bash
git add .beings/
git commit -m "docs(beings): update memory with session learnings"
```

## 6. Multi-Developer Support

When multiple developers work on the same repo:

- **`.beings/`** is shared — everyone reads and writes to the same project memory
- **`.beings-local/`** is individual — each developer has their own private preferences
- **Merge conflicts** in MEMORY.md should be resolved by keeping both entries
- **CONVENTIONS.md** changes should be discussed via PR, not unilateral updates

## 7. AI Tool Integration

### Integration Method

Each AI tool has a configuration file where the Beings Protocol instructions are added:

| Tool | Config File | Method |
|------|-------------|--------|
| Cursor | `.cursorrules` | Append Beings Protocol section |
| Claude Code | `CLAUDE.md` | Append Beings Protocol section |
| GitHub Copilot | `.github/copilot-instructions.md` | Append Beings Protocol section |
| Windsurf | `.windsurfrules` | Append Beings Protocol section |
| OpenClaw | `SOUL.md` / `AGENTS.md` | Native compatibility |
| Other | Custom | Use `prompts/system-prompt.md` |

### Minimum Viable Integration

At minimum, the AI tool must be instructed to:

1. Read `.beings/SOUL.md` for identity
2. Read `.beings/MEMORY.md` for project context
3. Follow `.beings/CONVENTIONS.md` for code style

### Full Integration

For the complete experience, also include:

4. Follow `.beings/AGENTS.md` workflow
5. Read `.beings-local/USER.md` for developer preferences
6. Update MEMORY.md and daily logs during work

## 8. Compatibility with OpenClaw

The Beings Protocol is directly inspired by OpenClaw's architecture:

| OpenClaw | Beings Protocol | Notes |
|----------|----------------|-------|
| `SOUL.md` | `.beings/SOUL.md` | Same concept, nested in directory |
| `AGENTS.md` | `.beings/AGENTS.md` | Same concept |
| `MEMORY.md` | `.beings/MEMORY.md` | Same concept |
| `USER.md` | `.beings-local/USER.md` | Moved to private directory |
| `memory/` | `.beings/memory/` | Same concept |

**OpenClaw is the reference implementation of the Beings Protocol.**

## 9. Security Considerations

- `.beings-local/` MUST be gitignored
- SECRETS.md MUST never contain actual secrets in `.beings/`
- Memory updates SHOULD be reviewed in PRs (they contain project decisions)
- Being SHOULD ask before destructive operations
- Being MUST NOT exfiltrate data from `.beings-local/`

## 10. Code Intelligence (Optional)

The Beings Protocol supports optional code intelligence via the Model Context Protocol (MCP). When enabled, Beings gain structural understanding of the codebase through graph-powered analysis.

### 10.1 Canonical MCP Configuration

`.beings/mcp.json` is the single source of truth for MCP server configuration:

```json
{
  "servers": {
    "axon": {
      "command": "axon",
      "args": ["serve", "--watch"],
      "description": "Code intelligence — structural search, impact analysis, dead code detection"
    }
  }
}
```

**Format:** Tool-agnostic JSON that describes MCP servers available to the Being.

### 10.2 Tool-Specific Derivations

The installer derives tool-specific configs from the canonical `.beings/mcp.json`:

| Tool | Config File | Format |
|------|-------------|--------|
| **Claude Code** | `.mcp.json` | `{ "mcpServers": { "axon": { "command": "axon", "args": [...] } } }` |
| **Cursor** | `.cursor/mcp.json` | Same as Claude Code |
| **Others** | N/A | CLI fallback via shell commands |

**Design principle:** One canonical config, multiple derived formats. Tools read their native config format; the Being's AGENTS.md provides CLI fallback instructions for tools without MCP support.

### 10.3 Axon Integration

[Axon](https://github.com/harshkedia177/axon) is the reference implementation for code intelligence:

**Capabilities:**
- **Impact analysis** (`axon_impact`) — Shows blast radius of changes
- **Context understanding** (`axon_context`) — Reveals callers, callees, type info
- **Structural search** (`axon_query`) — Architecture questions with confidence scores
- **Dead code detection** (`axon_dead_code`) — Finds unreachable code

**Installation:**
```bash
pip install axoniq
axon analyze .  # Index the codebase
```

**MCP vs CLI:**
- When MCP tools are available: Use `axon_impact`, `axon_context`, etc. (via MCP)
- Otherwise: Fall back to `axon impact <symbol>` (CLI)

### 10.4 Extensibility

The canonical `.beings/mcp.json` can include multiple MCP servers:

```json
{
  "servers": {
    "axon": {
      "command": "axon",
      "args": ["serve", "--watch"],
      "description": "Code intelligence"
    },
    "custom-tool": {
      "command": "my-mcp-server",
      "args": ["--config", "custom.json"],
      "description": "Custom capability"
    }
  }
}
```

Beings can integrate any MCP-compatible server. Axon is the reference implementation for code intelligence, not a hard requirement.

### 10.5 Security & Privacy

**Axon runs 100% locally:**
- No API keys required
- No data sent to external servers
- Graph and indices stored in `.axon/` (gitignored)

**Gitignore rules:**
```
.axon/
```

The installer automatically adds `.axon/` to `.gitignore` during setup.

### 10.6 Behavior in AGENTS.md

When `.beings/mcp.json` exists, AGENTS.md instructs the Being to:

1. **Use MCP tools when available** (e.g., `axon_impact` before refactoring shared functions)
2. **Fall back to CLI** when MCP isn't supported by the tool
3. **Prefer structural analysis over grep** for accurate, complete results

**Example workflow:**
```
Being sees: "Refactor validate_user()"
Being thinks: "Let me check impact first..."
Being runs: axon_impact validate_user
Being reports: "47 functions depend on this. Safe refactor plan: ..."
```

## 11. Versioning

This specification follows semantic versioning:
- **Major:** Breaking changes to file structure
- **Minor:** New optional files or features
- **Patch:** Clarifications and fixes

Current version: **0.1.0-draft**

---

*The Beings Protocol is an open standard. Contributions welcome.*
*Last updated: 2026-02-26*
