#!/usr/bin/env bats
# Integration test: full setup for two environments, shared/ parity (T-092)

load '../fixtures/setup'

REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"

setup() {
  parlei_setup_tmpdir
  parlei_create_shared_skeleton "$PARLEI_TEST_ROOT"
  parlei_setup_mock_crontab

  cp -r "$REPO_ROOT/scripts" "$PARLEI_TEST_ROOT/scripts"
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

@test "setup parity: claude and augment environments both succeed" {
  run bash "$PARLEI_TEST_ROOT/scripts/setup.sh" claude
  [ "$status" -eq 0 ]
  run bash "$PARLEI_TEST_ROOT/scripts/setup.sh" augment
  [ "$status" -eq 0 ]
}

@test "setup parity: shared/ dirs are identical regardless of which env was set up" {
  bash "$PARLEI_TEST_ROOT/scripts/setup.sh" claude
  DIRS_CLAUDE="$(find "$PARLEI_TEST_ROOT/shared" -type d | sort)"

  bash "$PARLEI_TEST_ROOT/scripts/setup.sh" augment
  DIRS_AUGMENT="$(find "$PARLEI_TEST_ROOT/shared" -type d | sort)"

  [ "$DIRS_CLAUDE" = "$DIRS_AUGMENT" ]
}

@test "setup parity: .parlei-env reflects the last environment set" {
  bash "$PARLEI_TEST_ROOT/scripts/setup.sh" claude
  bash "$PARLEI_TEST_ROOT/scripts/setup.sh" augment
  run cat "$PARLEI_TEST_ROOT/.parlei-env"
  [ "$output" = "augment" ]
}

@test "setup parity: all four environments complete successfully" {
  for env in claude augment codex openclaw; do
    run bash "$PARLEI_TEST_ROOT/scripts/setup.sh" "$env"
    [ "$status" -eq 0 ]
  done
}
