#!/usr/bin/env bash
# llm_call.sh — Minimal LLM HTTP interface. No proprietary SDK required.
# Usage: llm_call.sh <endpoint> <model> <prompt>
# Reads timeout from memory_config.json. Exits non-zero on any error.
# Prints the LLM response text to stdout on success.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/memory_config.json"

if [[ $# -lt 3 ]]; then
  echo "Usage: llm_call.sh <endpoint> <model> <prompt>" >&2
  exit 1
fi

ENDPOINT="$1"
MODEL="$2"
PROMPT="$3"

if [[ -z "$ENDPOINT" ]]; then
  echo "Error: llm_endpoint is not configured in memory_config.json" >&2
  exit 1
fi

if [[ -z "$MODEL" ]]; then
  echo "Error: llm_model is not configured in memory_config.json" >&2
  exit 1
fi

TIMEOUT="$(python3 -c "import json; d=json.load(open('$CONFIG_FILE')); print(d.get('llm_timeout_seconds', 30))")"
AUTH_TOKEN="$(python3 -c "import json; d=json.load(open('$CONFIG_FILE')); print(d.get('llm_auth_token', ''))")"

# Build JSON body
BODY="$(python3 -c "
import json, sys
body = {
    'model': sys.argv[1],
    'messages': [{'role': 'user', 'content': sys.argv[2]}],
    'stream': False
}
print(json.dumps(body))
" "$MODEL" "$PROMPT")"

# Build curl args
CURL_ARGS=(
  --silent
  --fail
  --max-time "$TIMEOUT"
  -X POST "$ENDPOINT"
  -H "Content-Type: application/json"
  -d "$BODY"
)

if [[ -n "$AUTH_TOKEN" ]]; then
  CURL_ARGS+=(-H "Authorization: Bearer $AUTH_TOKEN")
fi

# Execute request
HTTP_RESPONSE="$(curl "${CURL_ARGS[@]}" 2>&1)" || {
  echo "Error: HTTP request failed — $HTTP_RESPONSE" >&2
  exit 1
}

if [[ -z "$HTTP_RESPONSE" ]]; then
  echo "Error: LLM returned an empty response body" >&2
  exit 1
fi

# Extract content from OpenAI-compatible response format
CONTENT="$(python3 -c "
import json, sys
try:
    data = json.loads(sys.argv[1])
    # OpenAI-compatible: choices[0].message.content
    if 'choices' in data:
        print(data['choices'][0]['message']['content'])
    # Ollama-compatible: message.content
    elif 'message' in data:
        print(data['message']['content'])
    # Generic: response field
    elif 'response' in data:
        print(data['response'])
    else:
        print(json.dumps(data), file=sys.stderr)
        sys.exit(1)
except (json.JSONDecodeError, KeyError, IndexError) as e:
    print(f'Error parsing LLM response: {e}', file=sys.stderr)
    sys.exit(1)
" "$HTTP_RESPONSE")" || {
  echo "Error: could not parse LLM response body" >&2
  exit 1
}

echo "$CONTENT"
