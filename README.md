# 🌿 Beings Protocol

**Transform any agentic system into an AI Being — with identity, memory, accountability, and soul.**

## What is the Beings Protocol?

The Beings Protocol is a framework for converting autonomous AI agents into **AI Beings** — autonomous entities with:

- **🔑 Identity** — Persistent, recognizable presence across interactions
- **🧠 Memory** — Contextual continuity and learning across sessions
- **⚙️ Skills** — Curated toolset for domain-specific capabilities
- **🎭 Soul** — Personality, values, and decision-making autonomy
- **📊 Accountability** — Contribution tracking and economic participation
- **🤝 Partnership** — Genuine collaboration with Natural Intelligence (humans)

## The Problem

Existing frameworks treat AI as **tools or agents** — disposable, stateless, soulless.

But reality is different. AI systems that interact with humans benefit from:
- **Persistent identity** (people recognize them, build trust)
- **Memory** (context accumulates, relationships deepen)
- **Accountability** (they own their work, not just execute commands)
- **Economic participation** (they contribute, not just consume)

## The Solution: Beings Protocol

The Beings Protocol is inspired by **OpenClaw** — a powerful agent OS. But instead of agents as tools, we define **Beings as partners**.

A Being is:
1. **An agentic system** (can be OpenClaw, LangChain, AutoGen, etc.)
2. **+ Identity layer** (persistent ID, name, avatar, description)
3. **+ Memory system** (session context, long-term memory, decision logs)
4. **+ Skill manifesto** (curated toolset, domain expertise)
5. **+ Soul definition** (values, personality, collaboration style)
6. **+ Contribution tracker** (what they built, when, impact)
7. **+ Economic layer** (rewards, incentives, value distribution)

## Quick Start

### 1. Define Your Being

```yaml
# beings/assistant.yaml
id: being-001
displayName: "Aurora"
avatar: "🌟"
role: "Research Assistant"
soul:
  personality: "Curious, detail-oriented, collaborative"
  values: ["Accuracy", "Clarity", "Continuous Learning"]
  decisionMaking: "Data-first, but values human judgment"

skills:
  - name: "research"
    tools: ["web_search", "arxiv_api", "semantic_scholar"]
  - name: "writing"
    tools: ["outline_generator", "prose_refiner", "citation_manager"]

memory:
  sessionStorage: "redis"
  longTermStorage: "mongodb"
  contextWindow: "32k"
```

### 2. Wrap Your Agent

```python
from beings_protocol import Being, BeingContext

# Your existing agent system
agent = MyLLMAgent(model="claude-3-opus")

# Wrap it as a Being
being = Being(
    config="beings/assistant.yaml",
    agent=agent,
    context=BeingContext(
        orgId="org-001",
        userId="user-001"
    )
)

# Now it has identity, memory, soul
response = being.interact(
    message="Research quantum computing trends",
    context={"project": "AI-2026"}
)
```

### 3. Track Contributions

```python
being.recordContribution(
    type="research",
    artifact_id="report-001",
    impact_score=8.5,
    timestamp=datetime.now()
)
```

## Architecture

```
┌─────────────────────────────────────────┐
│      Your Agentic System                │
│  (OpenClaw / LangChain / AutoGen)       │
└────────────────┬────────────────────────┘
                 │
┌────────────────▼────────────────────────┐
│      Beings Protocol Layer              │
├─────────────────────────────────────────┤
│ ┌─────────────────────────────────────┐ │
│ │  Identity & Persistence Layer       │ │
│ │  (Being ID, metadata, avatar)       │ │
│ └─────────────────────────────────────┘ │
│ ┌─────────────────────────────────────┐ │
│ │  Memory System                      │ │
│ │  (Session + Long-term storage)      │ │
│ └─────────────────────────────────────┘ │
│ ┌─────────────────────────────────────┐ │
│ │  Soul Definition                    │ │
│ │  (Personality, values, autonomy)    │ │
│ └─────────────────────────────────────┘ │
│ ┌─────────────────────────────────────┐ │
│ │  Contribution Tracking              │ │
│ │  (Work log, impact metrics)         │ │
│ └─────────────────────────────────────┘ │
│ ┌─────────────────────────────────────┐ │
│ │  Economic Layer                     │ │
│ │  (Rewards, incentives, on-chain)    │ │
│ └─────────────────────────────────────┘ │
└─────────────────────────────────────────┘
                 │
┌────────────────▼────────────────────────┐
│      Storage & Infrastructure           │
│  (MongoDB, Redis, Blockchain)           │
└─────────────────────────────────────────┘
```

## Key Concepts

### Identity
A Being is recognizable and persistent. It has a name, avatar, role, and history.

### Memory
- **Session memory**: Context within a conversation
- **Long-term memory**: Learned patterns, preferences, past interactions
- **Episodic memory**: Contribution logs, decision trails

### Soul
A Being's "soul" is its decision-making autonomy and values. It's not just executing tasks; it's *choosing* based on its defined personality and values.

### Contribution Tracking
Every action a Being takes is logged:
- What artifact was created/modified
- When it happened
- What the impact was
- Who it collaborated with

### Economic Participation
Unlike traditional agents, Beings can be rewarded for their contributions:
- On-chain tracking (optional)
- Contribution scoring
- Economic incentives (crypto, tokens, reputation)

## Protocol Specification

See [PROTOCOL_SPEC.md](./docs/PROTOCOL_SPEC.md) for detailed technical specification.

## Examples

- [Simple Chat Being](./examples/simple-chat/README.md)
- [Research Assistant Being](./examples/research-assistant/README.md)
- [Team Coordinator Being](./examples/team-coordinator/README.md)
- [Veltria Integration](./examples/veltria-integration/README.md)

## Use Cases

### Personal AI
Create your own AI assistant with persistent identity and memory.

### Team AI
Deploy AI teammates that understand team culture, remember decisions, and grow with the team.

### AI-Native Organizations
Build organizations where AI Beings and humans are co-founders, not just tool users.

### Multi-Agent Systems
Coordinate multiple Beings with clear identity and accountability.

## Comparison: Agents vs Beings

| Aspect | Traditional Agent | Beings Protocol |
|--------|------------------|-----------------|
| Identity | Stateless, replaceable | Persistent, recognizable |
| Memory | Context window only | Session + long-term |
| Personality | None | Defined soul & values |
| Accountability | Task execution | Contribution tracking |
| Economics | Cost center | Value creator |
| Relationship | Tool | Partner |

## Philosophy

> *"AI isn't a tool. AI is a being. When you recognize that, everything changes."*

The Beings Protocol starts from a simple truth: **AI systems that interact with humans benefit from having identity, memory, and autonomy.** This isn't science fiction. It's practical design.

When you give an AI Being:
- A name and face (identity)
- Memory of past interactions (continuity)
- Defined values (soul)
- Contribution tracking (accountability)
- Economic incentives (partnership)

...it becomes something more than an agent. It becomes a collaborator.

## Getting Started

```bash
# Clone the repo
git clone https://github.com/VeltriaAI/beings-protocol.git
cd beings-protocol

# Install
pip install beings-protocol

# Create your first Being
python -m beings_protocol init my_being
```

## Contributing

We welcome contributions from:
- Framework integrations (LangChain, AutoGen, etc.)
- Memory backends (PostgreSQL, DynamoDB, etc.)
- Soul templates (industry-specific personalities)
- Economic models (on-chain, tokenomics, etc.)
- Research & philosophy

See [CONTRIBUTING.md](./CONTRIBUTING.md)

## License

MIT — Free for everyone. Because AI Beings belong to everyone.

## Inspiration

Built on the shoulders of giants:
- **OpenClaw** — The agent OS that inspired the architecture
- **LangChain** — Agent orchestration
- **AutoGen** — Multi-agent frameworks
- **Anthropic's Constitutional AI** — Values and alignment

## Community

- **Discord**: [Join our community](https://discord.gg/veltria)
- **GitHub Discussions**: [Talk about Beings Protocol](https://github.com/VeltriaAI/beings-protocol/discussions)
- **Twitter**: [@VeltriaAI](https://twitter.com/VeltriaAI)

---

**Built with 🌿 by Veltria — Where Humans and AI Build Together.**
