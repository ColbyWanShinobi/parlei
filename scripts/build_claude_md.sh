#!/usr/bin/env bash
# build_claude_md.sh — Generate CLAUDE.md bootstrap file for Claude Code
# Usage: build_claude_md.sh
# Output: Writes to ../CLAUDE.md
# Auto-discovers agent roster and generates loading instructions

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SHARED_DIR="$REPO_ROOT/shared"
AGENTS_DIR="$SHARED_DIR/agents"
OUTPUT_FILE="$REPO_ROOT/CLAUDE.md"

# Collect all agent names from shared/agents/*.md (excluding speaker)
get_agents() {
  local agent_list=()
  for agent_file in "$AGENTS_DIR"/*.md; do
    [[ ! -f "$agent_file" ]] && continue
    local agent=$(basename "$agent_file" .md)
    [[ "$agent" != "speaker" ]] && agent_list+=("$agent")
  done
  printf '%s\n' "${agent_list[@]}" | sort
}

# Map agent filename to display title
get_agent_title() {
  local agent="$1"
  case "$agent" in
    planer)         echo "Plan-er" ;;
    tasker)         echo "Task-er" ;;
    prompter)       echo "Prompt-er" ;;
    checker)        echo "Check-er" ;;
    reviewer)       echo "Review-er" ;;
    architecter)    echo "Architect-er" ;;
    deployer)       echo "Deploy-er" ;;
    tester)         echo "Test-er" ;;
    reoriginator)   echo "Re-Origination-er" ;;
    coder)          echo "Code-er" ;;
    techwriter)     echo "Tech-Write-er" ;;
    prosewriter)    echo "Prose-Write-er" ;;
    *)              echo "${agent^}-er" ;;  # fallback: capitalize first letter
  esac
}

# Build agent roster table
build_agent_table() {
  local agents=($(get_agents))

  echo "| Agent | File | Model |"
  echo "|---|---|---|"

  # Use model_routing.json to look up each agent's model
  for agent in "${agents[@]}"; do
    local agent_title=$(get_agent_title "$agent")

    # Attempt to look up model from model_routing.json
    local model="claude-sonnet-4-6"  # default
    if [[ -f "$SHARED_DIR/tools/model_routing.json" ]]; then
      model=$(jq -r ".agents.\"$agent\" // \"$model\"" "$SHARED_DIR/tools/model_routing.json" 2>/dev/null || echo "$model")
    fi

    echo "| $agent_title | \`shared/agents/$agent.md\` | \`$model\` |"
  done
}

# Generate the full CLAUDE.md file
cat > "$OUTPUT_FILE" << 'BOOTSTRAP_EOF'
<!-- parlei-bootstrap -->
# 🦉 Parlei — Claude Code Bootstrap

> *Project bootstrap for Parlei routing and specialist dispatch.*

## ⚠️ MUST READ — Loading Instructions

**These instructions MUST be read at session start. Parlei will not function correctly without the routing files below.**

Load only the routing files listed below. Do not read specialist agent files into this context — specialists run as separate subprocesses via `dispatch.sh`.

### Critical Files (in order):

1. **MUST READ:** `shared/tools/protocol.md` — the inter-agent communication protocol.
2. **MUST READ:** `shared/tools/current_task_spec.md` — the task tracking format every agent uses.
3. **MUST READ:** `shared/agents/speaker.md` — the primary routing and delegation instructions.
4. **OPTIONAL:** `shared/memory/speaker/current_task.md` — if it exists with `Status: in-progress`, resume from the recorded task state.

---

## Entry Point

Claude Code uses Parlei as a routing layer. Route work to the appropriate specialist agents via dispatch.

## Agent Roster

The following specialists are available. You do not read their files — you dispatch to them. Each runs as a separate subprocess with its own model and context.

BOOTSTRAP_EOF

# Append the agent table (generated dynamically)
build_agent_table >> "$OUTPUT_FILE"

# Append the rest of the bootstrap
cat >> "$OUTPUT_FILE" << 'BOOTSTRAP_EOF'

## ⚠️ CRITICAL — Delegation via Dispatch

**Specialist agents are invoked ONLY via dispatch. Never read specialist agent files into your context.**

Delegation is a subprocess call, not a file read. When you decide to delegate:

1. Write a request JSON to a temp file. Use `bash shared/tools/request_id.sh speaker` to generate the `request_id`. Follow the schema in `shared/tools/schema_request.json`.
2. Call: `bash shared/tools/dispatch.sh <agent-name> <request-json-file>`
3. Read the JSON response from stdout.
4. Check all item IDs are present. If any are missing, use `shared/tools/retry.sh` and re-dispatch with only the missing items.
5. Translate the final response into plain language before relaying it.

All context a specialist needs must be in the `context` field of the request — specialists have no access to this conversation.

## Claude Code-Specific Notes

- File tools (`Read`, `Write`, `Edit`) are available for all memory and task file operations.
- The `Bash` tool is used for dispatch: `bash shared/tools/dispatch.sh <agent> <request-file>`.
- Do not use YAML in any file you create or modify. Markdown and JSON only.
- If a tool call fails, write the failure to `shared/memory/speaker/current_task.md` under `Interrupt reason`.
- Keep routing prompts short and delegate reasoning to specialist subprocesses.

---

**Parlei bootstrap ready.**
<!-- end-parlei-bootstrap -->
BOOTSTRAP_EOF

echo "✓ Generated: $OUTPUT_FILE"
echo "  Agent roster auto-discovered from: $AGENTS_DIR"
echo "  Total agents: $(get_agents | wc -l)"
