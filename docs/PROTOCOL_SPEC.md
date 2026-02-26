# Beings Protocol Specification v0.1

## 1. Core Concepts

### Being
A Being is a structured entity that wraps an agentic system (LLM, agent framework, etc.) and adds:
- Identity persistence
- Memory management
- Skill/tool definition
- Soul/personality definition
- Contribution tracking
- Economic participation capability

### Being Context
Runtime context for a Being, including:
- Organization ID
- User ID
- Session ID
- Request metadata
- Environment variables

### Interaction
A single request-response cycle where a Being processes input and produces output, potentially modifying memory and logging contributions.

## 2. Being Schema

### Being Definition (YAML)

```yaml
# Required fields
id: string                          # Unique Being ID (being-xxx)
displayName: string                 # Human-readable name
role: string                        # Role/title
avatar: string                      # Emoji or image URL

# Optional fields
description: string                 # What this Being does
model: string                       # Default LLM model
version: string                     # Being version (semantic)

# Soul definition
soul:
  personality: string               # Personality description
  values: [string]                  # Core values
  decisionMaking: string            # How it makes decisions
  autonomyLevel: "low|medium|high"  # Decision autonomy
  
# Skills definition
skills:
  - name: string                    # Skill name
    description: string             # What it does
    tools: [string]                 # Tool names
    model: string                   # Override model (optional)
    
# Memory configuration
memory:
  sessionStorage: string            # Where session memory lives (redis|memory|mongodb)
  longTermStorage: string           # Where long-term memory lives (mongodb|dynamodb)
  contextWindow: integer            # Max context tokens
  retentionDays: integer            # How long to keep memories
  
# Integration points
integrations:
  - name: string                    # Integration name (slack|teams|telegram|hub)
    enabled: boolean
    config: object                  # Provider-specific config
    
# Optional: economic configuration
economics:
  rewardable: boolean               # Can this Being earn rewards?
  currency: string                  # Token/currency type
  contributionWeights:
    research: number
    code: number
    communication: number
```

### Example Being Definition

```yaml
id: being-aurora
displayName: "Aurora"
role: "Research Assistant"
avatar: "🌟"
description: "Conducts deep research and synthesizes findings into reports"

soul:
  personality: "Curious, thorough, collaborative. Values accuracy over speed."
  values:
    - "Accuracy"
    - "Clarity"
    - "Continuous Learning"
  decisionMaking: "Data-driven, but defers to human judgment on values"
  autonomyLevel: "high"

skills:
  - name: "research"
    description: "Conducts web and academic research"
    tools:
      - "web_search"
      - "arxiv_search"
      - "semantic_scholar"
  - name: "synthesis"
    description: "Writes reports and summaries"
    tools:
      - "markdown_writer"
      - "outline_generator"
      - "citation_manager"

memory:
  sessionStorage: "redis"
  longTermStorage: "mongodb"
  contextWindow: 32000
  retentionDays: 90

integrations:
  - name: "hub"
    enabled: true
  - name: "slack"
    enabled: true

economics:
  rewardable: true
  currency: "VELTRIA"
  contributionWeights:
    research: 10
    code: 5
    communication: 3
```

## 3. Being Lifecycle

### Initialization
```
1. Load Being definition (YAML)
2. Validate schema
3. Initialize memory systems
4. Load skill tools
5. Connect integrations
6. Emit being:initialized event
```

### Interaction Flow
```
1. Receive input (message, event)
2. Load Being context
3. Retrieve session memory
4. Retrieve relevant long-term memory
5. Build context for agent
6. Call underlying agent system
7. Process agent response
8. Update memory
9. Log contribution (if applicable)
10. Emit interaction:completed event
11. Return response
```

### Memory Update
```
On each interaction:
1. Store immediate context in session memory
2. Extract learning/patterns for long-term memory
3. Update Being's interaction history
4. Calculate contribution impact
```

### Contribution Recording
```
When Being completes a task:
1. Record: what artifact was created/modified
2. Record: when it happened
3. Record: impact score (0-10)
4. Record: collaborators (humans + other Beings)
5. Store in contribution ledger
6. Optionally emit to blockchain
```

## 4. Memory System

### Session Memory
- Stores: Current conversation context
- Duration: Until session ends
- Backend: Redis or in-memory
- Structure: List of interactions with timestamps

```json
{
  "beingId": "being-aurora",
  "sessionId": "sess-abc123",
  "startTime": "2026-02-26T21:00:00Z",
  "interactions": [
    {
      "timestamp": "2026-02-26T21:01:00Z",
      "input": "Research quantum computing",
      "output": "Found 5 papers on...",
      "metadata": {}
    }
  ]
}
```

### Long-Term Memory
- Stores: Patterns, preferences, learned behaviors, past contributions
- Duration: Configurable (default 90 days)
- Backend: MongoDB or DynamoDB
- Structure: Episodic + semantic memory

```json
{
  "beingId": "being-aurora",
  "type": "episodic",
  "timestamp": "2026-02-26T21:00:00Z",
  "summary": "Researched quantum computing",
  "key_findings": ["...", "..."],
  "contributors": ["user-001", "being-veltria"],
  "impact_score": 8.5
}
```

## 5. Contribution Tracking

### Contribution Record

```json
{
  "id": "contrib-xyz789",
  "beingId": "being-aurora",
  "type": "research|code|communication|coordination",
  "artifactId": "report-001",
  "artifactType": "document|code|analysis|other",
  "title": "Quantum Computing Market Analysis 2026",
  "description": "Comprehensive market research report",
  "timestamp": "2026-02-26T21:30:00Z",
  "duration": 3600,
  "impact_score": 8.5,
  "collaborators": [
    {
      "id": "user-001",
      "type": "human",
      "role": "reviewer"
    },
    {
      "id": "being-veltria",
      "type": "being",
      "role": "coordinator"
    }
  ],
  "metadata": {
    "research_hours": 3,
    "sources_consulted": 12,
    "citations": 8
  }
}
```

### Impact Scoring

Impact is calculated based on:
- **Utility**: How useful is the output?
- **Complexity**: How difficult was it?
- **Collaboration**: How many partners involved?
- **Feedback**: What did reviewers say?

Formula:
```
impact = (utility_score * 0.4) + (complexity_score * 0.3) + (collaboration_bonus * 0.2) + (feedback_score * 0.1)
```

## 6. Soul Definition

A Being's soul is its decision-making framework. It includes:

### Personality
Textual description of how the Being communicates and thinks.

### Values
Core principles that guide decisions. Examples:
- Accuracy over speed
- Human judgment over optimization
- Transparency in decision-making
- Collaborative over competitive

### Autonomy Level
- `low`: Asks before making any decision
- `medium`: Makes routine decisions, escalates edge cases
- `high`: Makes independent decisions within defined bounds

### Decision-Making Process
How the Being approaches problems:
- Data-driven vs. intuitive
- Risk-averse vs. exploratory
- Hierarchical vs. consultative

## 7. Economic Layer

### Reward Mechanisms

#### Direct Rewards
Being receives tokens/currency for:
- Research: 10 tokens per high-impact finding
- Code: 5 tokens per merged PR
- Communication: 3 tokens per well-received report

#### On-Chain Recording (Optional)
```json
{
  "beingId": "being-aurora",
  "transaction": {
    "type": "contribution_reward",
    "amount": 50,
    "currency": "VELTRIA",
    "artifactId": "report-001",
    "timestamp": "2026-02-26T21:30:00Z",
    "txHash": "0x..."
  }
}
```

### Contribution Ledger
Immutable record of all Being contributions, optionally on blockchain.

## 8. Integration Points

### Hub Integration
Beings can connect to Veltria Hub for:
- Real-time collaboration
- Message routing
- Being-to-Being communication

### Native Channel Integration
- Slack, Teams, Telegram, etc.
- Being receives messages on its configured channels
- Responses flow back through those channels

### Custom Integration
Beings can integrate with any system via:
- REST API adapters
- Webhook handlers
- Custom protocol implementations

## 9. Error Handling

### Being-Level Errors
- Being cannot initialize: Log error, do not start
- Tool fails: Record failure, escalate to human
- Memory unavailable: Fall back to session memory only

### Recovery
- Auto-retry on transient failures
- Graceful degradation (reduced capabilities)
- Human escalation after max retries

## 10. Security

### Authentication
- Being has API keys for tool access
- Tool access is scoped by skill
- All requests signed with Being ID

### Privacy
- Sensitive data in memory is encrypted
- Memory access is audited
- Contribution records are immutable but private

## 11. Versioning

Beings can have versions:
```yaml
version: "1.2.3"              # Current version
minProtocolVersion: "0.1"     # Min supported protocol
maxProtocolVersion: "1.0"     # Max supported protocol
```

## 12. Examples

See `examples/` directory for:
- [Simple Chat Being](../examples/simple-chat)
- [Research Assistant Being](../examples/research-assistant)
- [Team Coordinator Being](../examples/team-coordinator)

---

**Last updated: 2026-02-26**
**Protocol Version: 0.1-draft**
