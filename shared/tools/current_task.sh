#!/usr/bin/env bash
# current_task.sh — Create, update, check, and archive current_task.md files.
# Used by all agents for task tracking and interruption recovery.
#
# Commands:
#   current_task.sh write   <agent> <request_id> <from> <subtask1> [subtask2 ...] [--request-json <json>]
#   current_task.sh check   <agent>                    → 0=nothing, 1=in-progress (prints resume info)
#   current_task.sh checkoff <agent> <subtask_index>   → marks subtask N as [x]
#   current_task.sh complete <agent>                   → archives to episodic/
#   current_task.sh read    <agent>                    → prints current_task.md contents

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MEMORY_ROOT="$SCRIPT_DIR/../../shared/memory"

if [[ $# -lt 2 ]]; then
  echo "Usage: current_task.sh <command> <agent> [args...]" >&2
  exit 1
fi

COMMAND="$1"
AGENT="$2"
AGENT_DIR="$MEMORY_ROOT/$AGENT"
TASK_FILE="$AGENT_DIR/current_task.md"

if [[ ! -d "$AGENT_DIR" ]]; then
  echo "Error: agent memory directory not found: $AGENT_DIR" >&2
  exit 1
fi

case "$COMMAND" in

# ── write: Create a new current_task.md ───────────────────────────────────────
write)
  if [[ $# -lt 5 ]]; then
    echo "Usage: current_task.sh write <agent> <request_id> <from> <subtask1> [subtask2 ...] [--request-json <json>]" >&2
    exit 1
  fi

  REQUEST_ID="$3"
  FROM_AGENT="$4"
  shift 4

  SUBTASKS=()
  REQUEST_JSON="{}"
  while [[ $# -gt 0 ]]; do
    if [[ "$1" == "--request-json" ]]; then
      shift
      REQUEST_JSON="${1:-{\}}"
    else
      SUBTASKS+=("$1")
    fi
    shift
  done

  if [[ ${#SUBTASKS[@]} -eq 0 ]]; then
    echo "Error: at least one subtask is required" >&2
    exit 1
  fi

  STARTED="$(date '+%Y-%m-%d %H:%M')"
  SUBTASK_LIST=""
  for task in "${SUBTASKS[@]}"; do
    SUBTASK_LIST+="- [ ] $task"$'\n'
  done

  cat > "$TASK_FILE" << EOF
# Current Task

**Request ID:** $REQUEST_ID
**Status:** in-progress
**Started:** $STARTED
**Received from:** $FROM_AGENT
**Interrupt reason:**

## Subtasks
${SUBTASK_LIST}
## Context
(context to be filled in by the agent as work progresses)

## Original Request
\`\`\`json
$REQUEST_JSON
\`\`\`
EOF

  echo "Written: $TASK_FILE"
  ;;

# ── check: Detect in-progress task on startup ─────────────────────────────────
check)
  if [[ ! -f "$TASK_FILE" ]]; then
    exit 0  # Nothing to resume
  fi

  STATUS="$(grep '^\*\*Status:\*\*' "$TASK_FILE" | head -1 | sed 's/\*\*Status:\*\* //')"
  if [[ "$STATUS" != "in-progress" ]]; then
    exit 0  # Completed file left in place — not actionable
  fi

  REQUEST_ID="$(grep '^\*\*Request ID:\*\*' "$TASK_FILE" | head -1 | sed 's/\*\*Request ID:\*\* //')"
  STARTED="$(grep '^\*\*Started:\*\*' "$TASK_FILE" | head -1 | sed 's/\*\*Started:\*\* //')"

  # Find first unchecked subtask (1-based index)
  RESUME_INDEX=0
  LINE_NUM=0
  while IFS= read -r line; do
    LINE_NUM=$((LINE_NUM + 1))
    if [[ "$line" =~ ^-\ \[\ \] ]]; then
      RESUME_INDEX=$LINE_NUM
      break
    fi
  done < "$TASK_FILE"

  echo "RESUME=true"
  echo "REQUEST_ID=$REQUEST_ID"
  echo "STARTED=$STARTED"
  echo "RESUME_SUBTASK_LINE=$RESUME_INDEX"
  exit 1  # Exit 1 signals: in-progress task found
  ;;

# ── checkoff: Mark a subtask complete ─────────────────────────────────────────
checkoff)
  if [[ $# -lt 3 ]]; then
    echo "Usage: current_task.sh checkoff <agent> <subtask_index>" >&2
    exit 1
  fi

  INDEX="$3"
  if ! [[ "$INDEX" =~ ^[0-9]+$ ]] || [[ "$INDEX" -lt 1 ]]; then
    echo "Error: subtask index must be a positive integer" >&2
    exit 1
  fi

  if [[ ! -f "$TASK_FILE" ]]; then
    echo "Error: no current_task.md found for agent $AGENT" >&2
    exit 1
  fi

  # Count unchecked subtasks to validate index
  TOTAL_SUBTASKS="$(grep -c '^- \[' "$TASK_FILE" || true)"
  if [[ "$INDEX" -gt "$TOTAL_SUBTASKS" ]]; then
    echo "Error: subtask index $INDEX is out of range (total subtasks: $TOTAL_SUBTASKS)" >&2
    exit 1
  fi

  # Replace the Nth subtask checkbox
  python3 -c "
import sys
index = int(sys.argv[1])
with open('$TASK_FILE') as f:
    lines = f.readlines()

subtask_count = 0
for i, line in enumerate(lines):
    if line.startswith('- ['):
        subtask_count += 1
        if subtask_count == index:
            if line.startswith('- [ ]'):
                lines[i] = line.replace('- [ ]', '- [x]', 1)
            break  # Already checked — idempotent

with open('$TASK_FILE', 'w') as f:
    f.writelines(lines)
print('Checked off subtask $INDEX')
" "$INDEX"
  ;;

# ── complete: Archive the task file ──────────────────────────────────────────
complete)
  if [[ ! -f "$TASK_FILE" ]]; then
    echo "Error: no current_task.md found for agent $AGENT" >&2
    exit 1
  fi

  # Verify all subtasks are checked
  UNCHECKED="$(grep -c '^- \[ \]' "$TASK_FILE" || true)"
  if [[ "$UNCHECKED" -gt 0 ]]; then
    echo "Error: $UNCHECKED subtask(s) are not yet checked off. Cannot archive." >&2
    exit 1
  fi

  REQUEST_ID="$(grep '^\*\*Request ID:\*\*' "$TASK_FILE" | head -1 | sed 's/\*\*Request ID:\*\* //')"
  TODAY="$(date '+%Y-%m-%d')"
  ARCHIVE_NAME="${TODAY}-${REQUEST_ID}.md"
  EPISODIC_DIR="$AGENT_DIR/episodic"

  mkdir -p "$EPISODIC_DIR"

  # Set status to completed
  python3 -c "
with open('$TASK_FILE') as f:
    content = f.read()
content = content.replace('**Status:** in-progress', '**Status:** completed', 1)
with open('$TASK_FILE', 'w') as f:
    f.write(content)
"

  if mv "$TASK_FILE" "$EPISODIC_DIR/$ARCHIVE_NAME"; then
    echo "Archived: $EPISODIC_DIR/$ARCHIVE_NAME"
  else
    echo "Error: failed to move $TASK_FILE to $EPISODIC_DIR/$ARCHIVE_NAME" >&2
    exit 1
  fi
  ;;

# ── read: Print current_task.md contents ─────────────────────────────────────
read)
  if [[ ! -f "$TASK_FILE" ]]; then
    echo "(no current_task.md for agent $AGENT)"
    exit 0
  fi
  cat "$TASK_FILE"
  ;;

*)
  echo "Error: unknown command '$COMMAND'. Use: write | check | checkoff | complete | read" >&2
  exit 1
  ;;
esac
