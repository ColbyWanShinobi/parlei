#!/usr/bin/env bash
# build_system_prompt.sh — Assemble a full system prompt for a named agent.
# Usage: build_system_prompt.sh <agent-name>
# Output: assembled system prompt printed to stdout. No files written.
# Exits 1 if the agent memory directory does not exist.
# Missing individual source files are skipped with a warning to stderr.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

if [[ $# -ne 1 ]]; then
  echo "Usage: build_system_prompt.sh <agent-name>" >&2
  exit 1
fi

AGENT="$1"
AGENT_DIR="$REPO_ROOT/shared/memory/$AGENT"

if [[ ! -d "$AGENT_DIR" ]]; then
  echo "Error: agent memory directory not found: $AGENT_DIR" >&2
  exit 1
fi

# ── Section printer ───────────────────────────────────────────────────────────
# Prints a Markdown section header followed by the file contents.
# Warns to stderr and skips if the file is absent or empty.

print_section() {
  local header="$1"
  local file="$2"
  if [[ -f "$file" && -s "$file" ]]; then
    echo "## $header"
    echo ""
    cat "$file"
    echo ""
  else
    echo "Warning: skipping missing or empty file: $file" >&2
  fi
}

# ── Assembly order ────────────────────────────────────────────────────────────
# 1. Role & Responsibilities  — what this agent does and is accountable for
# 2. Personality              — tone, style, and character
# 3. Identity                 — core values and non-negotiables
# 4. Long-Term Memory         — accumulated knowledge and decisions
# 5. Communication Protocol   — inter-agent message rules
# 6. Task Tracking            — current_task.md format and lifecycle

print_section "Role & Responsibilities" "$REPO_ROOT/shared/agents/${AGENT}.md"
print_section "Personality"             "$REPO_ROOT/shared/personalities/${AGENT}.md"
print_section "Identity"                "$AGENT_DIR/identity.md"
print_section "Long-Term Memory"        "$AGENT_DIR/long_term.md"
print_section "Communication Protocol"  "$REPO_ROOT/shared/tools/protocol.md"
print_section "Task Tracking"           "$REPO_ROOT/shared/tools/current_task_spec.md"
