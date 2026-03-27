# 📡 Parlei Agent Communication Protocol

> *Every agent must read and follow this document. It is the law of the parliament.*

---

## 1. Message Format

All inter-agent messages are JSON. Two envelope types exist: **request** and **response**. Both must validate against their respective schemas in `shared/tools/schema_request.json` and `shared/tools/schema_response.json`.

### Request Envelope

```json
{
  "from": "tasker",
  "to": "checker",
  "request_id": "req-tasker-20260327-003",
  "items": [
    {
      "id": 1,
      "type": "verification",
      "description": "Confirm TASK-042 has a corresponding implementation",
      "context": "File: src/auth/login.ts"
    },
    {
      "id": 2,
      "type": "verification",
      "description": "Confirm TASK-043 has a corresponding implementation",
      "context": "File: src/auth/logout.ts"
    }
  ]
}
```

### Response Envelope

```json
{
  "from": "checker",
  "to": "tasker",
  "request_id": "req-tasker-20260327-003",
  "items": [
    {
      "id": 1,
      "status": "confirmed",
      "notes": "Implementation found at src/auth/login.ts:42"
    },
    {
      "id": 2,
      "status": "incomplete",
      "notes": "Logout function exists at src/auth/logout.ts:18 but body is a stub — returns TODO"
    }
  ]
}
```

### Item Status Values

| Status | Meaning |
|---|---|
| `confirmed` | Item is complete and verified |
| `incomplete` | Item exists but is not finished |
| `failed` | Item could not be completed; see `notes` |
| `deferred` | Item is acknowledged but cannot be completed now; see `notes` |

---

## 2. Request ID Format

Request IDs follow this format: `req-<agent-name>-<YYYYMMDD>-<NNN>`

- `<agent-name>`: the lowercase agent name (e.g., `tasker`, `checker`, `speaker`)
- `<YYYYMMDD>`: the date the request was created
- `<NNN>`: a zero-padded 3-digit sequence number, resetting to `001` each day

**Generate using:** `shared/tools/request_id.sh <agent-name>`

**Examples:**
- `req-tasker-20260327-001` — first request from Task-er on 2026-03-27
- `req-speaker-20260327-014` — fourteenth request from Speak-er on 2026-03-27

---

## 3. Communication Topology

### Default: Upward Only

By default, all agents send messages only to Speak-er. No agent addresses another agent directly.

```
Spirit of the Forest
       ↕
   Speak-er
   ↙  ↓  ↘
Plan-er  Task-er  Check-er  ...
```

### Lateral Communication (by Grant Only)

Speak-er may issue a **lateral grant** when two agents benefit from direct communication. The grant is:
- Scoped to a single named task
- Session-scoped — it expires when both agents report completion to Speak-er
- Communicated to both agents via a grant message (see §5)

---

## 4. Retry & Escalation Protocol

### Step-by-Step

1. Agent A sends a request with N items to Agent B.
2. Agent B returns a response. Agent A checks that all N item IDs are present in the response.
3. If any item IDs are missing, Agent A uses `shared/tools/retry.sh` to record the attempt and identify the missing IDs.
4. Agent A sends a **new request** containing **only the missing items**, with a new `request_id`.
5. Steps 2–4 repeat up to **3 total attempts**.
6. After 3 failed attempts, Agent A sends an **escalation message** to Speak-er.

### Escalation Message Format

```json
{
  "from": "tasker",
  "to": "speaker",
  "request_id": "req-tasker-20260327-005",
  "type": "escalation",
  "items": [
    {
      "id": 1,
      "type": "escalation",
      "description": "Agent checker failed to respond to item 2 after 3 attempts",
      "context": "{\"original_request_id\": \"req-tasker-20260327-003\", \"unresolved_item_ids\": [2], \"attempts\": [{\"attempt\": 1, \"timestamp\": \"2026-03-27 14:01:00\", \"missing_ids\": [2]}, {\"attempt\": 2, \"timestamp\": \"2026-03-27 14:02:10\", \"missing_ids\": [2]}, {\"attempt\": 3, \"timestamp\": \"2026-03-27 14:03:22\", \"missing_ids\": [2]}]}"
    }
  ]
}
```

### Resume Escalation (from `current_task.md` recovery)

When an agent resumes an interrupted task and cannot complete it:

```json
{
  "from": "planer",
  "to": "speaker",
  "request_id": "req-planer-20260327-006",
  "type": "resume_escalation",
  "items": [
    {
      "id": 1,
      "type": "resume_escalation",
      "description": "Resumed interrupted task but cannot complete — error at subtask 4",
      "context": "{\"original_request_id\": \"req-planer-20260327-001\", \"failure_reason\": \"Source file disappeared during resume\", \"current_task_contents\": \"<full contents of current_task.md>\"}"
    }
  ]
}
```

---

## 5. Lateral Grant Message Format

Issued by Speak-er to two agents to authorize direct communication:

```json
{
  "from": "speaker",
  "to": "tasker",
  "request_id": "req-speaker-20260327-009",
  "type": "lateral_grant",
  "items": [
    {
      "id": 1,
      "type": "lateral_grant",
      "description": "You are authorized to communicate directly with checker for the following task",
      "context": "{\"authorized_peer\": \"checker\", \"task_scope\": \"Verify plan-task coherence for feature area 3\", \"expires\": \"on task completion\"}"
    }
  ]
}
```

Both agents receive the grant message. Both must report back to Speak-er when the lateral task is complete.

---

## 6. Critical Finding Immediate Escalation

Review-er sends this immediately on finding a `critical` severity issue — does not wait to batch:

```json
{
  "from": "reviewer",
  "to": "speaker",
  "request_id": "req-reviewer-20260327-002",
  "type": "critical_finding",
  "items": [
    {
      "id": 1,
      "type": "critical_finding",
      "description": "SQL injection vulnerability — user input passed directly to query",
      "context": "File: src/db/query.ts:88 — severity: critical — category: security"
    }
  ]
}
```

---

## 7. Rules Summary

| Rule | Detail |
|---|---|
| All messages are JSON | No YAML, no plain text |
| Schemas must validate | Use `schema_request.json` and `schema_response.json` |
| Request IDs are unique | Generated via `request_id.sh`; never reused |
| All item IDs must be returned | Missing IDs trigger retry |
| Max 3 retries | Then escalate to Speak-er |
| Lateral communication requires a grant | No agent contacts another without Speak-er's authorization |
| Critical findings are immediate | Do not batch critical issues |
