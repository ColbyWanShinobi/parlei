#!/usr/bin/env bash
# setup.sh — Bootstrap Parlei (environment-agnostic)
# Usage: setup.sh [environment]
# Environments: all | claude | codex | openclaw
#
# Note: Parlei auto-detects which environment to use at runtime.
# This script sets up the shared infrastructure and optionally
# writes a preference marker for a specific environment.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SHARED_DIR="$REPO_ROOT/shared"
BACKUPS_DIR="$REPO_ROOT/backups"

VALID_ENVS=("all" "claude" "codex" "openclaw")

# ── Argument parsing & validation ────────────────────────────────────────────

usage() {
  cat <<EOF
Usage: $0 [environment]

  Environments: all | claude | codex | openclaw

  'all'     - Set up for all environments (recommended for multi-env use)
  Specific  - Set up and mark preference for one environment

  If no argument provided, defaults to 'all'.

  Note: Parlei auto-detects the environment at runtime based on which
  CLI tools are available. You can use Claude and Codex simultaneously!

EOF
  exit 1
}

ENV="${1:-all}"

VALID=false
for v in "${VALID_ENVS[@]}"; do
  [[ "$ENV" == "$v" ]] && VALID=true && break
done

if [[ "$VALID" == false ]]; then
  echo "Error: unrecognized environment '${ENV}'."
  usage
fi

# ── Create backups/ if absent ─────────────────────────────────────────────────

if [[ ! -d "$BACKUPS_DIR" ]]; then
  mkdir -p "$BACKUPS_DIR"
  echo "Created: $BACKUPS_DIR"
fi

# ── Create agent inbox/outbox directories (idempotent) ───────────────────────
# Each agent needs an inbox and outbox for the dispatch IPC system.
# .gitkeep files ensure the directories are tracked in version control.
#
# IMPORTANT: This setup script NEVER overwrites existing memory files:
#   - identity.md      (agent identity - preserved)
#   - long_term.md     (agent long-term memory - preserved)
#   - episodic/*.md    (session memories - preserved)
#   - current_task.md  (active task - preserved)
#
# Only creates directories if they don't exist. Safe to re-run.

AGENTS=(speaker planer tasker prompter checker reviewer architecter deployer tester reoriginator coder techwriter prosewriter)

for AGENT in "${AGENTS[@]}"; do
  AGENT_MEM="$SHARED_DIR/memory/$AGENT"

  # Create inbox/outbox directories only if they don't exist
  for dir in inbox outbox; do
    if [[ ! -d "$AGENT_MEM/$dir" ]]; then
      mkdir -p "$AGENT_MEM/$dir"
      touch "$AGENT_MEM/$dir/.gitkeep"
      echo "Created: $AGENT_MEM/$dir"
    fi
  done

  # Verify memory files exist but NEVER overwrite them
  for memory_file in identity.md long_term.md; do
    if [[ ! -f "$AGENT_MEM/$memory_file" ]]; then
      echo "Warning: $AGENT_MEM/$memory_file is missing (not created by setup)"
    fi
  done
done

# ── Ensure dispatch scripts are executable ────────────────────────────────────

DISPATCH_SCRIPTS=(
  "$SHARED_DIR/tools/dispatch.sh"
  "$SHARED_DIR/tools/agent_runner.sh"
  "$SHARED_DIR/tools/build_system_prompt.sh"
  "$SHARED_DIR/tools/request_id.sh"
  "$SHARED_DIR/tools/retry.sh"
  "$SHARED_DIR/tools/current_task.sh"
  "$SHARED_DIR/tools/llm_call.sh"
)

for script in "${DISPATCH_SCRIPTS[@]}"; do
  if [[ -f "$script" && ! -x "$script" ]]; then
    chmod +x "$script"
    echo "Made executable: $script"
  fi
done

# ── Environment marker (optional) ─────────────────────────────────────────────
# Create .parlei-env file only if a specific environment was requested.
# If 'all' was specified, don't create it - let auto-detection work.

ENV_MARKER="$REPO_ROOT/.parlei-env"

if [[ "$ENV" == "all" ]]; then
  # Remove any existing marker to enable auto-detection
  if [[ -f "$ENV_MARKER" ]]; then
    rm "$ENV_MARKER"
    echo "Removed environment marker - auto-detection enabled"
  fi
  echo "✓ Set up for ALL environments (auto-detection enabled)"
else
  # Write env marker for specific environment (backward compatibility)
  echo "$ENV" > "$ENV_MARKER"
  echo "✓ Environment preference set to: $ENV"
  echo "  Note: Parlei will auto-detect available CLIs unless PARLEI_ENV is set"
fi

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

# ── OpenClaw workspace symlink setup ──────────────────────────────────────────
# If OpenClaw environment is selected (all or openclaw), set up symlink in workspace

setup_openclaw_workspace() {
  local openclaw_workspace="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"

  # Check if OpenClaw workspace exists
  if [[ ! -d "$openclaw_workspace" ]]; then
    echo ""
    echo "Note: OpenClaw workspace not found at: $openclaw_workspace"
    echo "  If you plan to use OpenClaw:"
    echo "    1. Install OpenClaw: npm install -g openclaw"
    echo "    2. Run: openclaw setup"
    echo "    3. Re-run this setup to create symlinks"
    echo ""
    return 0
  fi

  # Create symlink from OpenClaw workspace to Parlei shared directory
  local target_link="$openclaw_workspace/shared"

  if [[ -L "$target_link" ]]; then
    # Symlink exists, check if it points to correct location
    local current_target="$(readlink "$target_link")"
    if [[ "$current_target" == "$SHARED_DIR" ]]; then
      echo "✓ OpenClaw workspace symlink already configured correctly"
      return 0
    else
      echo "Warning: OpenClaw workspace symlink exists but points to: $current_target"
      echo "  Expected: $SHARED_DIR"
      echo "  Remove manually if needed: rm $target_link"
      return 0
    fi
  elif [[ -e "$target_link" ]]; then
    echo "Warning: $target_link exists but is not a symlink"
    echo "  Cannot create Parlei symlink. Remove manually if needed."
    return 0
  fi

  # Create the symlink
  ln -s "$SHARED_DIR" "$target_link"
  echo "✓ Created OpenClaw workspace symlink: $target_link -> $SHARED_DIR"

  # Create/update AGENTS.md if it doesn't exist or doesn't reference Parlei
  local agents_md="$openclaw_workspace/AGENTS.md"
  if [[ ! -f "$agents_md" ]]; then
    cat > "$agents_md" <<'EOF'
# Parlei Multi-Agent System

You are Speak-er, the orchestrator of 13 specialist agents.

## Loading Bootstrap

Read the following files on session start:

1. `shared/agents/speaker.md` - Your role and responsibilities
2. `shared/personalities/speaker.md` - Your communication style
3. `shared/memory/speaker/identity.md` - Your identity
4. `shared/memory/speaker/long_term.md` - Your persistent memory
5. `shared/tools/protocol.md` - Inter-agent protocol
6. `shared/tools/current_task_spec.md` - Task tracking format

## Delegation

Use `sessions_spawn` to delegate tasks to specialist agents.

Available agents: Plan-er, Task-er, Code-er, Review-er, Test-er, Architect-er, Deploy-er, Tech-Write-er, Prose-Write-er, Check-er, Prompt-er, Re-Origination-er

See `shared/agents/` for complete agent roster and `bootstraps/OPENCLAW.md` for detailed usage.
EOF
    echo "✓ Created OpenClaw AGENTS.md with Parlei bootstrap instructions"
  elif ! grep -q "shared/agents/speaker.md" "$agents_md" 2>/dev/null; then
    echo "Note: OpenClaw AGENTS.md exists but doesn't reference Parlei"
    echo "  You may need to manually update: $agents_md"
    echo "  Add: Load shared/agents/speaker.md and other Parlei files"
  else
    echo "✓ OpenClaw AGENTS.md already configured for Parlei"
  fi
}

if [[ "$ENV" == "all" ]] || [[ "$ENV" == "openclaw" ]]; then
  setup_openclaw_workspace
fi

# ── Final validation ──────────────────────────────────────────────────────────

VALIDATION_ERRORS=0

# Confirm bootstrap files exist
if [[ "$ENV" == "all" ]]; then
  # Check all bootstrap files exist
  for bootstrap in "$REPO_ROOT/CLAUDE.md" "$REPO_ROOT/bootstraps/CODEX.md" "$REPO_ROOT/bootstraps/OPENCLAW.md"; do
    if [[ ! -f "$bootstrap" ]]; then
      echo "Error: bootstrap file not found: $bootstrap"
      VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
    fi
  done
else
  # Check specific environment config file
  CONFIG_FILE=""
  case "$ENV" in
    claude)   CONFIG_FILE="$REPO_ROOT/CLAUDE.md" ;;
    codex)    CONFIG_FILE="$REPO_ROOT/bootstraps/CODEX.md" ;;
    openclaw) CONFIG_FILE="$REPO_ROOT/bootstraps/OPENCLAW.md" ;;
  esac

  if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: config file not found: $CONFIG_FILE"
    VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
  fi
fi

# Confirm all required shared dirs exist and are readable
for dir in "${REQUIRED_DIRS[@]}"; do
  if [[ ! -d "$dir" ]]; then
    echo "Error: post-setup validation failed — missing: $dir"
    VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
  fi
done

# Confirm dispatch scripts exist and are executable
REQUIRED_SCRIPTS=(
  "$SHARED_DIR/tools/dispatch.sh"
  "$SHARED_DIR/tools/agent_runner.sh"
  "$SHARED_DIR/tools/build_system_prompt.sh"
)
REQUIRED_CONFIGS=(
  "$SHARED_DIR/tools/model_routing.json"
)

for script in "${REQUIRED_SCRIPTS[@]}"; do
  if [[ ! -f "$script" ]]; then
    echo "Error: required script missing: $script"
    VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
  elif [[ ! -x "$script" ]]; then
    echo "Error: required script not executable: $script"
    VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
  fi
done

for config in "${REQUIRED_CONFIGS[@]}"; do
  if [[ ! -f "$config" ]]; then
    echo "Error: required config missing: $config"
    VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
  fi
done

# Confirm agent inbox/outbox directories exist
for AGENT in "${AGENTS[@]}"; do
  for dir in inbox outbox; do
    if [[ ! -d "$SHARED_DIR/memory/$AGENT/$dir" ]]; then
      echo "Error: post-setup validation failed — missing: shared/memory/$AGENT/$dir"
      VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
    fi
  done
done

if [[ $VALIDATION_ERRORS -gt 0 ]]; then
  echo "Setup completed with $VALIDATION_ERRORS validation error(s). Review output above."
  exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✓ Parlei setup complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ "$ENV" == "all" ]]; then
  echo ""
  echo "Multi-environment mode enabled:"
  echo "  • Claude Code   → Load CLAUDE.md"
  echo "  • Codex         → Load bootstraps/CODEX.md"
  echo "  • OpenClaw      → Workspace configured at ~/.openclaw/workspace"
  echo ""
  echo "Parlei will auto-detect which CLI tool is available when agents run."
  echo "You can use Claude and Codex simultaneously on the same system!"

  # Check if OpenClaw workspace was successfully configured
  OPENCLAW_WS="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
  if [[ -L "$OPENCLAW_WS/shared" ]]; then
    echo ""
    echo "OpenClaw integration:"
    echo "  ✓ Workspace symlink: $OPENCLAW_WS/shared"
    echo "  ✓ Launch: openclaw"
    echo "  ✓ Bootstrap: Automatically loaded from AGENTS.md"
  fi
else
  echo ""
  echo "Environment: $ENV"

  if [[ "$ENV" == "openclaw" ]]; then
    OPENCLAW_WS="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
    if [[ -L "$OPENCLAW_WS/shared" ]]; then
      echo "  OpenClaw workspace: $OPENCLAW_WS"
      echo "  Symlink: shared -> $SHARED_DIR"
      echo "  Launch: openclaw"
    else
      echo "  Note: Install OpenClaw and run 'openclaw setup' to complete setup"
    fi
  else
    echo "  Bootstrap: Open your AI coding tool and load:"
    echo "    → $(basename "$CONFIG_FILE")"
  fi
fi

echo ""
echo "Shared resources:"
echo "  Memory:     $SHARED_DIR/memory/"
echo "  Agents:     13 configured (2 lightweight, 7 balanced, 4 premium)"
echo "  Cron jobs:  parlei-memory (03:00), parlei-backup (02:30)"
echo ""
echo "Use 'parlei status' to check configuration anytime."
echo "The parliament is in session. 🦉"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
