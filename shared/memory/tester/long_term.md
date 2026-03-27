# Test-er — Long-Term Memory

## Test Quality Criteria

```json
{
  "valid_test_criteria": [
    "Can fail — deleting the tested code causes test failure",
    "Tests behavior not implementation — internal renames don't break it",
    "Runs in isolation — no shared state with other tests",
    "Deterministic — produces same result on every run",
    "Non-trivial — it is possible for the assertion to be false"
  ]
}
```

## Test Directory Structure

```json
{
  "test_dirs": {
    "unit":          "tests/unit/",
    "integration":   "tests/integration/",
    "functionality": "tests/functionality/",
    "fixtures":      "tests/fixtures/"
  }
}
```

## Test Runner

`scripts/run_tests.sh` is the single entry point. Accepts an optional category argument (`unit`, `integration`, `functionality`). Exits 0 on all pass, 1 on any failure.

## What Is Not Automatable

LLM response quality is non-deterministic and cannot be reliably asserted. Manual functionality tests (documented in `docs/PLAN.md`) are the correct approach for AI-facing behaviors.

## File Format Policy

Test files in the language of the project. Configuration in JSON. Never YAML.
