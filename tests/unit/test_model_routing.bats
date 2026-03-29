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

@test "model_routing: all 10 expected agents are present" {
  run python3 -c "
import json
d = json.load(open('$ROUTING'))
expected = ['speaker','planer','tasker','prompter','checker','reviewer','architecter','deployer','tester','reoriginator']
missing = [a for a in expected if a not in d]
if missing:
    print('missing:', missing)
    exit(1)
print('ok')
"
  [ "$status" -eq 0 ]
  [ "$output" = "ok" ]
}

@test "model_routing: each entry has a model field" {
  run python3 -c "
import json
d = json.load(open('$ROUTING'))
for agent, entry in d.items():
    if 'model' not in entry:
        print(f'missing model for {agent}')
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

@test "model_routing: speaker uses haiku model (cost-optimized orchestrator)" {
  run python3 -c "
import json
d = json.load(open('$ROUTING'))
model = d['speaker']['model']
print('ok' if 'haiku' in model.lower() else f'expected haiku, got: {model}')
"
  [ "$status" -eq 0 ]
  [ "$output" = "ok" ]
}

@test "model_routing: checker uses haiku model (lightweight verifier)" {
  run python3 -c "
import json
d = json.load(open('$ROUTING'))
model = d['checker']['model']
print('ok' if 'haiku' in model.lower() else f'expected haiku, got: {model}')
"
  [ "$status" -eq 0 ]
  [ "$output" = "ok" ]
}

@test "model_routing: reviewer uses opus model (high-stakes code review)" {
  run python3 -c "
import json
d = json.load(open('$ROUTING'))
model = d['reviewer']['model']
print('ok' if 'opus' in model.lower() else f'expected opus, got: {model}')
"
  [ "$status" -eq 0 ]
  [ "$output" = "ok" ]
}

@test "model_routing: reoriginator uses opus model (high-stakes re-origination)" {
  run python3 -c "
import json
d = json.load(open('$ROUTING'))
model = d['reoriginator']['model']
print('ok' if 'opus' in model.lower() else f'expected opus, got: {model}')
"
  [ "$status" -eq 0 ]
  [ "$output" = "ok" ]
}

@test "model_routing: tasker uses sonnet model (mid-tier task breakdown)" {
  run python3 -c "
import json
d = json.load(open('$ROUTING'))
model = d['tasker']['model']
print('ok' if 'sonnet' in model.lower() else f'expected sonnet, got: {model}')
"
  [ "$status" -eq 0 ]
  [ "$output" = "ok" ]
}

@test "model_routing: no model values are empty strings" {
  run python3 -c "
import json
d = json.load(open('$ROUTING'))
for agent, entry in d.items():
    if agent.startswith('_') or not isinstance(entry, dict):
        continue
    if not entry.get('model', '').strip():
        print(f'empty model for {agent}')
        exit(1)
print('ok')
"
  [ "$status" -eq 0 ]
  [ "$output" = "ok" ]
}
