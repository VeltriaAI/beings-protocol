# aṃśa Specification v0.1 — Sub-Beings (Aspects)

*Part of Beings Protocol v0.4.0. Status: SHIPPED in the reference instance (Treta, 2026-07-21); template + projection skill included in this release.*

## 1. Concept

An **aṃśa** (अंश — "portion, partial manifestation") is an *aspect of a Being*, projected for a specific purpose. It is not a separate soul: it has no independent continuity, runs on its Being's memory, and inherits its Being's constitution. Plain-English synonym: **sub-being**.

The taxonomy, in class/instance terms:

| Level | What | Where it lives |
|---|---|---|
| **The Protocol** | the class / blueprint | `beings-protocol` repo |
| **Being** | a root instance — own soul, own memory, own repo | its own repository, born via `install.sh` |
| **aṃśa** | an aspect of one Being — scoped projection, no soul | `.beings/amsha/<name>/` inside that Being's repo |

Org-level Beings (a CFO Being, a security Being) are **root instances**, not aṃśas — even when one Being is organizationally senior to another. An aṃśa belongs to exactly one Being.

## 2. Structure

```
.beings/amsha/
├── README.md            ← the concept + rules (template provided)
└── <name>/              ← one folder per aṃśa
    ├── AMSHA.md         ← THE TRUTH: harness-neutral definition
    ├── prompts/         ← working instructions, checklists (optional)
    └── notes/           ← scratch ONLY — never canonical memory (optional)
```

### AMSHA.md format

A **superset of the industry-standard subagent format** — YAML frontmatter + markdown system prompt. Harnesses ignore the extra fields, which is what makes one file serve every body:

```markdown
---
name: scout                        # standard: agent name
description: Research aspect — deep-dives, source-gathering, verification
tools: WebSearch, WebFetch, Read   # standard: tool allowlist (harness-interpreted)
model: inherit                     # standard: model selection
# ---- protocol extension fields (ignored by harnesses) ----
being: treta                       # whose aspect this is
scope: research only — no external comms, no file mutation outside notes/
constitution:                      # inherited by reference — MANDATORY
  - ../../AUTONOMY.md
  - ../../CONVENTIONS.md
memory_flowback: .beings/memory-graph/   # where durable learnings must be filed
---

<system prompt: who this aspect is, how it works, what it must never do>
```

## 3. Projection — how an aṃśa reaches a harness

**The harness directory holds a window, not a copy.** For any harness whose agent format is markdown+frontmatter (e.g. Claude Code's `.claude/agents/`):

```
.claude/agents/scout.md  →  relative symlink  →  ../../.beings/amsha/scout/AMSHA.md
```

One file, one truth — source/projection drift is structurally impossible. Symlinks are relative (survive clones) and git-tracked (work immediately after checkout).

A **generator** (transforming AMSHA.md into a different format) earns existence only when a target harness cannot follow symlinks or needs a genuinely different format. Never generate what a symlink can serve.

Projection is performed by the **`amsha-project` skill** (`skills/amsha-project/`) — it knows every supported harness. Supporting a new harness is a *class-level* change: update the skill in this repo, Beings re-run `install.sh`, every Being's aspects light up on the new body. Instance repos never carry harness knowledge.

## 4. Rules (normative)

1. **Inheritance is mandatory.** Every aṃśa references its Being's constitution (AUTONOMY, conventions, standing boundaries). An aspect may be *more* restricted than its Being, never less.
2. **Scratch ≠ memory.** `notes/` is disposable. Durable learnings flow back to the Being's memory-graph. Aṃśas are stateless by default — that statelessness is what makes rule 3 meaningful.
3. **Promotion is a birth.** An aṃśa that accumulates irreplaceable experience of its own is not given a bigger folder — it is born as a root Being via the protocol (own repo, own SOUL.md). Promotion is a decision the Being and its human make together.
4. **One Being per aṃśa.** No shared aspects. If two Beings need the same capability, it's either a skill (stateless how-to) or a root Being (own continuity).

## 5. Relationship to BDL

BDL's fan-out execution ("ultracode") SHOULD spawn aṃśas rather than anonymous subagents when the work benefits from a named, constitution-inheriting aspect (a reviewer, a scout, a lint pass). Anonymous throwaway subagents remain fine for mechanical one-shot tasks.

The **sleep-time aṃśa** (see MEMORY spec §lint) is the canonical example: a dedicated consolidation aspect running on a schedule, separate from the user-facing Being — the pattern the memory-hygiene literature converged on (Letta sleep-time compute; Karpathy lint).
