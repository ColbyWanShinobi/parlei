<!-- parlei-bootstrap -->
# 🦉 Parlei — Claude Code Bootstrap

> *Project bootstrap for Parlei routing and specialist dispatch.*

## ⚠️ MUST READ — Loading Instructions

**These instructions MUST be read at session start. Parlei will not function correctly without the routing files below.**

Load only the routing files listed below. Do not read specialist agent files into this context — specialists run as separate subprocesses via `dispatch.sh`.

### Critical Files (in order):

1. **MUST READ:** `shared/tools/protocol.md` — the inter-agent communication protocol.
2. **MUST READ:** `shared/tools/current_task_spec.md` — the task tracking format every agent uses.
3. **MUST READ:** `shared/agents/speaker.md` — the primary routing and delegation instructions.
4. **OPTIONAL:** `shared/memory/speaker/current_task.md` — if it exists with `Status: in-progress`, resume from the recorded task state.

---

## Entry Point

Claude Code uses Parlei as a routing layer. Route work to the appropriate specialist agents via dispatch.

## Agent Roster

The following specialists are available. You do not read their files — you dispatch to them. Each runs as a separate subprocess with its own model and context.

| Agent | File | Model |
|---|---|---|
| Architect-er | `shared/agents/architecter.md` | `claude-sonnet-4-6` |
| Check-er | `shared/agents/checker.md` | `claude-sonnet-4-6` |
| Code-er | `shared/agents/coder.md` | `claude-sonnet-4-6` |
| Deploy-er | `shared/agents/deployer.md` | `claude-sonnet-4-6` |
| Plan-er | `shared/agents/planer.md` | `claude-sonnet-4-6` |
| Prompt-er | `shared/agents/prompter.md` | `claude-sonnet-4-6` |
| Prose-Write-er | `shared/agents/prosewriter.md` | `claude-sonnet-4-6` |
| Re-Origination-er | `shared/agents/reoriginator.md` | `claude-sonnet-4-6` |
| Review-er | `shared/agents/reviewer.md` | `claude-sonnet-4-6` |
| Task-er | `shared/agents/tasker.md` | `claude-sonnet-4-6` |
| Tech-Write-er | `shared/agents/techwriter.md` | `claude-sonnet-4-6` |
| Test-er | `shared/agents/tester.md` | `claude-sonnet-4-6` |

## ⚠️ CRITICAL — Delegation via Dispatch

**Specialist agents are invoked ONLY via dispatch. Never read specialist agent files into your context.**

Delegation is a subprocess call, not a file read. When you decide to delegate:

1. Write a request JSON to a temp file. Use `bash shared/tools/request_id.sh speaker` to generate the `request_id`. Follow the schema in `shared/tools/schema_request.json`.
2. Call: `bash shared/tools/dispatch.sh <agent-name> <request-json-file>`
3. Read the JSON response from stdout.
4. Check all item IDs are present. If any are missing, use `shared/tools/retry.sh` and re-dispatch with only the missing items.
5. Translate the final response into plain language before relaying it.

All context a specialist needs must be in the `context` field of the request — specialists have no access to this conversation.

## Claude Code-Specific Notes

- File tools (`Read`, `Write`, `Edit`) are available for all memory and task file operations.
- The `Bash` tool is used for dispatch: `bash shared/tools/dispatch.sh <agent> <request-file>`.
- Do not use YAML in any file you create or modify. Markdown and JSON only.
- If a tool call fails, write the failure to `shared/memory/speaker/current_task.md` under `Interrupt reason`.
- Keep routing prompts short and delegate reasoning to specialist subprocesses.

---

**Parlei bootstrap ready.**
<!-- end-parlei-bootstrap -->
