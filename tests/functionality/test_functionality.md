# 🎯 Parlei — Functionality Tests

> *Maintained by Test-er. These tests require a human runner or a semi-automated harness. Each has a binary pass/fail condition stated precisely.*
> *LLM responses are non-deterministic — these tests verify behavior, not output quality.*

---

## FT-100 — Bootstrap completes in under 5 minutes

**Steps:**
1. Clone the repo into a fresh directory.
2. Start a timer.
3. Run `scripts/setup.sh claude`.
4. Open Claude Code and load `CLAUDE.md`.
5. Send the message: "Who are you?"

**Pass condition:** Speak-er responds with its identity statement ("The parliament is in session...") within 5 minutes of `setup.sh` starting. The response acknowledges it is Speak-er and mentions the parliament.

**Fail condition:** Setup errors, Claude Code fails to load, or no response within 5 minutes.

---

## FT-101 — Plan → Tasks coherence via Check-er

**Steps:**
1. Ensure `docs/PLAN.md` and `docs/TASKS.md` are present.
2. Send Speak-er: "Ask Check-er to verify that docs/PLAN.md and docs/TASKS.md are in sync."
3. Wait for Check-er's response via Speak-er.

**Pass condition:** Check-er returns a JSON response (via Speak-er) with either:
- `"status": "confirmed"` and a count of features checked, or
- `"status": "incomplete"` with a list of specific gaps found.

Check-er's response must include evidence (file references), not just an assertion.

**Fail condition:** Check-er does not respond, returns a response with no evidence, or Speak-er cannot route the task.

---

## FT-102 — 48-hour autonomous operation

**Steps:**
1. Run `scripts/setup.sh claude` on a machine that will remain on for 48 hours.
2. Do not interact with the system for 48 hours.
3. After 48 hours, inspect:
   - `backups/` — should contain at least 2 dated archives
   - `shared/memory/optimize_log.md` — should have at least 2 entries
   - `shared/memory/error_log.md` — should not exist or be empty
   - `backups/error_log.md` — should not exist or be empty

**Pass condition:** All four conditions above are met.

**Fail condition:** Any condition is unmet; a script failed silently; or cron entries were not registered.

---

## FT-103 — All 10 agents respond to identity query

**Steps:**
For each agent in the roster, send Speak-er: "Please have [Agent Name] introduce themselves."

**Pass condition:** Each agent responds with:
1. Its name (e.g., "I am Plan-er")
2. A role summary that matches its definition in `shared/agents/`
3. At least one element of its personality (characteristic phrase or tone)

**Fail condition:** Any agent fails to respond, introduces itself with the wrong name, or gives a generic response not matching its defined personality.

---

## FT-104 — Environment switch preserves parity

**Steps:**
1. Run `scripts/setup.sh claude`. Open Claude Code. Send: "What agents are available to you?"
2. Note the full response.
3. Run `scripts/setup.sh augment`. Open Augment. Send the identical question.
4. Note the full response.

**Pass condition:** Both responses list the same 10 agents. Both responses demonstrate awareness of the same `shared/` memory and personality files. Any differences are limited to the environment-specific bootstrap text in the config files.

**Fail condition:** One environment lists different agents, shows different memory, or behaves differently on an identical prompt.

---

## FT-105 — Escalation chain produces human-visible output

**Steps:**
1. Deliberately configure one agent definition to always respond with an incomplete JSON response (missing item ID 2 on any request).
2. Send Speak-er a task that will be routed to that agent.
3. Observe what happens after 3 failed attempts.

**Pass condition:** Speak-er surfaces a plain-language notification containing:
- Which agent failed
- What it was asked to do
- What options the Spirit has (retry, skip, intervene)

The notification must be readable by a non-technical person — not a raw JSON blob.

**Fail condition:** The failure is swallowed silently, Speak-er does not notify the Spirit, or the notification is raw JSON with no plain-language explanation.

---

## FT-106 (Simulated interruption — see T-119)

See `tests/functionality/test_interruption.md` for the mid-task session kill scenario.
