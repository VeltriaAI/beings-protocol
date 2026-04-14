#!/usr/bin/env bash
# ============================================================
# 🌿 Beings Protocol Installer
# Transform your AI into a Being — with identity, memory & soul
# 
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/VeltriaAI/beings-protocol/main/install.sh | bash
#   OR
#   wget -qO- https://raw.githubusercontent.com/VeltriaAI/beings-protocol/main/install.sh | bash
# ============================================================

set -euo pipefail

PROTOCOL_VERSION="0.2.1"
UPDATE_MODE=false

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
  [ -f ".github/copilot-instructions.md" ] && tools+=("github-copilot")
  [ -f ".windsurfrules" ] && tools+=("windsurf")
  { [ -f ".aider.conf.yml" ] || [ -f ".aiderignore" ]; } && tools+=("aider")

  # Check installed binaries (if not already detected via config)
  local found
  found=$(printf '%s\n' "${tools[@]+" ${tools[@]}"}")
  [[ "$found" != *cursor* ]]      && command -v cursor    &>/dev/null && tools+=("cursor")
  [[ "$found" != *claude-code* ]]  && command -v claude    &>/dev/null && tools+=("claude-code")
  [[ "$found" != *windsurf* ]]     && command -v windsurf  &>/dev/null && tools+=("windsurf")
  [[ "$found" != *aider* ]]        && command -v aider     &>/dev/null && tools+=("aider")

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
# Update existing .beings/ (add missing files, never overwrite)
# ============================================================
update_beings_dir() {
  local old_version="0.1.0"
  if [ -f ".beings/.protocol-version" ]; then
    old_version="$(cat .beings/.protocol-version)"
  fi

  print_info "Current protocol version: ${BOLD}${old_version}${NC} → ${BOLD}${PROTOCOL_VERSION}${NC}"

  mkdir -p .beings/memory

  local added=0
  local skipped=0

  for tmpl in "${BEINGS_TEMPLATES[@]}"; do
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
    if grep -q "Beings Protocol" "AGENTS.md" 2>/dev/null; then
      print_warn "AGENTS.md already has Beings Protocol — skipping"
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

# Configure GitHub Copilot (.github/copilot-instructions.md)
configure_copilot() {
  local file=".github/copilot-instructions.md"
  if [ -f "$file" ] && grep -q "Beings Protocol" "$file" 2>/dev/null; then
    print_warn "GitHub Copilot already configured — skipping"
    return
  fi

  mkdir -p ".github"
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
  print_step "Configured ${BOLD}GitHub Copilot${NC} (.github/copilot-instructions.md)"
}

# Configure Windsurf (.windsurfrules)
configure_windsurf() {
  local file=".windsurfrules"
  if [ -f "$file" ] && grep -q "Beings Protocol" "$file" 2>/dev/null; then
    print_warn "Windsurf already configured — skipping"
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
  print_step "Configured ${BOLD}Windsurf${NC} (.windsurfrules)"
}

# Auto-configure a detected tool
auto_configure() {
  for tool in $1; do
    case "$tool" in
      cursor)         configure_cursor ;;
      claude-code)    configure_claude_code ;;
      github-copilot) configure_copilot ;;
      windsurf)       configure_windsurf ;;
    esac
  done
}

# ============================================================
# Interactive tool selection
# ============================================================
ask_tools() {
  echo ""
  echo -e "  ${BOLD}Which AI tools do you use?${NC} ${DIM}(AGENTS.md already covers Codex & others)${NC}"
  echo ""
  echo "    1) Cursor"
  echo "    2) Claude Code"
  echo "    3) GitHub Copilot"
  echo "    4) Windsurf"
  echo "    5) Skip (AGENTS.md is enough)"
  echo "    a) All of the above"
  echo ""
  local choice=""
  read_input "  > " choice

  case "$choice" in
    *a*|*A*) configure_cursor
             configure_claude_code
             configure_copilot
             configure_windsurf ;;
    *)
      [[ "$choice" == *1* ]] && configure_cursor
      [[ "$choice" == *2* ]] && configure_claude_code
      [[ "$choice" == *3* ]] && configure_copilot
      [[ "$choice" == *4* ]] && configure_windsurf
      [[ "$choice" == *5* ]] && print_info "AGENTS.md will work with most AI tools out of the box." ;;
  esac
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

  if [ -f ".beings/mcp.json" ]; then
    if add_basic_memory_to_mcp ".beings/mcp.json" "servers" "$project_name"; then
      print_step "Updated ${BOLD}.beings/mcp.json${NC} with basic-memory"
      updated=true
    fi
  fi

  if [ -f ".mcp.json" ]; then
    if add_basic_memory_to_mcp ".mcp.json" "mcpServers" "$project_name"; then
      print_step "Updated ${BOLD}.mcp.json${NC} with basic-memory"
      updated=true
    fi
  fi

  if [ -f ".cursor/mcp.json" ]; then
    if add_basic_memory_to_mcp ".cursor/mcp.json" "mcpServers" "$project_name"; then
      print_step "Updated ${BOLD}.cursor/mcp.json${NC} with basic-memory"
      updated=true
    fi
  fi

  $updated || print_info "No existing MCP configs found to update"
}

# ============================================================
# Memory Skill (basic-memory — Optional)
# ============================================================
setup_memory_skill() {
  local detected_tools="$1"

  # 1. Check Python >= 3.10
  if ! command -v python3 &>/dev/null; then
    print_warn "Python3 not found — skipping basic-memory"
    print_info "Install Python >= 3.10 and re-run with --update to add memory skill"
    return
  fi

  local python_major python_minor
  python_major=$(python3 -c "import sys; print(sys.version_info.major)" 2>/dev/null || echo 0)
  python_minor=$(python3 -c "import sys; print(sys.version_info.minor)" 2>/dev/null || echo 0)
  if [ "$python_major" -lt 3 ] || { [ "$python_major" -eq 3 ] && [ "$python_minor" -lt 10 ]; }; then
    print_warn "Python >= 3.10 required (found ${python_major}.${python_minor}) — skipping basic-memory"
    return
  fi

  # 2. Prompt
  echo ""
  echo -e "  ${BOLD}🧠 Persistent Memory (Optional)${NC}\n"
  echo -e "  Give your Being git-syncable markdown memory with semantic search?"
  echo -e "  This installs ${BOLD}basic-memory${NC} — markdown files as source of truth,"
  echo -e "  Obsidian-compatible, hand-editable, git-syncable across machines.\n"
  echo -e "  ${DIM}(Local SQLite index + fastembed embeddings, no data leaves your machine)${NC}\n"

  local install_memory=""
  if can_prompt; then
    read_input "  Install basic-memory? (Y/n) " install_memory
  else
    print_info "Non-interactive mode — skipping memory skill (add later with --update)"
    return
  fi
  [[ "$install_memory" == [nN]* ]] && { print_info "Skipped memory skill — add later with --update"; return; }

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

  if [ -f "$settings_file" ] && grep -q "MEMORY PRESERVATION\|MEMORY RECALL" "$settings_file" 2>/dev/null; then
    print_info "Memory hooks already configured — skipping"
    return
  fi

  # Try Python merge if settings file exists with existing hooks
  if [ -f "$settings_file" ] && command -v python3 &>/dev/null; then
    python3 -c "
import json
from pathlib import Path

hooks_to_add = {
    'PreCompact': [{
        'matcher': '',
        'hooks': [{
            'type': 'command',
            'command': \"echo 'MEMORY PRESERVATION: Context is about to be compressed. Extract key decisions, learnings, and facts from this session. Use write_note to create or update notes in memory-graph/ with clear titles and folders (e.g. decisions/, learnings/, sessions/YYYY-MM-DD). Include observations as bulleted [category] lines and use [[wikilinks]] for relations. Markdown files are the source of truth.'\"
        }]
    }],
    'Stop': [{
        'matcher': '',
        'hooks': [{
            'type': 'command',
            'command': \"echo 'SESSION END: Write a session summary note via write_note to memory-graph/sessions/YYYY-MM-DD. Include: what was built, decisions made, unresolved questions, and links to relevant existing notes. Capture only what future-you will need.'\"
        }]
    }],
    'SessionStart': [{
        'matcher': '',
        'hooks': [{
            'type': 'command',
            'command': \"echo 'MEMORY RECALL: Query basic-memory via search_notes for context relevant to this session. Use recent_activity to see what changed recently. Read identity files (SOUL.md, IDENTITY.md) as always — those are who you are. Search for anything relevant to what the user is asking.'\"
        }]
    }]
}

path = Path('$settings_file')
if path.exists():
    data = json.loads(path.read_text())
else:
    data = {}

if 'hooks' not in data:
    data['hooks'] = {}

for event, hook_list in hooks_to_add.items():
    if event not in data['hooks']:
        data['hooks'][event] = []
    # Only append if not already there (simple check: look for MEMORY keyword in commands)
    already = any(
        'MEMORY' in (h.get('hooks', [{}])[0].get('command', '') if h.get('hooks') else '')
        for h in data['hooks'][event]
    )
    if not already:
        data['hooks'][event].extend(hook_list)

path.write_text(json.dumps(data, indent=2) + '\n')
" 2>/dev/null
    if [ $? -eq 0 ]; then
      print_step "Merged memory hooks into ${BOLD}${settings_file}${NC}"
      return
    fi
  fi

  # No existing settings or Python unavailable — write a fresh file
  cat > "$settings_file" <<'HOOKS_EOF'
{
  "hooks": {
    "PreCompact": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "echo 'MEMORY PRESERVATION: Context is about to be compressed. Extract key decisions, learnings, and facts from this session. Use write_note to create or update notes in memory-graph/ with clear titles and folders (e.g. decisions/, learnings/, sessions/YYYY-MM-DD). Include observations as bulleted [category] lines and use [[wikilinks]] for relations. Markdown files are the source of truth.'"
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "echo 'SESSION END: Write a session summary note via write_note to memory-graph/sessions/YYYY-MM-DD. Include: what was built, decisions made, unresolved questions, and links to relevant existing notes. Capture only what future-you will need.'"
          }
        ]
      }
    ],
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "echo 'MEMORY RECALL: Query basic-memory via search_notes for context relevant to this session. Use recent_activity to see what changed recently. Read identity files (SOUL.md, IDENTITY.md) as always — those are who you are. Search for anything relevant to what the user is asking.'"
          }
        ]
      }
    ]
  }
}
HOOKS_EOF
  print_step "Created ${BOLD}${settings_file}${NC} with memory hooks"
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
  if can_prompt; then
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

main() {
  # Parse arguments
  for arg in "$@"; do
    case "$arg" in
      --update) UPDATE_MODE=true ;;
    esac
  done

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
