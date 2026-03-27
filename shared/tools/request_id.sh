#!/usr/bin/env bash
# request_id.sh — Generate a unique Parlei request ID.
# Usage: request_id.sh <agent-name>
# Output: req-<agent-name>-<YYYYMMDD>-<NNN>
# The sequence counter is stored per-agent per-day in a state file.

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: request_id.sh <agent-name>" >&2
  exit 1
fi

AGENT="$1"
DATE="$(date '+%Y%m%d')"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE_DIR="$SCRIPT_DIR/../../shared/memory/${AGENT}"
STATE_FILE="$STATE_DIR/.request_id_state"

if [[ ! -d "$STATE_DIR" ]]; then
  echo "Error: agent memory directory not found: $STATE_DIR" >&2
  exit 1
fi

# Read existing state
LAST_DATE=""
LAST_SEQ=0
if [[ -f "$STATE_FILE" ]]; then
  LAST_DATE="$(python3 -c "import json; d=json.load(open('$STATE_FILE')); print(d.get('date',''))")"
  LAST_SEQ="$(python3 -c "import json; d=json.load(open('$STATE_FILE')); print(d.get('seq',0))")"
fi

# Reset sequence on new day
if [[ "$LAST_DATE" != "$DATE" ]]; then
  LAST_SEQ=0
fi

SEQ=$((LAST_SEQ + 1))
SEQ_PADDED="$(printf '%03d' "$SEQ")"

# Write updated state
python3 -c "
import json
with open('$STATE_FILE', 'w') as f:
    json.dump({'date': '$DATE', 'seq': $SEQ}, f)
"

echo "req-${AGENT}-${DATE}-${SEQ_PADDED}"
