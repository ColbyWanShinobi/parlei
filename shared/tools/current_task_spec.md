# 📋 `current_task.md` — Format Specification

> *Every agent reads and writes this format. No exceptions.*

---

## Purpose

`current_task.md` is an agent's internal task list and recovery checkpoint. It is written before any work begins and updated incrementally as work progresses. Its existence at the active path (`shared/memory/<agent>/current_task.md`) means the agent has unfinished work.

---

## File Location

```
shared/memory/<agent-name>/current_task.md
```

Examples:
- `shared/memory/speaker/current_task.md`
- `shared/memory/planer/current_task.md`

---

## Format

```markdown
# Current Task

**Request ID:** req-<agent>-<YYYYMMDD>-<NNN>
**Status:** in-progress
**Started:** YYYY-MM-DD HH:MM
**Received from:** <agent-name or "spirit">
**Interrupt reason:**

## Subtasks
- [ ] Subtask 1 — brief description
- [ ] Subtask 2 — brief description
- [ ] Subtask 3 — brief description

## Context
Any state, intermediate values, or data the agent needs to resume work exactly
where it left off. Written in plain prose or embedded JSON code blocks.
Never YAML.

## Original Request
​```json
{
  "from": "speaker",
  "to": "<agent>",
  "request_id": "req-<agent>-<YYYYMMDD>-<NNN>",
  "items": [...]
}
​```
```

---

## Field Definitions

| Field | Required | Description |
|---|---|---|
| `Request ID` | Yes | The `request_id` from the original JSON request envelope |
| `Status` | Yes | Always `in-progress` while active. Set to `completed` just before archival. |
| `Started` | Yes | Timestamp when the file was first written (local time, `YYYY-MM-DD HH:MM`) |
| `Received from` | Yes | The agent or entity that sent the task |
| `Interrupt reason` | No | Blank normally. If the agent detects it is resuming, it fills this in. |
| `Subtasks` | Yes | Markdown checkbox list. At least 1 item. |
| `Context` | Yes | Enough state to resume without any external input. May be empty if task is atomic. |
| `Original Request` | Yes | Full JSON request envelope, embedded in a JSON code block. |

---

## Lifecycle

### 1. Write before working

Before any work begins, the agent writes this file with **all subtasks unchecked** (`[ ]`). If the write fails, the agent halts and reports to Speak-er.

### 2. Check off incrementally

Each subtask is marked `[x]` immediately upon completion — not batched at the end.

```markdown
- [x] Subtask 1 — parse incoming request
- [x] Subtask 2 — load context from long_term.md
- [ ] Subtask 3 — perform core work  ← resume here
```

### 3. Startup check

On every startup, an agent checks for an existing `current_task.md`. If found with `Status: in-progress`:
1. Fill in `Interrupt reason` with a brief description of why the session ended.
2. Notify Speak-er: "Resuming interrupted task `<request_id>` from subtask N."
3. Continue from the first unchecked subtask.

### 4. Complete and archive

When all subtasks are checked and the response has been sent:
1. Set `Status: completed`.
2. Move the file to `shared/memory/<agent>/episodic/<YYYY-MM-DD>-<request-id>.md`.
3. Confirm the active path no longer exists.

### 5. Unresolvable resumption

If an agent resumes but cannot complete the task, it sends a `resume_escalation` message to Speak-er with the full `current_task.md` contents attached. It does **not** delete the file.

---

## Example (completed with 2 of 5 done at interruption point)

```markdown
# Current Task

**Request ID:** req-planer-20260327-002
**Status:** in-progress
**Started:** 2026-03-27 14:32
**Received from:** speaker
**Interrupt reason:** Context window exhausted after subtask 2

## Subtasks
- [x] Subtask 1 — read existing docs/PLAN.md for current state
- [x] Subtask 2 — identify missing features in area 3
- [ ] Subtask 3 — draft new feature 3.4 description  ← resume here
- [ ] Subtask 4 — update dependency map
- [ ] Subtask 5 — send updated docs/PLAN.md path to Speak-er

## Context
Feature 3.4 is about agent resilience. The gap identified in subtask 2 is that
no feature describes the current_task.md lifecycle rules. Draft should follow
the pattern of existing features 3.1–3.3.

## Original Request
​```json
{
  "from": "speaker",
  "to": "planer",
  "request_id": "req-planer-20260327-002",
  "items": [
    {
      "id": 1,
      "type": "update",
      "description": "Add agent resilience feature to docs/PLAN.md area 3",
      "context": "See docs/DESIGN.md Universal Agent Behavior section"
    }
  ]
}
​```
```

---

## Rules Summary

| Rule | Detail |
|---|---|
| Write first | File is created before any work begins |
| All unchecked at start | Every subtask starts as `[ ]` |
| Incremental checkoff | Check off `[x]` immediately on each subtask's completion |
| Startup check is mandatory | Every agent checks on every startup |
| Archive on completion | Move to `episodic/`, remove from active path |
| Never YAML | Context section uses plain prose or JSON code blocks only |
| Never delete on failure | File stays in place during escalation |
