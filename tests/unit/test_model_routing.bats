#!/usr/bin/env bats
# Unit tests for shared/tools/model_routing.json (FIX-026)
# Verifies all agents have valid routing entries and tier assignments are correct.

load '../fixtures/setup'

REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
ROUTING="$REPO_ROOT/shared/tools/model_routing.json"

setup() {
  parlei_setup_tmpdir
  parlei_create_shared_skeleton "$PARLEI_TEST_ROOT"
}

teardown() {
  parlei_teardown_tmpdir
}

# ── Structural validity ───────────────────────────────────────────────────────

@test "model_routing: file is valid JSON" {
  run python3 -c "import json; json.load(open('$ROUTING')); print('ok')"
  [ "$status" -eq 0 ]
  [ "$output" = "ok" ]
}

@test "model_routing: all 13 expected agents are present" {
  run python3 -c "
import json
d = json.load(open('$ROUTING'))
expected = ['speaker','planer','tasker','prompter','checker','reviewer','architecter','deployer','tester','reoriginator','coder','techwriter','prosewriter']
missing = [a for a in expected if a not in d]
if missing:
    print('missing:', missing)
    exit(1)
print('ok')
"
  [ "$status" -eq 0 ]
  [ "$output" = "ok" ]
}

@test "model_routing: each agent has environment-specific models" {
  run python3 -c "
import json
d = json.load(open('$ROUTING'))
for agent, entry in d.items():
    if agent.startswith('_') or not isinstance(entry, dict):
        continue
    # Check for environment-specific keys or legacy 'model' key
    has_claude = 'claude' in entry
    has_codex = 'codex' in entry
    has_openclaw = 'openclaw' in entry
    has_legacy_model = 'model' in entry
    if not (has_claude or has_codex or has_openclaw or has_legacy_model):
        print(f'{agent} missing environment-specific models')
        exit(1)
print('ok')
"
  [ "$status" -eq 0 ]
  [ "$output" = "ok" ]
}

@test "model_routing: each agent entry has a rationale field" {
  run python3 -c "
import json
d = json.load(open('$ROUTING'))
for agent, entry in d.items():
    if agent.startswith('_'):
        continue  # skip metadata keys like _comment
    if not isinstance(entry, dict) or 'rationale' not in entry:
        print(f'missing rationale for {agent}')
        exit(1)
print('ok')
"
  [ "$status" -eq 0 ]
  [ "$output" = "ok" ]
}

# ── Model tier assignments ────────────────────────────────────────────────────

@test "model_routing: speaker uses lightweight tier (cost-optimized orchestrator)" {
  run python3 -c "
import json
d = json.load(open('$ROUTING'))
tier = d['speaker'].get('tier', '')
print('ok' if tier == 'lightweight' else f'expected lightweight, got: {tier}')
"
  [ "$status" -eq 0 ]
  [ "$output" = "ok" ]
}

@test "model_routing: checker uses lightweight tier (lightweight verifier)" {
  run python3 -c "
import json
d = json.load(open('$ROUTING'))
tier = d['checker'].get('tier', '')
print('ok' if tier == 'lightweight' else f'expected lightweight, got: {tier}')
"
  [ "$status" -eq 0 ]
  [ "$output" = "ok" ]
}

@test "model_routing: reviewer uses premium tier (high-stakes code review)" {
  run python3 -c "
import json
d = json.load(open('$ROUTING'))
tier = d['reviewer'].get('tier', '')
print('ok' if tier == 'premium' else f'expected premium, got: {tier}')
"
  [ "$status" -eq 0 ]
  [ "$output" = "ok" ]
}

@test "model_routing: reoriginator uses premium tier (high-stakes re-origination)" {
  run python3 -c "
import json
d = json.load(open('$ROUTING'))
tier = d['reoriginator'].get('tier', '')
print('ok' if tier == 'premium' else f'expected premium, got: {tier}')
"
  [ "$status" -eq 0 ]
  [ "$output" = "ok" ]
}

@test "model_routing: tasker uses balanced tier (mid-tier task breakdown)" {
  run python3 -c "
import json
d = json.load(open('$ROUTING'))
tier = d['tasker'].get('tier', '')
print('ok' if tier == 'balanced' else f'expected balanced, got: {tier}')
"
  [ "$status" -eq 0 ]
  [ "$output" = "ok" ]
}

@test "model_routing: planer/prompter/deployer/tester/coder/techwriter use balanced tier" {
  run python3 -c "
import json, sys
d = json.load(open('$ROUTING'))
balanced_agents = ['planer','prompter','deployer','tester','coder','techwriter']
for agent in balanced_agents:
    tier = d[agent].get('tier', '')
    if tier != 'balanced':
        print(f'{agent} expected balanced, got: {tier}')
        sys.exit(1)
print('ok')
"
  [ "$status" -eq 0 ]
  [ "$output" = "ok" ]
}

@test "model_routing: architecter uses premium tier (architecture decisions)" {
  run python3 -c "
import json
d = json.load(open('$ROUTING'))
tier = d['architecter'].get('tier', '')
print('ok' if tier == 'premium' else f'expected premium, got: {tier}')
"
  [ "$status" -eq 0 ]
  [ "$output" = "ok" ]
}

@test "model_routing: prosewriter uses premium tier (high-quality prose)" {
  run python3 -c "
import json
d = json.load(open('$ROUTING'))
tier = d['prosewriter'].get('tier', '')
print('ok' if tier == 'premium' else f'expected premium, got: {tier}')
"
  [ "$status" -eq 0 ]
  [ "$output" = "ok" ]
}

@test "model_routing: techwriter uses balanced tier (technical documentation)" {
  run python3 -c "
import json
d = json.load(open('$ROUTING'))
tier = d['techwriter'].get('tier', '')
print('ok' if tier == 'balanced' else f'expected balanced, got: {tier}')
"
  [ "$status" -eq 0 ]
  [ "$output" = "ok" ]
}

# ── Environment-specific models ────────────────────────────────────────────────

@test "model_routing: claude environment models use claude- prefix" {
  run python3 -c "
import json, sys
d = json.load(open('$ROUTING'))
for agent, entry in d.items():
    if agent.startswith('_') or not isinstance(entry, dict):
        continue
    model = entry.get('claude', '')
    if model and not model.startswith('claude-'):
        print(f'{agent} claude model does not start with claude-: {model}')
        sys.exit(1)
print('ok')
"
  [ "$status" -eq 0 ]
  [ "$output" = "ok" ]
}

@test "model_routing: codex environment models use gpt- prefix" {
  run python3 -c "
import json, sys
d = json.load(open('$ROUTING'))
for agent, entry in d.items():
    if agent.startswith('_') or not isinstance(entry, dict):
        continue
    model = entry.get('codex', '')
    if model and not model.startswith('gpt-'):
        print(f'{agent} codex model does not start with gpt-: {model}')
        sys.exit(1)
print('ok')
"
  [ "$status" -eq 0 ]
  [ "$output" = "ok" ]
}

@test "model_routing: codex lightweight tier uses gpt-5.1-codex-mini" {
  run python3 -c "
import json, sys
d = json.load(open('$ROUTING'))
lightweight_agents = ['speaker', 'checker']
for agent in lightweight_agents:
    model = d[agent].get('codex', '')
    if model != 'gpt-5.1-codex-mini':
        print(f'{agent} codex model expected gpt-5.1-codex-mini, got: {model}')
        sys.exit(1)
print('ok')
"
  [ "$status" -eq 0 ]
  [ "$output" = "ok" ]
}

@test "model_routing: codex balanced tier uses gpt-5.4" {
  run python3 -c "
import json, sys
d = json.load(open('$ROUTING'))
balanced_agents = ['planer', 'tasker', 'prompter', 'deployer', 'tester', 'coder', 'techwriter']
for agent in balanced_agents:
    model = d[agent].get('codex', '')
    if model != 'gpt-5.4':
        print(f'{agent} codex model expected gpt-5.4, got: {model}')
        sys.exit(1)
print('ok')
"
  [ "$status" -eq 0 ]
  [ "$output" = "ok" ]
}

@test "model_routing: codex premium tier uses gpt-5.1-codex-max" {
  run python3 -c "
import json, sys
d = json.load(open('$ROUTING'))
premium_agents = ['reviewer', 'architecter', 'reoriginator', 'prosewriter']
for agent in premium_agents:
    model = d[agent].get('codex', '')
    if model != 'gpt-5.1-codex-max':
        print(f'{agent} codex model expected gpt-5.1-codex-max, got: {model}')
        sys.exit(1)
print('ok')
"
  [ "$status" -eq 0 ]
  [ "$output" = "ok" ]
}

@test "model_routing: no environment model values are empty strings" {
  run python3 -c "
import json, sys
d = json.load(open('$ROUTING'))
for agent, entry in d.items():
    if agent.startswith('_') or not isinstance(entry, dict):
        continue
    # Check all environment-specific model fields
    for env in ['claude', 'codex', 'openclaw']:
        model = entry.get(env, '')
        if model is not None and not str(model).strip():
            print(f'empty {env} model for {agent}')
            sys.exit(1)
print('ok')
"
  [ "$status" -eq 0 ]
  [ "$output" = "ok" ]
}

@test "model_routing: each agent has a tier field" {
  run python3 -c "
import json, sys
d = json.load(open('$ROUTING'))
for agent, entry in d.items():
    if agent.startswith('_') or not isinstance(entry, dict):
        continue
    tier = entry.get('tier', '')
    if tier not in ['lightweight', 'balanced', 'premium']:
        print(f'{agent} has invalid tier: {tier}')
        sys.exit(1)
print('ok')
"
  [ "$status" -eq 0 ]
  [ "$output" = "ok" ]
}
