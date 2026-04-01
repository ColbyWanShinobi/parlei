#!/usr/bin/env bash
# uninstall_global.sh — Remove Parlei CLI from global PATH

set -euo pipefail

# ── Find parlei installation ──────────────────────────────────────────────────

if ! command -v parlei &>/dev/null; then
  echo "parlei command not found in PATH"
  exit 0
fi

PARLEI_PATH="$(command -v parlei)"

# ── Verify it's a symlink we installed ────────────────────────────────────────

if [[ ! -L "$PARLEI_PATH" ]]; then
  echo "Error: $PARLEI_PATH is not a symlink (not installed by install_global.sh)" >&2
  exit 1
fi

TARGET="$(readlink "$PARLEI_PATH")"
echo "Found parlei at: $PARLEI_PATH"
echo "Points to: $TARGET"
echo ""

read -p "Remove this symlink? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Uninstall cancelled."
  exit 0
fi

# ── Remove symlink ────────────────────────────────────────────────────────────

rm "$PARLEI_PATH"
echo "✓ Removed $PARLEI_PATH"
echo ""
echo "The Parlei repository at $(dirname "$(dirname "$TARGET")") is still intact."
echo "You can reinstall anytime with: bash scripts/install_global.sh"

