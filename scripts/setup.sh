#!/usr/bin/env bash
# setup.sh — Bootstrap Parlei for a given AI coding environment.
# Usage: setup.sh <environment>
# Environments: claude | augment | codex | openclaw

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SHARED_DIR="$REPO_ROOT/shared"
BACKUPS_DIR="$REPO_ROOT/backups"

VALID_ENVS=("claude" "augment" "codex" "openclaw")

# ── Argument parsing & validation ────────────────────────────────────────────

usage() {
  echo "Usage: $0 <environment>"
  echo "  Environments: claude | augment | codex | openclaw"
  exit 1
}

if [[ $# -ne 1 ]]; then
  echo "Error: exactly one argument required."
  usage
fi

ENV="$1"
VALID=false
for v in "${VALID_ENVS[@]}"; do
  [[ "$ENV" == "$v" ]] && VALID=true && break
done

if [[ "$VALID" == false ]]; then
  echo "Error: unrecognized environment '${ENV}'."
  usage
fi

# ── Determine config file for environment ────────────────────────────────────

case "$ENV" in
  claude)   CONFIG_FILE="$REPO_ROOT/CLAUDE.md" ;;
  augment)  CONFIG_FILE="$REPO_ROOT/bootstraps/AUGGIE.md" ;;
  codex)    CONFIG_FILE="$REPO_ROOT/bootstraps/CODEX.md" ;;
  openclaw) CONFIG_FILE="$REPO_ROOT/bootstraps/OPENCLAW.md" ;;
esac

# ── Create backups/ if absent ─────────────────────────────────────────────────

if [[ ! -d "$BACKUPS_DIR" ]]; then
  mkdir -p "$BACKUPS_DIR"
  echo "Created: $BACKUPS_DIR"
fi

# ── Symlink creation ──────────────────────────────────────────────────────────
# Each environment config file references shared/ paths. We create a symlink
# at the repo root named "shared" pointing to ./shared (already exists as a
# real dir). Beyond that, each env config may need env-specific symlinks.
# The primary symlink convention: <ENV_DIR>/shared -> ../shared
# Since all env configs live at repo root, shared/ is already accessible.
# We create a canonical .parlei-env file so tools know which env is active.

ENV_MARKER="$REPO_ROOT/.parlei-env"

# Write env marker (idempotent)
echo "$ENV" > "$ENV_MARKER"
echo "Environment set to: $ENV"

# Verify shared/ subdirs all exist (they must — T-001 must run first)
REQUIRED_DIRS=(
  "$SHARED_DIR/agents"
  "$SHARED_DIR/memory"
  "$SHARED_DIR/personalities"
  "$SHARED_DIR/prompts"
  "$SHARED_DIR/tools"
)

SYMLINK_ERRORS=0
for dir in "${REQUIRED_DIRS[@]}"; do
  if [[ ! -d "$dir" ]]; then
    echo "Error: required directory missing: $dir"
    SYMLINK_ERRORS=$((SYMLINK_ERRORS + 1))
  fi
done

if [[ $SYMLINK_ERRORS -gt 0 ]]; then
  echo "Error: $SYMLINK_ERRORS required director(ies) missing. Run setup.sh after ensuring shared/ structure exists."
  exit 1
fi

echo "Verified: all shared/ subdirectories present."

# ── Cron job registration (idempotent) ────────────────────────────────────────

MEMORY_CRON="0 2 * * * bash $SCRIPT_DIR/memory_optimize.sh >> $REPO_ROOT/shared/memory/cron.log 2>&1 # parlei-memory"
BACKUP_CRON="30 2 * * * bash $SCRIPT_DIR/backup.sh >> $BACKUPS_DIR/cron.log 2>&1 # parlei-backup"

register_cron() {
  local entry="$1"
  local marker="$2"
  # Check if entry already registered (by marker comment)
  if crontab -l 2>/dev/null | grep -qF "$marker"; then
    echo "Cron already registered: $marker (skipping)"
  else
    # Append to existing crontab
    (crontab -l 2>/dev/null; echo "$entry") | crontab -
    echo "Cron registered: $marker"
  fi
}

register_cron "$MEMORY_CRON" "parlei-memory"
register_cron "$BACKUP_CRON"  "parlei-backup"

# ── Final validation ──────────────────────────────────────────────────────────

VALIDATION_ERRORS=0

# Confirm config file for this environment exists
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "Error: config file not found: $CONFIG_FILE"
  VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
fi

# Confirm all required shared dirs exist and are readable
for dir in "${REQUIRED_DIRS[@]}"; do
  if [[ ! -d "$dir" ]]; then
    echo "Error: post-setup validation failed — missing: $dir"
    VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
  fi
done

if [[ $VALIDATION_ERRORS -gt 0 ]]; then
  echo "Setup completed with $VALIDATION_ERRORS validation error(s). Review output above."
  exit 1
fi

echo ""
echo "✓ Parlei setup complete for environment: $ENV"
echo "  Config file : $CONFIG_FILE"
echo "  Shared dir  : $SHARED_DIR"
echo "  Backups dir : $BACKUPS_DIR"
echo ""
echo "Open your AI coding tool and load $(basename "$CONFIG_FILE")."
echo "The parliament is in session. 🦉"
