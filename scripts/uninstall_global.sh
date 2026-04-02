#!/usr/bin/env bash
# uninstall_global.sh — Remove Parlei CLI from global PATH

set -euo pipefail

LOCAL_SYMLINK="$HOME/.local/bin/parlei"

# ── Find parlei installation(s) ───────────────────────────────────────────────

FOUND_PATHS=()

# Check the well-known ~/.local/bin location first
if [[ -L "$LOCAL_SYMLINK" ]]; then
  FOUND_PATHS+=("$LOCAL_SYMLINK")
elif [[ -e "$LOCAL_SYMLINK" ]]; then
  echo "Warning: $LOCAL_SYMLINK exists but is not a symlink — skipping" >&2
fi

# Also check whatever is in PATH (may differ or be a second install)
if command -v parlei &>/dev/null; then
  PARLEI_PATH="$(command -v parlei)"
  # Add only if not already in the list
  already_found=false
  for p in "${FOUND_PATHS[@]+"${FOUND_PATHS[@]}"}"; do
    [[ "$p" == "$PARLEI_PATH" ]] && already_found=true && break
  done
  if [[ "$already_found" == false ]]; then
    if [[ -L "$PARLEI_PATH" ]]; then
      FOUND_PATHS+=("$PARLEI_PATH")
    else
      echo "Warning: $PARLEI_PATH is not a symlink (not installed by setup.sh or install_global.sh)" >&2
    fi
  fi
fi

if [[ ${#FOUND_PATHS[@]} -eq 0 ]]; then
  echo "No parlei symlinks found to remove."
  exit 0
fi

# ── Confirm and remove ────────────────────────────────────────────────────────

for path in "${FOUND_PATHS[@]}"; do
  target="$(readlink "$path")"
  echo "Found: $path -> $target"
done
echo ""

read -p "Remove the above symlink(s)? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Uninstall cancelled."
  exit 0
fi

for path in "${FOUND_PATHS[@]}"; do
  target="$(readlink "$path")"
  rm "$path"
  echo "✓ Removed $path"
done

echo ""
echo "The Parlei repository is still intact."
echo "You can reinstall anytime with: bash scripts/setup.sh"
