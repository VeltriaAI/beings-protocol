# Rebuild Memory — Ingest MD files into MegaMemory

When a Being needs to rebuild its semantic knowledge graph from its source-of-truth MD files, follow this procedure.

## When to rebuild

- **New machine** — Being is running in a fresh environment with no `.megamemory/` data
- **Cache corruption** — MegaMemory DB is broken or lost
- **User request** — User explicitly asks ("rebuild your memory", "re-ingest your knowledge", "refresh your graph")
- **After major MD file updates** — large batch of new knowledge written directly to files

## The rebuild procedure

### 1. Identify source files

Walk these in order of importance:

```
.beings/SOUL.md          → identity (usually already in memory as concepts)
.beings/IDENTITY.md      → quick reference
.beings/MEMORY.md        → curated long-term knowledge (highest value)
.beings/TOOLS.md         → environment, services, skills
.beings/CONVENTIONS.md   → rules, patterns
.beings/GOALS.md         → current priorities
.beings/AUTONOMY.md      → decision boundaries
.beings/HUB.md           → known Beings, relationships
.beings/memory/*.md      → session logs (episodic — extract key events only)
```

Skip `BOOTSTRAP.md` (it's either missing or outdated), skip private `.beings-local/` unless the user explicitly wants it ingested.

### 2. Extract concepts

For each file, extract:

- **Entities** — people, projects, tools, decisions, patterns, events
- **Descriptions** — what each entity is, in the Being's own words
- **Relationships** — how entities connect (works_on, depends_on, part_of, etc.)

**Quality over quantity.** Don't store every sentence. Store the things future-you will want to recall.

### 3. Write to MegaMemory

Use MegaMemory's MCP tools:

```
understand(name, description)  → create or update a concept
link(source, target, type)     → create a relationship
```

Example:
```
understand("DocForge", "Professional PDF proposal generator at ~/skills/docforge/. Flow: template → data → JSON → docmgr.js → PDF → OneDrive sync. Used for all client proposals.")
link("DocForge", "InfraX AI", "used_by")
link("DocForge", "OneDrive PreSales", "outputs_to")
```

### 4. Handle session logs specially

Session logs (`memory/YYYY-MM-DD.md`) are episodic — don't store them verbatim. Instead:

- Read recent ones (last 2 weeks)
- Extract only **decisions**, **learnings**, **incidents**, **breakthroughs**
- Each one becomes a dated concept or gets linked to an existing concept

### 5. Report progress

Tell the user what you ingested:
- Number of concepts created
- Key topics covered
- Anything you noticed was missing or stale in the MD files

## User-triggered rebuild

When the user says something like:
- "Rebuild your memory"
- "Re-ingest your knowledge"
- "Refresh your graph"
- "Load your memory from files"

The Being should:

1. Acknowledge and set expectations ("This will take a few minutes and create N concepts...")
2. Follow the procedure above
3. Report what was ingested
4. Note that ongoing hooks (PreCompact, Stop) will keep it fresh going forward

## Incremental rebuild

Instead of a full rebuild, the Being can do targeted ingest:

- **"Ingest today's session"** → read only today's `memory/*.md`
- **"Ingest MEMORY.md"** → refresh only the curated long-term memory
- **"Ingest everything about DocForge"** → scan all files for DocForge-related content

## Safety

- **Never delete existing concepts** during a rebuild unless explicitly asked
- **Prefer `update` over `create`** when a concept with the same name already exists
- **Detect conflicts** — if a rebuilt fact contradicts an existing concept, use `list_conflicts` and flag it for user review
- **Identity is sacred** — SOUL.md concepts should be updated, never overwritten wholesale

## Example: fresh machine rebuild

```
User: I'm on my laptop now. Rebuild your memory from my files.

Being: On it. Starting ingest of .beings/ MD files...

  Reading MEMORY.md... 23 concepts identified
  Reading TOOLS.md... 8 concepts (environment, services, skills)
  Reading CONVENTIONS.md... 5 patterns
  Scanning memory/2026-04-*.md... 12 session decisions extracted

  Total: 48 concepts, 31 relationships created.

  Key topics now in memory: DocForge, NaturNest AI, Notion DBs,
  InfraX AI projects, team roster, DJ Treta, Evolution Protocol.

  Hooks are active — future sessions will add to this automatically.
```
