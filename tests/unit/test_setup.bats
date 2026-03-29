#!/usr/bin/env bats
# Unit tests for scripts/setup.sh (T-074, T-075, T-076, T-077)

load '../fixtures/setup'

REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
SETUP_SCRIPT="$REPO_ROOT/scripts/setup.sh"

setup() {
  parlei_setup_tmpdir
  parlei_create_shared_skeleton "$PARLEI_TEST_ROOT"
  parlei_setup_mock_crontab

  # Copy scripts into temp root so they have correct relative paths
  cp "$REPO_ROOT/scripts/"*.sh "$PARLEI_TEST_ROOT/scripts/"
  chmod +x "$PARLEI_TEST_ROOT/scripts/"*.sh
  # Copy env config files
  [[ -f "$REPO_ROOT/CLAUDE.md" ]] && cp "$REPO_ROOT/CLAUDE.md" "$PARLEI_TEST_ROOT/CLAUDE.md"
  mkdir -p "$PARLEI_TEST_ROOT/bootstraps"
  for f in AUGGIE.md CODEX.md OPENCLAW.md; do
    [[ -f "$REPO_ROOT/bootstraps/$f" ]] && cp "$REPO_ROOT/bootstraps/$f" "$PARLEI_TEST_ROOT/bootstraps/$f"
  done
}

teardown() {
  parlei_teardown_mock_crontab
  parlei_teardown_tmpdir
}

# ── T-074: Symlink creation (via .parlei-env marker + dir validation) ─────────

@test "setup: valid environment 'claude' exits 0" {
  run bash "$PARLEI_TEST_ROOT/scripts/setup.sh" claude
  [ "$status" -eq 0 ]
}

@test "setup: valid environment 'augment' exits 0" {
  run bash "$PARLEI_TEST_ROOT/scripts/setup.sh" augment
  [ "$status" -eq 0 ]
}

@test "setup: valid environment 'codex' exits 0" {
  run bash "$PARLEI_TEST_ROOT/scripts/setup.sh" codex
  [ "$status" -eq 0 ]
}

@test "setup: valid environment 'openclaw' exits 0" {
  run bash "$PARLEI_TEST_ROOT/scripts/setup.sh" openclaw
  [ "$status" -eq 0 ]
}

@test "setup: writes .parlei-env marker file with correct content" {
  bash "$PARLEI_TEST_ROOT/scripts/setup.sh" claude
  [ -f "$PARLEI_TEST_ROOT/.parlei-env" ]
  run cat "$PARLEI_TEST_ROOT/.parlei-env"
  [ "$output" = "claude" ]
}

@test "setup: all required shared/ subdirs are verified present" {
  run bash "$PARLEI_TEST_ROOT/scripts/setup.sh" claude
  [ "$status" -eq 0 ]
  [[ "$output" == *"Verified: all shared/"* ]]
}

# ── T-075: Idempotency ─────────────────────────────────────────────────────────

@test "setup: running twice produces same .parlei-env content" {
  bash "$PARLEI_TEST_ROOT/scripts/setup.sh" claude
  bash "$PARLEI_TEST_ROOT/scripts/setup.sh" claude
  run cat "$PARLEI_TEST_ROOT/.parlei-env"
  [ "$output" = "claude" ]
}

@test "setup: running twice exits 0 both times" {
  run bash "$PARLEI_TEST_ROOT/scripts/setup.sh" claude
  [ "$status" -eq 0 ]
  run bash "$PARLEI_TEST_ROOT/scripts/setup.sh" claude
  [ "$status" -eq 0 ]
}

# ── T-076: Cron registration ───────────────────────────────────────────────────

@test "setup: cron entries are written for parlei-memory and parlei-backup" {
  bash "$PARLEI_TEST_ROOT/scripts/setup.sh" claude
  run cat "$MOCK_CRONTAB_FILE"
  [[ "$output" == *"parlei-memory"* ]]
  [[ "$output" == *"parlei-backup"* ]]
}

@test "setup: running twice does not duplicate cron entries" {
  bash "$PARLEI_TEST_ROOT/scripts/setup.sh" claude
  bash "$PARLEI_TEST_ROOT/scripts/setup.sh" claude
  MEMORY_COUNT="$(grep -c "parlei-memory" "$MOCK_CRONTAB_FILE" 2>/dev/null || echo 0)"
  [ "$MEMORY_COUNT" -eq 1 ]
  BACKUP_COUNT="$(grep -c "parlei-backup" "$MOCK_CRONTAB_FILE" 2>/dev/null || echo 0)"
  [ "$BACKUP_COUNT" -eq 1 ]
}

# ── T-077: Non-zero exit on failure ───────────────────────────────────────────

@test "setup: no arguments exits 1" {
  run bash "$PARLEI_TEST_ROOT/scripts/setup.sh"
  [ "$status" -eq 1 ]
}

@test "setup: unknown environment argument exits 1" {
  run bash "$PARLEI_TEST_ROOT/scripts/setup.sh" vscode
  [ "$status" -eq 1 ]
  [[ "$output" == *"unrecognized environment"* ]]
}

@test "setup: exits 1 if shared/agents dir is missing" {
  rm -rf "$PARLEI_TEST_ROOT/shared/agents"
  run bash "$PARLEI_TEST_ROOT/scripts/setup.sh" claude
  [ "$status" -eq 1 ]
  [[ "$output" == *"required directory missing"* ]]
}
