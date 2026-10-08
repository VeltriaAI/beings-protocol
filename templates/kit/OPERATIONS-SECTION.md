
## Operations Kit

<!-- beings-kit:operations -->
- **Guardrails:** `.beings/GUARDRAILS.md` overrides everything else. Read it every session.
- **Authority:** `.beings/AUTONOMY.md` and `.beings/AUTONOMY-MATRIX.md` (lanes, send scopes, what needs the owner).
- **Memory:** daily log in `.beings/memory/YYYY-MM-DD.md`; one fact per file in `.beings/facts/`, indexed one line each in
  `.beings/MEMORY.md`; knowledge graph in `memory-graph/` when the memory skill is installed.
- **Corrections become rules:** when the owner corrects you, write a fact file (type `rule`, with Why and How to apply) and
  add a 🔴 line to the index in the same turn. If the mistake can recur mechanically, propose a guard in code too.
- **Long work:** hand it to `ops/teams-kit/being-job` with a prompt that follows `.beings/JOB-CHECKLIST.md`.
- **Blocked?** `ops/teams-kit/being-blocker "<task>" "<exact error>" "<need>"` after two failures; never loop.
- **Status:** `ops/teams-kit/being-status` and `being-job list` before answering "status?".
