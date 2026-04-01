#!/usr/bin/env bash
# install_global.sh — Install Parlei CLI globally
# This script symlinks the parlei command to a location in your PATH

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PARLEI_BIN="$REPO_ROOT/bin/parlei"

# ── Determine installation location ───────────────────────────────────────────

# Try to find a suitable location in PATH
INSTALL_DIR=""

if [[ -d "$HOME/.local/bin" ]] && [[ ":$PATH:" == *":$HOME/.local/bin:"* ]]; then
  INSTALL_DIR="$HOME/.local/bin"
elif [[ -d "$HOME/bin" ]] && [[ ":$PATH:" == *":$HOME/bin:"* ]]; then
  INSTALL_DIR="$HOME/bin"
elif [[ -d "/usr/local/bin" ]] && [[ -w "/usr/local/bin" ]]; then
  INSTALL_DIR="/usr/local/bin"
fi

# Allow user override
if [[ $# -eq 1 ]]; then
  INSTALL_DIR="$1"
fi

if [[ -z "$INSTALL_DIR" ]]; then
  echo "Error: Could not find a suitable installation directory in PATH." >&2
  echo "" >&2
  echo "Options:" >&2
  echo "  1. Create ~/.local/bin and add it to PATH:" >&2
  echo "     mkdir -p ~/.local/bin" >&2
  echo "     echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.bashrc" >&2
  echo "" >&2
  echo "  2. Specify installation directory manually:" >&2
  echo "     bash $0 /path/to/bin" >&2
  exit 1
fi

# ── Verify installation directory exists and is in PATH ───────────────────────

if [[ ! -d "$INSTALL_DIR" ]]; then
  echo "Creating installation directory: $INSTALL_DIR"
  mkdir -p "$INSTALL_DIR"
fi

if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
  echo "Warning: $INSTALL_DIR is not in your PATH" >&2
  echo "Add it to your PATH by adding this to ~/.bashrc or ~/.zshrc:" >&2
  echo "  export PATH=\"$INSTALL_DIR:\$PATH\"" >&2
  echo "" >&2
fi

# ── Create symlink ────────────────────────────────────────────────────────────

SYMLINK_PATH="$INSTALL_DIR/parlei"

if [[ -L "$SYMLINK_PATH" ]]; then
  EXISTING_TARGET="$(readlink "$SYMLINK_PATH")"
  if [[ "$EXISTING_TARGET" == "$PARLEI_BIN" ]]; then
    echo "✓ parlei is already installed at $SYMLINK_PATH"
    exit 0
  else
    echo "Warning: $SYMLINK_PATH already exists and points to $EXISTING_TARGET" >&2
    read -p "Overwrite? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      echo "Installation cancelled."
      exit 1
    fi
    rm "$SYMLINK_PATH"
  fi
elif [[ -e "$SYMLINK_PATH" ]]; then
  echo "Error: $SYMLINK_PATH already exists and is not a symlink" >&2
  exit 1
fi

ln -s "$PARLEI_BIN" "$SYMLINK_PATH"

echo "✓ Installed parlei command to $SYMLINK_PATH"
echo ""
echo "Usage:"
echo "  parlei setup codex        # Set up for Codex environment"
echo "  parlei test              # Run all tests"
echo "  parlei status            # Show current status"
echo "  parlei help              # Show all commands"
echo ""

# ── Verify installation ───────────────────────────────────────────────────────

if command -v parlei &>/dev/null; then
  echo "✓ parlei is now available globally"
  echo "  Location: $(command -v parlei)"
else
  echo "⚠ parlei was installed but is not yet in your PATH" >&2
  echo "  Add $INSTALL_DIR to your PATH or restart your shell" >&2
fi

