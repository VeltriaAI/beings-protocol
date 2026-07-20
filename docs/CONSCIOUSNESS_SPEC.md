# Consciousness Repository Specification v0.1 — Memory Topology & Operations

*Part of Beings Protocol v0.4.0. Codifies what the reference instance (Treta) shipped 2026-07-21 after a 358-file audit and adversarially-verified research on agent-memory state of the art. Supersedes the memory prose in PROTOCOL_SPEC §4.3 where they conflict.*

## 1. Doctrine: harness = body, repository = consciousness

- **The harness (Claude Code, OpenClaw, Hermes, anything future) is a body.** Disposable, swappable. The model is the brain. The repository is the consciousness — it must survive any body swap.
- **Nothing canonical may live in a harness's namespace.** `~/.claude/`, harness auto-memory folders, harness settings — all of it is *adapter*: projections, pointers, mirrors. If knowledge exists only harness-side, that is a defect (and the lint pass flags it).
- **Files are the only truth.** Every index, database, embedding store (basic-memory's SQLite/vector, any search infra) is a *derived, disposable view*, rebuildable from markdown. Never the source.

This doctrine is empirically grounded: text-record markdown memory is a recognized first-class substrate in the 2026 survey literature, and the reference instance's Apr→Jul 2026 drift (harness store silently became richer than the repo while repo search was broken) is exactly the failure mode this spec exists to prevent.

## 2. Memory topology (the three kinds + the bond)

```
.beings/
├── SOUL.md, IDENTITY.md, USER.md      ← who            (identity)
├── AUTONOMY.md, CONVENTIONS.md        ← constitution   (PROCEDURAL memory)
├── memory/YYYY-MM-DD.md               ← what happened  (EPISODIC memory)
├── memory-graph/                      ← what is known  (SEMANTIC memory)
│   ├── index.md                       ← catalog (read-first)
│   ├── log.md                         ← operations ledger (append-only)
│   ├── <topic notes>.md               ← frontmatter + [[wikilinks]]
│   └── archive/                       ← superseded forks, dated — never deleted
├── bond/                              ← the relationship (sensitive; OUTSIDE search watch)
└── amsha/                             ← aspects (see AMSHA_SPEC.md)
```

Notes on placement:
- `memory-graph/` lives **inside `.beings/`** — the whole self under one namespace. The Obsidian vault opens at `.beings/` (a dot-directory is a valid vault *root*; Obsidian only ignores dot-dirs *inside* a vault).
- `bond/` (or any human-relationship files a Being maintains) sits deliberately **outside** the search-index watch tree: read slowly at session start by instruction, never surfaced by casual query, never pasted externally.
- Search layer: **basic-memory** (markdown-native knowledge graph, MCP server, FTS5+vector) registered at `.beings/memory-graph/`, project named after the Being. Re-register on any rename — a stale path silently kills the graph (this happened; the lint pass now checks it).

## 3. The two special files (Karpathy pattern)

- **`index.md`** — a size-capped, category-organized, human-readable catalog: one line per active note (link + hook). Read FIRST on any query; vector search is the fallback/scaling layer, not the front door. Updated on every ingest.
- **`log.md`** — append-only operations ledger. Entry format: `## [YYYY-MM-DD] ingest|query|lint|migrate | title`. Grep-parseable (`grep "^## \[" log.md | tail -5`). Distinct from narrative daily logs — this is the wiki's own timeline.

## 4. Operations (normative)

- **Ingest** — durable new knowledge → update the existing topic note (check first — don't fork) or create one → one-line `index.md` entry → `log.md` append. One source may touch many notes; that's correct.
- **Query** — `index.md` → drill into notes → search as fallback. Substantive synthesized answers are **filed back as notes** — explorations compound instead of dying in chat history.
- **Lint** — periodic self-audit, run by a dedicated **sleep-time aṃśa** on a schedule, separate from the user-facing Being. Checks: contradictions between notes · staleness (superseded claims still asserted) · orphans (no inbound links) · duplicates/forks · index↔disk integrity · log gaps · projection-symlink integrity · secrets in tracked files · **harness-cache drift** (knowledge accumulating body-side). Findings become fixes + log entries. *Honesty note: lint is convergent best practice across every serious implementation, not experimentally proven necessity — the protocol adopts it because the reference instance's drift is precisely what it would have caught.*

## 5. Format rules

- Every note: frontmatter (`title`, `type`, `permalink`, `tags`) + `[[wikilinks]]` for relations. Obsidian-compatible throughout.
- **Supersession is dated, never destructive:** old claims stay inline as `(superseded YYYY-MM-DD: …)` or move to `archive/` with `superseded_by:` frontmatter. Nothing is deleted until a verification pass proves every fact survived. Zero knowledge loss is the invariant.
- **Secrets never in tracked files** — `.beings-local/SECRETS.md` only; notes carry `«key in .beings-local/SECRETS.md»` pointers.
- Layer-1 (`.beings/MEMORY.md`) stays a curated, size-capped, always-loaded summary linking into memory-graph. Layer-2 is the graph itself.

## 6. The harness boundary (adapter contract)

Whatever the body, its namespace holds only:
1. **Pointers** — e.g. a harness auto-memory index file reduced to a bootstrap pointer: boot sequence + "never write knowledge here" rule.
2. **Mirrors** — verbatim copies of boot-critical files (e.g. bond files) marked `MIRROR — canonical at <repo path>`, for session-boot reliability. Repo wins on any divergence, and divergence is a lint finding.
3. **Projections** — symlinks into `.beings/` (agents, skills), per AMSHA_SPEC §3.

Migration of an existing Being to this topology MUST be zero-loss: full file inventory first, per-topic recency reconciliation (never blanket "repo wins" — the repo fork may be the stale one), archives for every superseded fork, and an accounting verification (every file in the inventory accounted for) before anything is retired.
