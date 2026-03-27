#!/usr/bin/env bats
# Integration tests for current_task.md resilience (T-117, T-118)

load '../fixtures/setup'

REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
TODAY="$(date '+%Y-%m-%d')"

setup() {
  parlei_setup_tmpdir
  parlei_create_shared_skeleton "$PARLEI_TEST_ROOT"
  cp "$REPO_ROOT/shared/tools/current_task.sh" "$PARLEI_TEST_ROOT/shared/tools/current_task.sh"
  chmod +x "$PARLEI_TEST_ROOT/shared/tools/current_task.sh"
}

teardown() {
  parlei_teardown_tmpdir
}

run_ct() {
  bash "$PARLEI_TEST_ROOT/shared/tools/current_task.sh" "$@"
}

# ── T-117: Mid-task interruption and resume ────────────────────────────────────

@test "resilience: 5-task job interrupted at task 2 resumes correctly at task 3" {
  # Start a 5-task job
  run_ct write planer "req-planer-20260327-100" "speaker" \
    "Task 1 - read request" \
    "Task 2 - load context" \
    "Task 3 - perform work" \
    "Task 4 - write output" \
    "Task 5 - send response"

  # Complete tasks 1 and 2
  run_ct checkoff planer 1
  run_ct checkoff planer 2

  # "Session killed" — we simply don't checkoff further. Now simulate restart.

  # Resume check should find the file
  run bash "$PARLEI_TEST_ROOT/shared/tools/current_task.sh" check planer
  [ "$status" -eq 1 ]
  [[ "$output" == *"RESUME=true"* ]]

  # Verify task 1 and 2 are already checked
  TASK_FILE="$PARLEI_TEST_ROOT/shared/memory/planer/current_task.md"
  CHECKED="$(grep -c '^- \[x\]' "$TASK_FILE")"
  [ "$CHECKED" -eq 2 ]

  UNCHECKED="$(grep -c '^- \[ \]' "$TASK_FILE")"
  [ "$UNCHECKED" -eq 3 ]
}

@test "resilience: completing remaining tasks after interrupt archives correctly" {
  run_ct write tasker "req-tasker-20260327-101" "speaker" \
    "Task A" "Task B" "Task C" "Task D" "Task E"

  # First session: complete A and B
  run_ct checkoff tasker 1
  run_ct checkoff tasker 2

  # "Interruption" — resume check
  run bash "$PARLEI_TEST_ROOT/shared/tools/current_task.sh" check tasker
  [ "$status" -eq 1 ]

  # Second session: complete C, D, E
  run_ct checkoff tasker 3
  run_ct checkoff tasker 4
  run_ct checkoff tasker 5

  # Now complete
  run_ct complete tasker

  # Active path gone
  [ ! -f "$PARLEI_TEST_ROOT/shared/memory/tasker/current_task.md" ]

  # Archived file exists
  [ -f "$PARLEI_TEST_ROOT/shared/memory/tasker/episodic/${TODAY}-req-tasker-20260327-101.md" ]

  # Archived file shows all 5 checked
  CHECKED="$(grep -c '^- \[x\]' "$PARLEI_TEST_ROOT/shared/memory/tasker/episodic/${TODAY}-req-tasker-20260327-101.md")"
  [ "$CHECKED" -eq 5 ]
}

@test "resilience: tasks completed before interruption are not repeated after resume" {
  run_ct write checker "req-checker-20260327-102" "speaker" \
    "Verify feature A" "Verify feature B" "Verify feature C"

  run_ct checkoff checker 1

  # Count checked before "interrupt"
  CHECKED_BEFORE="$(grep -c '^- \[x\]' "$PARLEI_TEST_ROOT/shared/memory/checker/current_task.md")"

  # Simulate restart — check finds in-progress
  run bash "$PARLEI_TEST_ROOT/shared/tools/current_task.sh" check checker
  [ "$status" -eq 1 ]

  # Checked count must still be 1 (not reset)
  CHECKED_AFTER="$(grep -c '^- \[x\]' "$PARLEI_TEST_ROOT/shared/memory/checker/current_task.md")"
  [ "$CHECKED_BEFORE" -eq "$CHECKED_AFTER" ]
}

# ── T-118: Unresolvable resume triggers escalation ────────────────────────────

@test "resilience: unresolvable resume — task file remains at active path" {
  run_ct write reviewer "req-reviewer-20260327-103" "speaker" \
    "Step 1" "Step 2" "Step 3" "Step 4" "Step 5"

  run_ct checkoff reviewer 1
  run_ct checkoff reviewer 2

  # Agent detects in-progress
  run bash "$PARLEI_TEST_ROOT/shared/tools/current_task.sh" check reviewer
  [ "$status" -eq 1 ]

  # Simulate: agent cannot complete (e.g., source file missing)
  # The protocol says: do NOT delete current_task.md during escalation
  # The file must still be at active path
  [ -f "$PARLEI_TEST_ROOT/shared/memory/reviewer/current_task.md" ]

  # Read the task contents to confirm they can be embedded in an escalation message
  run bash "$PARLEI_TEST_ROOT/shared/tools/current_task.sh" read reviewer
  [ "$status" -eq 0 ]
  [[ "$output" == *"req-reviewer-20260327-103"* ]]
}

@test "resilience: backup skips in-progress current_task.md" {
  cp "$REPO_ROOT/scripts/backup.sh" "$PARLEI_TEST_ROOT/scripts/backup.sh"
  chmod +x "$PARLEI_TEST_ROOT/scripts/backup.sh"

  # Create an in-progress current_task.md
  run_ct write speaker "req-speaker-20260327-200" "spirit" "Interrupted task"

  # Create a completed (archived) task file for contrast
  mkdir -p "$PARLEI_TEST_ROOT/shared/memory/planer/episodic"
  echo "# Completed task" > "$PARLEI_TEST_ROOT/shared/memory/planer/episodic/${TODAY}-req-planer-001.md"

  bash "$PARLEI_TEST_ROOT/scripts/backup.sh"

  ARCHIVE="$PARLEI_TEST_ROOT/backups/${TODAY}.tar.gz"
  [ -f "$ARCHIVE" ]

  # Check archive contents
  ARCHIVE_CONTENTS="$(tar -tzf "$ARCHIVE")"

  # In-progress current_task.md should NOT be in the archive
  ! echo "$ARCHIVE_CONTENTS" | grep -q "speaker/current_task.md"

  # Completed episodic file SHOULD be in the archive
  echo "$ARCHIVE_CONTENTS" | grep -q "planer/episodic/${TODAY}-req-planer-001.md"
}
