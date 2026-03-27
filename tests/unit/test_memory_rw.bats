#!/usr/bin/env bats
# Unit tests for memory read/write conventions and LLM interface (T-090, T-091)

load '../fixtures/setup'

REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"

setup() {
  parlei_setup_tmpdir
  parlei_create_shared_skeleton "$PARLEI_TEST_ROOT"
  cp "$REPO_ROOT/shared/tools/llm_call.sh" "$PARLEI_TEST_ROOT/shared/tools/llm_call.sh"
  chmod +x "$PARLEI_TEST_ROOT/shared/tools/llm_call.sh"
}

teardown() {
  parlei_stop_mock_llm 2>/dev/null || true
  parlei_teardown_tmpdir
}

# ── T-090: Memory read/write conventions ──────────────────────────────────────

@test "memory: agent can write an episodic log to its own directory" {
  EPISODIC_FILE="$PARLEI_TEST_ROOT/shared/memory/speaker/episodic/2026-03-27.md"
  echo "# Session Log 2026-03-27" > "$EPISODIC_FILE"
  echo "- Received task from Spirit" >> "$EPISODIC_FILE"
  echo "- Delegated to Plan-er" >> "$EPISODIC_FILE"

  assert_file_nonempty "$EPISODIC_FILE"
}

@test "memory: episodic log is valid Markdown (starts with # heading)" {
  EPISODIC_FILE="$PARLEI_TEST_ROOT/shared/memory/tasker/episodic/2026-03-27.md"
  echo "# Session 2026-03-27" > "$EPISODIC_FILE"
  echo "- Task T-001 delegated" >> "$EPISODIC_FILE"

  run head -1 "$EPISODIC_FILE"
  [[ "$output" == "# "* ]]
}

@test "memory: episodic log contains no YAML frontmatter" {
  EPISODIC_FILE="$PARLEI_TEST_ROOT/shared/memory/planer/episodic/2026-03-27.md"
  cat > "$EPISODIC_FILE" << 'EOF'
# Planning Session 2026-03-27

Updated PLAN.md with Feature Area 3 details.

```json
{"decision": "add area 3", "reason": "missing from original plan"}
```
EOF

  assert_no_yaml "$EPISODIC_FILE"
}

@test "memory: long_term.md can be written and read for correct agent" {
  LT="$PARLEI_TEST_ROOT/shared/memory/checker/long_term.md"
  echo "# Checker Long-Term Memory" > "$LT"
  echo "Scope: completeness only." >> "$LT"

  run grep "completeness" "$LT"
  [ "$status" -eq 0 ]
}

@test "memory: agent directory structure has episodic/ subdir" {
  for agent in speaker planer tasker prompter checker reviewer architecter deployer tester reoriginator; do
    [ -d "$PARLEI_TEST_ROOT/shared/memory/$agent/episodic" ] || {
      echo "Missing episodic/ for $agent"
      return 1
    }
  done
}

# ── T-091: LLM interface module ───────────────────────────────────────────────

@test "llm_call: exits 1 with no arguments" {
  run bash "$PARLEI_TEST_ROOT/shared/tools/llm_call.sh"
  [ "$status" -ne 0 ]
}

@test "llm_call: exits 1 when endpoint is empty string" {
  run bash "$PARLEI_TEST_ROOT/shared/tools/llm_call.sh" "" "some-model" "test prompt"
  [ "$status" -ne 0 ]
  [[ "$output" == *"not configured"* ]]
}

@test "llm_call: exits 1 when model is empty string" {
  run bash "$PARLEI_TEST_ROOT/shared/tools/llm_call.sh" "http://localhost:9999" "" "test prompt"
  [ "$status" -ne 0 ]
  [[ "$output" == *"not configured"* ]]
}

@test "llm_call: returns response text from mock LLM endpoint" {
  parlei_start_mock_llm "Test response from mock"
  run bash "$PARLEI_TEST_ROOT/shared/tools/llm_call.sh" \
    "http://127.0.0.1:$MOCK_LLM_PORT/v1/chat/completions" \
    "test-model" \
    "Hello"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Test response from mock"* ]]
}

@test "llm_call: exits non-zero when endpoint is unreachable" {
  run bash "$PARLEI_TEST_ROOT/shared/tools/llm_call.sh" \
    "http://127.0.0.1:19999/v1/chat/completions" \
    "test-model" \
    "Hello"
  [ "$status" -ne 0 ]
}
