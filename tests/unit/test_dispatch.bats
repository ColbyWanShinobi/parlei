#!/usr/bin/env bats
# Unit tests for shared/tools/dispatch.sh (FIX-025)
# Uses a stub agent_runner.sh to avoid real LLM calls.

load '../fixtures/setup'

REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"

# Canned valid response JSON
CANNED_RESPONSE='{"from":"speaker","to":"tasker","request_id":"req-speaker-20260329-001","items":[{"id":1,"status":"confirmed","notes":"stub"}]}'

setup() {
  parlei_setup_tmpdir
  parlei_create_shared_skeleton "$PARLEI_TEST_ROOT"

  # Copy dispatch.sh (real) and its dependencies
  cp "$REPO_ROOT/shared/tools/dispatch.sh"    "$PARLEI_TEST_ROOT/shared/tools/dispatch.sh"
  cp "$REPO_ROOT/shared/tools/request_id.sh"  "$PARLEI_TEST_ROOT/shared/tools/request_id.sh"
  cp "$REPO_ROOT/shared/tools/schema_response.json" \
     "$PARLEI_TEST_ROOT/shared/tools/schema_response.json"
  chmod +x "$PARLEI_TEST_ROOT/shared/tools/dispatch.sh" \
            "$PARLEI_TEST_ROOT/shared/tools/request_id.sh"

  # Stub agent_runner.sh to return canned response without an LLM call
  cat > "$PARLEI_TEST_ROOT/shared/tools/agent_runner.sh" << RUNNER_STUB
#!/usr/bin/env bash
echo '$CANNED_RESPONSE'
RUNNER_STUB
  chmod +x "$PARLEI_TEST_ROOT/shared/tools/agent_runner.sh"

  # Minimal agent definition file (dispatch.sh checks this)
  echo "# Speaker" > "$PARLEI_TEST_ROOT/shared/agents/speaker.md"
  echo "# Checker" > "$PARLEI_TEST_ROOT/shared/agents/checker.md"

  # Write a valid request file
  python3 -c "
import json
req = {
  'from': 'speaker',
  'to': 'checker',
  'request_id': 'req-speaker-20260329-001',
  'items': [{'id': 1, 'type': 'test', 'description': 'Dispatch unit test'}]
}
print(json.dumps(req))
" > "$PARLEI_TEST_ROOT/request.json"
}

teardown() {
  parlei_teardown_tmpdir
}

# ── Argument validation ───────────────────────────────────────────────────────

@test "dispatch: exits 1 with no arguments" {
  run bash "$PARLEI_TEST_ROOT/shared/tools/dispatch.sh"
  [ "$status" -eq 1 ]
}

@test "dispatch: exits 1 for unknown agent" {
  run bash "$PARLEI_TEST_ROOT/shared/tools/dispatch.sh" ghostagent "$PARLEI_TEST_ROOT/request.json"
  [ "$status" -eq 1 ]
  [[ "$output" == *"unknown agent"* ]]
}

@test "dispatch: exits 1 when request file does not exist" {
  run bash "$PARLEI_TEST_ROOT/shared/tools/dispatch.sh" speaker /nonexistent.json
  [ "$status" -eq 1 ]
}

@test "dispatch: exits 1 when request file is not valid JSON" {
  echo "invalid json" > "$PARLEI_TEST_ROOT/bad.json"
  run bash "$PARLEI_TEST_ROOT/shared/tools/dispatch.sh" speaker "$PARLEI_TEST_ROOT/bad.json"
  [ "$status" -eq 1 ]
}

# ── Successful dispatch ───────────────────────────────────────────────────────

@test "dispatch: writes response to outbox" {
  bash "$PARLEI_TEST_ROOT/shared/tools/dispatch.sh" speaker "$PARLEI_TEST_ROOT/request.json" > /dev/null
  OUTBOX="$PARLEI_TEST_ROOT/shared/memory/speaker/outbox"
  [ "$(ls "$OUTBOX"/*.json 2>/dev/null | wc -l)" -gt 0 ]
}

@test "dispatch: exits 0 for valid agent and request" {
  OUTPUT="$(bash "$PARLEI_TEST_ROOT/shared/tools/dispatch.sh" speaker "$PARLEI_TEST_ROOT/request.json" 2>&1)"
  STATUS=$?
  [ "$STATUS" -eq 0 ]
}

@test "dispatch: output is valid JSON" {
  OUTPUT="$(bash "$PARLEI_TEST_ROOT/shared/tools/dispatch.sh" speaker "$PARLEI_TEST_ROOT/request.json" 2>&1)"
  STATUS=$?
  [ "$STATUS" -eq 0 ]
  python3 -c "import json,sys; json.loads(sys.argv[1])" "$OUTPUT"
}

@test "dispatch: removes inbox file after success" {
  bash "$PARLEI_TEST_ROOT/shared/tools/dispatch.sh" speaker "$PARLEI_TEST_ROOT/request.json" > /dev/null
  INBOX="$PARLEI_TEST_ROOT/shared/memory/speaker/inbox"
  INBOX_JSON_COUNT="$(ls "$INBOX"/*.json 2>/dev/null | wc -l || echo 0)"
  [ "$INBOX_JSON_COUNT" -eq 0 ]
}


@test "dispatch: inbox path uses request_id naming" {
  REQUEST_ID="$(python3 -c "import json; print(json.load(open('$PARLEI_TEST_ROOT/request.json'))['request_id'])")"
  PATCHED="$PARLEI_TEST_ROOT/shared/tools/dispatch_no_rm.sh"
  CAPTURE="$PARLEI_TEST_ROOT/last_inbox_path.txt"

  python3 - <<PY
from pathlib import Path
import os

root = os.environ["PARLEI_TEST_ROOT"]
src = Path(root) / "shared/tools/dispatch.sh"
patched = Path(root) / "shared/tools/dispatch_no_rm.sh"
patched.write_text(src.read_text().replace('rm -f "$INBOX_FILE"', '# rm -f "$INBOX_FILE"'))
PY
  chmod +x "$PATCHED"

  DISPATCH_CAPTURE_PATH="$CAPTURE" \
  bash "$PATCHED" speaker "$PARLEI_TEST_ROOT/request.json"
  [ "$?" -eq 0 ]

  INBOX_FILE="$(cat "$CAPTURE")"
  EXPECTED="$PARLEI_TEST_ROOT/shared/memory/speaker/inbox/${REQUEST_ID}.json"
  [ "$INBOX_FILE" = "$EXPECTED" ]

  rm -f "$CAPTURE" "$PATCHED"
}

@test "dispatch: outbox file named after request_id" {
  REQUEST_ID="$(python3 -c "import json; print(json.load(open('$PARLEI_TEST_ROOT/request.json'))['request_id'])")"

  bash "$PARLEI_TEST_ROOT/shared/tools/dispatch.sh" speaker "$PARLEI_TEST_ROOT/request.json"
  [ "$?" -eq 0 ]
  OUTBOX_FILE="$PARLEI_TEST_ROOT/shared/memory/speaker/outbox/${REQUEST_ID}.json"
  [ -f "$OUTBOX_FILE" ]
}
# ── Escalation on runner failure ──────────────────────────────────────────────

@test "dispatch: exits 1 and returns escalation envelope when runner fails" {
  # Override runner to fail
  cat > "$PARLEI_TEST_ROOT/shared/tools/agent_runner.sh" << 'FAIL_STUB'
#!/usr/bin/env bash
echo "runner crashed" >&2
exit 1
FAIL_STUB
  chmod +x "$PARLEI_TEST_ROOT/shared/tools/agent_runner.sh"

  run bash "$PARLEI_TEST_ROOT/shared/tools/dispatch.sh" speaker "$PARLEI_TEST_ROOT/request.json"
  [ "$status" -eq 1 ]
  python3 -c "import json,sys; d=json.loads(sys.argv[1]); assert d.get('type')=='escalation'" "$output"
}

@test "dispatch: escalation envelope contains request_id" {
  cat > "$PARLEI_TEST_ROOT/shared/tools/agent_runner.sh" << 'FAIL_STUB'
#!/usr/bin/env bash
exit 1
FAIL_STUB
  chmod +x "$PARLEI_TEST_ROOT/shared/tools/agent_runner.sh"

  run bash "$PARLEI_TEST_ROOT/shared/tools/dispatch.sh" speaker "$PARLEI_TEST_ROOT/request.json"
  [ "$status" -eq 1 ]
  python3 -c "import json,sys; d=json.loads(sys.argv[1]); assert d.get('request_id'), 'no request_id'" "$output"
}
