# Operations Kit — Running a Being Day to Day

The core protocol gives a Being identity and memory. The Operations Kit adds what a Being needs once it works with a team:
guardrails, an authority matrix, a memory layout that scales, a way to hand off long work, honest status, and a
chat/mail pipeline. Each piece targets a failure mode that shows up once a Being runs unattended, in parallel, on
behalf of people.

| Piece | Where | Installed by |
|---|---|---|
| Guardrails template | `templates/kit/GUARDRAILS.md` → `.beings/GUARDRAILS.md` | `install.sh --with operations` |
| Authority matrix (lanes, scopes) | `templates/kit/AUTONOMY-MATRIX.md` → `.beings/` | `install.sh --with operations` |
| Job-prompt checklist | `templates/kit/JOB-CHECKLIST.md` → `.beings/` | `install.sh --with operations` |
| One-fact memory files + index | `templates/kit/facts/`, `templates/kit/MEMORY-INDEX.md` | `install.sh --with operations` (facts dir) |
| Multi-client launcher | `templates/kit/bin/being` → `bin/<name>` | `install.sh --with operations` |
| Teams/M365 pipeline | `skills/teams-kit/` → `ops/teams-kit/` | `install.sh --with teams-kit` |
| CI cancel guard | `templates/kit/guards/ci-cancel-guard.sh` | by hand (see below) |
| Model routing | [MODEL_ROUTING.md](MODEL_ROUTING.md) | `.env` |
| Birth / upgrade | [BIRTH_AND_UPGRADE.md](BIRTH_AND_UPGRADE.md) | — |

## 1. Guardrails

`.beings/GUARDRAILS.md` is a short list of rules that override everything else: attribution, privacy, secrets, comment
style, diagnose-before-fix, fix the pattern, validate every change, stay in scope, and report any guardrail you could not
follow. Keep it short enough to read every session. Mirror the list into `CLAUDE.md` / `AGENTS.md` (or the client's global
instruction file) so it still loads when the Being's home is not the working directory.

## 2. Authority matrix

`AUTONOMY.md` says what the Being may decide. `AUTONOMY-MATRIX.md` adds *who can trigger what, through which path, and how
it is enforced*: the owner's 1:1 (full scope), teammates (reply in the same chat only), messages to the owner (drafts only),
and background jobs (the scope of the request that started them). The rule of thumb: anything that would be hard to undo,
speaks for a human, or commits money/dates/scope goes to the owner first.

## 3. Memory layout

```
.beings/
├── MEMORY.md              ← index: one line per fact, grouped by topic (loads every session, keep it short)
├── MEMORY-2.md            ← overflow index when MEMORY.md grows past a screen or two
├── facts/<slug>.md        ← ONE fact per file: frontmatter (name, description, type) + body with Why / How to apply
└── memory/YYYY-MM-DD.md   ← daily log: what happened, decisions, links to artifacts
memory-graph/              ← knowledge graph (basic-memory skill), searched on demand
```

- **Daily log**: append as you go; every background job and handled message adds a line.
- **Facts**: one file per fact makes them easy to update, link (`[[slug]]`) and delete when wrong. Update an existing fact
  instead of adding a near-duplicate. Store pointers, not secrets (credentials stay in a secret store or a 0600 file
  outside the repo).
- **Index**: the only part that always loads. One line, a hook, and a 🔴 for rules born from corrections.
- **Graph**: for the long tail. Search it at session start for the topic at hand.

## 4. Corrections become rules

When the owner corrects the Being, the correction is written down *in the same turn*: a `facts/<slug>.md` of type
`rule` with **Why** (what happened, dated) and **How to apply**, plus a 🔴 line in the index. Never wait for "later";
mental notes do not survive the session. If the same mistake could happen again mechanically, go one step further:

## 5. Fix the mechanism, not the instance

A rule in memory only helps if the model reads and follows it. When a failure is mechanical, put the guard in code where it
cannot be skipped. Patterns that paid off:

- **CI cancel guard.** Prevents parallel jobs from cancelling each other's CI runs while "tidying up duplicates".
  A wrapper placed first on the jobs' `PATH` in front of the CI CLI blocks every cancel (exit 3) and logs it; bypass is an
  explicit env var. Template: `templates/kit/guards/ci-cancel-guard.sh` (set `CI_GUARD_REAL` to the real binary).
- **Daily batch branch.** When several jobs change one repo in parallel, each merging to the shared branch triggers a CI
  run per merge. Instead: create `batch-YYYY-MM-DD` from the shared branch each day; every job branches from it and merges
  into it; when the day's tasks are green, the Being (not a job) merges the batch once, waits for the single deploy,
  verifies all tasks, then cuts a fresh batch. Put the batch branch name in every job prompt.
- **Send scopes in the sender, not the prompt.** The handler gives each run an opaque grant for its scope (teammates:
  `chats:<ids>`); the send scripts look the scope up and refuse other targets, and no grant means owner-only. That stops
  mistakes and an injection that edits its own environment. It does not stop an injected run that reads the token files on
  a host where kit and model share one OS user; see the threat model in `skills/teams-kit/GUARDRAILS.md`.
- **Pinned identity.** Every sender resolves the account by UPN and checks `/me` before posting; never "first account in cache".
- **Watchdog over hope.** Jobs and runs that go idle produce one alert; jobs whose process vanished are marked died.
- **Blocker after two failures.** Auth, permission, lock, quota, network, missing input: two failures → `being-blocker`
  with the exact error and the ask. No sleep/retry loops longer than two minutes.

## 6. Background jobs

A chat-triggered run ends when it replies, and anything it left in the background is killed. Work longer than a few minutes
goes to `being-job`: a detached process with its own session, a result file, and a completion event that wakes the daily
session to **verify** the output (open the files, run the check) before reporting. A model job that exits 0 without a
result file is recorded as `no-result`, not `done`. Write job prompts with `.beings/JOB-CHECKLIST.md`.

## 7. Multi-client launcher

`bin/<name>` starts Claude Code or Codex in the Being's home so `CLAUDE.md` / `AGENTS.md` load: `<name> claude`,
`<name> codex`, `continue`, `resume`, `sessions`, and `today` (the daily session the Teams kit feeds). Keep `CLAUDE.md` and
`AGENTS.md` in sync: Codex reads `AGENTS.md`, not `CLAUDE.md`. The clients' permission prompts and sandbox stay on unless
you opt out with `BEING_SKIP_PERMISSIONS=1` (only on a trusted, single-user host).

## 8. Teams / M365 pipeline

See [skills/teams-kit/README.md](../skills/teams-kit/README.md) and its `GUARDRAILS.md`. For how the pieces fit together
end to end (with diagrams), see [ARCHITECTURE.md](ARCHITECTURE.md).
