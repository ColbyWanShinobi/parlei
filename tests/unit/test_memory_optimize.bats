#!/usr/bin/env bats
# Unit tests for scripts/memory_optimize.sh (T-078, T-079, T-080, T-081)

load '../fixtures/setup'

REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"

setup() {
  parlei_setup_tmpdir
  parlei_create_shared_skeleton "$PARLEI_TEST_ROOT"

  # Write a config with small retention values for testing
  cat > "$PARLEI_TEST_ROOT/shared/tools/memory_config.json" << 'EOF'
{
  "llm_endpoint": "",
  "llm_model": "",
  "llm_auth_token": "",
  "episodic_retention_days": 30,
  "promotion_threshold": 3,
  "backup_retention_count": 5,
  "llm_timeout_seconds": 2,
  "compression": "gzip"
}
EOF

  cp "$REPO_ROOT/scripts/memory_optimize.sh" "$PARLEI_TEST_ROOT/scripts/memory_optimize.sh"
  cp "$REPO_ROOT/shared/tools/llm_call.sh" "$PARLEI_TEST_ROOT/shared/tools/llm_call.sh"
  chmod +x "$PARLEI_TEST_ROOT/scripts/memory_optimize.sh" \
            "$PARLEI_TEST_ROOT/shared/tools/llm_call.sh"
}

teardown() {
  parlei_teardown_tmpdir
}

# Helper: write a dated episodic file for an agent
write_episodic() {
  local agent="$1" date="$2" content="$3"
  echo "$content" > "$PARLEI_TEST_ROOT/shared/memory/$agent/episodic/${date}.md"
}

# ── T-078: Deduplication ──────────────────────────────────────────────────────

@test "memory_optimize: duplicate lines across episodic files are removed" {
  write_episodic "speaker" "2026-03-25" "Unique line A
Duplicate line"
  write_episodic "speaker" "2026-03-26" "Unique line B
Duplicate line"

  bash "$PARLEI_TEST_ROOT/scripts/memory_optimize.sh"

  COMBINED="$(cat "$PARLEI_TEST_ROOT/shared/memory/speaker/episodic/"*.md)"
  COUNT="$(echo "$COMBINED" | grep -c "Duplicate line" || true)"
  [ "$COUNT" -eq 1 ]
}

@test "memory_optimize: file with no duplicates is unchanged in content" {
  write_episodic "planer" "2026-03-25" "Only line alpha
Only line beta"

  bash "$PARLEI_TEST_ROOT/scripts/memory_optimize.sh"

  run cat "$PARLEI_TEST_ROOT/shared/memory/planer/episodic/2026-03-25.md"
  [[ "$output" == *"Only line alpha"* ]]
  [[ "$output" == *"Only line beta"* ]]
}

# ── T-079: Promotion logic ─────────────────────────────────────────────────────

@test "memory_optimize: entry in 2 files is NOT promoted (below threshold)" {
  touch "$PARLEI_TEST_ROOT/shared/memory/tasker/long_term.md"
  write_episodic "tasker" "2026-03-24" "Candidate line"
  write_episodic "tasker" "2026-03-25" "Candidate line"

  bash "$PARLEI_TEST_ROOT/scripts/memory_optimize.sh"

  run grep -c "Candidate line" "$PARLEI_TEST_ROOT/shared/memory/tasker/long_term.md" || true
  [ "$output" -eq 0 ]
}

@test "memory_optimize: entry in 3+ files IS promoted to long_term.md" {
  touch "$PARLEI_TEST_ROOT/shared/memory/tasker/long_term.md"
  write_episodic "tasker" "2026-03-23" "Promoted candidate"
  write_episodic "tasker" "2026-03-24" "Promoted candidate"
  write_episodic "tasker" "2026-03-25" "Promoted candidate"

  bash "$PARLEI_TEST_ROOT/scripts/memory_optimize.sh"

  run grep -c "Promoted candidate" "$PARLEI_TEST_ROOT/shared/memory/tasker/long_term.md"
  [ "$output" -eq 1 ]
}

@test "memory_optimize: already-promoted entry is not duplicated" {
  echo "Already here" > "$PARLEI_TEST_ROOT/shared/memory/checker/long_term.md"
  write_episodic "checker" "2026-03-23" "Already here"
  write_episodic "checker" "2026-03-24" "Already here"
  write_episodic "checker" "2026-03-25" "Already here"

  bash "$PARLEI_TEST_ROOT/scripts/memory_optimize.sh"

  run grep -c "Already here" "$PARLEI_TEST_ROOT/shared/memory/checker/long_term.md"
  [ "$output" -eq 1 ]
}

# ── T-080: Pruning ─────────────────────────────────────────────────────────────

@test "memory_optimize: file older than retention threshold is deleted" {
  # retention = 30 days; use a date clearly older than that
  write_episodic "reviewer" "2025-01-01" "Old content"

  bash "$PARLEI_TEST_ROOT/scripts/memory_optimize.sh"

  [ ! -f "$PARLEI_TEST_ROOT/shared/memory/reviewer/episodic/2025-01-01.md" ]
}

@test "memory_optimize: file within retention threshold is retained" {
  RECENT_DATE="$(date '+%Y-%m-%d')"
  write_episodic "reviewer" "$RECENT_DATE" "Recent content"

  bash "$PARLEI_TEST_ROOT/scripts/memory_optimize.sh"

  [ -f "$PARLEI_TEST_ROOT/shared/memory/reviewer/episodic/${RECENT_DATE}.md" ]
}

# ── T-081: Error logging ───────────────────────────────────────────────────────

@test "memory_optimize: exits 0 with no errors when all runs clean" {
  run bash "$PARLEI_TEST_ROOT/scripts/memory_optimize.sh"
  [ "$status" -eq 0 ]
}

@test "memory_optimize: optimize_log.md is appended after run" {
  bash "$PARLEI_TEST_ROOT/scripts/memory_optimize.sh"
  assert_file_nonempty "$PARLEI_TEST_ROOT/shared/memory/optimize_log.md"
}

@test "memory_optimize: error_log.md written when config is missing" {
  rm -f "$PARLEI_TEST_ROOT/shared/tools/memory_config.json"
  run bash "$PARLEI_TEST_ROOT/scripts/memory_optimize.sh"
  [ "$status" -ne 0 ]
  assert_file_nonempty "$PARLEI_TEST_ROOT/shared/memory/error_log.md"
}
