#!/usr/bin/env bash
# backup.sh — Nightly backup of shared/ to a dated tar.gz archive.
# Skips in-progress current_task.md files.
# Prunes archives beyond the configured retention count.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SHARED_DIR="$REPO_ROOT/shared"
BACKUPS_DIR="$REPO_ROOT/backups"
CONFIG_FILE="$SHARED_DIR/tools/memory_config.json"
BACKUP_LOG="$BACKUPS_DIR/backup_log.md"
ERROR_LOG="$BACKUPS_DIR/error_log.md"

NOW="$(date '+%Y-%m-%d %H:%M')"
TODAY="$(date '+%Y-%m-%d')"
ARCHIVE="$BACKUPS_DIR/${TODAY}.tar.gz"

log_error() {
  local step="$1" message="$2"
  echo "- $NOW | step: $step | error: $message" >> "$ERROR_LOG"
  echo "ERROR [$step]: $message" >&2
}

# ── Read retention count from config ─────────────────────────────────────────

RETENTION_COUNT=30
if [[ -f "$CONFIG_FILE" ]]; then
  RETENTION_COUNT="$(python3 -c "import json; d=json.load(open('$CONFIG_FILE')); print(d.get('backup_retention_count', 30))")"
fi

# ── Check for memory optimization errors ──────────────────────────────────────

MEMORY_ERROR_LOG="$SHARED_DIR/memory/error_log.md"
if [[ -f "$MEMORY_ERROR_LOG" ]]; then
  # Check if the error log was modified today
  if find "$MEMORY_ERROR_LOG" -newer "$BACKUPS_DIR" -daystart 2>/dev/null | grep -q .; then
    WARN_MSG="Memory optimization had errors today — backup may reflect incomplete optimization"
    echo "WARNING: $WARN_MSG"
    echo "- $NOW | WARNING: $WARN_MSG" >> "$BACKUP_LOG"
  fi
fi

# ── Collect in-progress current_task.md paths to exclude ─────────────────────

EXCLUDES=()
while IFS= read -r -d '' TASK_FILE; do
  if grep -q '^**Status:** in-progress' "$TASK_FILE" 2>/dev/null || \
     grep -q '^\*\*Status:\*\* in-progress' "$TASK_FILE" 2>/dev/null; then
    # Make path relative to REPO_ROOT for tar --exclude
    REL_PATH="${TASK_FILE#$REPO_ROOT/}"
    EXCLUDES+=("--exclude=$REL_PATH")
  fi
done < <(find "$SHARED_DIR/memory" -name "current_task.md" -print0 2>/dev/null)

# ── Create archive ────────────────────────────────────────────────────────────

COMPRESS_CMD="gzip"
if command -v zstd &>/dev/null; then
  # Use zstd if available for better compression, but fall back to gzip
  COMPRESS_CMD="gzip"
fi

TEMP_ARCHIVE="${ARCHIVE}.tmp"

if ! tar \
  --exclude="$BACKUPS_DIR" \
  "${EXCLUDES[@]}" \
  -czf "$TEMP_ARCHIVE" \
  -C "$REPO_ROOT" \
  shared/ 2>&1; then
  log_error "tar" "Archive creation failed"
  rm -f "$TEMP_ARCHIVE"
  exit 1
fi

# Verify the archive is non-empty
if [[ ! -s "$TEMP_ARCHIVE" ]]; then
  log_error "verify" "Archive is zero bytes"
  rm -f "$TEMP_ARCHIVE"
  exit 1
fi

mv "$TEMP_ARCHIVE" "$ARCHIVE"

ARCHIVE_SIZE="$(du -sh "$ARCHIVE" | cut -f1)"

# ── Retention pruning ─────────────────────────────────────────────────────────

mapfile -t EXISTING_ARCHIVES < <(find "$BACKUPS_DIR" -maxdepth 1 -name "*.tar.gz" | sort)
ARCHIVE_COUNT="${#EXISTING_ARCHIVES[@]}"

if [[ $ARCHIVE_COUNT -gt $RETENTION_COUNT ]]; then
  EXCESS=$((ARCHIVE_COUNT - RETENTION_COUNT))
  for i in $(seq 0 $((EXCESS - 1))); do
    rm -f "${EXISTING_ARCHIVES[$i]}"
    echo "Pruned old backup: $(basename "${EXISTING_ARCHIVES[$i]}")"
  done
fi

# ── Log success ───────────────────────────────────────────────────────────────

echo "- $NOW | backup successful | archive: $(basename "$ARCHIVE") | size: $ARCHIVE_SIZE" >> "$BACKUP_LOG"
echo "Backup complete: $(basename "$ARCHIVE") ($ARCHIVE_SIZE)"
