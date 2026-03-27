#!/usr/bin/env bats
# Unit tests for shared/tools/current_task.sh (T-113, T-114, T-115, T-116)

load '../fixtures/setup'

REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
TODAY="$(date '+%Y-%m-%d')"

setup() {
  parlei_setup_tmpdir
  parlei_create_shared_skeleton "$PARLEI_TEST_ROOT"
  cp "$REPO_ROOT/shared/tools/current_task.sh" "$PARLEI_TEST_ROOT/shared/tools/current_task.sh"
  chmod +x "$PARLEI_TEST_ROOT/shared/tools/current_task.sh"

  # Override MEMORY_ROOT used by current_task.sh via symlink trick
  # The script uses SCRIPT_DIR/../../shared/memory — so we put it in the right place
  TASK_TOOL="$PARLEI_TEST_ROOT/shared/tools/current_task.sh"
}

teardown() {
  parlei_teardown_tmpdir
}

run_ct() {
  bash "$PARLEI_TEST_ROOT/shared/tools/current_task.sh" "$@"
}

# ── T-113: Write behavior ──────────────────────────────────────────────────────

@test "current_task write: file is created at correct path" {
  run_ct write speaker "req-speaker-20260327-001" "spirit" \
    "Parse request" "Load context" "Do work" "Send response"
  [ -f "$PARLEI_TEST_ROOT/shared/memory/speaker/current_task.md" ]
}

@test "current_task write: all subtasks start unchecked" {
  run_ct write planer "req-planer-20260327-001" "speaker" \
    "Read plan" "Find gaps" "Write update"
  CHECKED="$(grep -c '^- \[x\]' "$PARLEI_TEST_ROOT/shared/memory/planer/current_task.md" || true)"
  [ "$CHECKED" -eq 0 ]
  UNCHECKED="$(grep -c '^- \[ \]' "$PARLEI_TEST_ROOT/shared/memory/planer/current_task.md")"
  [ "$UNCHECKED" -eq 3 ]
}

@test "current_task write: file contains request ID" {
  run_ct write tasker "req-tasker-20260327-005" "speaker" "Do something"
  run grep "req-tasker-20260327-005" "$PARLEI_TEST_ROOT/shared/memory/tasker/current_task.md"
  [ "$status" -eq 0 ]
}

@test "current_task write: file contains no YAML" {
  run_ct write checker "req-checker-20260327-001" "speaker" "Verify task"
  assert_no_yaml "$PARLEI_TEST_ROOT/shared/memory/checker/current_task.md"
}

@test "current_task write: exits non-zero with no subtasks" {
  run bash "$PARLEI_TEST_ROOT/shared/tools/current_task.sh" write speaker "req-speaker-20260327-002" "spirit"
  [ "$status" -ne 0 ]
}

# ── T-114: Checkoff behavior ──────────────────────────────────────────────────

@test "current_task checkoff: marks exactly the specified subtask" {
  run_ct write reviewer "req-reviewer-20260327-001" "speaker" \
    "Step 1" "Step 2" "Step 3" "Step 4"
  run_ct checkoff reviewer 2
  TASK_FILE="$PARLEI_TEST_ROOT/shared/memory/reviewer/current_task.md"
  run python3 -c "
lines = open('$TASK_FILE').readlines()
subtasks = [l for l in lines if l.startswith('- [')]
assert subtasks[0].startswith('- [ ]'), 'Step 1 should be unchecked'
assert subtasks[1].startswith('- [x]'), 'Step 2 should be checked'
assert subtasks[2].startswith('- [ ]'), 'Step 3 should be unchecked'
assert subtasks[3].startswith('- [ ]'), 'Step 4 should be unchecked'
print('ok')
"
  [ "$status" -eq 0 ]
  [[ "$output" == "ok" ]]
}

@test "current_task checkoff: is idempotent (double-check does not duplicate)" {
  run_ct write deployer "req-deployer-20260327-001" "speaker" "Task A" "Task B"
  run_ct checkoff deployer 1
  run_ct checkoff deployer 1
  CHECKED="$(grep -c '^- \[x\]' "$PARLEI_TEST_ROOT/shared/memory/deployer/current_task.md")"
  [ "$CHECKED" -eq 1 ]
}

@test "current_task checkoff: out-of-range index exits non-zero without modifying file" {
  run_ct write prompter "req-prompter-20260327-001" "speaker" "Only task"
  BEFORE="$(cat "$PARLEI_TEST_ROOT/shared/memory/prompter/current_task.md")"
  run bash "$PARLEI_TEST_ROOT/shared/tools/current_task.sh" checkoff prompter 5
  [ "$status" -ne 0 ]
  AFTER="$(cat "$PARLEI_TEST_ROOT/shared/memory/prompter/current_task.md")"
  [ "$BEFORE" = "$AFTER" ]
}

@test "current_task checkoff: all subtasks checked when all are checked off" {
  run_ct write tester "req-tester-20260327-001" "speaker" "T1" "T2" "T3"
  for i in 1 2 3; do run_ct checkoff tester $i; done
  UNCHECKED="$(grep -c '^- \[ \]' "$PARLEI_TEST_ROOT/shared/memory/tester/current_task.md" || true)"
  [ "$UNCHECKED" -eq 0 ]
}

# ── T-115: Startup resume detection ──────────────────────────────────────────

@test "current_task check: returns exit 0 when no file exists" {
  run bash "$PARLEI_TEST_ROOT/shared/tools/current_task.sh" check architecter
  [ "$status" -eq 0 ]
}

@test "current_task check: returns exit 1 and RESUME=true when in-progress file exists" {
  run_ct write speaker "req-speaker-20260327-010" "spirit" "S1" "S2" "S3"
  run bash "$PARLEI_TEST_ROOT/shared/tools/current_task.sh" check speaker
  [ "$status" -eq 1 ]
  [[ "$output" == *"RESUME=true"* ]]
  [[ "$output" == *"req-speaker-20260327-010"* ]]
}

@test "current_task check: identifies correct resume subtask line" {
  run_ct write planer "req-planer-20260327-020" "speaker" "P1" "P2" "P3"
  run_ct checkoff planer 1
  run bash "$PARLEI_TEST_ROOT/shared/tools/current_task.sh" check planer
  [ "$status" -eq 1 ]
  [[ "$output" == *"RESUME_SUBTASK_LINE="* ]]
}

@test "current_task check: returns exit 0 when completed file is present (edge case)" {
  run_ct write tasker "req-tasker-20260327-030" "speaker" "T1"
  run_ct checkoff tasker 1
  run_ct complete tasker
  # After completion, file is in episodic/ — not at active path
  run bash "$PARLEI_TEST_ROOT/shared/tools/current_task.sh" check tasker
  [ "$status" -eq 0 ]
}

# ── T-116: Completion archival ────────────────────────────────────────────────

@test "current_task complete: archives file to episodic/ with correct name" {
  run_ct write checker "req-checker-20260327-040" "speaker" "C1" "C2"
  run_ct checkoff checker 1
  run_ct checkoff checker 2
  run_ct complete checker

  EPISODIC_FILE="$PARLEI_TEST_ROOT/shared/memory/checker/episodic/${TODAY}-req-checker-20260327-040.md"
  [ -f "$EPISODIC_FILE" ]
}

@test "current_task complete: active path no longer exists after archival" {
  run_ct write reviewer "req-reviewer-20260327-050" "speaker" "R1"
  run_ct checkoff reviewer 1
  run_ct complete reviewer
  [ ! -f "$PARLEI_TEST_ROOT/shared/memory/reviewer/current_task.md" ]
}

@test "current_task complete: exits non-zero if unchecked subtasks remain" {
  run_ct write deployer "req-deployer-20260327-060" "speaker" "D1" "D2"
  run_ct checkoff deployer 1
  run bash "$PARLEI_TEST_ROOT/shared/tools/current_task.sh" complete deployer
  [ "$status" -ne 0 ]
  # File should still be at active path (not moved)
  [ -f "$PARLEI_TEST_ROOT/shared/memory/deployer/current_task.md" ]
}
