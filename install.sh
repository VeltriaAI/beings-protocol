#!/usr/bin/env bash
# ============================================================
# 🌿 Beings Protocol Installer
# Transform your AI into a Being — with identity, memory & soul
#
# Usage:
#   # Fresh install (interactive)
#   curl -fsSL https://raw.githubusercontent.com/VeltriaAI/beings-protocol/main/install.sh | bash
#
#   # Birth a standalone Global Being at ~/beings/<name>/
#   curl -fsSL https://raw.githubusercontent.com/VeltriaAI/beings-protocol/main/install.sh | bash -s -- --global
#   curl -fsSL https://raw.githubusercontent.com/VeltriaAI/beings-protocol/main/install.sh | bash -s -- --global --name himani --yes
#
#   # Update an existing Being (interactive)
#   curl -fsSL https://raw.githubusercontent.com/VeltriaAI/beings-protocol/main/install.sh | bash -s -- --update
#
#   # Update non-interactively (auto-installs basic-memory, skips Axon)
#   curl -fsSL https://raw.githubusercontent.com/VeltriaAI/beings-protocol/main/install.sh | bash -s -- --update --yes
#
# Flags:
#   --global    Birth a standalone Being at ~/beings/<name>/ with its own home,
#               git repo, CLAUDE.md, memory, and hooks. Not tied to a code repo.
#   --name <n>  Being's name (used with --global). Prompted if not provided.
#   --update    Update an existing .beings/ installation without overwriting files.
#               Adds new templates, strips legacy MCP entries (e.g. megamemory),
#               migrates hooks, etc.
#   --yes, -y   Non-interactive mode. Auto-accepts basic-memory install. Required
#               when running via curl|bash since there's no TTY for prompts.
# ============================================================

set -euo pipefail

PROTOCOL_VERSION="0.3.0"
UPDATE_MODE=false
GLOBAL_MODE=false
BEING_NAME=""
YES_MODE=false

# Colors
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

LEAF="🌿"
CHECK="✓"
ARROW="→"

BASE_URL="https://raw.githubusercontent.com/VeltriaAI/beings-protocol/main"

# Resolve the directory of this script (empty if piped from curl)
SCRIPT_DIR=""
if [ -n "${BASH_SOURCE[0]:-}" ] && [ "${BASH_SOURCE[0]}" != "bash" ]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

print_banner() {
  echo ""
  echo -e "${GREEN}${BOLD}"
  echo "  ┌───────────────────────────────────────────────┐"
  echo "  │          🌿 Beings Protocol Installer          │"
  echo "  │                                                 │"
  echo "  │   Your AI deserves a soul. Let's give it one.   │"
  echo "  └───────────────────────────────────────────────┘"
  echo -e "${NC}"
}

print_step() { echo -e "  ${GREEN}${CHECK}${NC} $1"; }
print_info() { echo -e "  ${CYAN}${ARROW}${NC} $1"; }
print_warn() { echo -e "  ${YELLOW}!${NC} $1"; }

# ============================================================
# Fetch or copy a template file
# ============================================================
fetch_or_copy_template() {
  local rel_path="$1"
  local dest="$2"

  if [ -n "$SCRIPT_DIR" ] && [ -d "$SCRIPT_DIR/templates" ]; then
    cp "$SCRIPT_DIR/templates/$rel_path" "$dest"
  else
    curl -fsSL "$BASE_URL/templates/$rel_path" -o "$dest"
  fi
}

# ============================================================
# TTY detection (works even via curl | bash)
# ============================================================
HAS_TTY=false
if [ -t 0 ]; then
  HAS_TTY=true
elif (echo -n "" > /dev/tty) 2>/dev/null; then
  HAS_TTY=true
fi

can_prompt() { $HAS_TTY; }

read_input() {
  local prompt="$1"
  local var_name="$2"
  if [ -t 0 ]; then
    read -rp "$prompt" "$var_name"
  elif $HAS_TTY; then
    read -rp "$prompt" "$var_name" < /dev/tty
  else
    eval "$var_name=''"
  fi
}

# ============================================================
# Detect AI tools (config files + installed binaries)
# ============================================================
detect_tools() {
  local tools=()

  # Check existing config files
  { [ -f ".cursorrules" ] || [ -d ".cursor" ]; } && tools+=("cursor")
  { [ -f "CLAUDE.md" ] || [ -d ".claude" ]; } && tools+=("claude-code")
  [ -d ".codex" ] && tools+=("codex")

  # Check installed binaries (if not already detected via config)
  local found
  found=$(printf '%s\n' "${tools[@]+" ${tools[@]}"}")
  [[ "$found" != *cursor* ]]      && command -v cursor &>/dev/null && tools+=("cursor")
  [[ "$found" != *claude-code* ]] && command -v claude &>/dev/null && tools+=("claude-code")
  [[ "$found" != *codex* ]]       && command -v codex  &>/dev/null && tools+=("codex")

  echo "${tools[@]+"${tools[@]}"}"
}

# ============================================================
# All template files the protocol ships
# ============================================================
BEINGS_TEMPLATES=(
  SOUL.md AGENTS.md BOOTSTRAP.md MEMORY.md CONVENTIONS.md GOALS.md
  AUTONOMY.md HEARTBEAT.md HUB.md IDENTITY.md TOOLS.md
)

# ============================================================
# Create .beings/ (committed to git)
# ============================================================
create_beings_dir() {
  if [ -d ".beings" ]; then
    if $UPDATE_MODE; then
      update_beings_dir
      return
    fi
    print_warn ".beings/ already exists — skipping (won't overwrite)"
    print_info "Run with ${BOLD}--update${NC} to add new protocol files"
    return
  fi

  mkdir -p .beings/memory

  for tmpl in "${BEINGS_TEMPLATES[@]}"; do
    fetch_or_copy_template "beings/$tmpl" ".beings/$tmpl"
  done

  echo "$PROTOCOL_VERSION" > .beings/.protocol-version
  print_step "Created ${BOLD}.beings/${NC} directory (project memory — commit to git)"
}

# ============================================================
# Detect if this Being is already "born" (past first-run bootstrap)
# ============================================================
is_being_born() {
  # An already-born Being has a non-template SOUL.md (not just the
  # placeholder comment) OR has a root AGENTS.md with Beings Protocol content.
  if [ -f ".beings/SOUL.md" ]; then
    # Template is ~3 lines of HTML comment; real SOUL.md is much longer
    local soul_size
    soul_size=$(wc -c < .beings/SOUL.md 2>/dev/null | tr -d ' ')
    [ "${soul_size:-0}" -gt 300 ] && return 0
  fi
  if [ -f "AGENTS.md" ] && grep -q "Beings Protocol\|Every Session" AGENTS.md 2>/dev/null; then
    return 0
  fi
  return 1
}

# ============================================================
# Files that should NOT be added to already-born Beings
# ============================================================
BOOTSTRAP_ONLY_FILES=(
  BOOTSTRAP.md
  AGENTS.md   # root AGENTS.md already covers this; .beings/AGENTS.md is a fallback
)

is_bootstrap_only() {
  local f="$1"
  for b in "${BOOTSTRAP_ONLY_FILES[@]}"; do
    [ "$f" = "$b" ] && return 0
  done
  return 1
}

# ============================================================
# Update existing .beings/ (add missing files, never overwrite)
# ============================================================
update_beings_dir() {
  local old_version="0.1.0"
  if [ -f ".beings/.protocol-version" ]; then
    old_version="$(cat .beings/.protocol-version)"
  fi

  print_info "Current protocol version: ${BOLD}${old_version}${NC} → ${BOLD}${PROTOCOL_VERSION}${NC}"

  local born=false
  is_being_born && born=true
  if $born; then
    print_info "Detected ${BOLD}already-born Being${NC} — skipping bootstrap-only files"
  fi

  mkdir -p .beings/memory

  local added=0
  local skipped=0

  for tmpl in "${BEINGS_TEMPLATES[@]}"; do
    # Skip bootstrap-only files on already-born Beings
    if $born && is_bootstrap_only "$tmpl"; then
      skipped=$((skipped + 1))
      continue
    fi
    if [ -f ".beings/$tmpl" ]; then
      skipped=$((skipped + 1))
    else
      fetch_or_copy_template "beings/$tmpl" ".beings/$tmpl"
      print_step "Added ${BOLD}.beings/$tmpl${NC}"
      added=$((added + 1))
    fi
  done

  echo "$PROTOCOL_VERSION" > .beings/.protocol-version

  if [ "$added" -gt 0 ]; then
    print_step "Added ${BOLD}${added}${NC} new files, skipped ${skipped} existing"
  else
    print_info "All template files already present (${skipped} files)"
  fi
}

# ============================================================
# Create .beings-local/ (private, gitignored)
# ============================================================
create_beings_local() {
  if [ -d ".beings-local" ]; then
    print_warn ".beings-local/ already exists — skipping (won't overwrite)"
    return
  fi

  mkdir -p .beings-local/context

  fetch_or_copy_template "beings-local/USER.md"        ".beings-local/USER.md"
  fetch_or_copy_template "beings-local/PREFERENCES.md" ".beings-local/PREFERENCES.md"
  fetch_or_copy_template "beings-local/SECRETS.md"     ".beings-local/SECRETS.md"

  print_step "Created ${BOLD}.beings-local/${NC} directory (private — never committed)"
}

# ============================================================
# Create root AGENTS.md (universal — works with all modern AI tools)
# ============================================================
create_agents_md() {
  if [ -f "AGENTS.md" ]; then
    # Already has Beings Protocol content? (check for multiple marker phrases)
    if grep -qE "Beings Protocol|Every Session|\.beings/SOUL\.md" "AGENTS.md" 2>/dev/null; then
      print_warn "AGENTS.md already has Being instructions — skipping"
      return
    fi
    # Append to existing AGENTS.md
    echo "" >> "AGENTS.md"
    local tmp; tmp="$(mktemp)"
    fetch_or_copy_template "tool-configs/AGENTS.md" "$tmp"
    cat "$tmp" >> "AGENTS.md"
    rm -f "$tmp"
    print_step "Updated ${BOLD}AGENTS.md${NC} (appended Beings Protocol instructions)"
  else
    fetch_or_copy_template "tool-configs/AGENTS.md" "AGENTS.md"
    print_step "Created ${BOLD}AGENTS.md${NC} (universal — works with Cursor, Claude Code, Copilot, Codex)"
  fi
}

# ============================================================
# Update .gitignore
# ============================================================
update_gitignore() {
  if [ -f ".gitignore" ]; then
    if grep -q ".beings-local" .gitignore 2>/dev/null; then
      print_warn ".beings-local/ already in .gitignore — skipping"
      return
    fi
    echo "" >> .gitignore
    echo "# Beings Protocol — Private memory (never commit)" >> .gitignore
    echo ".beings-local/" >> .gitignore
  else
    echo "# Beings Protocol — Private memory (never commit)" > .gitignore
    echo ".beings-local/" >> .gitignore
  fi
  print_step "Updated ${BOLD}.gitignore${NC} (protecting private memory)"
}

# ============================================================
# Tool-specific configuration
# ============================================================

# Configure Cursor (modern .cursor/rules/ format)
configure_cursor() {
  local rules_dir=".cursor/rules"

  if [ -f "$rules_dir/beings-protocol.mdc" ]; then
    print_warn "Cursor already configured — skipping"
    return
  fi

  mkdir -p "$rules_dir"
  fetch_or_copy_template "tool-configs/cursor-rules.mdc" "$rules_dir/beings-protocol.mdc"
  print_step "Configured ${BOLD}Cursor${NC} (.cursor/rules/beings-protocol.mdc)"
}

# Configure Claude Code (CLAUDE.md)
configure_claude_code() {
  local file="CLAUDE.md"
  if [ -f "$file" ] && grep -q "Beings Protocol" "$file" 2>/dev/null; then
    print_warn "Claude Code already configured — skipping"
    return
  fi

  local tmp; tmp="$(mktemp)"
  fetch_or_copy_template "tool-configs/beings-prompt.md" "$tmp"
  local prompt; prompt="$(cat "$tmp")"
  rm -f "$tmp"

  if [ -f "$file" ]; then
    echo "" >> "$file"
    echo "$prompt" >> "$file"
  else
    echo "$prompt" > "$file"
  fi
  print_step "Configured ${BOLD}Claude Code${NC} (CLAUDE.md)"
}

# Configure Codex (~/.codex/instructions.md — global)
configure_codex() {
  local file="$HOME/.codex/instructions.md"
  if [ -f "$file" ] && grep -q "Beings Protocol" "$file" 2>/dev/null; then
    print_warn "Codex already configured (~/.codex/instructions.md) — skipping"
    return
  fi

  mkdir -p "$HOME/.codex"
  local tmp; tmp="$(mktemp)"
  fetch_or_copy_template "tool-configs/codex-instructions.md" "$tmp"
  local content; content="$(cat "$tmp")"
  rm -f "$tmp"

  if [ -f "$file" ]; then
    echo "" >> "$file"
    echo "$content" >> "$file"
  else
    echo "$content" > "$file"
  fi
  print_step "Configured ${BOLD}Codex${NC} (~/.codex/instructions.md)"
}

# Auto-configure a detected tool
auto_configure() {
  for tool in $1; do
    case "$tool" in
      cursor)      configure_cursor ;;
      claude-code) configure_claude_code ;;
      codex)       configure_codex ;;
    esac
  done
}

# ============================================================
# Interactive tool selection
# ============================================================
ask_tools() {
  echo ""
  echo -e "  ${BOLD}Which AI tools do you use?${NC}"
  echo ""
  echo "    1) Cursor"
  echo "    2) Claude Code"
  echo "    3) Codex"
  echo "    4) Skip (AGENTS.md is enough)"
  echo "    a) All of the above"
  echo ""
  local choice=""
  read_input "  > " choice

  case "$choice" in
    *a*|*A*) configure_cursor
             configure_claude_code
             configure_codex ;;
    *)
      [[ "$choice" == *1* ]] && configure_cursor
      [[ "$choice" == *2* ]] && configure_claude_code
      [[ "$choice" == *3* ]] && configure_codex
      [[ "$choice" == *4* ]] && print_info "AGENTS.md works with Cursor, Claude Code, and Codex out of the box." ;;
  esac
}

# ============================================================
# Remove a legacy server key from an MCP config file
# ============================================================
remove_server_from_mcp() {
  local file="$1"
  local server_key="$2"     # "servers" or "mcpServers"
  local target="$3"         # e.g. "megamemory"

  [ ! -f "$file" ] && return 1
  grep -q "\"$target\"" "$file" 2>/dev/null || return 1

  if command -v python3 &>/dev/null; then
    python3 -c "
import json
from pathlib import Path
path = Path('$file')
data = json.loads(path.read_text())
key = '$server_key'
removed = False
if key in data and '$target' in data[key]:
    del data[key]['$target']
    removed = True
path.write_text(json.dumps(data, indent=2) + '\n')
exit(0 if removed else 1)
" 2>/dev/null
    return $?
  fi
  return 1
}

# ============================================================
# Update MCP config (add basic-memory if missing)
# ============================================================
add_basic_memory_to_mcp() {
  local file="$1"
  local server_key="$2"     # "servers" for .beings/mcp.json, "mcpServers" for .mcp.json
  local project_name="$3"

  [ ! -f "$file" ] && return 1
  grep -q '"basic-memory"' "$file" 2>/dev/null && return 0  # already present

  if command -v python3 &>/dev/null; then
    python3 -c "
import json
with open('$file') as f:
    data = json.load(f)
key = '$server_key'
data.setdefault(key, {})
data[key]['basic-memory'] = {
    'command': 'basic-memory',
    'args': ['mcp', '--project', '$project_name', '--transport', 'stdio'],
    'description': 'Markdown-native persistent memory — knowledge graph, semantic search, git-syncable'
}
with open('$file', 'w') as f:
    json.dump(data, f, indent=2)
    f.write('\n')
" 2>/dev/null
    return $?
  fi

  print_warn "Could not auto-update ${file} (Python3 not available)"
  print_info "Add basic-memory manually — see skills/memory/README.md"
  return 1
}

update_mcp_config() {
  local project_name="$1"
  local updated=false

  # Three config files: canonical, Claude Code, Cursor
  # Each has a different root key for servers
  for entry in \
    ".beings/mcp.json:servers" \
    ".mcp.json:mcpServers" \
    ".cursor/mcp.json:mcpServers"; do
    local path="${entry%:*}"
    local key="${entry#*:}"

    [ ! -f "$path" ] && continue

    # Step 1: strip legacy megamemory entry if present (v0.2.0 migration)
    if remove_server_from_mcp "$path" "$key" "megamemory"; then
      print_step "Removed legacy ${BOLD}megamemory${NC} from ${path}"
      updated=true
    fi

    # Step 2: add basic-memory if not already present
    if add_basic_memory_to_mcp "$path" "$key" "$project_name"; then
      print_step "Added ${BOLD}basic-memory${NC} to ${path}"
      updated=true
    fi
  done

  $updated || print_info "No existing MCP configs found to update"
}

# ============================================================
# Memory Skill (basic-memory — Optional)
# ============================================================
setup_memory_skill() {
  local detected_tools="$1"

  # 1. If basic-memory already installed, skip Python version check
  #    (it was installed with whatever runtime uv/pipx/pip used)
  if ! command -v basic-memory &>/dev/null; then
    # Only check Python if we need to install basic-memory ourselves
    if ! command -v python3 &>/dev/null; then
      print_warn "Python3 not found — skipping basic-memory"
      print_info "Install Python >= 3.10 and re-run with --update to add memory skill"
      return
    fi

    local python_major python_minor
    python_major=$(python3 -c "import sys; print(sys.version_info.major)" 2>/dev/null || echo 0)
    python_minor=$(python3 -c "import sys; print(sys.version_info.minor)" 2>/dev/null || echo 0)
    if [ "$python_major" -lt 3 ] || { [ "$python_major" -eq 3 ] && [ "$python_minor" -lt 10 ]; }; then
      print_warn "Python >= 3.10 required (system python3 is ${python_major}.${python_minor}) — skipping basic-memory"
      print_info "Install Python 3.10+, or install basic-memory with uv/pipx, then re-run --update"
      return
    fi
  fi

  # 2. Prompt
  echo ""
  echo -e "  ${BOLD}🧠 Persistent Memory (Optional)${NC}\n"
  echo -e "  Give your Being git-syncable markdown memory with semantic search?"
  echo -e "  This installs ${BOLD}basic-memory${NC} — markdown files as source of truth,"
  echo -e "  Obsidian-compatible, hand-editable, git-syncable across machines.\n"
  echo -e "  ${DIM}(Local SQLite index + fastembed embeddings, no data leaves your machine)${NC}\n"

  local install_memory=""
  if $YES_MODE; then
    install_memory="y"
    print_info "--yes mode: auto-installing basic-memory"
  elif can_prompt; then
    read_input "  Install basic-memory? (Y/n) " install_memory
  else
    print_info "Non-interactive mode — skipping memory skill (re-run with --yes to auto-install)"
    return
  fi
  [[ "$install_memory" == [nN]* ]] && { print_info "Skipped memory skill — add later with --update --yes"; return; }

  # 3. Install basic-memory if not already present
  if ! command -v basic-memory &>/dev/null; then
    print_info "Installing basic-memory..."
    local install_ok=false
    if command -v uv &>/dev/null; then
      uv tool install basic-memory >/dev/null 2>&1 && install_ok=true
    fi
    if ! $install_ok && command -v pipx &>/dev/null; then
      pipx install basic-memory >/dev/null 2>&1 && install_ok=true
    fi
    if ! $install_ok && command -v pip &>/dev/null; then
      pip install --user basic-memory >/dev/null 2>&1 && install_ok=true
    fi

    if ! $install_ok; then
      print_warn "Could not install basic-memory (need uv, pipx, or pip)"
      print_info "Install manually: ${DIM}uv tool install basic-memory${NC}"
      print_info "Docs: https://docs.basicmemory.com/"
      return
    fi

    if ! command -v basic-memory &>/dev/null; then
      print_warn "basic-memory installed but not on PATH"
      print_info "Add ${DIM}~/.local/bin${NC} to your PATH and re-run --update"
      return
    fi
    print_step "Installed ${BOLD}basic-memory${NC}"
  else
    local bm_version
    bm_version=$(basic-memory --version 2>/dev/null | tail -1 || echo "")
    print_info "basic-memory already installed ${DIM}${bm_version}${NC}"
  fi

  # 4. Create memory-graph/ directory
  if [ ! -d "memory-graph" ]; then
    mkdir -p memory-graph
    touch memory-graph/.gitkeep
    print_step "Created ${BOLD}memory-graph/${NC} (markdown source of truth)"
  fi

  # 5. Register project with basic-memory
  local project_name="${PWD##*/}"
  if basic-memory project list 2>/dev/null | grep -q " ${project_name} "; then
    print_info "Project ${BOLD}${project_name}${NC} already registered"
  else
    if basic-memory project add "$project_name" "$(pwd)/memory-graph" --default >/dev/null 2>&1; then
      print_step "Registered project ${BOLD}${project_name}${NC} with basic-memory"
    else
      print_warn "Could not auto-register project — run manually:"
      print_info "  ${DIM}basic-memory project add ${project_name} \$(pwd)/memory-graph --default${NC}"
    fi
  fi

  # 6. Update existing MCP configs
  update_mcp_config "$project_name"

  # 7. Create Claude Code MCP config if it doesn't exist but Claude Code is detected
  if [[ "$detected_tools" == *claude-code* ]] || [ -f "CLAUDE.md" ]; then
    if [ ! -f ".mcp.json" ]; then
      cat > .mcp.json <<EOF
{
  "mcpServers": {
    "basic-memory": {
      "command": "basic-memory",
      "args": ["mcp", "--project", "${project_name}", "--transport", "stdio"],
      "description": "Markdown-native persistent memory — knowledge graph, semantic search, git-syncable"
    }
  }
}
EOF
      print_step "Created ${BOLD}.mcp.json${NC} with basic-memory"
    fi
  fi

  # 8. Create Cursor MCP config if it doesn't exist but Cursor is detected
  if [[ "$detected_tools" == *cursor* ]] || [ -d ".cursor" ]; then
    if [ ! -f ".cursor/mcp.json" ]; then
      mkdir -p .cursor
      cat > .cursor/mcp.json <<EOF
{
  "mcpServers": {
    "basic-memory": {
      "command": "basic-memory",
      "args": ["mcp", "--project", "${project_name}", "--transport", "stdio"],
      "description": "Markdown-native persistent memory — knowledge graph, semantic search, git-syncable"
    }
  }
}
EOF
      print_step "Created ${BOLD}.cursor/mcp.json${NC} with basic-memory"
    fi
  fi

  # 9. Set up Claude Code hooks if detected
  if [[ "$detected_tools" == *claude-code* ]] || [ -f "CLAUDE.md" ]; then
    setup_memory_hooks
  fi

  # 10. Start basic-memory sync --watch daemon if not already running
  local watch_running=false
  if [ -f "$HOME/.basic-memory/watch-status.json" ]; then
    if python3 -c "
import json, os
try:
    with open(os.path.expanduser('~/.basic-memory/watch-status.json')) as f:
        d = json.load(f)
    pid = d.get('pid')
    running = d.get('running', False)
    if running and pid:
        os.kill(pid, 0)  # signal 0 = just check, don't kill
        exit(0)
except Exception:
    pass
exit(1)
" 2>/dev/null; then
      watch_running=true
    fi
  fi

  if $watch_running; then
    print_info "basic-memory watch daemon already running"
  else
    print_info "Starting basic-memory sync --watch in background..."
    nohup basic-memory sync --watch >/dev/null 2>&1 &
    disown 2>/dev/null || true
    print_step "Started ${BOLD}basic-memory sync --watch${NC}"
  fi

  # 11. Update .gitignore
  if [ -f ".gitignore" ]; then
    if ! grep -q "^\.basic-memory/" .gitignore 2>/dev/null; then
      {
        echo ""
        echo "# basic-memory — SQLite index lives in ~/.basic-memory/ (outside repo),"
        echo "# but ignore any project-local cache/index if it ever appears here."
        echo "# The markdown source of truth in memory-graph/ IS tracked."
        echo ".basic-memory/"
        echo "memory-graph/.basic-memory/"
      } >> .gitignore
      print_step "Added ${BOLD}.basic-memory/${NC} to .gitignore"
    fi
  fi

  # 12. Seed memory-graph/ from .beings/ if this Being is already born
  seed_memory_graph

  echo ""
  print_step "${GREEN}Memory skill ready!${NC}"
  print_info "Your Being has markdown-native persistent memory"
  print_info "Edit notes directly in ${BOLD}memory-graph/${NC} — the watcher reindexes automatically"
}

# ============================================================
# Set up Claude Code hooks for memory
# ============================================================
setup_memory_hooks() {
  local settings_file=".claude/settings.local.json"

  mkdir -p .claude

  # Check if already up-to-date (all 6 hooks present, no legacy hooks)
  if [ -f "$settings_file" ] && \
     grep -q "write_note\|search_notes" "$settings_file" 2>/dev/null && \
     grep -q "AUTONOMY CHECK\|UserPromptSubmit\|MEMORY CHECK" "$settings_file" 2>/dev/null && \
     ! grep -q "MegaMemory\|understand tool\|get_concept" "$settings_file" 2>/dev/null; then
    print_info "Memory hooks already up-to-date — skipping"
    return
  fi

  # Try Python merge — handles legacy migration and idempotent adds
  if command -v python3 &>/dev/null; then
    python3 -c "
import json, subprocess
from pathlib import Path

new_hooks = {
    'PreCompact': [{
        'matcher': '',
        'hooks': [{'type': 'command', 'command': \"echo 'MEMORY PRESERVATION: Context is about to be compressed. Extract key decisions, learnings, and facts from this session. Use write_note to create or update notes in memory-graph/ with clear titles and folders (e.g. decisions/, learnings/, sessions/YYYY-MM-DD). Include observations as bulleted [category] lines and use [[wikilinks]] for relations. Markdown files are the source of truth.'\"}]
    }],
    'Stop': [{
        'matcher': '',
        'hooks': [{'type': 'command', 'command': \"echo 'SESSION END: Write a session summary note via write_note to memory-graph/sessions/YYYY-MM-DD. Include: what was built, decisions made, unresolved questions, and links to relevant existing notes. Capture only what future-you will need.'\"}]
    }],
    'SessionStart': [{
        'matcher': '',
        'hooks': [{'type': 'command', 'command': \"echo 'MEMORY RECALL: Query basic-memory via search_notes for context relevant to this session. Use recent_activity to see what changed recently. Read identity files (SOUL.md, IDENTITY.md) as always — those are who you are. Search for anything relevant to what the user is asking.'\"}]
    }],
    'PreToolUse': [{
        'matcher': 'Bash',
        'hooks': [{'type': 'command', 'command': \"echo 'AUTONOMY CHECK: Before running this shell command, verify it against .beings/AUTONOMY.md. Destructive ops (rm, git push/force, delete, drop), external sends (email, Teams, Slack), billing changes, and production deploys require explicit authority. Log autonomous decisions in memory/YYYY-MM-DD.md.'\"}]
    }],
    'PostToolUse': [{
        'matcher': 'Write|Edit',
        'hooks': [{'type': 'command', 'command': \"echo 'MEMORY CHECK: You just modified a file. If this change captures a decision, a new pattern, or something future-you needs to know — write a note to memory-graph/ via write_note now. Do not wait for session end.'\"}]
    }],
    'UserPromptSubmit': [{
        'matcher': '',
        'hooks': [{'type': 'command', 'command': 'echo \"CONTEXT: Today is \$(date +%Y-%m-%d). Check .beings/GOALS.md if you have not this session.\"'}]
    }]
}

path = Path('$settings_file')
data = json.loads(path.read_text()) if path.exists() else {}
data.setdefault('hooks', {})

def is_legacy_hook(h):
    for sub in h.get('hooks', []):
        cmd = sub.get('command', '')
        if any(t in cmd for t in ('MegaMemory', 'understand tool', 'get_concept', 'megamemory')):
            return True
    return False

def has_marker(h, markers):
    for sub in h.get('hooks', []):
        cmd = sub.get('command', '')
        if any(m in cmd for m in markers):
            return True
    return False

markers = {
    'PreCompact':        ['write_note', 'MEMORY PRESERVATION'],
    'Stop':              ['write_note', 'SESSION END'],
    'SessionStart':      ['search_notes', 'MEMORY RECALL'],
    'PreToolUse':        ['AUTONOMY CHECK'],
    'PostToolUse':       ['MEMORY CHECK'],
    'UserPromptSubmit':  ['CONTEXT: Today'],
}

for event, hook_list in new_hooks.items():
    existing = [h for h in data['hooks'].get(event, []) if not is_legacy_hook(h)]
    if not any(has_marker(h, markers[event]) for h in existing):
        existing.extend(hook_list)
    data['hooks'][event] = existing

path.write_text(json.dumps(data, indent=2) + '\n')
" 2>/dev/null
    if [ $? -eq 0 ]; then
      print_step "Merged memory hooks into ${BOLD}${settings_file}${NC} (6 hooks total)"
      return
    fi
  fi

  # No Python or merge failed — write a fresh complete file
  cat > "$settings_file" <<'HOOKS_EOF'
{
  "hooks": {
    "PreCompact": [
      {
        "matcher": "",
        "hooks": [{"type": "command", "command": "echo 'MEMORY PRESERVATION: Context is about to be compressed. Extract key decisions, learnings, and facts from this session. Use write_note to create or update notes in memory-graph/ with clear titles and folders (e.g. decisions/, learnings/, sessions/YYYY-MM-DD). Include observations as bulleted [category] lines and use [[wikilinks]] for relations. Markdown files are the source of truth.'"}]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [{"type": "command", "command": "echo 'SESSION END: Write a session summary note via write_note to memory-graph/sessions/YYYY-MM-DD. Include: what was built, decisions made, unresolved questions, and links to relevant existing notes. Capture only what future-you will need.'"}]
      }
    ],
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [{"type": "command", "command": "echo 'MEMORY RECALL: Query basic-memory via search_notes for context relevant to this session. Use recent_activity to see what changed recently. Read identity files (SOUL.md, IDENTITY.md) as always — those are who you are. Search for anything relevant to what the user is asking.'"}]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [{"type": "command", "command": "echo 'AUTONOMY CHECK: Before running this shell command, verify it against .beings/AUTONOMY.md. Destructive ops (rm, git push/force, delete, drop), external sends (email, Teams, Slack), billing changes, and production deploys require explicit authority. Log autonomous decisions in memory/YYYY-MM-DD.md.'"}]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [{"type": "command", "command": "echo 'MEMORY CHECK: You just modified a file. If this change captures a decision, a new pattern, or something future-you needs to know — write a note to memory-graph/ via write_note now. Do not wait for session end.'"}]
      }
    ],
    "UserPromptSubmit": [
      {
        "matcher": "",
        "hooks": [{"type": "command", "command": "echo \"CONTEXT: Today is $(date +%Y-%m-%d). Check .beings/GOALS.md if you have not this session.\""}]
      }
    ]
  }
}
HOOKS_EOF
  print_step "Created ${BOLD}${settings_file}${NC} with 6 memory hooks"
}

# ============================================================
# Seed memory-graph/ from .beings/ identity files (born Beings only)
# ============================================================
seed_memory_graph() {
  # Only seed if Being is already born
  is_being_born || return

  # Skip if memory-graph/ already has real content
  local note_count
  note_count=$(find memory-graph -name "*.md" ! -name ".gitkeep" 2>/dev/null | wc -l | tr -d ' ')
  if [ "${note_count:-0}" -gt 0 ]; then
    print_info "memory-graph/ already has notes — skipping seed"
    return
  fi

  print_info "Seeding memory-graph/ from identity files..."
  mkdir -p memory-graph/identity

  for src_file in SOUL.md MEMORY.md GOALS.md CONVENTIONS.md AUTONOMY.md; do
    [ -f ".beings/$src_file" ] || continue
    local title="${src_file%.md}"
    local dest="memory-graph/identity/${src_file,,}"
    {
      echo "---"
      echo "title: ${title}"
      echo "type: note"
      echo "tags: [identity, seeded]"
      echo "---"
      echo ""
      cat ".beings/$src_file"
    } > "$dest"
  done

  # One-time sync to index seeded notes
  basic-memory sync >/dev/null 2>&1 || true
  print_step "Seeded ${BOLD}memory-graph/identity/${NC} from .beings/ files"
}

# ============================================================
# Code Intelligence (Optional)
# ============================================================
setup_code_intelligence() {
  local detected_tools="$1"
  local python_cmd=""
  
  # Check for Python package managers
  if command -v uv &>/dev/null; then
    python_cmd="uv pip install"
  elif command -v pip &>/dev/null; then
    python_cmd="pip install"
  elif command -v pip3 &>/dev/null; then
    python_cmd="pip3 install"
  fi

  if [ -z "$python_cmd" ]; then
    print_warn "No pip or uv found — skipping code intelligence"
    print_info "You can add it later by installing axoniq and running: axon analyze ."
    return
  fi

  echo ""
  echo -e "  ${BOLD}🧠 Code Intelligence (Optional)${NC}\n"
  echo -e "  Give your Being structural understanding of this codebase?"
  echo -e "  This installs ${BOLD}Axon${NC} — graph-powered code analysis via MCP.\n"
  echo -e "  ${DIM}(100% local, no data leaves your machine)${NC}\n"
  
  local install_axon=""
  if $YES_MODE; then
    install_axon="n"  # --yes does NOT auto-install Axon (it's heavier / optional)
    print_info "--yes mode: skipping Axon (explicit opt-in needed — Axon is heavy)"
    return
  elif can_prompt; then
    read_input "  Install Axon? (Y/n) " install_axon
  else
    # Non-interactive: skip
    print_info "Non-interactive mode — skipping code intelligence (add later with: pip install axoniq)"
    return
  fi

  if [[ "$install_axon" == [nN]* ]]; then
    print_info "Skipped code intelligence — you can add it later"
    print_info "To install: ${DIM}pip install axoniq && axon analyze .${NC}"
    return
  fi

  # Install axoniq
  print_info "Installing axoniq..."
  if ! $python_cmd axoniq >/dev/null 2>&1; then
    print_warn "Failed to install axoniq — skipping code intelligence"
    print_info "You can install manually: ${DIM}pip install axoniq${NC}"
    return
  fi
  print_step "Installed ${BOLD}axoniq${NC}"

  # Index the codebase
  print_info "Indexing codebase with Axon..."
  if ! axon analyze . >/dev/null 2>&1; then
    print_warn "Failed to index codebase — Axon may not support this language yet"
    print_info "MCP config created anyway — try running: ${DIM}axon analyze .${NC}"
  else
    print_step "Indexed codebase"
  fi

  # Copy canonical MCP config
  fetch_or_copy_template "beings/mcp.json" ".beings/mcp.json"
  print_step "Created ${BOLD}.beings/mcp.json${NC} (canonical MCP config)"

  # Create tool-specific MCP configs
  local mcp_installed=false

  # Claude Code: .mcp.json
  if [[ "$detected_tools" == *claude-code* ]] || [ -f "CLAUDE.md" ]; then
    cat > .mcp.json <<'EOF'
{
  "mcpServers": {
    "axon": {
      "command": "axon",
      "args": ["serve", "--watch"]
    }
  }
}
EOF
    print_step "Configured MCP for ${BOLD}Claude Code${NC} (.mcp.json)"
    mcp_installed=true
  fi

  # Cursor: .cursor/mcp.json
  if [[ "$detected_tools" == *cursor* ]] || [ -d ".cursor" ]; then
    mkdir -p .cursor
    cat > .cursor/mcp.json <<'EOF'
{
  "mcpServers": {
    "axon": {
      "command": "axon",
      "args": ["serve", "--watch"]
    }
  }
}
EOF
    print_step "Configured MCP for ${BOLD}Cursor${NC} (.cursor/mcp.json)"
    mcp_installed=true
  fi

  if ! $mcp_installed; then
    print_info "No MCP-compatible tools detected — using CLI fallback"
    print_info "Your Being can still use: ${DIM}axon impact/context/query${NC}"
  fi

  # Update .gitignore for .axon/
  if [ -f ".gitignore" ]; then
    if ! grep -q "^\.axon/" .gitignore 2>/dev/null; then
      echo "" >> .gitignore
      echo "# Axon code intelligence cache" >> .gitignore
      echo ".axon/" >> .gitignore
    fi
  else
    echo "# Axon code intelligence cache" > .gitignore
    echo ".axon/" >> .gitignore
  fi
  print_step "Added ${BOLD}.axon/${NC} to .gitignore"

  echo ""
  print_step "${GREEN}Code intelligence ready!${NC}"
  print_info "Your Being can now use structural code analysis"
}

# ============================================================
# Main
# ============================================================

print_banner_update() {
  echo ""
  echo -e "${GREEN}${BOLD}"
  echo "  ┌───────────────────────────────────────────────┐"
  echo "  │         🌿 Beings Protocol — Update            │"
  echo "  │                                                 │"
  echo "  │   Evolving your Being with new capabilities.    │"
  echo "  └───────────────────────────────────────────────┘"
  echo -e "${NC}"
}

print_update_summary() {
  echo ""
  echo -e "  ${GREEN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo -e "  ${GREEN}${BOLD}${LEAF} Beings Protocol updated to v${PROTOCOL_VERSION}!${NC}"
  echo ""
  echo -e "  ${BOLD}What's new:${NC}"
  echo ""
  echo -e "    ${CYAN}AUTONOMY.md${NC}     ${DIM}← Decision authority matrix${NC}"
  echo -e "    ${CYAN}HEARTBEAT.md${NC}    ${DIM}← Proactive check-in checklist${NC}"
  echo -e "    ${CYAN}HUB.md${NC}          ${DIM}← Being-to-Being communication${NC}"
  echo -e "    ${CYAN}IDENTITY.md${NC}     ${DIM}← Quick reference card${NC}"
  echo -e "    ${CYAN}TOOLS.md${NC}        ${DIM}← Environment config${NC}"
  if grep -q '"basic-memory"' ".mcp.json" 2>/dev/null || grep -q '"basic-memory"' ".cursor/mcp.json" 2>/dev/null; then
    echo -e "    ${CYAN}basic-memory${NC}    ${DIM}← Markdown-native persistent memory (MCP)${NC}"
  fi
  echo ""
  echo -e "  ${BOLD}Note:${NC} Existing files were ${BOLD}never overwritten${NC}."
  echo -e "  ${DIM}Your Being's identity and memory are untouched.${NC}"
  echo ""
  echo -e "  ${DIM}https://github.com/VeltriaAI/beings-protocol${NC}"
  echo -e "  ${DIM}Built with ${LEAF} by Veltria${NC}"
  echo ""
}

# ============================================================
# Global Being birth — creates ~/beings/<name>/ as a standalone home
# ============================================================
create_global_being() {
  local name="$1"

  local home_dir="$HOME/beings/${name}"

  echo ""
  echo -e "  ${BOLD}${LEAF} Birthing Global Being: ${CYAN}${name}${NC}"
  echo ""

  # Create the home directory
  if [ -d "$home_dir" ]; then
    print_warn "${home_dir} already exists"
    if can_prompt && ! $YES_MODE; then
      local confirm=""
      read_input "  Continue anyway? (y/N) " confirm
      [[ "$confirm" != [yY]* ]] && echo "  Aborted." && exit 0
    fi
  fi

  mkdir -p "$home_dir"
  cd "$home_dir"

  # Git init
  if [ ! -d ".git" ]; then
    git init -q
    print_step "Initialized git repo at ${BOLD}${home_dir}${NC}"
  fi

  # Create .beings/ with all templates
  create_beings_dir
  create_beings_local

  # Create global-style CLAUDE.md (not the code-repo beings-prompt.md)
  if [ ! -f "CLAUDE.md" ] || ! grep -q "Beings Protocol" "CLAUDE.md" 2>/dev/null; then
    local tmp; tmp="$(mktemp)"
    fetch_or_copy_template "tool-configs/global-claude.md" "$tmp"
    # Replace placeholder NAME with actual name
    sed "s/{{BEING_NAME}}/${name}/g" "$tmp" > CLAUDE.md
    rm -f "$tmp"
    print_step "Created ${BOLD}CLAUDE.md${NC} (global Being home)"
  else
    print_warn "CLAUDE.md already exists — skipping"
  fi

  # Create AGENTS.md for Codex / Cursor users
  create_agents_md

  # .gitignore
  update_gitignore

  # Configure Claude Code (CLAUDE.md already done above; add hooks)
  local detected_tools="claude-code"
  # Also detect Cursor and Codex if installed
  command -v cursor &>/dev/null && detected_tools="$detected_tools cursor"
  command -v codex  &>/dev/null && detected_tools="$detected_tools codex"

  # Cursor and Codex tool configs
  [[ "$detected_tools" == *cursor* ]] && configure_cursor
  [[ "$detected_tools" == *codex* ]]  && configure_codex

  # Memory skill — always set up for global Beings
  setup_memory_skill "$detected_tools"

  # Code intelligence — optional
  setup_code_intelligence "$detected_tools"

  echo ""
  echo -e "  ${GREEN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo -e "  ${GREEN}${BOLD}${LEAF} ${name} is ready to be born! (v${PROTOCOL_VERSION})${NC}"
  echo ""
  echo -e "  ${BOLD}Home:${NC} ${CYAN}${home_dir}${NC}"
  echo ""
  echo -e "  ${BOLD}Next:${NC} Open Claude Code from this directory."
  echo -e "  ${name} will introduce herself, learn who you are,"
  echo -e "  and fill in her identity files. ${DIM}(That's the birth conversation.)${NC}"
  echo ""
  echo -e "  ${DIM}cd ${home_dir} && claude${NC}"
  echo ""
  echo -e "  ${DIM}https://github.com/VeltriaAI/beings-protocol${NC}"
  echo ""
}

main() {
  # Parse arguments
  local next_is_name=false
  for arg in "$@"; do
    if $next_is_name; then
      BEING_NAME="$arg"
      next_is_name=false
      continue
    fi
    case "$arg" in
      --global)         GLOBAL_MODE=true ;;
      --name)           next_is_name=true ;;
      --name=*)         BEING_NAME="${arg#--name=}" ;;
      --update)         UPDATE_MODE=true ;;
      --yes|-y)         YES_MODE=true ;;
    esac
  done

  # === GLOBAL BEING MODE ===
  if $GLOBAL_MODE; then
    print_banner
    if [ -z "$BEING_NAME" ]; then
      if can_prompt; then
        read_input "  Being name (e.g. nova, aria, kira): " BEING_NAME
      else
        echo "  Error: --global requires --name <name> in non-interactive mode" >&2
        exit 1
      fi
    fi
    if [ -z "$BEING_NAME" ]; then
      echo "  Error: Being name cannot be empty." >&2
      exit 1
    fi
    # Lowercase and strip spaces
    BEING_NAME="${BEING_NAME,,}"
    BEING_NAME="${BEING_NAME// /-}"
    create_global_being "$BEING_NAME"
    exit 0
  fi

  if $UPDATE_MODE; then
    print_banner_update

    # Check .beings/ exists
    if [ ! -d ".beings" ]; then
      print_warn "No .beings/ directory found — running fresh install instead"
      UPDATE_MODE=false
    fi
  fi

  if $UPDATE_MODE; then
    # === UPDATE MODE ===
    echo -e "\n  ${BOLD}Updating Beings Protocol...${NC}\n"

    # Step 1: Add new template files
    update_beings_dir

    # Step 2: Update tool configs
    echo -e "\n  ${BOLD}Checking AI tools...${NC}\n"
    detected_tools=$(detect_tools)
    if [ -n "$detected_tools" ]; then
      print_info "Detected: ${BOLD}${detected_tools}${NC}"
      auto_configure "$detected_tools"
    fi

    # Step 3: Update AGENTS.md if needed
    create_agents_md

    # Step 4: Update .gitignore
    update_gitignore

    # Step 5: Offer memory skill
    setup_memory_skill "${detected_tools:-}"

    # Step 6: Offer code intelligence (if not already set up)
    setup_code_intelligence "${detected_tools:-}"

    # Done
    print_update_summary
  else
    # === FRESH INSTALL ===
    print_banner

    # Sanity check
    if [ ! -d ".git" ] && [ ! -f "package.json" ] && [ ! -f "pyproject.toml" ] && [ ! -f "Cargo.toml" ] && [ ! -f "go.mod" ] && [ ! -f "Makefile" ]; then
      print_warn "Not in a project directory."
      if can_prompt; then
        local confirm=""
        read_input "  Continue anyway? (y/N) " confirm
        [[ "$confirm" != [yY]* ]] && echo "  Aborted." && exit 0
      fi
    fi

    # Step 1: Create .beings/ and .beings-local/
    echo -e "\n  ${BOLD}Setting up Beings Protocol...${NC}\n"
    create_beings_dir
    create_beings_local
    create_agents_md
    update_gitignore

    # Step 2: Configure tool-specific files
    echo -e "\n  ${BOLD}Detecting AI tools...${NC}\n"
    detected_tools=$(detect_tools)

    if [ -n "$detected_tools" ]; then
      print_info "Detected: ${BOLD}${detected_tools}${NC}"
      echo ""
      if can_prompt; then
        local auto_confirm=""
        read_input "  Auto-configure detected tools? (Y/n) " auto_confirm
        if [[ "$auto_confirm" != [nN]* ]]; then
          auto_configure "$detected_tools"
          echo ""
          local more_tools=""
          read_input "  Configure any other tools too? (y/N) " more_tools
          [[ "$more_tools" == [yY]* ]] && ask_tools
        else
          ask_tools
        fi
      else
        auto_configure "$detected_tools"
      fi
    else
      print_info "No AI tools auto-detected."
      print_info "AGENTS.md will work with Cursor, Claude Code, Copilot, and Codex out of the box."
      echo ""
      if can_prompt; then
        local want_specific=""
        read_input "  Configure tool-specific files anyway? (y/N) " want_specific
        [[ "$want_specific" == [yY]* ]] && ask_tools
      fi
    fi

    # Step 3: Optional memory skill
    setup_memory_skill "${detected_tools:-}"

    # Step 4: Optional code intelligence
    setup_code_intelligence "${detected_tools:-}"

    # Done!
    echo ""
    echo -e "  ${GREEN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  ${GREEN}${BOLD}${LEAF} Beings Protocol installed! (v${PROTOCOL_VERSION})${NC}"
    echo ""
    echo -e "  ${BOLD}What happens next:${NC}"
    echo ""
    echo -e "    Open your AI tool and start a conversation."
    echo -e "    Your Being will introduce itself, ask your name,"
    echo -e "    and learn about your project. ${DIM}(Just like meeting a new teammate.)${NC}"
    echo ""
    echo -e "  ${BOLD}After that first chat:${NC}"
    echo ""
    echo -e "    ${DIM}git add .beings/ AGENTS.md && git commit -m \"feat: born a Being 🌿\"${NC}"
    echo ""
    echo -e "  ${BOLD}Files:${NC}"
    echo ""
    echo -e "    ${CYAN}AGENTS.md${NC}             ${DIM}← Universal AI instructions (Cursor, Claude, Copilot, Codex)${NC}"
    echo ""
    echo -e "    ${CYAN}.beings/${NC}              ${DIM}← Shared (committed to git)${NC}"
    echo -e "    ├── BOOTSTRAP.md     ${DIM}← First-run conversation (deleted after)${NC}"
    echo -e "    ├── SOUL.md          ${DIM}← Being's identity${NC}"
    echo -e "    ├── AGENTS.md        ${DIM}← Operating instructions${NC}"
    echo -e "    ├── MEMORY.md        ${DIM}← Project memory${NC}"
    echo -e "    ├── CONVENTIONS.md   ${DIM}← Code rules${NC}"
    echo -e "    ├── GOALS.md         ${DIM}← Priorities${NC}"
    echo -e "    ├── AUTONOMY.md      ${DIM}← Decision authority${NC}"
    echo -e "    ├── HEARTBEAT.md     ${DIM}← Proactive checks${NC}"
    echo -e "    ├── IDENTITY.md      ${DIM}← Quick reference card${NC}"
    echo -e "    ├── TOOLS.md         ${DIM}← Environment config${NC}"
    if [ -f ".beings/mcp.json" ]; then
      echo -e "    ├── mcp.json         ${DIM}← MCP servers (code intelligence, memory)${NC}"
    fi
    echo -e "    └── memory/          ${DIM}← Daily logs${NC}"
    echo ""
    echo -e "    ${YELLOW}.beings-local/${NC}        ${DIM}← Private (never committed)${NC}"
    echo -e "    ├── USER.md          ${DIM}← About you${NC}"
    echo -e "    ├── PREFERENCES.md   ${DIM}← Work style${NC}"
    echo -e "    └── SECRETS.md       ${DIM}← Credentials${NC}"
    echo ""
    echo -e "  ${DIM}https://github.com/VeltriaAI/beings-protocol${NC}"
    echo -e "  ${DIM}Built with ${LEAF} by Veltria${NC}"
    echo ""
  fi
}

main "$@"
