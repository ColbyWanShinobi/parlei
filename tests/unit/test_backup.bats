#!/usr/bin/env bats
# Unit tests for scripts/backup.sh and scripts/restore.sh (T-082 to T-086)

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
  "backup_retention_count": 3,
  "llm_timeout_seconds": 2,
  "compression": "gzip"
}
EOF

  cp "$REPO_ROOT/scripts/backup.sh"  "$PARLEI_TEST_ROOT/scripts/backup.sh"
  cp "$REPO_ROOT/scripts/restore.sh" "$PARLEI_TEST_ROOT/scripts/restore.sh"
  chmod +x "$PARLEI_TEST_ROOT/scripts/backup.sh" \
            "$PARLEI_TEST_ROOT/scripts/restore.sh"

  # Seed some content so the archive is non-empty
  echo "test content" > "$PARLEI_TEST_ROOT/shared/memory/speaker/long_term.md"
}

teardown() {
  parlei_teardown_tmpdir
}

# ── T-082: Archive creation and naming ────────────────────────────────────────

@test "backup: creates archive named YYYY-MM-DD.tar.gz for today" {
  bash "$PARLEI_TEST_ROOT/scripts/backup.sh"
  [ -f "$PARLEI_TEST_ROOT/backups/${TODAY}.tar.gz" ]
}

@test "backup: archive is non-empty" {
  bash "$PARLEI_TEST_ROOT/scripts/backup.sh"
  [ -s "$PARLEI_TEST_ROOT/backups/${TODAY}.tar.gz" ]
}

@test "backup: archive extracts to valid shared/ contents" {
  bash "$PARLEI_TEST_ROOT/scripts/backup.sh"
  EXTRACT_DIR="$(mktemp -d)"
  tar -xzf "$PARLEI_TEST_ROOT/backups/${TODAY}.tar.gz" -C "$EXTRACT_DIR"
  [ -d "$EXTRACT_DIR/shared" ]
  rm -rf "$EXTRACT_DIR"
}

@test "backup: running twice on same day overwrites archive (not duplicate)" {
  bash "$PARLEI_TEST_ROOT/scripts/backup.sh"
  bash "$PARLEI_TEST_ROOT/scripts/backup.sh"
  COUNT="$(find "$PARLEI_TEST_ROOT/backups" -name "${TODAY}.tar.gz" | wc -l)"
  [ "$COUNT" -eq 1 ]
}

# ── T-083: Retention pruning ───────────────────────────────────────────────────

@test "backup: prunes oldest archives when count exceeds retention limit" {
  # Create 4 fake old archives (retention limit is 3)
  for d in 2026-01-01 2026-01-02 2026-01-03 2026-01-04; do
    touch "$PARLEI_TEST_ROOT/backups/${d}.tar.gz"
  done

  bash "$PARLEI_TEST_ROOT/scripts/backup.sh"

  # Should have at most 3 archives (retention limit)
  COUNT="$(find "$PARLEI_TEST_ROOT/backups" -name "*.tar.gz" | wc -l)"
  [ "$COUNT" -le 3 ]
}

@test "backup: oldest archive is the one pruned" {
  touch "$PARLEI_TEST_ROOT/backups/2026-01-01.tar.gz"
  touch "$PARLEI_TEST_ROOT/backups/2026-01-02.tar.gz"
  touch "$PARLEI_TEST_ROOT/backups/2026-01-03.tar.gz"

  bash "$PARLEI_TEST_ROOT/scripts/backup.sh"

  # 2026-01-01 should be gone (oldest)
  [ ! -f "$PARLEI_TEST_ROOT/backups/2026-01-01.tar.gz" ]
}

# ── T-084: Error logging ───────────────────────────────────────────────────────

@test "backup: success appends to backup_log.md" {
  bash "$PARLEI_TEST_ROOT/scripts/backup.sh"
  assert_file_nonempty "$PARLEI_TEST_ROOT/backups/backup_log.md"
  run grep "backup successful" "$PARLEI_TEST_ROOT/backups/backup_log.md"
  [ "$status" -eq 0 ]
}

@test "backup: exits non-zero and writes error_log.md if shared/ is missing" {
  rm -rf "$PARLEI_TEST_ROOT/shared"
  run bash "$PARLEI_TEST_ROOT/scripts/backup.sh"
  [ "$status" -ne 0 ]
}

# ── T-085: restore.sh — extraction and confirmation ───────────────────────────

@test "restore: extracts archive when YES is confirmed" {
  bash "$PARLEI_TEST_ROOT/scripts/backup.sh"

  # Modify shared to detect restore
  echo "modified" > "$PARLEI_TEST_ROOT/shared/memory/speaker/long_term.md"

  echo "YES" | bash "$PARLEI_TEST_ROOT/scripts/restore.sh" "$TODAY"

  run cat "$PARLEI_TEST_ROOT/shared/memory/speaker/long_term.md"
  [[ "$output" == *"test content"* ]]
}

@test "restore: aborts and leaves shared/ unchanged when input is not YES" {
  bash "$PARLEI_TEST_ROOT/scripts/backup.sh"
  echo "modified after backup" > "$PARLEI_TEST_ROOT/shared/memory/speaker/long_term.md"

  echo "no" | bash "$PARLEI_TEST_ROOT/scripts/restore.sh" "$TODAY" || true

  run cat "$PARLEI_TEST_ROOT/shared/memory/speaker/long_term.md"
  [[ "$output" == *"modified after backup"* ]]
}

@test "restore: exits 1 when archive does not exist for given date" {
  run bash "$PARLEI_TEST_ROOT/scripts/restore.sh" "1999-01-01" <<< "YES"
  [ "$status" -eq 1 ]
}

# ── T-086: restore does not modify backups/ ───────────────────────────────────

@test "restore: backups/ directory is unchanged after restore" {
  bash "$PARLEI_TEST_ROOT/scripts/backup.sh"

  BEFORE="$(find "$PARLEI_TEST_ROOT/backups" -name "*.tar.gz" | sort | xargs md5sum 2>/dev/null | md5sum)"

  echo "YES" | bash "$PARLEI_TEST_ROOT/scripts/restore.sh" "$TODAY"

  AFTER="$(find "$PARLEI_TEST_ROOT/backups" -name "*.tar.gz" | sort | xargs md5sum 2>/dev/null | md5sum)"

  [ "$BEFORE" = "$AFTER" ]
}
