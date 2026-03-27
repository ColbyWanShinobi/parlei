#!/usr/bin/env bats
# Integration tests: memory optimize → backup pipeline, restore, Re-Origination safety gate
# Covers T-096, T-097, T-098, T-099

load '../fixtures/setup'

REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
TODAY="$(date '+%Y-%m-%d')"

setup() {
  parlei_setup_tmpdir
  parlei_create_shared_skeleton "$PARLEI_TEST_ROOT"

  cat > "$PARLEI_TEST_ROOT/shared/tools/memory_config.json" << 'EOF'
{
  "llm_endpoint": "",
  "llm_model": "",
  "llm_auth_token": "",
  "episodic_retention_days": 90,
  "promotion_threshold": 3,
  "backup_retention_count": 5,
  "llm_timeout_seconds": 2,
  "compression": "gzip"
}
EOF

  cp "$REPO_ROOT/scripts/memory_optimize.sh" "$PARLEI_TEST_ROOT/scripts/memory_optimize.sh"
  cp "$REPO_ROOT/scripts/backup.sh"          "$PARLEI_TEST_ROOT/scripts/backup.sh"
  cp "$REPO_ROOT/scripts/restore.sh"         "$PARLEI_TEST_ROOT/scripts/restore.sh"
  cp "$REPO_ROOT/shared/tools/llm_call.sh"   "$PARLEI_TEST_ROOT/shared/tools/llm_call.sh"
  chmod +x "$PARLEI_TEST_ROOT/scripts/"*.sh \
            "$PARLEI_TEST_ROOT/shared/tools/llm_call.sh"

  echo "# Speaker Identity" > "$PARLEI_TEST_ROOT/shared/memory/speaker/identity.md"
  echo "Test content" > "$PARLEI_TEST_ROOT/shared/memory/speaker/long_term.md"
}

teardown() {
  parlei_teardown_tmpdir
}

# ── T-096: Memory optimization full run ───────────────────────────────────────

@test "memory optimize: runs cleanly with no episodic files" {
  run bash "$PARLEI_TEST_ROOT/scripts/memory_optimize.sh"
  [ "$status" -eq 0 ]
}

@test "memory optimize: optimize_log.md is written after successful run" {
  bash "$PARLEI_TEST_ROOT/scripts/memory_optimize.sh"
  assert_file_nonempty "$PARLEI_TEST_ROOT/shared/memory/optimize_log.md"
}

@test "memory optimize: deduplication runs on multiple episodic files" {
  for d in 2026-03-24 2026-03-25 2026-03-26; do
    echo "Recurring fact about speaker" > "$PARLEI_TEST_ROOT/shared/memory/speaker/episodic/${d}.md"
    echo "Unique content for $d" >> "$PARLEI_TEST_ROOT/shared/memory/speaker/episodic/${d}.md"
  done

  bash "$PARLEI_TEST_ROOT/scripts/memory_optimize.sh"

  # Recurring fact should appear in long_term.md (promoted after 3 occurrences)
  run grep -c "Recurring fact" "$PARLEI_TEST_ROOT/shared/memory/speaker/long_term.md"
  [ "$output" -eq 1 ]
}

# ── T-097: Backup run after optimization ──────────────────────────────────────

@test "backup pipeline: optimize then backup both succeed" {
  run bash "$PARLEI_TEST_ROOT/scripts/memory_optimize.sh"
  [ "$status" -eq 0 ]
  run bash "$PARLEI_TEST_ROOT/scripts/backup.sh"
  [ "$status" -eq 0 ]
}

@test "backup pipeline: archive created after pipeline run" {
  bash "$PARLEI_TEST_ROOT/scripts/memory_optimize.sh"
  bash "$PARLEI_TEST_ROOT/scripts/backup.sh"
  [ -f "$PARLEI_TEST_ROOT/backups/${TODAY}.tar.gz" ]
}

@test "backup pipeline: backup_log.md contains success entry" {
  bash "$PARLEI_TEST_ROOT/scripts/memory_optimize.sh"
  bash "$PARLEI_TEST_ROOT/scripts/backup.sh"
  run grep "backup successful" "$PARLEI_TEST_ROOT/backups/backup_log.md"
  [ "$status" -eq 0 ]
}

# ── T-098: Restore from backup ────────────────────────────────────────────────

@test "restore: full pipeline — backup then restore recovers original state" {
  ORIGINAL="Original content for restore test"
  echo "$ORIGINAL" > "$PARLEI_TEST_ROOT/shared/memory/speaker/long_term.md"

  bash "$PARLEI_TEST_ROOT/scripts/backup.sh"

  # Modify the file post-backup
  echo "Modified after backup" > "$PARLEI_TEST_ROOT/shared/memory/speaker/long_term.md"

  echo "YES" | bash "$PARLEI_TEST_ROOT/scripts/restore.sh" "$TODAY"

  run cat "$PARLEI_TEST_ROOT/shared/memory/speaker/long_term.md"
  [[ "$output" == *"$ORIGINAL"* ]]
}

@test "restore: backups/ is unchanged after restore" {
  bash "$PARLEI_TEST_ROOT/scripts/backup.sh"

  BEFORE="$(find "$PARLEI_TEST_ROOT/backups" -name "*.tar.gz" | sort | xargs md5sum 2>/dev/null | md5sum)"
  echo "YES" | bash "$PARLEI_TEST_ROOT/scripts/restore.sh" "$TODAY"
  AFTER="$(find "$PARLEI_TEST_ROOT/backups" -name "*.tar.gz" | sort | xargs md5sum 2>/dev/null | md5sum)"

  [ "$BEFORE" = "$AFTER" ]
}

# ── T-099: Re-Origination-er safety gate ──────────────────────────────────────

@test "safety gate: reoriginator definition file contains spirit_token requirement" {
  run grep -i "spirit_token\|spirit token\|confirmation token" \
    "$REPO_ROOT/shared/agents/reoriginator.md"
  [ "$status" -eq 0 ]
}

@test "safety gate: reoriginator definition includes self-authorization prohibition" {
  run grep -i "cannot self-authorize\|cannot issue.*own\|self-authorize" \
    "$REPO_ROOT/shared/agents/reoriginator.md"
  [ "$status" -eq 0 ]
}

@test "safety gate: reoriginator definition requires REORIGINATION.md logging" {
  run grep -i "REORIGINATION.md" "$REPO_ROOT/shared/agents/reoriginator.md"
  [ "$status" -eq 0 ]
}
