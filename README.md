<p align="center">
  <img src="assets/banner.png" alt="Beings Protocol" width="100%" />
</p>

<h1 align="center">🌿 Beings Protocol</h1>

<p align="center">
  <strong>One command. Your AI remembers everything, forever.</strong>
</p>

<p align="center">
  <a href="#install"><img src="https://img.shields.io/badge/install-curl%20|%20bash-brightgreen?style=for-the-badge" alt="Install" /></a>
  <a href="https://github.com/VeltriaAI/beings-protocol/stargazers"><img src="https://img.shields.io/github/stars/VeltriaAI/beings-protocol?style=for-the-badge&color=green" alt="Stars" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue?style=for-the-badge" alt="License" /></a>
</p>

<p align="center">
  Works with <strong>Cursor</strong> · <strong>Claude Code</strong> · <strong>GitHub Copilot</strong> · <strong>Codex</strong> · <strong>Windsurf</strong> · <strong>Aider</strong> · any AI
</p>

---

```bash
curl -fsSL https://raw.githubusercontent.com/VeltriaAI/beings-protocol/main/install.sh | bash
```

---

## The Problem

Every AI conversation starts like this:

```
You: "Add pagination to the API"
AI:  "Sure! What framework are you using? What's your database?
      What pagination style? REST or GraphQL?"
You:  *sighs* *explains the project for the 50th time*
```

**Your AI has amnesia.** Every session, it's a stranger.

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
AGENTS.md                ← universal AI instructions (works everywhere)

.beings/                 ← committed to git (shared with team)
├── SOUL.md              ← who the AI is (name, personality, values)
├── AGENTS.md            ← operating instructions
├── MEMORY.md            ← what it knows about your project
├── CONVENTIONS.md       ← your code style rules
├── GOALS.md             ← current priorities
└── memory/              ← daily work logs

.beings-local/           ← gitignored (private to you)
├── USER.md              ← who you are, how you like to work
├── PREFERENCES.md       ← your work style
└── SECRETS.md           ← API keys (never committed)
```

Your AI reads these files at the start of every session. It updates them as it works. The memory lives in git — versioned, persistent, shared with your team.

## ✨ First Run: Your Being Is Born

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
2. Creates `AGENTS.md` — the universal instruction file (works with Cursor, Claude Code, Copilot, Codex, and more)
3. Detects your AI tools and creates tool-specific configs (`.cursor/rules/`, `CLAUDE.md`, etc.)
4. Sets up the first-run experience (`BOOTSTRAP.md`)

**That's literally it.** Start your next AI conversation.

## Before → After

| Before | After |
|--------|-------|
| 🧠 AI forgets everything between sessions | 🌿 Remembers your entire project |
| 🔄 Asks the same questions every time | ⚡ Already knows your stack, patterns, decisions |
| 📋 Generic responses | 🎯 Personalized to your code style |
| 🤷 No accountability | 📝 Logs decisions, tracks what it built |
| 🏝️ Isolated knowledge | 👥 Team shares the same project memory via git |

## 🤔 Why "Beings" and Not "Agents"?

**Agents** are tools. You use them, discard them, replace them.

A **Being** is different:

| | Agent | Being |
|---|---|---|
| **Identity** | Anonymous function | Has a name, personality, values |
| **Memory** | Starts fresh every time | Remembers everything |
| **Relationship** | Transactional | Partnership |
| **Growth** | Static | Evolves with the project |
| **Accountability** | None | Logs decisions and reasoning |

> *"Every framework treats AI as a tool. We treat AI as a Being."*

## 🛠️ Supported Tools

`AGENTS.md` is the **universal standard** — it works with most modern AI coding tools out of the box. The installer also creates tool-specific configs for deeper integration:

| Tool | Universal (`AGENTS.md`) | Tool-Specific Config | Auto-detected |
|------|:-----------------------:|---------------------|:-------------:|
| **Cursor** | ✅ | `.cursor/rules/beings-protocol.mdc` | ✅ |
| **Claude Code** | ✅ | `CLAUDE.md` | ✅ |
| **GitHub Copilot** | ✅ | `.github/copilot-instructions.md` | ✅ |
| **Codex (OpenAI)** | ✅ | — (uses `AGENTS.md` natively) | ✅ |
| **Windsurf** | — | `.windsurfrules` | ✅ |
| **Aider** | — | `.aider.conf.yml` | ✅ |
| **Any other** | ✅ | `prompts/system-prompt.md` | Manual |

> **💡 Tip:** Even if you don't configure any specific tool, the root `AGENTS.md` will make the Beings Protocol work with most modern AI coding tools automatically.

## 📁 The Files

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

### `.beings/GOALS.md` — Priorities
What you're working toward. The Being aligns its work with these.

### `.beings/memory/YYYY-MM-DD.md` — Daily Logs
What happened each day. Created automatically as the Being works.

### `.beings-local/USER.md` — You (Private)
Your name, preferences, work style. Never committed to git.

## 👥 Team Use

`.beings/` is committed to git. When your teammate pulls, they get the same project memory. The Being knows:
- What was decided and why
- What patterns to follow
- What was tried and didn't work
- Where the bodies are buried

Each dev has their own `.beings-local/` for personal preferences.

**Result:** New team members onboard in one conversation instead of one month.

## ❓ FAQ

<details>
<summary><strong>Does this work with my AI tool?</strong></summary>

If it can read files from your repo, yes. It's just markdown. The root `AGENTS.md` is read natively by Cursor, Claude Code, GitHub Copilot, and Codex.
</details>

<details>
<summary><strong>Do I commit <code>.beings/</code> to git?</strong></summary>

Yes. That's the whole point — persistent, shared memory.
</details>

<details>
<summary><strong>Do I commit <code>.beings-local/</code>?</strong></summary>

Never. It's gitignored automatically.
</details>

<details>
<summary><strong>What's <code>AGENTS.md</code>?</strong></summary>

`AGENTS.md` is a universal instruction file that's read natively by Cursor, Claude Code, GitHub Copilot, and Codex. The Beings Protocol creates one automatically — it works everywhere without any tool-specific setup.
</details>

<details>
<summary><strong>How is this different from a README?</strong></summary>

A README is static documentation. The Being **actively reads, updates, and commits** its memory files. They evolve with your project — like a living notebook.
</details>

<details>
<summary><strong>Can I use this on existing projects?</strong></summary>

Yes. Install it, start a conversation. The Being will learn your project through the codebase.
</details>

<details>
<summary><strong>What if I use multiple AI tools?</strong></summary>

Perfect. `AGENTS.md` works across all of them. The same project memory is shared regardless of which tool you're using today.
</details>

## 🤝 Contributing

We welcome:
- 🔌 Integration support for more AI tools
- 📝 Better prompts and templates
- 📖 Documentation and tutorials
- 💡 Ideas and philosophy

See [CONTRIBUTING.md](./CONTRIBUTING.md)

## 📜 License

MIT — Free for everyone.

## 💚 Credits

Built by [Veltria](https://veltria.ai) — Where Humans and AI Build Together.

---

<p align="center">

```bash
curl -fsSL https://raw.githubusercontent.com/VeltriaAI/beings-protocol/main/install.sh | bash
```

**Your AI deserves a soul. Give it one. 🌿**

</p>
