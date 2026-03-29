#!/usr/bin/env bats
# Unit tests for shared/tools/build_system_prompt.sh (FIX-023)

load '../fixtures/setup'

REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"

setup() {
  parlei_setup_tmpdir
  parlei_create_shared_skeleton "$PARLEI_TEST_ROOT"

  # Copy the script under test
  cp "$REPO_ROOT/shared/tools/build_system_prompt.sh" \
     "$PARLEI_TEST_ROOT/shared/tools/build_system_prompt.sh"
  chmod +x "$PARLEI_TEST_ROOT/shared/tools/build_system_prompt.sh"

  # Copy protocol and task spec (referenced by the script)
  cp "$REPO_ROOT/shared/tools/protocol.md"         "$PARLEI_TEST_ROOT/shared/tools/protocol.md"
  cp "$REPO_ROOT/shared/tools/current_task_spec.md" "$PARLEI_TEST_ROOT/shared/tools/current_task_spec.md"

  # Create minimal speaker files
  echo "# Speaker Role" > "$PARLEI_TEST_ROOT/shared/agents/speaker.md"
  echo "# Speaker Personality" > "$PARLEI_TEST_ROOT/shared/personalities/speaker.md"
  echo "# Speaker Identity" > "$PARLEI_TEST_ROOT/shared/memory/speaker/identity.md"
  echo "# Speaker Long Term" > "$PARLEI_TEST_ROOT/shared/memory/speaker/long_term.md"
}

teardown() {
  parlei_teardown_tmpdir
}

# ── Argument validation ───────────────────────────────────────────────────────

@test "build_system_prompt: exits 1 with no arguments" {
  run bash "$PARLEI_TEST_ROOT/shared/tools/build_system_prompt.sh"
  [ "$status" -eq 1 ]
}

@test "build_system_prompt: exits 1 for unknown agent (no memory dir)" {
  run bash "$PARLEI_TEST_ROOT/shared/tools/build_system_prompt.sh" ghostagent
  [ "$status" -eq 1 ]
  [[ "$output" == *"not found"* ]]
}

# ── Output structure ──────────────────────────────────────────────────────────

@test "build_system_prompt: output contains Role section header" {
  run bash "$PARLEI_TEST_ROOT/shared/tools/build_system_prompt.sh" speaker
  [ "$status" -eq 0 ]
  [[ "$output" == *"## Role"* ]]
}

@test "build_system_prompt: output contains Personality section header" {
  run bash "$PARLEI_TEST_ROOT/shared/tools/build_system_prompt.sh" speaker
  [ "$status" -eq 0 ]
  [[ "$output" == *"## Personality"* ]]
}

@test "build_system_prompt: output contains Communication Protocol section" {
  run bash "$PARLEI_TEST_ROOT/shared/tools/build_system_prompt.sh" speaker
  [ "$status" -eq 0 ]
  [[ "$output" == *"## Communication Protocol"* ]]
}

@test "build_system_prompt: output contains Task Tracking section" {
  run bash "$PARLEI_TEST_ROOT/shared/tools/build_system_prompt.sh" speaker
  [ "$status" -eq 0 ]
  [[ "$output" == *"## Task Tracking"* ]]
}

@test "build_system_prompt: output includes content from agent role file" {
  run bash "$PARLEI_TEST_ROOT/shared/tools/build_system_prompt.sh" speaker
  [ "$status" -eq 0 ]
  [[ "$output" == *"Speaker Role"* ]]
}

@test "build_system_prompt: output includes content from identity file" {
  run bash "$PARLEI_TEST_ROOT/shared/tools/build_system_prompt.sh" speaker
  [ "$status" -eq 0 ]
  [[ "$output" == *"Speaker Identity"* ]]
}

@test "build_system_prompt: output contains Identity section header" {
  run bash "$PARLEI_TEST_ROOT/shared/tools/build_system_prompt.sh" speaker
  [ "$status" -eq 0 ]
  [[ "$output" == *"## Identity"* ]]
}

@test "build_system_prompt: output contains Long-Term Memory section header and content" {
  run bash "$PARLEI_TEST_ROOT/shared/tools/build_system_prompt.sh" speaker
  [ "$status" -eq 0 ]
  [[ "$output" == *"## Long-Term Memory"* ]]
  [[ "$output" == *"Speaker Long Term"* ]]
}

@test "build_system_prompt: produces non-empty output for every known agent" {
  agents=(speaker planer tasker prompter checker reviewer architecter deployer tester reoriginator)
  for agent in "${agents[@]}"; do
    mkdir -p "$PARLEI_TEST_ROOT/shared/personalities"
    echo "# ${agent} Role" > "$PARLEI_TEST_ROOT/shared/agents/${agent}.md"
    echo "# ${agent} Personality" > "$PARLEI_TEST_ROOT/shared/personalities/${agent}.md"
    mkdir -p "$PARLEI_TEST_ROOT/shared/memory/${agent}"
    echo "# ${agent} Identity" > "$PARLEI_TEST_ROOT/shared/memory/${agent}/identity.md"
    echo "# ${agent} Long Term" > "$PARLEI_TEST_ROOT/shared/memory/${agent}/long_term.md"
    run bash "$PARLEI_TEST_ROOT/shared/tools/build_system_prompt.sh" "$agent"
    [ "$status" -eq 0 ]
    [[ -n "$output" ]]
  done
}

# ── Missing file handling ─────────────────────────────────────────────────────

@test "build_system_prompt: still succeeds when personality file is missing" {
  rm -f "$PARLEI_TEST_ROOT/shared/personalities/speaker.md"
  run bash "$PARLEI_TEST_ROOT/shared/tools/build_system_prompt.sh" speaker
  [ "$status" -eq 0 ]
}

@test "build_system_prompt: warns to stderr when a source file is missing" {
  rm -f "$PARLEI_TEST_ROOT/shared/personalities/speaker.md"
  run bash "$PARLEI_TEST_ROOT/shared/tools/build_system_prompt.sh" speaker
  [ "$status" -eq 0 ]
  # Warnings go to stderr — check stderr via $output when 2>&1 is not used
  # (bats captures combined output by default with run — check for Warning text)
  # Re-run capturing stderr explicitly
  STDERR_OUT="$(bash "$PARLEI_TEST_ROOT/shared/tools/build_system_prompt.sh" speaker 2>&1 >/dev/null)"
  [[ "$STDERR_OUT" == *"Warning"* ]]
}

@test "build_system_prompt: output is non-empty for a fully populated agent" {
  run bash "$PARLEI_TEST_ROOT/shared/tools/build_system_prompt.sh" speaker
  [ "$status" -eq 0 ]
  [[ -n "$output" ]]
}
