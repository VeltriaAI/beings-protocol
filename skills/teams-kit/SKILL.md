---
name: teams-kit
version: 0.1.0
description: Microsoft Teams + Outlook pipeline for a Being with its own M365 account — watcher, triage → work → voice, scoped lanes, background jobs, blockers, watchdog, owner drafts
author: Beings Protocol
scope: claude-code (work session, agent jobs) + codex or claude (triage/voice) + codex (optional jobs)
dependencies:
  - Node.js >= 20, Python >= 3.10, bash, flock (util-linux), Linux /proc (watchdog)
  - "@azure/msal-node" (npm install)
  - Claude Code CLI (`claude`); Codex CLI (`codex`) when BEING_FAST_CLIENT=codex or for codex jobs
  - An Entra app registration (public client, delegated permissions) and a licensed M365 account for the Being
installed_by: scripts/being-kit.sh birth|upgrade --teams  →  <being-home>/ops/teams-kit
---
