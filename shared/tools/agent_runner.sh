#!/usr/bin/env bash
# agent_runner.sh — Invoke a specialist agent as a real subprocess with its own model.
# Usage: agent_runner.sh <agent-name> <request-json-file>
# Reads model from model_routing.json, builds system prompt, invokes LLM CLI.
# Prints JSON response to stdout. Exits non-zero on any failure.
# Does not write to inbox/outbox — that is dispatch.sh's responsibility.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

if [[ $# -ne 2 ]]; then
  echo "Usage: agent_runner.sh <agent-name> <request-json-file>" >&2
  exit 1
fi

AGENT="$1"
REQUEST_FILE="$2"

# ── Validate inputs ───────────────────────────────────────────────────────────

if [[ ! -f "$REQUEST_FILE" ]]; then
  echo "Error: request file not found: $REQUEST_FILE" >&2
  exit 1
fi

python3 -c "import json; json.load(open('$REQUEST_FILE'))" 2>/dev/null || {
  echo "Error: request file is not valid JSON: $REQUEST_FILE" >&2
  exit 1
}

# ── Read model from routing table ─────────────────────────────────────────────

ROUTING_FILE="$SCRIPT_DIR/model_routing.json"
if [[ ! -f "$ROUTING_FILE" ]]; then
  echo "Error: model_routing.json not found at $ROUTING_FILE" >&2
  exit 1
fi

MODEL="$(python3 -c "
import json, sys
d = json.load(open('$ROUTING_FILE'))
entry = d.get('$AGENT')
if not entry:
    print('Error: agent \"$AGENT\" not found in model_routing.json', file=sys.stderr)
    sys.exit(1)
print(entry['model'])
")" || exit 1

# ── Read active environment ───────────────────────────────────────────────────

ENV="claude"
ENV_FILE="$REPO_ROOT/.parlei-env"
[[ -f "$ENV_FILE" ]] && ENV="$(tr -d '[:space:]' < "$ENV_FILE")"

# ── Build system prompt ───────────────────────────────────────────────────────

SYSTEM_PROMPT="$("$SCRIPT_DIR/build_system_prompt.sh" "$AGENT")" || {
  echo "Error: failed to build system prompt for agent: $AGENT" >&2
  exit 1
}

# ── Assemble combined input ───────────────────────────────────────────────────
# System prompt is prepended to the request so the agent has full context.
# A clear separator and instruction precede the JSON request.

COMBINED_FILE="$(mktemp)"
trap 'rm -f "$COMBINED_FILE"' EXIT

{
  printf '%s\n' "$SYSTEM_PROMPT"
  echo ""
  echo "---"
  echo ""
  echo "You have received the following inter-agent request. Read it carefully, perform your role as defined above, and respond with a valid JSON response envelope per the Communication Protocol. Output only the JSON — no preamble, no commentary."
  echo ""
  cat "$REQUEST_FILE"
} > "$COMBINED_FILE"

# ── Invoke the LLM CLI ────────────────────────────────────────────────────────

RESPONSE=""

case "$ENV" in
  claude)
    # Claude Code CLI: --print runs non-interactively, reads prompt from stdin.
    RESPONSE="$(claude --print --model "$MODEL" < "$COMBINED_FILE")" || {
      echo "Error: claude CLI invocation failed for agent $AGENT (model: $MODEL)" >&2
      exit 1
    }
    ;;
  openclaw)
    # OpenClaw CLI: mirrors Claude Code's --print interface.
    RESPONSE="$(openclaw --print --model "$MODEL" < "$COMBINED_FILE")" || {
      echo "Error: openclaw CLI invocation failed for agent $AGENT (model: $MODEL)" >&2
      exit 1
    }
    ;;
  codex|augment|*)
    # No interactive CLI with a --print equivalent. Fall back to llm_call.sh
    # using the endpoint configured in memory_config.json.
    CONFIG_FILE="$SCRIPT_DIR/memory_config.json"
    ENDPOINT="$(python3 -c "import json; print(json.load(open('$CONFIG_FILE')).get('llm_endpoint',''))")"
    if [[ -z "$ENDPOINT" ]]; then
      echo "Error: llm_endpoint not configured in memory_config.json (required for env: $ENV)" >&2
      exit 1
    fi
    COMBINED_PROMPT="$(cat "$COMBINED_FILE")"
    RESPONSE="$("$SCRIPT_DIR/llm_call.sh" "$ENDPOINT" "$MODEL" "$COMBINED_PROMPT")" || {
      echo "Error: llm_call.sh invocation failed for agent $AGENT (env: $ENV, model: $MODEL)" >&2
      exit 1
    }
    ;;
esac

# ── Validate response ─────────────────────────────────────────────────────────

if [[ -z "$RESPONSE" ]]; then
  echo "Error: LLM returned empty response for agent $AGENT (model: $MODEL)" >&2
  exit 1
fi

python3 -c "import json, sys; json.loads(sys.argv[1])" "$RESPONSE" 2>/dev/null || {
  # Truncate raw response in error message to avoid flooding stderr
  echo "Error: LLM response is not valid JSON for agent $AGENT. Raw (first 300 chars): ${RESPONSE:0:300}" >&2
  exit 1
}

printf '%s\n' "$RESPONSE"
