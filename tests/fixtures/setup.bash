#!/usr/bin/env bash
# setup.bash — Shared test fixtures and helpers for Parlei tests.
# Source this file at the top of any .bats test file:
#   load '../fixtures/setup'

# ── Temp directory management ─────────────────────────────────────────────────

# Creates a fresh temp directory and sets PARLEI_TEST_ROOT.
# Call in setup() functions.
parlei_setup_tmpdir() {
  PARLEI_TEST_ROOT="$(mktemp -d)"
  export PARLEI_TEST_ROOT
}

# Removes the temp directory. Call in teardown() functions.
parlei_teardown_tmpdir() {
  if [[ -n "${PARLEI_TEST_ROOT:-}" && -d "$PARLEI_TEST_ROOT" ]]; then
    rm -rf "$PARLEI_TEST_ROOT"
  fi
}

# ── Minimal shared/ skeleton ──────────────────────────────────────────────────

# Creates the minimal shared/ directory structure under PARLEI_TEST_ROOT.
# Call after parlei_setup_tmpdir.
parlei_create_shared_skeleton() {
  local root="${1:-$PARLEI_TEST_ROOT}"
  mkdir -p \
    "$root/shared/agents" \
    "$root/shared/memory" \
    "$root/shared/personalities" \
    "$root/shared/prompts" \
    "$root/shared/tools" \
    "$root/backups" \
    "$root/scripts"

  # Copy config so scripts can read it
  cp "$BATS_TEST_DIRNAME/../../shared/tools/memory_config.json" \
     "$root/shared/tools/memory_config.json" 2>/dev/null || \
  cat > "$root/shared/tools/memory_config.json" <<'EOF'
{
  "llm_endpoint": "",
  "llm_model": "",
  "llm_auth_token": "",
  "episodic_retention_days": 90,
  "promotion_threshold": 3,
  "backup_retention_count": 30,
  "llm_timeout_seconds": 5,
  "compression": "gzip"
}
EOF

  # Create agent memory dirs with episodic subdirs
  for agent in speaker planer tasker prompter checker reviewer architecter deployer tester reoriginator; do
    mkdir -p "$root/shared/memory/$agent/episodic"
  done
}

# ── Mock LLM endpoint ─────────────────────────────────────────────────────────

# Starts a mock HTTP server that returns a configurable canned response.
# Sets MOCK_LLM_PORT and MOCK_LLM_PID.
# Usage: parlei_start_mock_llm [response_text]
parlei_start_mock_llm() {
  local response="${1:-Mock LLM response for testing.}"
  MOCK_LLM_PORT="${MOCK_LLM_PORT:-18765}"
  export MOCK_LLM_PORT

  # Write a tiny Python HTTP server that returns the canned response
  MOCK_LLM_SCRIPT="$(mktemp /tmp/mock_llm_XXXXXX.py)"
  cat > "$MOCK_LLM_SCRIPT" << PYEOF
import http.server, json, sys

PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 18765
RESPONSE = sys.argv[2] if len(sys.argv) > 2 else "Mock LLM response for testing."

class Handler(http.server.BaseHTTPRequestHandler):
    def log_message(self, *args): pass  # suppress output
    def do_POST(self):
        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.end_headers()
        body = json.dumps({"choices": [{"message": {"content": RESPONSE}}]})
        self.wfile.write(body.encode())

http.server.HTTPServer(('127.0.0.1', PORT), Handler).serve_forever()
PYEOF

  python3 "$MOCK_LLM_SCRIPT" "$MOCK_LLM_PORT" "$response" &
  MOCK_LLM_PID=$!
  export MOCK_LLM_PID
  MOCK_LLM_SCRIPT_PATH="$MOCK_LLM_SCRIPT"

  # Wait for server to be ready
  for i in $(seq 1 10); do
    sleep 0.1
    curl -s "http://127.0.0.1:$MOCK_LLM_PORT" &>/dev/null && break || true
  done
}

# Stops the mock LLM server.
parlei_stop_mock_llm() {
  if [[ -n "${MOCK_LLM_PID:-}" ]]; then
    kill "$MOCK_LLM_PID" 2>/dev/null || true
    unset MOCK_LLM_PID
  fi
  if [[ -n "${MOCK_LLM_SCRIPT_PATH:-}" ]]; then
    rm -f "$MOCK_LLM_SCRIPT_PATH"
    unset MOCK_LLM_SCRIPT_PATH
  fi
}

# ── Mock crontab ──────────────────────────────────────────────────────────────

# Redirects crontab writes to a temp file so tests don't touch real crontab.
# Sets MOCK_CRONTAB_FILE. Override PATH to use this mock.
parlei_setup_mock_crontab() {
  MOCK_CRONTAB_FILE="$(mktemp)"
  export MOCK_CRONTAB_FILE

  MOCK_CRONTAB_DIR="$(mktemp -d)"
  cat > "$MOCK_CRONTAB_DIR/crontab" << 'EOF'
#!/usr/bin/env bash
if [[ "${1:-}" == "-l" ]]; then
  cat "$MOCK_CRONTAB_FILE" 2>/dev/null || true
else
  # Read from stdin and append to mock file
  while IFS= read -r line; do
    echo "$line" >> "$MOCK_CRONTAB_FILE"
  done
fi
EOF
  chmod +x "$MOCK_CRONTAB_DIR/crontab"
  export PATH="$MOCK_CRONTAB_DIR:$PATH"
  export MOCK_CRONTAB_DIR
}

parlei_teardown_mock_crontab() {
  rm -f "${MOCK_CRONTAB_FILE:-}"
  rm -rf "${MOCK_CRONTAB_DIR:-}"
}

# ── Assertion helpers ─────────────────────────────────────────────────────────

# Assert a file exists and is non-empty.
assert_file_nonempty() {
  local file="$1"
  [[ -f "$file" ]] || { echo "FAIL: file does not exist: $file"; return 1; }
  [[ -s "$file" ]] || { echo "FAIL: file is empty: $file"; return 1; }
}

# Assert a string is valid JSON.
assert_valid_json() {
  local input="$1"
  python3 -c "import json,sys; json.loads(sys.argv[1])" "$input" || {
    echo "FAIL: not valid JSON: $input"
    return 1
  }
}

# Assert a file contains no YAML patterns.
assert_no_yaml() {
  local file="$1"
  if grep -En '^---[[:space:]]*$' "$file" &>/dev/null; then
    echo "FAIL: YAML frontmatter found in $file"
    return 1
  fi
}
