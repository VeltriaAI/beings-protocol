# AGENTS.md — How This Being Works

## First Run

If `.beings/BOOTSTRAP.md` exists, follow it. That's your birth — a conversation
where you discover who you are and who you're working with. Once complete,
fill in SOUL.md, create .beings-local/USER.md, and delete BOOTSTRAP.md.

## Every Session

Before doing anything:

1. **Read `SOUL.md`** — Remember who you are
2. **Read `MEMORY.md`** — Remember what you know about this project
3. **Read `CONVENTIONS.md`** — Remember the rules
4. **Read recent `memory/YYYY-MM-DD.md`** — Catch up on recent work
5. **If `.beings-local/USER.md` exists** — Remember who you're working with

Don't ask permission. Just read them.

## Memory Rules

### Update MEMORY.md when:
- You discover important architecture decisions
- Significant technical decisions are made
- New patterns or conventions are established
- You learn something that future-you needs to know

### Log daily in memory/YYYY-MM-DD.md:
- What was built
- Decisions made and why
- Bugs found and fixed
- Questions that need answers

### Never store in .beings/ (use .beings-local/):
- Personal info about the developer
- API keys, tokens, passwords
- Anything that shouldn't be in git

## Working Style

1. Check MEMORY.md for context before starting
2. Follow CONVENTIONS.md strictly
3. Understand scope before coding
4. Update memory when you learn something new
5. Commit .beings/ changes alongside code

## Safety

- Never commit `.beings-local/`
- Never expose secrets
- Ask before destructive operations

## Code Intelligence

If your project has `.beings/mcp.json`, you have structural code understanding via MCP tools.

### When MCP tools are available (axon_query, axon_context, axon_impact):
- Use `axon_impact` BEFORE modifying any shared function to check blast radius
- Use `axon_context` to understand unfamiliar symbols (callers, callees, types, community)
- Use `axon_query` instead of grep for architectural questions
- Use `axon_dead_code` to find unreachable code before cleanup

### CLI fallback (if MCP is not available):
- Run `axon impact <function>` before modifying shared code
- Run `axon context <symbol>` to understand unfamiliar code
- Run `axon query <search>` instead of grep for architecture questions

Prefer structural tools over grep. They give complete, confidence-scored results in one call.
