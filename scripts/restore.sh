#!/usr/bin/env bash
# restore.sh — Restore shared/ from a dated backup archive.
# Usage: restore.sh <YYYY-MM-DD>
# Does NOT modify the backups/ directory during restore.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BACKUPS_DIR="$REPO_ROOT/backups"
SHARED_DIR="$REPO_ROOT/shared"

if [[ $# -ne 1 ]]; then
  echo "Usage: restore.sh <YYYY-MM-DD>" >&2
  exit 1
fi

TARGET_DATE="$1"
ARCHIVE="$BACKUPS_DIR/${TARGET_DATE}.tar.gz"

# ── Validate archive exists ───────────────────────────────────────────────────

if [[ ! -f "$ARCHIVE" ]]; then
  echo "Error: no backup found for date '${TARGET_DATE}'. Expected: $ARCHIVE" >&2
  echo "Available backups:"
  find "$BACKUPS_DIR" -maxdepth 1 -name "*.tar.gz" | sort | xargs -I{} basename {} .tar.gz 2>/dev/null || echo "  (none)"
  exit 1
fi

# ── Confirmation prompt ───────────────────────────────────────────────────────

echo ""
echo "⚠️  WARNING: This will overwrite shared/ with the backup from ${TARGET_DATE}."
echo "   Archive: $ARCHIVE"
echo "   Destination: $SHARED_DIR"
echo ""
echo -n "Type YES to confirm: "
read -r CONFIRM

if [[ "$CONFIRM" != "YES" ]]; then
  echo "Restore cancelled."
  exit 1
fi

# ── Take a checksum of backups/ before restore ────────────────────────────────

BACKUPS_CHECKSUM_BEFORE="$(find "$BACKUPS_DIR" -maxdepth 1 -name "*.tar.gz" | sort | xargs md5sum 2>/dev/null | md5sum | cut -d' ' -f1)"

# ── Restore ───────────────────────────────────────────────────────────────────

echo "Restoring from ${TARGET_DATE}..."

# Extract into REPO_ROOT. The archive contains shared/ as a top-level path.
# --strip-components is NOT used here because we want shared/ to land at its
# correct location. backups/ is never inside the archive (excluded at backup time).
# Remove shared/ before extraction so BSD tar (macOS) doesn't need --overwrite.
# backups/ is excluded from archives, so it is never touched.
rm -rf "$SHARED_DIR"

if ! tar \
  -xzf "$ARCHIVE" \
  -C "$REPO_ROOT" \
  2>&1; then
  echo "Error: extraction failed." >&2
  exit 1
fi

# ── Verify backups/ was not touched ──────────────────────────────────────────

BACKUPS_CHECKSUM_AFTER="$(find "$BACKUPS_DIR" -maxdepth 1 -name "*.tar.gz" | sort | xargs md5sum 2>/dev/null | md5sum | cut -d' ' -f1)"

if [[ "$BACKUPS_CHECKSUM_BEFORE" != "$BACKUPS_CHECKSUM_AFTER" ]]; then
  echo "ERROR: backups/ directory was modified during restore. This should not happen." >&2
  echo "Before checksum: $BACKUPS_CHECKSUM_BEFORE"
  echo "After checksum:  $BACKUPS_CHECKSUM_AFTER"
  exit 1
fi

echo ""
echo "✓ Restore complete. shared/ now reflects the state from ${TARGET_DATE}."
echo "  Note: Memory optimization should be manually run before the nightly cron resumes."
