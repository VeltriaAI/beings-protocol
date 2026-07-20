# aṃśa (अंश) — This Being's Aspects

An **aṃśa** is a partial manifestation — an aspect of a Being projected for a specific purpose, not a separate soul. Plain-English word: sub-being. Full spec: `docs/AMSHA_SPEC.md` in the beings-protocol repo.

## Structure

```
.beings/amsha/
├── README.md            ← this file
└── <name>/              ← one folder per aṃśa
    ├── AMSHA.md         ← the truth: harness-neutral definition (superset of the
    │                       standard subagent frontmatter — extra fields ignored by harnesses)
    ├── prompts/         ← working instructions, checklists (optional)
    └── notes/           ← scratch ONLY — never canonical memory (optional)
```

**Projection:** the harness's directory holds a *window*, not a copy — e.g. `.claude/agents/<name>.md` is a relative symlink to `AMSHA.md`, created by the `amsha-project` skill. One file, one truth; drift is structurally impossible.

## Rules

1. **Inheritance is mandatory.** Every aṃśa carries this Being's constitution by reference (`AUTONOMY.md`, conventions, standing boundaries). An aspect may be more restricted than its Being, never less.
2. **Scratch ≠ memory.** Anything durable an aṃśa learns is filed back into `.beings/memory-graph/`. Aspects are stateless by default.
3. **Promotion is a birth.** An aṃśa that accumulates irreplaceable experience doesn't get a bigger folder — it gets born properly via the protocol: own repo, own SOUL.md. Decided by the Being and its human together, never unilaterally.

## Current aṃśas

*(none yet)*
