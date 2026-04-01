#!/usr/bin/env bats
# test_setup_memory_preservation.bats — Ensure setup never overwrites memory files

setup() {
  # Create a temporary test root
  export PARLEI_TEST_ROOT="$(mktemp -d)"
  
  # Copy setup script and minimal structure
  cp -r "$BATS_TEST_DIRNAME/../../scripts" "$PARLEI_TEST_ROOT/"
  cp -r "$BATS_TEST_DIRNAME/../../shared" "$PARLEI_TEST_ROOT/"
  cp -r "$BATS_TEST_DIRNAME/../../bootstraps" "$PARLEI_TEST_ROOT/"
  cp "$BATS_TEST_DIRNAME/../../CLAUDE.md" "$PARLEI_TEST_ROOT/"
  
  # Make scripts executable
  chmod +x "$PARLEI_TEST_ROOT/scripts/setup.sh"
}

teardown() {
  # Clean up test directory
  if [[ -n "${PARLEI_TEST_ROOT:-}" && -d "$PARLEI_TEST_ROOT" ]]; then
    rm -rf "$PARLEI_TEST_ROOT"
  fi
}

# ── Memory file preservation tests ───────────────────────────────────────────

@test "setup: does not overwrite existing identity.md files" {
  cd "$PARLEI_TEST_ROOT"
  
  # Create custom identity content
  ORIGINAL_CONTENT="This is my custom identity that must be preserved"
  echo "$ORIGINAL_CONTENT" > shared/memory/speaker/identity.md
  
  # Run setup
  run bash scripts/setup.sh all
  [ "$status" -eq 0 ]
  
  # Verify content unchanged
  CURRENT_CONTENT="$(cat shared/memory/speaker/identity.md)"
  [[ "$CURRENT_CONTENT" == "$ORIGINAL_CONTENT" ]]
}

@test "setup: does not overwrite existing long_term.md files" {
  cd "$PARLEI_TEST_ROOT"
  
  # Create custom long-term memory
  ORIGINAL_CONTENT="My precious long-term memories"
  echo "$ORIGINAL_CONTENT" > shared/memory/speaker/long_term.md
  
  # Run setup
  run bash scripts/setup.sh all
  [ "$status" -eq 0 ]
  
  # Verify content unchanged
  CURRENT_CONTENT="$(cat shared/memory/speaker/long_term.md)"
  [[ "$CURRENT_CONTENT" == "$ORIGINAL_CONTENT" ]]
}

@test "setup: preserves all agent memory files on re-run" {
  cd "$PARLEI_TEST_ROOT"
  
  # Modify memory files for multiple agents
  echo "Custom speaker identity" > shared/memory/speaker/identity.md
  echo "Custom coder identity" > shared/memory/coder/identity.md
  echo "Custom reviewer identity" > shared/memory/reviewer/identity.md
  
  echo "Speaker memories" > shared/memory/speaker/long_term.md
  echo "Coder memories" > shared/memory/coder/long_term.md
  echo "Reviewer memories" > shared/memory/reviewer/long_term.md
  
  # Run setup
  run bash scripts/setup.sh all
  [ "$status" -eq 0 ]
  
  # Verify all preserved
  [[ "$(cat shared/memory/speaker/identity.md)" == "Custom speaker identity" ]]
  [[ "$(cat shared/memory/coder/identity.md)" == "Custom coder identity" ]]
  [[ "$(cat shared/memory/reviewer/identity.md)" == "Custom reviewer identity" ]]
  
  [[ "$(cat shared/memory/speaker/long_term.md)" == "Speaker memories" ]]
  [[ "$(cat shared/memory/coder/long_term.md)" == "Coder memories" ]]
  [[ "$(cat shared/memory/reviewer/long_term.md)" == "Reviewer memories" ]]
}

@test "setup: preserves episodic memory files" {
  cd "$PARLEI_TEST_ROOT"
  
  # Create episodic memory
  mkdir -p shared/memory/speaker/episodic
  echo "Session from yesterday" > shared/memory/speaker/episodic/2026-03-31.md
  
  # Run setup
  run bash scripts/setup.sh all
  [ "$status" -eq 0 ]
  
  # Verify episodic memory preserved
  [ -f shared/memory/speaker/episodic/2026-03-31.md ]
  [[ "$(cat shared/memory/speaker/episodic/2026-03-31.md)" == "Session from yesterday" ]]
}

@test "setup: preserves current_task.md if it exists" {
  cd "$PARLEI_TEST_ROOT"
  
  # Create in-progress task
  mkdir -p shared/memory/speaker
  cat > shared/memory/speaker/current_task.md <<'EOF'
# Current Task

Status: in-progress
Task: Implementing authentication
EOF
  
  # Run setup
  run bash scripts/setup.sh all
  [ "$status" -eq 0 ]
  
  # Verify task preserved
  [ -f shared/memory/speaker/current_task.md ]
  grep -q "Status: in-progress" shared/memory/speaker/current_task.md
  grep -q "Implementing authentication" shared/memory/speaker/current_task.md
}

@test "setup: only creates inbox/outbox directories, nothing else" {
  cd "$PARLEI_TEST_ROOT"
  
  # Remove inbox/outbox to test creation
  rm -rf shared/memory/speaker/inbox
  rm -rf shared/memory/speaker/outbox
  
  # Count files before
  FILES_BEFORE=$(find shared/memory/speaker -type f | wc -l)
  
  # Run setup
  run bash scripts/setup.sh all
  [ "$status" -eq 0 ]
  
  # Verify directories created
  [ -d shared/memory/speaker/inbox ]
  [ -d shared/memory/speaker/outbox ]
  
  # Verify no new files created (only .gitkeep in directories)
  FILES_AFTER=$(find shared/memory/speaker -type f | wc -l)
  EXPECTED_NEW_FILES=2  # .gitkeep in inbox and outbox
  
  [[ "$FILES_AFTER" -eq "$((FILES_BEFORE + EXPECTED_NEW_FILES))" ]]
}

@test "setup: is idempotent - running twice preserves everything" {
  cd "$PARLEI_TEST_ROOT"
  
  # Add custom content
  echo "Custom identity" > shared/memory/speaker/identity.md
  echo "Custom memory" > shared/memory/speaker/long_term.md
  
  # Run setup first time
  bash scripts/setup.sh all
  
  # Capture state
  IDENTITY_HASH=$(md5sum shared/memory/speaker/identity.md | cut -d' ' -f1)
  MEMORY_HASH=$(md5sum shared/memory/speaker/long_term.md | cut -d' ' -f1)
  
  # Run setup second time
  run bash scripts/setup.sh all
  [ "$status" -eq 0 ]
  
  # Verify nothing changed
  NEW_IDENTITY_HASH=$(md5sum shared/memory/speaker/identity.md | cut -d' ' -f1)
  NEW_MEMORY_HASH=$(md5sum shared/memory/speaker/long_term.md | cut -d' ' -f1)
  
  [[ "$IDENTITY_HASH" == "$NEW_IDENTITY_HASH" ]]
  [[ "$MEMORY_HASH" == "$NEW_MEMORY_HASH" ]]
}

@test "setup: warns about missing memory files but doesn't create them" {
  cd "$PARLEI_TEST_ROOT"
  
  # Remove a memory file
  rm shared/memory/speaker/identity.md
  
  # Run setup
  run bash scripts/setup.sh all
  [ "$status" -eq 0 ]
  
  # Should warn about missing file
  [[ "$output" == *"Warning"*"identity.md is missing"* ]]
  
  # Should NOT create the file
  [ ! -f shared/memory/speaker/identity.md ]
}

