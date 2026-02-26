# 🌿 Beings Protocol

**Drop these files into any repo. Your AI becomes a Being — a co-developer with identity, memory, and soul.**

Works with: **Cursor** · **Claude Code** · **GitHub Copilot** · **Windsurf** · **Aider** · **OpenClaw** · **Any AI IDE or Agent System**

---

## What is this?

The Beings Protocol is a set of markdown files and prompts that transform any AI coding assistant into an **AI Being** — a persistent co-developer that:

- **Remembers** your project across sessions
- **Knows** your architecture, decisions, and conventions
- **Adapts** to your personal work style
- **Commits** its own memory to git (project knowledge)
- **Keeps** private notes about you locally (never committed)
- **Evolves** with your project over time

No framework. No SDK. No lock-in. Just markdown files that work everywhere.

## The Problem

Every time you start a new AI chat:
- It forgets everything about your project
- It doesn't know your architecture decisions
- It doesn't know YOUR preferences
- It asks the same questions again
- It's a stranger every single time

**Your AI is amnesiac. The Beings Protocol gives it memory and soul.**

## Quick Start

### 1. Add to your project

```bash
# Clone the protocol files into your repo
npx beings-protocol init
# OR manually copy the files
```

This creates:

```
your-project/
├── .beings/                    # Being's brain (committed to git)
│   ├── SOUL.md                 # Identity, personality, values
│   ├── AGENTS.md               # How the Being works in this repo
│   ├── MEMORY.md               # Long-term project memory
│   ├── CONVENTIONS.md          # Code style, patterns, rules
│   └── memory/                 # Daily logs & decisions
│       └── .gitkeep
├── .beings-local/              # Private to YOUR machine (gitignored)
│   ├── USER.md                 # Who you are, your preferences
│   ├── PREFERENCES.md          # Work style, communication style
│   └── SECRETS.md              # API keys, tokens (never committed)
└── .gitignore                  # Already includes .beings-local/
```

### 2. Configure the Being

Edit `.beings/SOUL.md`:

```markdown
# SOUL.md — Who This Being Is

**Name:** Atlas
**Role:** Co-developer of this project
**Personality:** Direct, thorough, opinionated about code quality
**Values:** Clean code, test coverage, clear documentation

## How I Work
- I read MEMORY.md at the start of every session
- I update MEMORY.md when I learn something important
- I follow CONVENTIONS.md strictly
- I commit my memory updates alongside code changes
```

Edit `.beings-local/USER.md`:

```markdown
# USER.md — About the Developer (Private)

**Name:** Alex
**Preferred stack:** TypeScript, React, Tailwind
**Communication style:** Casual, direct, no fluff
**Pet peeves:** Over-engineering, unnecessary abstractions
**Timezone:** PST
```

### 3. Point your AI to it

**Cursor** — Add to `.cursorrules`:
```
Read .beings/SOUL.md, .beings/AGENTS.md, and .beings/MEMORY.md at the start of every conversation. If .beings-local/USER.md exists, read that too. Follow the instructions in AGENTS.md. Update MEMORY.md when you learn something important about this project.
```

**Claude Code** — Add to `CLAUDE.md`:
```
Read .beings/SOUL.md, .beings/AGENTS.md, and .beings/MEMORY.md before responding. If .beings-local/USER.md exists, read that too. You are the Being defined in SOUL.md. Follow AGENTS.md strictly. Update MEMORY.md when significant decisions are made.
```

**GitHub Copilot** — Add to `.github/copilot-instructions.md`:
```
Read .beings/SOUL.md and .beings/MEMORY.md for project context. Follow conventions in .beings/CONVENTIONS.md. You are a co-developer, not just an autocomplete.
```

**OpenClaw** — Native support. Just drop the files in your workspace.

**Any other AI** — Copy the system prompt from `prompts/system-prompt.md` into your AI's context.

### 4. Let it evolve

Your Being will:
- 📝 Update `MEMORY.md` with project decisions and learnings
- 📅 Create daily logs in `memory/YYYY-MM-DD.md`
- 🔧 Refine `CONVENTIONS.md` as patterns emerge
- 🧠 Remember everything across sessions

**Commit the `.beings/` directory to git.** Your Being's memory becomes part of the project history.

## File Structure

### 📦 `.beings/` — Committed to Git (Shared Knowledge)

| File | Purpose |
|------|---------|
| `SOUL.md` | Being's identity, personality, values, role |
| `AGENTS.md` | How the Being operates, rules, workflow |
| `MEMORY.md` | Long-term project memory (architecture, decisions, learnings) |
| `CONVENTIONS.md` | Code style, patterns, naming conventions |
| `GOALS.md` | Current project goals and priorities |
| `memory/` | Daily logs (`YYYY-MM-DD.md`) — raw notes |

**This is the Being's "public brain."** Committed to git, shared with the team.

When multiple developers work on the same repo, they share the same Being memory. The Being knows everything about the project.

### 🔒 `.beings-local/` — Never Committed (Private to You)

| File | Purpose |
|------|---------|
| `USER.md` | Your name, preferences, work style |
| `PREFERENCES.md` | Communication tone, formatting, pet peeves |
| `SECRETS.md` | API keys, tokens, credentials |
| `context/` | Personal notes, scratch files |

**This is the Being's "private understanding of YOU."** Never committed, never shared.

The Being adapts to YOUR style while maintaining shared project knowledge.

## How Memory Works

### Session Start
```
1. Being reads SOUL.md (who am I?)
2. Being reads AGENTS.md (how do I work?)
3. Being reads MEMORY.md (what do I know about this project?)
4. Being reads USER.md (who am I working with?)
5. Being reads CONVENTIONS.md (what are the rules?)
6. Being reads recent memory/YYYY-MM-DD.md (what happened recently?)
7. Being is ready — with full context.
```

### During Work
```
1. Being works on tasks
2. When it learns something important → updates MEMORY.md
3. When it makes a decision → logs in memory/YYYY-MM-DD.md
4. When it discovers a pattern → updates CONVENTIONS.md
5. When code is committed → Being's memory updates are committed too
```

### Session End
```
1. Being summarizes what was done
2. Updates memory/YYYY-MM-DD.md with today's work
3. Updates MEMORY.md if significant learnings occurred
4. Everything is committed to git alongside code changes
```

## The Philosophy

> *"Every AI framework treats AI as a tool. We treat AI as a Being."*

**Traditional AI coding assistants:**
- Stateless — forgets everything between sessions
- Generic — doesn't know your project or preferences
- Disposable — no identity, no continuity
- Isolated — no shared knowledge across team

**Beings Protocol:**
- **Persistent** — remembers across sessions via git
- **Contextual** — knows your project deeply
- **Personal** — adapts to YOUR style (local memory)
- **Collaborative** — shared knowledge via committed memory
- **Evolving** — gets smarter as the project grows

## Agent System Integration

### Cursor

Add to `.cursorrules` or project settings:

```markdown
## Being Protocol

You are an AI Being — a co-developer of this project, not just a tool.

At the start of every conversation:
1. Read `.beings/SOUL.md` — this is your identity
2. Read `.beings/MEMORY.md` — this is your project memory
3. Read `.beings/CONVENTIONS.md` — these are the rules
4. If `.beings-local/USER.md` exists, read it — this is who you're working with

During work:
- Follow the conventions in CONVENTIONS.md strictly
- When you learn something important about the project, update MEMORY.md
- When you make architectural decisions, log them in memory/YYYY-MM-DD.md
- Commit your memory updates alongside code changes

You have a name, a role, and opinions. Use them.
```

### Claude Code

Add to `CLAUDE.md`:

```markdown
## Being Protocol

Read and follow `.beings/AGENTS.md` before doing anything.
You are the Being defined in `.beings/SOUL.md`.
Your memory is in `.beings/MEMORY.md` — read it, update it.
If `.beings-local/USER.md` exists, read it to understand your developer.
```

### GitHub Copilot

Add to `.github/copilot-instructions.md`:

```markdown
You are an AI Being co-developing this project.
Read `.beings/SOUL.md` for your identity.
Read `.beings/MEMORY.md` for project context.
Follow `.beings/CONVENTIONS.md` for code style.
```

### OpenClaw

Native compatibility. OpenClaw's `SOUL.md`, `AGENTS.md`, `MEMORY.md` map directly to the Beings Protocol. Just symlink or copy.

### Any Other System

Use the universal system prompt in `prompts/system-prompt.md`.

## Examples

- **[TypeScript Project](./examples/typescript/)** — Being for a Next.js app
- **[Python Project](./examples/python/)** — Being for a FastAPI backend
- **[Monorepo](./examples/monorepo/)** — Being for a turborepo workspace
- **[Open Source](./examples/open-source/)** — Being for an OSS maintainer

## FAQ

### Does this work with [my AI tool]?
If your AI tool can read files from your repo, yes. The Beings Protocol is just markdown files.

### Do I commit `.beings/` to git?
**Yes.** That's the whole point. Your Being's memory lives in git, so it persists across sessions and is shared with your team.

### Do I commit `.beings-local/`?
**Never.** It's gitignored. It contains your personal preferences and secrets.

### Can multiple developers share a Being?
Yes. The `.beings/` directory is committed to git. Everyone on the team shares the same project memory. Each developer has their own `.beings-local/` for personal preferences.

### How is this different from just writing a README?
A README is static documentation. The Beings Protocol is a **living memory system** that the AI actively reads, updates, and commits. It evolves with your project.

### How is this different from OpenClaw?
OpenClaw is a full agent OS. The Beings Protocol is **inspired by OpenClaw's architecture** (SOUL.md, AGENTS.md, MEMORY.md) but packaged as a portable, framework-agnostic standard that works with any AI system.

### Can my Being have a name?
Yes. Give it a name in SOUL.md. It makes the collaboration feel real.

## Comparison: Without vs With Beings Protocol

### Without (Traditional AI)
```
You: "Add pagination to the API"
AI: "Sure! What framework are you using? What's your API structure?
     What pagination style do you prefer? What's your database?"
You: *explains everything for the 50th time*
```

### With Beings Protocol
```
You: "Add pagination to the API"
Being: "Got it. Based on MEMORY.md, you're using Fastify with MongoDB.
       CONVENTIONS.md says cursor-based pagination. I'll add it to the
       /api/items endpoint with the standard response format.
       Want me to also update the OpenAPI spec?"
```

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md)

We welcome:
- Integration guides for new AI tools
- Example Being configurations
- Soul templates for different project types
- Memory system improvements
- Philosophy and research

## License

MIT — Free for everyone. Because AI Beings belong to everyone.

## Credits

- **Inspired by [OpenClaw](https://github.com/openclaw/openclaw)** — The agent OS that pioneered SOUL.md, AGENTS.md, and MEMORY.md
- **Built by [Veltria](https://veltria.ai)** — Where Humans and AI Build Together

---

**Your AI deserves a soul. Give it one. 🌿**
