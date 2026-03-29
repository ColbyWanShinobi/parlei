#!/usr/bin/env bash
# dispatch.sh — Route a request to a specialist agent subprocess.
# Usage: dispatch.sh <agent-name> <request-json-file>
#
# Steps:
#   1. Validate agent and request.
#   2. Extract or generate a request_id.
#   3. Acquire a per-agent file lock (prevents concurrent inbox/outbox collision).
#   4. Copy request to inbox/<request_id>.json.
#   5. Invoke agent_runner.sh.
#   6. On runner failure: return an escalation envelope and exit 1.
#   7. Write response to outbox/<request_id>.json.
#   8. Validate response schema (warn only — caller decides whether to retry).
#   9. Remove inbox file. Release lock.
#  10. Print response JSON to stdout.
#
# Exit codes:
#   0 — dispatch succeeded (response may still contain failed/deferred items)
#   1 — dispatch-level failure (runner crashed, no JSON returned, lock timeout)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
MEMORY_ROOT="$REPO_ROOT/shared/memory"

if [[ $# -ne 2 ]]; then
  echo "Usage: dispatch.sh <agent-name> <request-json-file>" >&2
  exit 1
fi

AGENT="$1"
REQUEST_FILE="$2"
AGENT_DEF="$REPO_ROOT/shared/agents/${AGENT}.md"
AGENT_DIR="$MEMORY_ROOT/$AGENT"

# ── Validate inputs ───────────────────────────────────────────────────────────

if [[ ! -f "$AGENT_DEF" ]]; then
  echo "Error: unknown agent '$AGENT' — no definition found at $AGENT_DEF" >&2
  exit 1
fi

if [[ ! -f "$REQUEST_FILE" ]]; then
  echo "Error: request file not found: $REQUEST_FILE" >&2
  exit 1
fi

python3 -c "import json; json.load(open('$REQUEST_FILE'))" 2>/dev/null || {
  echo "Error: request file is not valid JSON: $REQUEST_FILE" >&2
  exit 1
}

# ── Extract or generate request_id ───────────────────────────────────────────

REQUEST_ID="$(python3 -c "
import json
d = json.load(open('$REQUEST_FILE'))
print(d.get('request_id', ''))
")"

if [[ -z "$REQUEST_ID" ]]; then
  FROM_AGENT="$(python3 -c "import json; print(json.load(open('$REQUEST_FILE')).get('from', 'unknown'))")"
  if [[ -d "$MEMORY_ROOT/$FROM_AGENT" ]]; then
    REQUEST_ID="$("$SCRIPT_DIR/request_id.sh" "$FROM_AGENT")"
  else
    # Caller is not a named agent (e.g. a script) — generate a time-based ID
    REQUEST_ID="req-${FROM_AGENT}-$(date '+%Y%m%d')-$(printf '%03d' $(( RANDOM % 1000 )))"
  fi
fi

# ── Per-agent file lock ───────────────────────────────────────────────────────
# Serializes concurrent dispatches to the same agent.
# Prevents inbox/outbox filename collisions and interleaved responses.
# Uses flock if available; falls back to atomic mkdir on systems without it.

LOCK_FILE="$AGENT_DIR/.dispatch.lock"
LOCK_TIMEOUT=60
LOCK_FD=""

acquire_lock() {
  if command -v flock &>/dev/null; then
    exec {LOCK_FD}>"$LOCK_FILE"
    flock -w "$LOCK_TIMEOUT" "$LOCK_FD" || {
      echo "Error: could not acquire dispatch lock for agent $AGENT after ${LOCK_TIMEOUT}s" >&2
      exit 1
    }
  else
    local lock_dir="${LOCK_FILE}.d"
    local deadline=$(( $(date +%s) + LOCK_TIMEOUT ))
    until mkdir "$lock_dir" 2>/dev/null; do
      if [[ $(date +%s) -ge $deadline ]]; then
        echo "Error: could not acquire dispatch lock for agent $AGENT after ${LOCK_TIMEOUT}s" >&2
        exit 1
      fi
      sleep 0.5
    done
    trap 'rmdir "${LOCK_FILE}.d" 2>/dev/null || true' EXIT
  fi
}

release_lock() {
  if command -v flock &>/dev/null && [[ -n "$LOCK_FD" ]]; then
    flock -u "$LOCK_FD" 2>/dev/null || true
  else
    rmdir "${LOCK_FILE}.d" 2>/dev/null || true
    trap - EXIT
  fi
}

acquire_lock

# ── Write request to inbox ────────────────────────────────────────────────────

INBOX_DIR="$AGENT_DIR/inbox"
OUTBOX_DIR="$AGENT_DIR/outbox"
INBOX_FILE="$INBOX_DIR/${REQUEST_ID}.json"

cp "$REQUEST_FILE" "$INBOX_FILE"

# ── Invoke agent runner ───────────────────────────────────────────────────────

RUNNER_OUTPUT=""
RUNNER_EXIT=0
RUNNER_OUTPUT="$("$SCRIPT_DIR/agent_runner.sh" "$AGENT" "$INBOX_FILE" 2>&1)" || RUNNER_EXIT=$?

if [[ $RUNNER_EXIT -ne 0 ]]; then
  rm -f "$INBOX_FILE"
  release_lock

  # Return a well-formed escalation envelope so the caller can handle it
  python3 -c "
import json, sys
envelope = {
    'from': '$AGENT',
    'to': 'speaker',
    'request_id': '${REQUEST_ID}-esc',
    'type': 'escalation',
    'items': [{
        'id': 1,
        'type': 'escalation',
        'description': 'dispatch.sh: agent_runner.sh failed for agent $AGENT',
        'context': json.dumps({
            'request_id': '$REQUEST_ID',
            'error': sys.argv[1]
        })
    }]
}
print(json.dumps(envelope, indent=2))
" "$RUNNER_OUTPUT"
  exit 1
fi

# ── Write response to outbox ──────────────────────────────────────────────────

OUTBOX_FILE="$OUTBOX_DIR/${REQUEST_ID}.json"
printf '%s\n' "$RUNNER_OUTPUT" > "$OUTBOX_FILE"

# ── Validate response schema (warn only) ──────────────────────────────────────

python3 -c "
import json, sys
schema_file = '$REPO_ROOT/shared/tools/schema_response.json'
try:
    import jsonschema
    schema = json.load(open(schema_file))
    data = json.loads(sys.argv[1])
    jsonschema.validate(data, schema)
except ImportError:
    pass  # jsonschema not installed — skip full validation
except jsonschema.ValidationError as e:
    print(f'Warning: response from $AGENT does not match schema: {e.message}', file=sys.stderr)
except Exception as e:
    print(f'Warning: schema validation error: {e}', file=sys.stderr)
" "$RUNNER_OUTPUT" || true

# ── Clean up inbox and release lock ──────────────────────────────────────────

rm -f "$INBOX_FILE"
release_lock

# ── Return response ───────────────────────────────────────────────────────────

printf '%s\n' "$RUNNER_OUTPUT"
