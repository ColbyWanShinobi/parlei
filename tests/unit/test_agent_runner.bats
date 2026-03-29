#!/usr/bin/env bats
# Unit tests for shared/tools/agent_runner.sh (FIX-024)
# Uses a stub "claude" command to avoid real LLM calls.

load '../fixtures/setup'

REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"

setup() {
  parlei_setup_tmpdir
  parlei_create_shared_skeleton "$PARLEI_TEST_ROOT"

  # Copy all tool scripts
  for s in agent_runner.sh build_system_prompt.sh llm_call.sh; do
    cp "$REPO_ROOT/shared/tools/$s" "$PARLEI_TEST_ROOT/shared/tools/$s"
  done
  for s in agent_runner.sh build_system_prompt.sh llm_call.sh; do
    chmod +x "$PARLEI_TEST_ROOT/shared/tools/$s"
  done
  cp "$REPO_ROOT/shared/tools/protocol.md"          "$PARLEI_TEST_ROOT/shared/tools/protocol.md"
  cp "$REPO_ROOT/shared/tools/current_task_spec.md"  "$PARLEI_TEST_ROOT/shared/tools/current_task_spec.md"

  # Minimal speaker agent files
  echo "# Speaker Role"  > "$PARLEI_TEST_ROOT/shared/agents/speaker.md"
  echo "# Personality"   > "$PARLEI_TEST_ROOT/shared/personalities/speaker.md"
  echo "# Identity"      > "$PARLEI_TEST_ROOT/shared/memory/speaker/identity.md"
  echo "# Long Term"     > "$PARLEI_TEST_ROOT/shared/memory/speaker/long_term.md"

  # Create a stub "claude" on PATH that returns canned valid JSON
  STUB_BIN="$(mktemp -d)"
  export STUB_BIN
  cat > "$STUB_BIN/claude" << 'STUB_EOF'
#!/usr/bin/env bash
# Consume all stdin; record --model flag; return a valid JSON response envelope
cat > /dev/null
for i in "$@"; do
  if [[ "${prev:-}" == "--model" ]]; then
    echo "$i" > "$STUB_BIN/last_model"
  fi
  prev="$i"
done
echo '{"from":"speaker","to":"tasker","request_id":"req-speaker-20260329-001","items":[{"id":1,"status":"confirmed","notes":"stub response"}]}'
STUB_EOF
  chmod +x "$STUB_BIN/claude"
  export PATH="$STUB_BIN:$PATH"

  # Set environment to claude
  echo "claude" > "$PARLEI_TEST_ROOT/.parlei-env"

  # Write a valid request file
  python3 -c "
import json
req = {
  'from': 'speaker',
  'to': 'speaker',
  'request_id': 'req-speaker-20260329-001',
  'items': [{'id': 1, 'type': 'test', 'description': 'Unit test request'}]
}
print(json.dumps(req))
" > "$PARLEI_TEST_ROOT/request.json"

  # Ensure the copied memory_config.json has an endpoint for codex/openclaw tests
  python3 - <<PY
import json, pathlib, os
path = pathlib.Path(os.environ["PARLEI_TEST_ROOT"]) / "shared/tools/memory_config.json"
data = json.loads(path.read_text())
data["llm_endpoint"] = "https://mock.llm"
path.write_text(json.dumps(data, indent=2))
PY
}

teardown() {
  rm -rf "${STUB_BIN:-}"
  parlei_teardown_tmpdir
}

# ── Argument validation ───────────────────────────────────────────────────────

@test "agent_runner: exits 1 with no arguments" {
  run bash "$PARLEI_TEST_ROOT/shared/tools/agent_runner.sh"
  [ "$status" -eq 1 ]
}

@test "agent_runner: exits 1 with only one argument" {
  run bash "$PARLEI_TEST_ROOT/shared/tools/agent_runner.sh" speaker
  [ "$status" -eq 1 ]
}

@test "agent_runner: exits 1 when request file does not exist" {
  run bash "$PARLEI_TEST_ROOT/shared/tools/agent_runner.sh" speaker /nonexistent/file.json
  [ "$status" -eq 1 ]
  [[ "$output" == *"not found"* ]]
}

@test "agent_runner: exits 1 when request file is not valid JSON" {
  echo "not json" > "$PARLEI_TEST_ROOT/bad_request.json"
  run bash "$PARLEI_TEST_ROOT/shared/tools/agent_runner.sh" speaker "$PARLEI_TEST_ROOT/bad_request.json"
  [ "$status" -eq 1 ]
  [[ "$output" == *"not valid JSON"* ]]
}

@test "agent_runner: exits 1 for agent not in model_routing.json" {
  run bash "$PARLEI_TEST_ROOT/shared/tools/agent_runner.sh" unknownagent "$PARLEI_TEST_ROOT/request.json"
  [ "$status" -eq 1 ]
}

# ── Successful dispatch ───────────────────────────────────────────────────────

@test "agent_runner: exits 0 and returns valid JSON for known agent" {
  run bash "$PARLEI_TEST_ROOT/shared/tools/agent_runner.sh" speaker "$PARLEI_TEST_ROOT/request.json"
  [ "$status" -eq 0 ]
  python3 -c "import json,sys; json.loads(sys.argv[1])" "$output"
}

@test "agent_runner: response contains expected items array" {
  run bash "$PARLEI_TEST_ROOT/shared/tools/agent_runner.sh" speaker "$PARLEI_TEST_ROOT/request.json"
  [ "$status" -eq 0 ]
  python3 -c "
import json,sys
d = json.loads(sys.argv[1])
assert 'items' in d, 'items key missing'
assert len(d['items']) > 0, 'items array empty'
" "$output"
}

@test "agent_runner: uses haiku model for speaker" {
  rm -f "$STUB_BIN/last_model"
  run bash "$PARLEI_TEST_ROOT/shared/tools/agent_runner.sh" speaker "$PARLEI_TEST_ROOT/request.json"
  [ "$status" -eq 0 ]
  [[ "$(cat "$STUB_BIN/last_model")" == *"haiku"* ]]
}

@test "agent_runner: uses sonnet model for tasker" {
  rm -f "$STUB_BIN/last_model"
  run bash "$PARLEI_TEST_ROOT/shared/tools/agent_runner.sh" tasker "$PARLEI_TEST_ROOT/request.json"
  [ "$status" -eq 0 ]
  [[ "$(cat "$STUB_BIN/last_model")" == *"sonnet"* ]]
}

@test "agent_runner: uses opus model for reviewer" {
  rm -f "$STUB_BIN/last_model"
  run bash "$PARLEI_TEST_ROOT/shared/tools/agent_runner.sh" reviewer "$PARLEI_TEST_ROOT/request.json"
  [ "$status" -eq 0 ]
  [[ "$(cat "$STUB_BIN/last_model")" == *"opus"* ]]
}

@test "agent_runner: openclaw environment uses openclaw CLI" {
  cat > "$STUB_BIN/openclaw" << 'OPENCLAW_EOF'
#!/usr/bin/env bash
cat > /dev/null
for i in "$@"; do
  if [[ "${prev:-}" == "--model" ]]; then
    echo "$i" > "$STUB_BIN/openclaw_model"
  fi
  prev="$i"
done
echo '{"from":"speaker","to":"checker","request_id":"req-speaker-20260329-001","items":[{"id":1,"status":"confirmed","notes":"openclaw stub"}]}'
OPENCLAW_EOF
  chmod +x "$STUB_BIN/openclaw"
  echo "openclaw" > "$PARLEI_TEST_ROOT/.parlei-env"

  run bash "$PARLEI_TEST_ROOT/shared/tools/agent_runner.sh" speaker "$PARLEI_TEST_ROOT/request.json"
  [ "$status" -eq 0 ]
  [[ "$(cat "$STUB_BIN/openclaw_model")" == *"haiku"* ]]

  rm -f "$PARLEI_TEST_ROOT/.parlei-env" "$STUB_BIN/openclaw_model" "$STUB_BIN/openclaw"
}

@test "agent_runner: codex environment uses llm_call.sh fallback" {
  cat > "$PARLEI_TEST_ROOT/shared/tools/llm_call.sh" <<'LLM_EOF'
#!/usr/bin/env bash
echo "$2" > "$PARLEI_TEST_ROOT/shared/tools/last_llm_call_model"
cat > /dev/null
echo '{"from":"speaker","to":"tasker","request_id":"req-speaker-20260329-001","items":[{"id":1,"status":"confirmed","notes":"llm_call stub"}]}'
LLM_EOF
  chmod +x "$PARLEI_TEST_ROOT/shared/tools/llm_call.sh"

  echo "codex" > "$PARLEI_TEST_ROOT/.parlei-env"

  run bash "$PARLEI_TEST_ROOT/shared/tools/agent_runner.sh" speaker "$PARLEI_TEST_ROOT/request.json"
  [ "$status" -eq 0 ]
  [[ "$(cat "$PARLEI_TEST_ROOT/shared/tools/last_llm_call_model")" == *"haiku"* ]]

  rm -f "$PARLEI_TEST_ROOT/.parlei-env" "$PARLEI_TEST_ROOT/shared/tools/last_llm_call_model"
  cp "$REPO_ROOT/shared/tools/llm_call.sh" "$PARLEI_TEST_ROOT/shared/tools/llm_call.sh"
  chmod +x "$PARLEI_TEST_ROOT/shared/tools/llm_call.sh"
}

# ── Error handling ────────────────────────────────────────────────────────────

@test "agent_runner: exits 1 when LLM returns non-JSON response" {
  # Override stub to return garbage
  cat > "$STUB_BIN/claude" << 'STUB_EOF'
#!/usr/bin/env bash
cat > /dev/null
echo "This is not JSON"
STUB_EOF
  chmod +x "$STUB_BIN/claude"

  run bash "$PARLEI_TEST_ROOT/shared/tools/agent_runner.sh" speaker "$PARLEI_TEST_ROOT/request.json"
  [ "$status" -eq 1 ]
  [[ "$output" == *"not valid JSON"* ]]
}

@test "agent_runner: exits 1 when LLM returns empty response" {
  # Override stub to return nothing
  cat > "$STUB_BIN/claude" << 'STUB_EOF'
#!/usr/bin/env bash
cat > /dev/null
echo ""
STUB_EOF
  chmod +x "$STUB_BIN/claude"

  run bash "$PARLEI_TEST_ROOT/shared/tools/agent_runner.sh" speaker "$PARLEI_TEST_ROOT/request.json"
  [ "$status" -eq 1 ]
  [[ "$output" == *"empty response"* ]]
}
