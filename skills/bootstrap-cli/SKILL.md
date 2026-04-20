---
name: bootstrap-cli
version: 0.1.0
description: Being self-installs a shell CLI wrapper (bin/<name>) at the end of its first conversation — Claude Code only.
author: Beings Protocol
scope: claude-code
dependencies:
  - Claude Code CLI (`claude`)
  - write access to a directory already on PATH (`~/.local/bin` or `~/bin`)
invoked_by: BOOTSTRAP.md (step 4, after the Being has its name)
---
