---
name: memory
version: 0.4.0
description: Markdown-native persistent memory for AI Beings via basic-memory — semantic wiki with index/log + ingest/query/lint operations
author: Beings Protocol
dependencies:
  - Python >= 3.10
  - basic-memory (pip/uv install)
  - Claude Code (for hooks — optional)
---

# Memory Skill v0.4

Full topology + doctrine: `docs/CONSCIOUSNESS_SPEC.md`. Summary of what this skill maintains:

- **Location:** `.beings/memory-graph/` (v0.4 — inside `.beings/`; previously repo-root). basic-memory project named after the Being, registered at this path. **Re-register on any rename** — a stale path silently kills the graph.
- **Special files:** `index.md` (read-first catalog, one line per active note, updated on every ingest) · `log.md` (append-only ledger: `## [YYYY-MM-DD] ingest|query|lint|migrate | title`).
- **Operations:**
  - **Ingest** — durable knowledge → update existing note (check first, don't fork) or create → index line → log entry.
  - **Query** — index.md first, notes second, vector search as fallback; substantive answers filed back as notes.
  - **Lint** — scheduled self-audit (ideally a dedicated sleep-time aṃśa): contradictions, staleness, orphans, dupes, index/disk integrity, projection-symlink integrity, secrets in tracked files, harness-cache drift.
- **Invariants:** files are the only truth (SQLite/vector index is disposable — see REBUILD.md) · supersession is dated, never destructive · secrets only in `.beings-local/SECRETS.md` · sensitive relationship files (`.beings/bond/`) stay outside the watch tree.
