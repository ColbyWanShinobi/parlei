#!/usr/bin/env bash
# run_tests.sh — Single entry point for all Parlei tests.
# Usage: run_tests.sh [unit|integration|functionality]
# Without argument, runs all categories in order.
# Requires bats-core. Install with: brew install bats-core
#                              or:  apt-get install bats
#                              or:  git clone https://github.com/bats-core/bats-core vendor/bats

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TESTS_DIR="$REPO_ROOT/tests"

# ── Locate bats ───────────────────────────────────────────────────────────────

BATS=""
if command -v bats &>/dev/null; then
  BATS="$(command -v bats)"
elif [[ -x "$REPO_ROOT/vendor/bats/bin/bats" ]]; then
  BATS="$REPO_ROOT/vendor/bats/bin/bats"
else
  echo "Error: bats-core not found." >&2
  echo "Install with one of:" >&2
  echo "  brew install bats-core" >&2
  echo "  apt-get install bats" >&2
  echo "  git clone https://github.com/bats-core/bats-core vendor/bats" >&2
  exit 1
fi

# ── Parse category argument ───────────────────────────────────────────────────

CATEGORY="${1:-all}"

case "$CATEGORY" in
  unit|integration|functionality|all) ;;
  *)
    echo "Error: unknown test category '${CATEGORY}'. Use: unit | integration | functionality | all" >&2
    exit 1
    ;;
esac

# ── Run tests ─────────────────────────────────────────────────────────────────

PASS=0
FAIL=0
TOTAL=0

run_category() {
  local cat="$1"
  local dir="$TESTS_DIR/$cat"

  if [[ ! -d "$dir" ]]; then
    echo "Skipping $cat — directory not found: $dir"
    return
  fi

  mapfile -t TEST_FILES < <(find "$dir" -maxdepth 1 -name "*.bats" | sort)

  if [[ ${#TEST_FILES[@]} -eq 0 ]]; then
    echo "Skipping $cat — no .bats files found in $dir"
    return
  fi

  echo ""
  echo "━━━ ${cat^^} TESTS ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  for TEST_FILE in "${TEST_FILES[@]}"; do
    if "$BATS" "$TEST_FILE"; then
      PASS=$((PASS + 1))
    else
      FAIL=$((FAIL + 1))
    fi
    TOTAL=$((TOTAL + 1))
  done
}

if [[ "$CATEGORY" == "all" ]]; then
  run_category "unit"
  run_category "integration"
  run_category "functionality"
else
  run_category "$CATEGORY"
fi

# ── Summary ───────────────────────────────────────────────────────────────────

echo ""
echo "━━━ RESULTS ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Test files: $TOTAL"
echo "  Passed:     $PASS"
echo "  Failed:     $FAIL"

if [[ $FAIL -gt 0 ]]; then
  exit 1
fi

exit 0
