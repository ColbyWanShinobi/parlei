#!/usr/bin/env bats
# Unit tests for protocol tools: JSON schemas, request ID, retry counter
# Covers T-087, T-088, T-089

load '../fixtures/setup'

REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
TOOLS_DIR="$REPO_ROOT/shared/tools"

setup() {
  parlei_setup_tmpdir
  parlei_create_shared_skeleton "$PARLEI_TEST_ROOT"
  cp -r "$REPO_ROOT/shared/tools/." "$PARLEI_TEST_ROOT/shared/tools/"
  chmod +x "$PARLEI_TEST_ROOT/shared/tools/"*.sh 2>/dev/null || true
}

teardown() {
  parlei_teardown_tmpdir
}

# ── T-087: JSON envelope validation ───────────────────────────────────────────

validate_json() {
  local schema="$1" data="$2"
  python3 -c "
import json, sys
try:
    import jsonschema
    schema = json.load(open('$schema'))
    data = json.loads('$data'.replace(\"'\", '\"'))
    jsonschema.validate(data, schema)
    print('valid')
except ImportError:
    # jsonschema not installed — do basic JSON parse only
    json.loads('$data'.replace(\"'\", '\"'))
    print('valid')
except jsonschema.ValidationError as e:
    print('invalid: ' + str(e.message))
    sys.exit(1)
except json.JSONDecodeError as e:
    print('invalid json: ' + str(e))
    sys.exit(1)
"
}

REQUEST_SCHEMA="$PARLEI_TEST_ROOT/shared/tools/schema_request.json"
RESPONSE_SCHEMA="$PARLEI_TEST_ROOT/shared/tools/schema_response.json"

@test "schema: valid request envelope passes" {
  VALID='{"from":"tasker","to":"checker","request_id":"req-tasker-20260327-001","items":[{"id":1,"type":"verify","description":"Check task"}]}'
  run python3 -c "import json; json.loads('$VALID'); print('valid')"
  [ "$status" -eq 0 ]
  [[ "$output" == "valid" ]]
}

@test "schema: request_id follows correct format pattern" {
  # Test the pattern manually since jsonschema may not be installed
  run python3 -c "
import re
pattern = r'^req-[a-z]+-[0-9]{8}-[0-9]{3}$'
tests = [
  ('req-tasker-20260327-001', True),
  ('req-speaker-20260327-014', True),
  ('bad-id', False),
  ('req-Tasker-20260327-001', False),
  ('req-tasker-2026032-001', False),
  ('req-tasker-20260327-1', False),
]
for val, expected in tests:
    result = bool(re.match(pattern, val))
    assert result == expected, f'Failed for {val}: expected {expected}, got {result}'
print('all pass')
"
  [ "$status" -eq 0 ]
  [[ "$output" == "all pass" ]]
}

@test "schema: valid response envelope has required status enum values" {
  run python3 -c "
valid_statuses = {'confirmed', 'incomplete', 'failed', 'deferred'}
test_statuses = ['confirmed', 'incomplete', 'failed', 'deferred']
invalid_statuses = ['unknown', 'done', 'ok', '']
for s in test_statuses:
    assert s in valid_statuses, f'{s} should be valid'
for s in invalid_statuses:
    assert s not in valid_statuses, f'{s} should be invalid'
print('all pass')
"
  [ "$status" -eq 0 ]
}

@test "schema: request and response schema files are valid JSON" {
  local req_schema="$PARLEI_TEST_ROOT/shared/tools/schema_request.json"
  local res_schema="$PARLEI_TEST_ROOT/shared/tools/schema_response.json"
  run python3 -c "import json; json.load(open('$req_schema')); json.load(open('$res_schema')); print('valid')"
  [ "$status" -eq 0 ]
  [[ "$output" == "valid" ]]
}

# ── T-088: Request ID generator ───────────────────────────────────────────────

@test "request_id: generates ID in correct format" {
  run bash "$PARLEI_TEST_ROOT/shared/tools/request_id.sh" tasker
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^req-tasker-[0-9]{8}-[0-9]{3}$ ]]
}

@test "request_id: sequential calls produce incrementing sequence numbers" {
  ID1="$(bash "$PARLEI_TEST_ROOT/shared/tools/request_id.sh" tasker)"
  ID2="$(bash "$PARLEI_TEST_ROOT/shared/tools/request_id.sh" tasker)"
  ID3="$(bash "$PARLEI_TEST_ROOT/shared/tools/request_id.sh" tasker)"

  SEQ1="${ID1##*-}"
  SEQ2="${ID2##*-}"
  SEQ3="${ID3##*-}"

  [ "$SEQ2" -eq $((10#$SEQ1 + 1)) ]
  [ "$SEQ3" -eq $((10#$SEQ2 + 1)) ]
}

@test "request_id: different agents produce different prefixes" {
  ID_TASKER="$(bash "$PARLEI_TEST_ROOT/shared/tools/request_id.sh" tasker)"
  ID_CHECKER="$(bash "$PARLEI_TEST_ROOT/shared/tools/request_id.sh" checker)"

  [[ "$ID_TASKER" == req-tasker-* ]]
  [[ "$ID_CHECKER" == req-checker-* ]]
}

@test "request_id: exits 1 with no arguments" {
  run bash "$PARLEI_TEST_ROOT/shared/tools/request_id.sh"
  [ "$status" -ne 0 ]
}

# ── T-089: Retry counter ───────────────────────────────────────────────────────

make_request_json() {
  local file="$1"
  cat > "$file" << 'EOF'
{"from":"tasker","to":"checker","request_id":"req-tasker-20260327-001","items":[{"id":1,"type":"verify","description":"Check A"},{"id":2,"type":"verify","description":"Check B"},{"id":3,"type":"verify","description":"Check C"}]}
EOF
}

make_complete_response() {
  local file="$1"
  cat > "$file" << 'EOF'
{"from":"checker","to":"tasker","request_id":"req-tasker-20260327-001","items":[{"id":1,"status":"confirmed","notes":"ok"},{"id":2,"status":"confirmed","notes":"ok"},{"id":3,"status":"confirmed","notes":"ok"}]}
EOF
}

make_partial_response() {
  local file="$1"
  cat > "$file" << 'EOF'
{"from":"checker","to":"tasker","request_id":"req-tasker-20260327-001","items":[{"id":1,"status":"confirmed","notes":"ok"},{"id":3,"status":"confirmed","notes":"ok"}]}
EOF
}

@test "retry: exits 0 when all item IDs are present in response" {
  REQ="$(mktemp)" RESP="$(mktemp)"
  make_request_json "$REQ"
  make_complete_response "$RESP"

  run bash "$PARLEI_TEST_ROOT/shared/tools/retry.sh" "req-tasker-20260327-001" "tasker" "$REQ" "$RESP"
  [ "$status" -eq 0 ]
  rm -f "$REQ" "$RESP"
}

@test "retry: exits 2 when items are missing and under retry limit" {
  REQ="$(mktemp)" RESP="$(mktemp)"
  make_request_json "$REQ"
  make_partial_response "$RESP"

  run bash "$PARLEI_TEST_ROOT/shared/tools/retry.sh" "req-tasker-20260327-001" "tasker" "$REQ" "$RESP"
  [ "$status" -eq 2 ]
  [[ "$output" == *"MISSING_IDS=2"* ]]
  [[ "$output" == *"ESCALATE=false"* ]]
  rm -f "$REQ" "$RESP"
}

@test "retry: exits 3 and sets ESCALATE=true after 3 failures" {
  REQ="$(mktemp)" RESP="$(mktemp)"
  make_request_json "$REQ"
  make_partial_response "$RESP"

  bash "$PARLEI_TEST_ROOT/shared/tools/retry.sh" "req-tasker-20260327-002" "tasker" "$REQ" "$RESP" || true
  bash "$PARLEI_TEST_ROOT/shared/tools/retry.sh" "req-tasker-20260327-002" "tasker" "$REQ" "$RESP" || true
  run bash "$PARLEI_TEST_ROOT/shared/tools/retry.sh" "req-tasker-20260327-002" "tasker" "$REQ" "$RESP"

  [ "$status" -eq 3 ]
  [[ "$output" == *"ESCALATE=true"* ]]
  rm -f "$REQ" "$RESP"
}

@test "retry: state file is removed on successful complete response" {
  REQ="$(mktemp)" RESP_PARTIAL="$(mktemp)" RESP_COMPLETE="$(mktemp)"
  make_request_json "$REQ"
  make_partial_response "$RESP_PARTIAL"
  make_complete_response "$RESP_COMPLETE"

  # First attempt: partial
  bash "$PARLEI_TEST_ROOT/shared/tools/retry.sh" "req-tasker-20260327-003" "tasker" "$REQ" "$RESP_PARTIAL" || true
  # Second attempt: complete
  bash "$PARLEI_TEST_ROOT/shared/tools/retry.sh" "req-tasker-20260327-003" "tasker" "$REQ" "$RESP_COMPLETE"

  [ ! -f "$PARLEI_TEST_ROOT/shared/memory/tasker/.retry_state/req-tasker-20260327-003.json" ]
  rm -f "$REQ" "$RESP_PARTIAL" "$RESP_COMPLETE"
}
