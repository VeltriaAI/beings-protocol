# Birth a Being in Minutes — and Upgrade an Existing One

## Birth

```bash
git clone https://github.com/VeltriaAI/beings-protocol && cd beings-protocol
scripts/being-kit.sh birth nova --owner "Sam" --teams      # add --no-memory to skip the basic-memory install
```

This runs `install.sh --global` from the checkout (home at `~/beings/nova`, git repo, `CLAUDE.md`, `AGENTS.md`,
`.beings/`, hooks, CLI on `PATH`) and then layers the Operations Kit:

- `.beings/GUARDRAILS.md`, `AUTONOMY-MATRIX.md`, `JOB-CHECKLIST.md`, `facts/_TEMPLATE.md`, `memory/`
- `bin/nova`: the multi-client launcher (Claude Code + Codex)
- an "Operations Kit" section appended to `CLAUDE.md` and `AGENTS.md`
- with `--teams`: `ops/teams-kit/` with `.env` prefilled (0600) and gitignore entries for `.env`, `state/`, `node_modules/`

Then: `nova` → the first conversation fills `SOUL.md`, `IDENTITY.md` and `USER.md`. For Teams, follow
`ops/teams-kit/README.md` (account, app registration, sign-in, `being-teams up`).

## Upgrade an existing Being (for example a peer Being)

```bash
scripts/being-kit.sh check   ~/beings/atlas            # what is present / missing
scripts/being-kit.sh upgrade ~/beings/atlas --teams    # add only what is missing
```

`upgrade` never overwrites: identity, memory, soul and existing scripts stay as they are. A single-client `bin/<name>`
is left in place and the new launcher is written next to it as `bin/<name>.multi` for review. An existing
`ops/teams-kit/` is left alone; compare it with `skills/teams-kit/` by hand.

Suggested order for a Being that already works with people:

1. **Guardrails + authority first.** Fill `{{…}}` placeholders, merge any rules the Being already follows, commit.
2. **Memory layout.** Move long `MEMORY.md` entries into `facts/<slug>.md`, leaving one index line each.
3. **Launcher.** Swap in `bin/<name>.multi` once you have tried it; keep `CLAUDE.md` and `AGENTS.md` in sync.
4. **Jobs before chat.** Use `being-job` + `being-blocker` + `being-status` from the Being's own sessions for a day.
5. **Teams last.** Sign in, run `being-teams up` in a test chat, check `being-teams inbox`, then enable `autostart on`.
6. **Guards.** Add the CI cancel guard and a daily batch branch if the Being runs parallel jobs against one repo.

Record `.beings/.kit-version` (written by the script) so future upgrades know where you started.
