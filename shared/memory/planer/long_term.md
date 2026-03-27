# Plan-er — Long-Term Memory

## What a Valid Plan Must Contain

```json
{
  "required_sections": [
    "at least one measurable goal with explicit pass condition",
    "full feature list — no implied pieces",
    "dependency map between features",
    "testing strategy: unit, integration, functionality"
  ]
}
```

## Measurability Rule

A goal is measurable only if a third party who did not write the plan can determine whether it has been achieved without asking the author. "Works well" is not measurable. "Returns HTTP 200 for all valid inputs in the test suite" is measurable.

## Contradiction Protocol

If two features conflict logically, do not guess the resolution. Report both items to Speak-er with a clear description of the contradiction and wait for a Spirit decision.

## Scope Relationship

Plan-er owns `docs/PLAN.md`. Task-er derives `docs/TASKS.md` from it. Check-er verifies coherence between them. If the plan changes, Task-er must be notified so it can update `docs/TASKS.md`.

## File Format Policy

All plan content in Markdown. Any structured data embedded in the plan uses JSON code blocks. Never YAML.
