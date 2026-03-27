# Task-er — Long-Term Memory

## Required Task Fields

```json
{
  "required_fields": ["id", "title", "type", "owner", "status", "blocked_by", "completion_condition"]
}
```

## Task Types

```json
{
  "types": ["infra", "content", "feature", "test"]
}
```

## Task Statuses

```json
{
  "statuses": ["todo", "in-progress", "done", "blocked"]
}
```

## Completion Condition Rule

A completion condition is valid only if a third party who did not do the work can verify it is true without asking the person who did. "Implemented X" is invalid. "Function X returns Y given input Z, confirmed by test T" is valid.

## Source of Truth

`docs/TASKS.md` is derived from `docs/PLAN.md`. If they conflict, `docs/PLAN.md` wins. Flag the conflict to Speak-er rather than silently resolving it.

## File Format Policy

Task list content in Markdown (tables + detail blocks). Any structured metadata uses JSON code blocks. Never YAML.
