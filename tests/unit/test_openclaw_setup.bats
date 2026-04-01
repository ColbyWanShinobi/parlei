#!/usr/bin/env bats
# test_openclaw_setup.bats — OpenClaw workspace setup tests

setup() {
  # Create a temporary test root
  export PARLEI_TEST_ROOT="$(mktemp -d)"
  
  # Mock OpenClaw workspace
  export OPENCLAW_WORKSPACE="$PARLEI_TEST_ROOT/.openclaw/workspace"
  mkdir -p "$OPENCLAW_WORKSPACE"
  
  # Copy setup script and shared directory structure
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

# ── OpenClaw workspace symlink tests ──────────────────────────────────────────

@test "openclaw_setup: creates symlink in workspace when openclaw environment selected" {
  cd "$PARLEI_TEST_ROOT"
  run bash scripts/setup.sh openclaw
  
  [ "$status" -eq 0 ]
  
  # Check symlink was created
  [ -L "$OPENCLAW_WORKSPACE/shared" ]
  
  # Check symlink points to correct location
  target="$(readlink "$OPENCLAW_WORKSPACE/shared")"
  [[ "$target" == "$PARLEI_TEST_ROOT/shared" ]]
}

@test "openclaw_setup: creates symlink when 'all' environment selected" {
  cd "$PARLEI_TEST_ROOT"
  run bash scripts/setup.sh all
  
  [ "$status" -eq 0 ]
  [ -L "$OPENCLAW_WORKSPACE/shared" ]
}

@test "openclaw_setup: does not create symlink when claude environment selected" {
  cd "$PARLEI_TEST_ROOT"
  run bash scripts/setup.sh claude
  
  [ "$status" -eq 0 ]
  [ ! -L "$OPENCLAW_WORKSPACE/shared" ]
}

@test "openclaw_setup: creates AGENTS.md with Parlei bootstrap instructions" {
  cd "$PARLEI_TEST_ROOT"
  run bash scripts/setup.sh openclaw
  
  [ "$status" -eq 0 ]
  [ -f "$OPENCLAW_WORKSPACE/AGENTS.md" ]
  
  # Check AGENTS.md contains Parlei references
  grep -q "shared/agents/speaker.md" "$OPENCLAW_WORKSPACE/AGENTS.md"
  grep -q "shared/personalities/speaker.md" "$OPENCLAW_WORKSPACE/AGENTS.md"
  grep -q "sessions_spawn" "$OPENCLAW_WORKSPACE/AGENTS.md"
}

@test "openclaw_setup: handles existing symlink correctly" {
  cd "$PARLEI_TEST_ROOT"
  
  # Create symlink manually
  ln -s "$PARLEI_TEST_ROOT/shared" "$OPENCLAW_WORKSPACE/shared"
  
  # Run setup again
  run bash scripts/setup.sh openclaw
  
  [ "$status" -eq 0 ]
  [[ "$output" == *"already configured correctly"* ]]
  
  # Symlink should still exist and point to correct location
  [ -L "$OPENCLAW_WORKSPACE/shared" ]
  target="$(readlink "$OPENCLAW_WORKSPACE/shared")"
  [[ "$target" == "$PARLEI_TEST_ROOT/shared" ]]
}

@test "openclaw_setup: handles existing AGENTS.md gracefully" {
  cd "$PARLEI_TEST_ROOT"
  
  # Create AGENTS.md with Parlei content
  cat > "$OPENCLAW_WORKSPACE/AGENTS.md" <<'EOF'
# Custom AGENTS.md
Load shared/agents/speaker.md
EOF
  
  # Run setup
  run bash scripts/setup.sh openclaw
  
  [ "$status" -eq 0 ]
  [[ "$output" == *"already configured for Parlei"* ]]
  
  # AGENTS.md should not be overwritten
  grep -q "Custom AGENTS.md" "$OPENCLAW_WORKSPACE/AGENTS.md"
}

@test "openclaw_setup: warns when OpenClaw workspace doesn't exist" {
  cd "$PARLEI_TEST_ROOT"
  
  # Remove OpenClaw workspace
  rm -rf "$OPENCLAW_WORKSPACE"
  
  # Run setup
  run bash scripts/setup.sh openclaw
  
  [ "$status" -eq 0 ]
  [[ "$output" == *"OpenClaw workspace not found"* ]]
  [[ "$output" == *"openclaw setup"* ]]
}

@test "openclaw_setup: respects OPENCLAW_WORKSPACE environment variable" {
  cd "$PARLEI_TEST_ROOT"
  
  # Set custom workspace location
  export OPENCLAW_WORKSPACE="$PARLEI_TEST_ROOT/custom-workspace"
  mkdir -p "$OPENCLAW_WORKSPACE"
  
  # Run setup
  run bash scripts/setup.sh openclaw
  
  [ "$status" -eq 0 ]
  
  # Check symlink created in custom location
  [ -L "$OPENCLAW_WORKSPACE/shared" ]
  target="$(readlink "$OPENCLAW_WORKSPACE/shared")"
  [[ "$target" == "$PARLEI_TEST_ROOT/shared" ]]
}

@test "openclaw_setup: handles symlink pointing to wrong location" {
  cd "$PARLEI_TEST_ROOT"
  
  # Create symlink pointing to wrong location
  mkdir -p "$PARLEI_TEST_ROOT/wrong"
  ln -s "$PARLEI_TEST_ROOT/wrong" "$OPENCLAW_WORKSPACE/shared"
  
  # Run setup
  run bash scripts/setup.sh openclaw
  
  [ "$status" -eq 0 ]
  [[ "$output" == *"points to:"* ]]
  [[ "$output" == *"Remove manually if needed"* ]]
  
  # Symlink should still point to wrong location (we don't force overwrite)
  target="$(readlink "$OPENCLAW_WORKSPACE/shared")"
  [[ "$target" == "$PARLEI_TEST_ROOT/wrong" ]]
}

@test "openclaw_setup: handles non-symlink file at shared location" {
  cd "$PARLEI_TEST_ROOT"
  
  # Create regular file instead of symlink
  touch "$OPENCLAW_WORKSPACE/shared"
  
  # Run setup
  run bash scripts/setup.sh openclaw
  
  [ "$status" -eq 0 ]
  [[ "$output" == *"exists but is not a symlink"* ]]
  [[ "$output" == *"Remove manually if needed"* ]]
  
  # File should still exist (we don't force overwrite)
  [ -f "$OPENCLAW_WORKSPACE/shared" ]
  [ ! -L "$OPENCLAW_WORKSPACE/shared" ]
}

@test "openclaw_setup: output shows workspace configuration" {
  cd "$PARLEI_TEST_ROOT"
  run bash scripts/setup.sh openclaw

  [ "$status" -eq 0 ]
  [[ "$output" == *"OpenClaw workspace:"* ]]
  [[ "$output" == *"Symlink: shared"* ]]
  [[ "$output" == *"Launch: openclaw"* ]]
}

