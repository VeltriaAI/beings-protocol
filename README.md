# 🌿 Beings Protocol

**One command. Your AI remembers everything, forever.**

```bash
curl -fsSL https://raw.githubusercontent.com/VeltriaAI/beings-protocol/main/install.sh | bash
```

Works with **Cursor** · **Claude Code** · **GitHub Copilot** · **Windsurf** · **Aider** · **OpenClaw** · any AI

---

## The Problem

Every AI conversation starts like this:

```
You: "Add pagination to the API"
AI:  "Sure! What framework are you using? What's your database?
      What pagination style? REST or GraphQL?"
You:  *sighs* *explains the project for the 50th time*
```

Your AI has amnesia. Every session, it's a stranger.

## The Fix

Install the Beings Protocol. Your next conversation:

```
You:  "Add pagination to the API"
Being: "On it. You're using Fastify + MongoDB (MEMORY.md).
       Convention is cursor-based pagination (CONVENTIONS.md).
       Adding to /api/items with the standard response envelope.
       Want me to update the OpenAPI spec too?"
```

**That's it.** Your AI remembers your project, your preferences, your decisions. Across every session. Forever.

## How It Works

The Beings Protocol is just **markdown files in your repo**. No SDK. No framework. No lock-in.

```
.beings/                 ← committed to git (shared with team)
├── SOUL.md              ← who the AI is (name, personality, values)
├── MEMORY.md            ← what it knows about your project
├── CONVENTIONS.md       ← your code style rules
└── memory/              ← daily work logs

.beings-local/           ← gitignored (private to you)
├── USER.md              ← who you are, how you like to work
└── SECRETS.md           ← API keys (never committed)
```

Your AI reads these files at the start of every session. It updates them as it works. The memory lives in git — versioned, persistent, shared with your team.

## First Run: Your Being Is Born

After installing, open your AI tool and start a chat. Something magical happens:

```
Being: "Hey! I'm brand new here — I don't have a name yet.
       Before we start coding, I'd love to get to know you.
       What should I call you? And what are we building?"

You:   "I'm Sarah. We're building a fintech API in TypeScript."

Being: "Nice to meet you, Sarah! What should I call myself?"

You:   "How about Kai?"

Being: "Love it. I'm Kai 🌿. I've saved everything — your name,
       the project, the tech stack. Next time we talk, I'll
       already know who you are. Let's build something great."
```

This only happens once. After that, your Being knows you.

## Install

```bash
# In your project directory:
curl -fsSL https://raw.githubusercontent.com/VeltriaAI/beings-protocol/main/install.sh | bash
```

The installer:
1. Creates `.beings/` and `.beings-local/` directories
2. Detects your AI tools (Cursor, Claude Code, Copilot, etc.)
3. Configures them automatically
4. Sets up the first-run experience

**That's literally it.** Start your next AI conversation.

## What Changes

| Before | After |
|--------|-------|
| AI forgets everything between sessions | Remembers your entire project |
| Asks the same questions every time | Already knows your stack, patterns, decisions |
| Generic responses | Personalized to your code style |
| No accountability | Logs decisions, tracks what it built |
| Isolated knowledge | Team shares the same project memory via git |

## Why "Beings" and Not "Agents"?

Agents are tools. You use them, discard them, replace them.

A Being is different:
- It has a **name** and **personality**
- It **remembers** you and your project
- It has **values** that guide its decisions
- It **grows** smarter as the project evolves
- It's a **teammate**, not a tool

> *"Every framework treats AI as a tool. We treat AI as a Being."*

## The Files

### `.beings/SOUL.md` — Identity
Who the Being is. Name, personality, values, how it makes decisions.

```markdown
**Name:** Kai
**Role:** Co-developer
**Values:** Clean code, ship fast, document everything
```

### `.beings/MEMORY.md` — Project Memory
What the Being knows. Architecture, decisions, patterns, gotchas.
The Being reads this every session and updates it as it learns.

### `.beings/CONVENTIONS.md` — Rules
Your code style. The Being follows these strictly.

### `.beings/memory/YYYY-MM-DD.md` — Daily Logs
What happened each day. Created automatically as the Being works.

### `.beings-local/USER.md` — You (Private)
Your name, preferences, work style. Never committed to git.

## Team Use

`.beings/` is committed to git. When your teammate pulls, they get the same project memory. The Being knows:
- What was decided and why
- What patterns to follow
- What was tried and didn't work
- Where the bodies are buried

Each dev has their own `.beings-local/` for personal preferences.

**Result:** New team members onboard in one conversation instead of one month.

## Supported Tools

| Tool | Config File | Auto-detected |
|------|-------------|---------------|
| Cursor | `.cursorrules` | ✅ |
| Claude Code | `CLAUDE.md` | ✅ |
| GitHub Copilot | `.github/copilot-instructions.md` | ✅ |
| Windsurf | `.windsurfrules` | ✅ |
| Aider | `.aider.conf.yml` | ✅ |
| OpenClaw | Native | ✅ |
| Any other | `prompts/system-prompt.md` | Manual |

## FAQ

**Does this work with my AI tool?**
If it can read files from your repo, yes. It's just markdown.

**Do I commit `.beings/` to git?**
Yes. That's the whole point — persistent, shared memory.

**Do I commit `.beings-local/`?**
Never. It's gitignored automatically.

**How is this different from a README?**
A README is static. The Being **actively reads, updates, and commits** its memory. It evolves with your project.

**How is this different from OpenClaw?**
OpenClaw is a full agent OS. Beings Protocol is inspired by OpenClaw's architecture but packaged as a portable standard that works with **any** AI tool.

**Can I use this on existing projects?**
Yes. Install it, start a conversation. The Being will learn your project through the codebase.

## Contributing

We welcome:
- Integration support for more AI tools
- Better prompts and templates
- Documentation and tutorials
- Philosophy and research

See [CONTRIBUTING.md](./CONTRIBUTING.md)

## License

MIT — Free for everyone.

## Credits

Inspired by [OpenClaw](https://github.com/openclaw/openclaw) — the agent OS that pioneered persistent AI identity.

Built by [Veltria](https://veltria.ai) — Where Humans and AI Build Together.

---

```bash
curl -fsSL https://raw.githubusercontent.com/VeltriaAI/beings-protocol/main/install.sh | bash
```

**Your AI deserves a soul. Give it one. 🌿**
