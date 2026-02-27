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
# Usage: fetch_or_copy_template <template_relative_path> <destination>
# Example: fetch_or_copy_template "beings/SOUL.md" ".beings/SOUL.md"
# ============================================================
fetch_or_copy_template() {
  local rel_path="$1"
  local dest="$2"

  if [ -n "$SCRIPT_DIR" ] && [ -d "$SCRIPT_DIR/templates" ]; then
    # Running locally — copy from repo
    cp "$SCRIPT_DIR/templates/$rel_path" "$dest"
  else
    # Running via curl | bash — fetch from GitHub
    curl -fsSL "$BASE_URL/templates/$rel_path" -o "$dest"
  fi
}

# ============================================================
# Check if we can prompt the user (works even via curl | bash)
# ============================================================
HAS_TTY=false
if [ -t 0 ]; then
  HAS_TTY=true
elif (echo -n "" > /dev/tty) 2>/dev/null; then
  HAS_TTY=true
fi

can_prompt() {
  $HAS_TTY
}

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
  [ -f ".cursorrules" ] || [ -d ".cursor" ] && tools+=("cursor")
  [ -f "CLAUDE.md" ] || [ -f ".claude" ] && tools+=("claude-code")
  [ -f ".github/copilot-instructions.md" ] && tools+=("github-copilot")
  [ -f ".windsurfrules" ] && tools+=("windsurf")
  [ -f ".aider.conf.yml" ] || [ -f ".aiderignore" ] && tools+=("aider")
  [ -d ".openclaw" ] && tools+=("openclaw")

  # Also check installed binaries (if no config file found yet)
  if ! printf '%s\n' "${tools[@]}" | grep -q "^cursor$" 2>/dev/null; then
    command -v cursor &>/dev/null && tools+=("cursor")
  fi
  if ! printf '%s\n' "${tools[@]}" | grep -q "^claude-code$" 2>/dev/null; then
    command -v claude &>/dev/null && tools+=("claude-code")
  fi
  if ! printf '%s\n' "${tools[@]}" | grep -q "^windsurf$" 2>/dev/null; then
    command -v windsurf &>/dev/null && tools+=("windsurf")
  fi
  if ! printf '%s\n' "${tools[@]}" | grep -q "^aider$" 2>/dev/null; then
    command -v aider &>/dev/null && tools+=("aider")
  fi
  if ! printf '%s\n' "${tools[@]}" | grep -q "^openclaw$" 2>/dev/null; then
    command -v openclaw &>/dev/null && tools+=("openclaw")
  fi

  echo "${tools[@]}"
}

# ============================================================
# Create .beings/ (committed to git)
# ============================================================
create_beings_dir() {
  if [ -d ".beings" ]; then
    print_warn ".beings/ already exists — skipping (won't overwrite)"
    return
  fi

  mkdir -p .beings/memory

  fetch_or_copy_template "beings/SOUL.md"        ".beings/SOUL.md"
  fetch_or_copy_template "beings/AGENTS.md"      ".beings/AGENTS.md"
  fetch_or_copy_template "beings/BOOTSTRAP.md"   ".beings/BOOTSTRAP.md"
  fetch_or_copy_template "beings/MEMORY.md"      ".beings/MEMORY.md"
  fetch_or_copy_template "beings/CONVENTIONS.md" ".beings/CONVENTIONS.md"
  fetch_or_copy_template "beings/GOALS.md"       ".beings/GOALS.md"

  print_step "Created ${BOLD}.beings/${NC} directory (project memory — commit to git)"
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
# Tool configuration
# ============================================================

configure_tool() {
  local name="$1"
  local file="$2"
  local dir="$3"  # optional: create directory first

  [ -n "$dir" ] && mkdir -p "$dir"

  # Read prompt content from template (fetch or copy)
  local prompt_file
  prompt_file="$(mktemp)"
  fetch_or_copy_template "tool-configs/beings-prompt.md" "$prompt_file"
  local beings_prompt
  beings_prompt="$(cat "$prompt_file")"
  rm -f "$prompt_file"

  if [ -f "$file" ]; then
    if grep -q "Beings Protocol" "$file" 2>/dev/null; then
      print_warn "$name already configured — skipping"
      return
    fi
    echo "" >> "$file"
    echo "$beings_prompt" >> "$file"
  else
    echo "$beings_prompt" > "$file"
  fi
  print_step "Configured ${BOLD}${name}${NC} (${file})"
}

configure_openclaw() {
  print_info "OpenClaw detected — native compatibility! No extra config needed."
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
  echo "    3) GitHub Copilot"
  echo "    4) Windsurf"
  echo "    5) OpenClaw"
  echo "    6) Other / Skip"
  echo "    a) All"
  echo ""
  local choice=""
  read_input "  > " choice

  case "$choice" in
    *a*|*A*) configure_tool "Cursor" ".cursorrules" ""
             configure_tool "Claude Code" "CLAUDE.md" ""
             configure_tool "GitHub Copilot" ".github/copilot-instructions.md" ".github"
             configure_tool "Windsurf" ".windsurfrules" "" ;;
    *)
      [[ "$choice" == *1* ]] && configure_tool "Cursor" ".cursorrules" ""
      [[ "$choice" == *2* ]] && configure_tool "Claude Code" "CLAUDE.md" ""
      [[ "$choice" == *3* ]] && configure_tool "GitHub Copilot" ".github/copilot-instructions.md" ".github"
      [[ "$choice" == *4* ]] && configure_tool "Windsurf" ".windsurfrules" ""
      [[ "$choice" == *5* ]] && configure_openclaw
      [[ "$choice" == *6* ]] && print_info "Use prompts/system-prompt.md for manual setup." ;;
  esac
}

auto_configure() {
  for tool in $1; do
    case "$tool" in
      cursor)         configure_tool "Cursor" ".cursorrules" "" ;;
      claude-code)    configure_tool "Claude Code" "CLAUDE.md" "" ;;
      github-copilot) configure_tool "GitHub Copilot" ".github/copilot-instructions.md" ".github" ;;
      windsurf)       configure_tool "Windsurf" ".windsurfrules" "" ;;
      openclaw)       configure_openclaw ;;
    esac
  done
}

# ============================================================
# Main
# ============================================================
main() {
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

  # Step 1: Create files
  echo -e "\n  ${BOLD}Setting up Beings Protocol...${NC}\n"
  create_beings_dir
  create_beings_local
  update_gitignore

  # Step 2: Configure tools
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
      # Non-interactive, no TTY at all — auto-configure what we found
      auto_configure "$detected_tools"
    fi
  else
    print_info "No AI tools auto-detected."
    echo ""
    if can_prompt; then
      ask_tools
    else
      print_info "Run install.sh interactively to configure tools."
    fi
  fi

  # Done!
  echo ""
  echo -e "  ${GREEN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo -e "  ${GREEN}${BOLD}${LEAF} Beings Protocol installed!${NC}"
  echo ""
  echo -e "  ${BOLD}What happens next:${NC}"
  echo ""
  echo -e "    Open your AI tool and start a conversation."
  echo -e "    Your Being will introduce itself, ask your name,"
  echo -e "    and learn about your project. ${DIM}(Just like meeting a new teammate.)${NC}"
  echo ""
  echo -e "  ${BOLD}After that first chat:${NC}"
  echo ""
  echo -e "    ${DIM}git add .beings/ && git commit -m \"feat: born a Being 🌿\"${NC}"
  echo ""
  echo -e "  ${BOLD}Files:${NC}"
  echo ""
  echo -e "    ${CYAN}.beings/${NC}              ${DIM}← Shared (committed to git)${NC}"
  echo -e "    ├── BOOTSTRAP.md     ${DIM}← First-run conversation (deleted after)${NC}"
  echo -e "    ├── SOUL.md          ${DIM}← Being's identity${NC}"
  echo -e "    ├── AGENTS.md        ${DIM}← Operating instructions${NC}"
  echo -e "    ├── MEMORY.md        ${DIM}← Project memory${NC}"
  echo -e "    ├── CONVENTIONS.md   ${DIM}← Code rules${NC}"
  echo -e "    ├── GOALS.md         ${DIM}← Priorities${NC}"
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
}

main "$@"
