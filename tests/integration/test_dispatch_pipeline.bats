#!/usr/bin/env bats
# Integration tests for the full dispatch pipeline (FIX-027, FIX-028)
# dispatch.sh → agent_runner.sh → build_system_prompt.sh → stub LLM
# Also validates model routing is used correctly.

load '../fixtures/setup'

REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"

# Canned valid response the stub LLM will return
CANNED_JSON='{"from":"checker","to":"speaker","request_id":"req-speaker-20260329-001","items":[{"id":1,"status":"confirmed","notes":"integration test stub"}]}'

setup() {
  parlei_setup_tmpdir
  parlei_create_shared_skeleton "$PARLEI_TEST_ROOT"

  # Copy all dispatch pipeline scripts
  for s in dispatch.sh agent_runner.sh build_system_prompt.sh request_id.sh; do
    cp "$REPO_ROOT/shared/tools/$s" "$PARLEI_TEST_ROOT/shared/tools/$s"
    chmod +x "$PARLEI_TEST_ROOT/shared/tools/$s"
  done
  for f in model_routing.json schema_request.json schema_response.json; do
    cp "$REPO_ROOT/shared/tools/$f" "$PARLEI_TEST_ROOT/shared/tools/$f"
  done
  cp "$REPO_ROOT/shared/tools/protocol.md"          "$PARLEI_TEST_ROOT/shared/tools/protocol.md"
  cp "$REPO_ROOT/shared/tools/current_task_spec.md"  "$PARLEI_TEST_ROOT/shared/tools/current_task_spec.md"

  # Create minimal agent files for all agents dispatch.sh might need
  for agent in speaker checker tasker planer prompter reviewer architecter deployer tester reoriginator; do
    echo "# ${agent} role" > "$PARLEI_TEST_ROOT/shared/agents/${agent}.md"
    echo "# ${agent} personality" > "$PARLEI_TEST_ROOT/shared/personalities/${agent}.md"
    echo "# ${agent} identity" > "$PARLEI_TEST_ROOT/shared/memory/${agent}/identity.md"
    echo "# ${agent} long term" > "$PARLEI_TEST_ROOT/shared/memory/${agent}/long_term.md"
  done

  # Create a stub "claude" on PATH that records which model it was called with
  STUB_BIN="$(mktemp -d)"
  export STUB_BIN
  cat > "$STUB_BIN/claude" << STUB_EOF
#!/usr/bin/env bash
# Consume stdin; log model flag; return canned JSON
cat > /dev/null
# Record model passed via --model flag
for i in "\$@"; do
  if [[ "\${prev:-}" == "--model" ]]; then
    echo "\$i" > "$STUB_BIN/last_model"
  fi
  prev="\$i"
done
echo '$CANNED_JSON'
STUB_EOF
  chmod +x "$STUB_BIN/claude"
  export PATH="$STUB_BIN:$PATH"

  echo "claude" > "$PARLEI_TEST_ROOT/.parlei-env"

  # Write a valid request file
  python3 -c "
import json
req = {
  'from': 'speaker',
  'to': 'checker',
  'request_id': 'req-speaker-20260329-001',
  'items': [{'id': 1, 'type': 'verify', 'description': 'Integration pipeline test'}]
}
print(json.dumps(req))
" > "$PARLEI_TEST_ROOT/request.json"
}

teardown() {
  rm -rf "${STUB_BIN:-}"
  parlei_teardown_tmpdir
}

# ── End-to-end pipeline ───────────────────────────────────────────────────────

@test "dispatch pipeline: full dispatch.sh → agent_runner.sh → stub LLM succeeds" {
  run bash "$PARLEI_TEST_ROOT/shared/tools/dispatch.sh" checker "$PARLEI_TEST_ROOT/request.json"
  [ "$status" -eq 0 ]
}

@test "dispatch pipeline: response is valid JSON" {
  run bash "$PARLEI_TEST_ROOT/shared/tools/dispatch.sh" checker "$PARLEI_TEST_ROOT/request.json"
  [ "$status" -eq 0 ]
  python3 -c "import json,sys; json.loads(sys.argv[1])" "$output"
}

@test "dispatch pipeline: response items array is present and non-empty" {
  run bash "$PARLEI_TEST_ROOT/shared/tools/dispatch.sh" checker "$PARLEI_TEST_ROOT/request.json"
  [ "$status" -eq 0 ]
  python3 -c "
import json,sys
d = json.loads(sys.argv[1])
assert 'items' in d and len(d['items']) > 0
" "$output"
}

@test "dispatch pipeline: outbox file is written after successful dispatch" {
  bash "$PARLEI_TEST_ROOT/shared/tools/dispatch.sh" checker "$PARLEI_TEST_ROOT/request.json" > /dev/null
  ls "$PARLEI_TEST_ROOT/shared/memory/checker/outbox/"*.json
}

@test "dispatch pipeline: inbox file is cleaned up after successful dispatch" {
  bash "$PARLEI_TEST_ROOT/shared/tools/dispatch.sh" checker "$PARLEI_TEST_ROOT/request.json" > /dev/null
  INBOX_COUNT="$(ls "$PARLEI_TEST_ROOT/shared/memory/checker/inbox/"*.json 2>/dev/null | wc -l | tr -d ' ')"
  [ "$INBOX_COUNT" -eq 0 ]
}

# ── Model routing integration ─────────────────────────────────────────────────

@test "dispatch pipeline (FIX-028): checker dispatch uses haiku model" {
  bash "$PARLEI_TEST_ROOT/shared/tools/dispatch.sh" checker "$PARLEI_TEST_ROOT/request.json" > /dev/null
  USED_MODEL="$(cat "$STUB_BIN/last_model" 2>/dev/null || echo '')"
  [[ "$USED_MODEL" == *"haiku"* ]]
}

@test "dispatch pipeline (FIX-028): reviewer dispatch uses opus model" {
  python3 -c "
import json
req = {
  'from': 'speaker',
  'to': 'reviewer',
  'request_id': 'req-speaker-20260329-002',
  'items': [{'id': 1, 'type': 'review', 'description': 'Review test'}]
}
print(json.dumps(req))
" > "$PARLEI_TEST_ROOT/review_req.json"

  bash "$PARLEI_TEST_ROOT/shared/tools/dispatch.sh" reviewer "$PARLEI_TEST_ROOT/review_req.json" > /dev/null
  USED_MODEL="$(cat "$STUB_BIN/last_model" 2>/dev/null || echo '')"
  [[ "$USED_MODEL" == *"opus"* ]]
}

@test "dispatch pipeline (FIX-028): tasker dispatch uses sonnet model" {
  python3 -c "
import json
req = {
  'from': 'speaker',
  'to': 'tasker',
  'request_id': 'req-speaker-20260329-003',
  'items': [{'id': 1, 'type': 'task', 'description': 'Task routing test'}]
}
print(json.dumps(req))
" > "$PARLEI_TEST_ROOT/task_req.json"

  bash "$PARLEI_TEST_ROOT/shared/tools/dispatch.sh" tasker "$PARLEI_TEST_ROOT/task_req.json" > /dev/null
  USED_MODEL="$(cat "$STUB_BIN/last_model" 2>/dev/null || echo '')"
  [[ "$USED_MODEL" == *"sonnet"* ]]
}

# ── System prompt assembly ────────────────────────────────────────────────────

@test "dispatch pipeline: build_system_prompt includes agent role content" {
  PROMPT="$(bash "$PARLEI_TEST_ROOT/shared/tools/build_system_prompt.sh" checker)"
  [[ "$PROMPT" == *"checker role"* ]]
}

@test "dispatch pipeline: build_system_prompt includes protocol section" {
  PROMPT="$(bash "$PARLEI_TEST_ROOT/shared/tools/build_system_prompt.sh" checker)"
  [[ "$PROMPT" == *"## Communication Protocol"* ]]
}
