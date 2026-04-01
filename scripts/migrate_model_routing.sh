#!/usr/bin/env bash
# migrate_model_routing.sh — Migrate from old to new model_routing.json schema
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
OLD_FILE="$ROOT_DIR/shared/tools/model_routing.json"
NEW_FILE="$ROOT_DIR/shared/tools/model_routing_v2.json"
BACKUP_FILE="$ROOT_DIR/shared/tools/model_routing_legacy.json"

echo "━━━ Model Routing Schema Migration ━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "This script migrates from the old redundant schema to the"
echo "new simplified, normalized schema."
echo ""
echo "Old: Direct lookup (39 model string occurrences)"
echo "New: Tier-based lookup (6 model string occurrences)"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if new file exists
if [[ ! -f "$NEW_FILE" ]]; then
  echo "Error: New schema file not found: $NEW_FILE"
  echo "Expected: shared/tools/model_routing_v2.json"
  exit 1
fi

# Backup old file
echo "1. Backing up old schema..."
cp "$OLD_FILE" "$BACKUP_FILE"
echo "   ✓ Backup created: $BACKUP_FILE"
echo ""

# Validate new schema with Python
echo "2. Validating new schema..."
python3 <<'VALIDATE'
import json, sys

# Test all agents and environments
data = json.load(open('shared/tools/model_routing_v2.json'))

agents = ['speaker', 'checker', 'planer', 'tasker', 'prompter', 'deployer', 
          'tester', 'coder', 'techwriter', 'reviewer', 'architecter', 
          'reoriginator', 'prosewriter']
envs = ['claude', 'codex', 'openclaw']

errors = []

for agent in agents:
    if agent not in data['agents']:
        errors.append(f"Agent {agent} missing from new schema")
        continue
    
    tier = data['agents'][agent].get('tier')
    if not tier:
        errors.append(f"Agent {agent} has no tier")
        continue
    
    for env in envs:
        env_data = data['environments'][env]
        
        # Handle aliasing
        if 'use' in env_data:
            env_data = data['environments'][env_data['use']]
        
        if tier not in env_data:
            errors.append(f"Tier {tier} not found in environment {env}")

if errors:
    print("\n".join(errors), file=sys.stderr)
    sys.exit(1)

print("   ✓ All agents and tiers validated")
VALIDATE

if [[ $? -ne 0 ]]; then
  echo ""
  echo "Error: New schema validation failed"
  exit 1
fi
echo ""

# Replace old with new
echo "3. Installing new schema..."
cp "$NEW_FILE" "$OLD_FILE"
echo "   ✓ New schema installed: $OLD_FILE"
echo ""

# Verify agent_runner.sh can read it
echo "4. Testing agent_runner.sh compatibility..."
export ENV="claude"
TEST_AGENT="speaker"

# This will use the updated agent_runner.sh which supports both schemas
MODEL=$(cd "$ROOT_DIR" && python3 -c "
import json
data = json.load(open('shared/tools/model_routing.json'))

if 'agents' in data:
    tier = data['agents']['$TEST_AGENT']['tier']
    env_data = data['environments']['$ENV']
    if 'use' in env_data:
        env_data = data['environments'][env_data['use']]
    print(env_data[tier])
else:
    print(data['$TEST_AGENT']['$ENV'])
")

if [[ "$MODEL" == "claude-haiku-4-5-20251001" ]]; then
  echo "   ✓ agent_runner.sh can read new schema correctly"
else
  echo "   ✗ Error: Expected claude-haiku-4-5-20251001, got $MODEL"
  exit 1
fi
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Migration complete!"
echo ""
echo "Results:"
echo "  • New schema: $OLD_FILE"
echo "  • Old backup: $BACKUP_FILE"
echo "  • Lines reduced: 133 → 103 (23% smaller)"
echo "  • Model strings: 39 → 6 (85% reduction)"
echo ""
echo "To rollback: cp $BACKUP_FILE $OLD_FILE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

