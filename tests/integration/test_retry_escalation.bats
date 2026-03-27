#!/usr/bin/env bats
# Integration test: retry and escalation chain (T-093, T-094, T-095)

load '../fixtures/setup'

REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"

setup() {
  parlei_setup_tmpdir
  parlei_create_shared_skeleton "$PARLEI_TEST_ROOT"
  cp -r "$REPO_ROOT/shared/tools/." "$PARLEI_TEST_ROOT/shared/tools/"
  chmod +x "$PARLEI_TEST_ROOT/shared/tools/"*.sh 2>/dev/null || true
}

teardown() {
  parlei_teardown_tmpdir
}

# ── T-094: Full retry chain → escalation ──────────────────────────────────────

@test "retry chain: 3 failures for same request_id produce ESCALATE=true" {
  REQ="$(mktemp)" RESP="$(mktemp)"

  cat > "$REQ" << 'EOF'
{"from":"tasker","to":"checker","request_id":"req-tasker-20260327-010","items":[{"id":1,"type":"verify","description":"Check A"},{"id":2,"type":"verify","description":"Check B"}]}
EOF
  # Response is always missing item 2
  cat > "$RESP" << 'EOF'
{"from":"checker","to":"tasker","request_id":"req-tasker-20260327-010","items":[{"id":1,"status":"confirmed","notes":"ok"}]}
EOF

  bash "$PARLEI_TEST_ROOT/shared/tools/retry.sh" "req-tasker-20260327-010" "tasker" "$REQ" "$RESP" || true
  bash "$PARLEI_TEST_ROOT/shared/tools/retry.sh" "req-tasker-20260327-010" "tasker" "$REQ" "$RESP" || true
  run bash "$PARLEI_TEST_ROOT/shared/tools/retry.sh" "req-tasker-20260327-010" "tasker" "$REQ" "$RESP"

  [ "$status" -eq 3 ]
  [[ "$output" == *"ESCALATE=true"* ]]
  [[ "$output" == *"MISSING_IDS=2"* ]]
  rm -f "$REQ" "$RESP"
}

@test "retry chain: state file contains full attempt history after 3 failures" {
  REQ="$(mktemp)" RESP="$(mktemp)"
  cat > "$REQ" << 'EOF'
{"from":"planer","to":"checker","request_id":"req-planer-20260327-011","items":[{"id":1,"type":"verify","description":"Plan check"},{"id":2,"type":"verify","description":"Task check"}]}
EOF
  cat > "$RESP" << 'EOF'
{"from":"checker","to":"planer","request_id":"req-planer-20260327-011","items":[{"id":1,"status":"confirmed","notes":"ok"}]}
EOF

  for i in 1 2 3; do
    bash "$PARLEI_TEST_ROOT/shared/tools/retry.sh" "req-planer-20260327-011" "planer" "$REQ" "$RESP" || true
  done

  STATE_FILE="$PARLEI_TEST_ROOT/shared/memory/planer/.retry_state/req-planer-20260327-011.json"
  assert_file_nonempty "$STATE_FILE"
  run python3 -c "import json; d=json.load(open('$STATE_FILE')); print(len(d['history']))"
  [ "$output" -eq 3 ]
  rm -f "$REQ" "$RESP"
}

# ── T-095: Lateral grant flow ─────────────────────────────────────────────────

@test "lateral grant: grant message is valid JSON with correct type field" {
  GRANT='{
    "from": "speaker",
    "to": "tasker",
    "request_id": "req-speaker-20260327-005",
    "type": "lateral_grant",
    "items": [{
      "id": 1,
      "type": "lateral_grant",
      "description": "Authorized to contact checker directly",
      "context": "{\"authorized_peer\": \"checker\", \"task_scope\": \"coherence check\", \"expires\": \"on task completion\"}"
    }]
  }'

  run python3 -c "
import json, sys
d = json.loads(sys.argv[1])
assert d['type'] == 'lateral_grant'
assert d['items'][0]['type'] == 'lateral_grant'
assert 'authorized_peer' in d['items'][0]['context']
print('valid')
" "$GRANT"

  [ "$status" -eq 0 ]
  [[ "$output" == "valid" ]]
}
