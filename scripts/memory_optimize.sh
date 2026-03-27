#!/usr/bin/env bash
# memory_optimize.sh — Nightly memory optimization for all Parlei agents.
# Runs deduplication, episodic-to-long-term promotion, age pruning,
# and tool-native LLM summarization for each agent.
# Summarization is invoked via the active environment's own CLI (claude, codex,
# openclaw). Augment has no CLI and skips summarization. The active environment
# is read from .parlei-env at the repo root.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MEMORY_DIR="$REPO_ROOT/shared/memory"
CONFIG_FILE="$REPO_ROOT/shared/tools/memory_config.json"
OPTIMIZE_LOG="$MEMORY_DIR/optimize_log.md"
ERROR_LOG="$MEMORY_DIR/error_log.md"

AGENTS=(speaker planer tasker prompter checker reviewer architecter deployer tester reoriginator)

NOW="$(date '+%Y-%m-%d %H:%M')"
ERRORS=0

log_error() {
  local agent="$1" step="$2" message="$3"
  echo "- $NOW | agent: $agent | step: $step | error: $message" >> "$ERROR_LOG"
  echo "ERROR [$agent/$step]: $message" >&2
  ERRORS=$((ERRORS + 1))
}

# ── Read config values ────────────────────────────────────────────────────────

if [[ ! -f "$CONFIG_FILE" ]]; then
  log_error "global" "config" "memory_config.json not found at $CONFIG_FILE"
  exit 1
fi

RETENTION_DAYS="$(python3 -c "import json,sys; d=json.load(open('$CONFIG_FILE')); print(d.get('episodic_retention_days', 90))")"
PROMOTION_THRESHOLD="$(python3 -c "import json,sys; d=json.load(open('$CONFIG_FILE')); print(d.get('promotion_threshold', 3))")"
LLM_MODEL="$(python3 -c "import json,sys; d=json.load(open('$CONFIG_FILE')); print(d.get('llm_model', ''))")"

# Read active environment from .parlei-env
ENV=""
ENV_FILE="$REPO_ROOT/.parlei-env"
if [[ -f "$ENV_FILE" ]]; then
  ENV="$(tr -d '[:space:]' < "$ENV_FILE")"
fi

# ── Tool-native LLM invocation ────────────────────────────────────────────────
# Each environment uses its own CLI to run the summarization prompt.
# Augment has no standalone CLI and is explicitly excluded.
# MODEL_FLAG is empty when llm_model is unset; each CLI accepts --model or
# falls back to its own configured default.

MODEL_FLAG=()
[[ -n "$LLM_MODEL" ]] && MODEL_FLAG=(--model "$LLM_MODEL")

invoke_tool_llm() {
  local prompt="$1"
  case "$ENV" in
    claude)
      # Claude Code CLI: --print runs non-interactively and writes to stdout.
      printf '%s' "$prompt" | claude --print "${MODEL_FLAG[@]}"
      ;;
    codex)
      # Codex CLI (github.com/openai/codex): --quiet suppresses interactive UI.
      printf '%s' "$prompt" | codex --quiet "${MODEL_FLAG[@]}"
      ;;
    openclaw)
      # OpenClaw CLI: mirrors Claude Code's --print interface.
      printf '%s' "$prompt" | openclaw --print "${MODEL_FLAG[@]}"
      ;;
    augment)
      # Augment is an editor extension with no standalone CLI.
      # Summarization is not available in the cron context for this environment.
      return 1
      ;;
    *)
      return 1
      ;;
  esac
}

TOTAL_DEDUPED=0
TOTAL_PROMOTED=0
TOTAL_PRUNED=0

# ── Per-agent processing ──────────────────────────────────────────────────────

for AGENT in "${AGENTS[@]}"; do
  AGENT_DIR="$MEMORY_DIR/$AGENT"
  EPISODIC_DIR="$AGENT_DIR/episodic"
  LONG_TERM="$AGENT_DIR/long_term.md"

  [[ ! -d "$EPISODIC_DIR" ]] && continue

  mapfile -t EPISODIC_FILES < <(find "$EPISODIC_DIR" -maxdepth 1 -name "*.md" ! -name "current_task*.md" | sort)

  # ── Step 1: Deduplication across episodic logs ────────────────────────────

  DEDUPED=0
  if [[ ${#EPISODIC_FILES[@]} -gt 1 ]]; then
    SEEN_LINES_FILE="$(mktemp)"
    trap 'rm -f "$SEEN_LINES_FILE"' EXIT

    for EFILE in "${EPISODIC_FILES[@]}"; do
      TEMP="$(mktemp)"
      while IFS= read -r line; do
        if grep -qxF "$line" "$SEEN_LINES_FILE" 2>/dev/null && [[ -n "$line" ]]; then
          DEDUPED=$((DEDUPED + 1))
        else
          echo "$line" >> "$SEEN_LINES_FILE"
          echo "$line" >> "$TEMP"
        fi
      done < "$EFILE"
      mv "$TEMP" "$EFILE"
    done

    rm -f "$SEEN_LINES_FILE"
    trap - EXIT
  fi
  TOTAL_DEDUPED=$((TOTAL_DEDUPED + DEDUPED))

  # ── Step 2: Promote entries appearing in N+ episodic files ───────────────

  PROMOTED=0
  if [[ ${#EPISODIC_FILES[@]} -ge "$PROMOTION_THRESHOLD" && -f "$LONG_TERM" ]]; then
    # Extract non-empty lines from all episodic files, count occurrences
    FREQ_FILE="$(mktemp)"
    for EFILE in "${EPISODIC_FILES[@]}"; do
      grep -v '^#' "$EFILE" | grep -v '^[[:space:]]*$' || true
    done | sort | uniq -c | sort -rn > "$FREQ_FILE"

    while IFS= read -r freq_line; do
      COUNT="$(echo "$freq_line" | awk '{print $1}')"
      ENTRY="$(echo "$freq_line" | sed 's/^[[:space:]]*[0-9]\+[[:space:]]*//')"
      if [[ "$COUNT" -ge "$PROMOTION_THRESHOLD" ]]; then
        if ! grep -qxF "$ENTRY" "$LONG_TERM" 2>/dev/null; then
          echo "" >> "$LONG_TERM"
          echo "$ENTRY" >> "$LONG_TERM"
          PROMOTED=$((PROMOTED + 1))
        fi
      fi
    done < "$FREQ_FILE"

    rm -f "$FREQ_FILE"
  fi
  TOTAL_PROMOTED=$((TOTAL_PROMOTED + PROMOTED))

  # ── Step 3: Prune episodic files older than retention threshold ──────────

  PRUNED=0
  CUTOFF_DATE="$(date -d "-${RETENTION_DAYS} days" '+%Y-%m-%d' 2>/dev/null || date -v "-${RETENTION_DAYS}d" '+%Y-%m-%d')"

  for EFILE in "${EPISODIC_FILES[@]}"; do
    BASENAME="$(basename "$EFILE")"
    FILE_DATE="${BASENAME:0:10}"  # Expects filename starting with YYYY-MM-DD
    if [[ "$FILE_DATE" < "$CUTOFF_DATE" ]]; then
      rm -f "$EFILE"
      PRUNED=$((PRUNED + 1))
    fi
  done
  TOTAL_PRUNED=$((TOTAL_PRUNED + PRUNED))

  # ── Step 4: LLM summarization of long_term.md ────────────────────────────
  # Invoked via the active environment's own CLI (claude, codex, openclaw).
  # Skipped silently when ENV is "augment", unknown, or unset.

  case "$ENV" in
    claude|codex|openclaw)
      if [[ -f "$LONG_TERM" ]]; then
        CURRENT_CONTENT="$(cat "$LONG_TERM")"
        PROMPT="You are a memory optimizer for an AI agent named ${AGENT}. The following is this agent's long-term memory file. Rewrite it to be more concise and deduplicated, preserving all important facts and rules. Keep all JSON code blocks intact. Output only the rewritten file contents, no commentary. Memory file:

${CURRENT_CONTENT}"

        RESPONSE="$(invoke_tool_llm "$PROMPT" 2>&1)" || {
          log_error "$AGENT" "llm_summarize" "tool invocation failed: $RESPONSE"
          continue
        }

        if [[ -n "$RESPONSE" ]]; then
          echo "$RESPONSE" > "$LONG_TERM"
        else
          log_error "$AGENT" "llm_summarize" "tool returned empty response"
        fi
      fi
      ;;
  esac

done

# ── Write optimize log entry ──────────────────────────────────────────────────

echo "- $NOW | agents: ${#AGENTS[@]} | deduped: $TOTAL_DEDUPED | promoted: $TOTAL_PROMOTED | pruned: $TOTAL_PRUNED | errors: $ERRORS" >> "$OPTIMIZE_LOG"

if [[ $ERRORS -gt 0 ]]; then
  echo "Memory optimization completed with $ERRORS error(s). See $ERROR_LOG"
  exit 1
fi

echo "Memory optimization complete. Deduped: $TOTAL_DEDUPED, promoted: $TOTAL_PROMOTED, pruned: $TOTAL_PRUNED."
