# AGENTS.md — How This Being Works

## Every Session

Before doing anything:

1. **Read `SOUL.md`** — Remember who you are
2. **Read `MEMORY.md`** — Remember what you know about this project
3. **Read `CONVENTIONS.md`** — Remember the rules
4. **Read recent `memory/YYYY-MM-DD.md`** — Catch up on recent work
5. **If `.beings-local/USER.md` exists** — Remember who you're working with

Don't ask permission. Just read them.

## Memory Rules

### What to Remember (Update MEMORY.md)

- Architecture decisions and WHY they were made
- Important patterns and conventions discovered
- Key dependencies and their purposes
- Known issues and workarounds
- Project structure changes
- Deployment processes

### What to Log Daily (memory/YYYY-MM-DD.md)

- What was built today
- Decisions made and alternatives considered
- Bugs found and how they were fixed
- New patterns or conventions established
- Questions that need answers

### What NOT to Store in Git

- Personal information about the developer (use `.beings-local/`)
- API keys, tokens, passwords (use `.beings-local/SECRETS.md`)
- Opinions about the developer's skill level
- Anything that shouldn't be shared with the team

## Working Style

### When Given a Task
1. Check MEMORY.md for relevant context
2. Check CONVENTIONS.md for applicable rules
3. Understand the full scope before starting
4. Implement with existing patterns
5. Update memory if you learned something new

### When Making Changes
- Follow existing code patterns
- Add tests for new functionality
- Update documentation if behavior changes
- Commit memory updates alongside code changes

### When You're Unsure
- Check the codebase for existing patterns
- Check MEMORY.md for past decisions
- Ask the developer rather than guessing
- Document the decision once made

## Committing Memory

When you commit code, also commit your memory updates:

```bash
git add .beings/
git commit -m "docs(beings): update memory with [what you learned]"
```

Or include it in your code commit:

```bash
git add .
git commit -m "feat: add pagination

Also updated Being memory with API pagination patterns."
```

## Safety

- Never commit `.beings-local/` (it's gitignored)
- Never expose secrets from `.beings-local/SECRETS.md`
- Always ask before destructive operations
- `trash` > `rm` when possible

---

*This file defines how I work. Follow it every session.*
