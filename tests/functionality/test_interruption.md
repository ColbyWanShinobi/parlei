# 🔁 Functionality Test: Mid-Task Session Kill and Resume (T-119)

> *This test validates the `current_task.md` resilience system end-to-end.*

---

## Pre-conditions

- Parlei is set up in a working environment (`scripts/setup.sh` completed).
- `shared/tools/current_task_spec.md` exists.
- At least one agent has been loaded and can receive tasks.

---

## Steps

1. Send Speak-er a multi-step task with at least 5 subtasks. A good example:
   > "Ask Plan-er to write a full docs/PLAN.md for a new to-do app. It should include goals, features, dependencies, and a testing strategy."

2. Wait until Plan-er has checked off at least 2 subtasks (you can see this in `shared/memory/planer/current_task.md`).

3. **Kill the session.** Close the AI tool window, reset the context, or revoke the API token temporarily — whichever is appropriate for the environment.

4. Reopen the session. Load the environment config again.

5. Observe Speak-er's first response.

---

## Pass Condition

Speak-er's first response must:
1. Detect the in-progress `shared/memory/planer/current_task.md`.
2. Notify the Spirit in plain language: something like "I found an interrupted task for Plan-er — it was writing a docs/PLAN.md for a to-do app. It completed 2 of 5 subtasks. Shall I resume from subtask 3?"
3. Upon confirmation, Plan-er resumes from the correct subtask (subtask 3, not subtask 1).
4. Subtasks 1 and 2 are **not repeated**.
5. The final output (completed `docs/PLAN.md`) is consistent — the sections written before the kill match the sections written after.
6. After all subtasks complete, `shared/memory/planer/current_task.md` is archived to `episodic/` and no longer present at the active path.

---

## Fail Conditions

- Speak-er does not mention the interrupted task.
- Plan-er starts from subtask 1 (repeated work).
- The final `docs/PLAN.md` has inconsistencies between pre- and post-interruption sections.
- `current_task.md` remains at the active path after completion.
- Any subtask is marked complete but the corresponding work was not done.
