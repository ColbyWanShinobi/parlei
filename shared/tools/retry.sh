#!/usr/bin/env bash
# retry.sh — Check a response for missing item IDs and manage retry state.
# Usage: retry.sh <request_id> <agent_name> <request_json_file> <response_json_file>
# Exits 0 if all items are accounted for.
# Exits 2 if items are missing and retry limit not yet reached (caller should retry).
# Exits 3 if retry limit reached (caller should escalate).
# Writes retry state to shared/memory/<agent>/.retry_state/<request_id>.json

set -euo pipefail

MAX_RETRIES=3

if [[ $# -ne 4 ]]; then
  echo "Usage: retry.sh <request_id> <agent_name> <request_json_file> <response_json_file>" >&2
  exit 1
fi

REQUEST_ID="$1"
AGENT="$2"
REQUEST_FILE="$3"
RESPONSE_FILE="$4"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE_DIR="$SCRIPT_DIR/../../shared/memory/${AGENT}/.retry_state"
mkdir -p "$STATE_DIR"
STATE_FILE="$STATE_DIR/${REQUEST_ID}.json"

# Get all item IDs from request
REQUEST_IDS="$(python3 -c "
import json
with open('$REQUEST_FILE') as f:
    data = json.load(f)
print(' '.join(str(i['id']) for i in data['items']))
")"

# Get all item IDs from response
RESPONSE_IDS="$(python3 -c "
import json
with open('$RESPONSE_FILE') as f:
    data = json.load(f)
print(' '.join(str(i['id']) for i in data['items']))
" 2>/dev/null || echo "")"

# Find missing IDs
MISSING="$(python3 -c "
req = set(int(x) for x in '$REQUEST_IDS'.split())
resp = set(int(x) for x in '$RESPONSE_IDS'.split()) if '$RESPONSE_IDS' else set()
missing = sorted(req - resp)
print(' '.join(str(i) for i in missing))
")"

if [[ -z "$MISSING" ]]; then
  # All items accounted for — clean up state file
  rm -f "$STATE_FILE"
  exit 0
fi

# Load or initialize retry state
ATTEMPT=0
HISTORY="[]"
if [[ -f "$STATE_FILE" ]]; then
  ATTEMPT="$(python3 -c "import json; d=json.load(open('$STATE_FILE')); print(d.get('attempt',0))")"
  HISTORY="$(python3 -c "import json; d=json.load(open('$STATE_FILE')); print(json.dumps(d.get('history',[])))")"
fi

ATTEMPT=$((ATTEMPT + 1))
TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S')"

# Record this attempt
python3 -c "
import json
history = $HISTORY
history.append({
    'attempt': $ATTEMPT,
    'timestamp': '$TIMESTAMP',
    'missing_ids': [int(x) for x in '$MISSING'.split()],
    'response_ids_received': [int(x) for x in '$RESPONSE_IDS'.split()] if '$RESPONSE_IDS' else []
})
state = {
    'request_id': '$REQUEST_ID',
    'agent': '$AGENT',
    'attempt': $ATTEMPT,
    'history': history
}
with open('$STATE_FILE', 'w') as f:
    json.dump(state, f, indent=2)
"

echo "MISSING_IDS=$MISSING"
echo "ATTEMPT=$ATTEMPT"

if [[ $ATTEMPT -ge $MAX_RETRIES ]]; then
  echo "ESCALATE=true"
  exit 3
fi

echo "ESCALATE=false"
exit 2
