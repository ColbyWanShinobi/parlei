# 📋 Parlei — Project Plan

> *Authored by Plan-er, on behalf of the Parliament.*
> *This document is the source of truth for what Parlei is, what it must do, and how success is measured. All tasks, code, and tests must trace back to this plan. If something is not here, it is not a feature — it is scope creep.*

---

## 🎯 Goals

A plan must have at least one clear, measurable goal. Parlei has three, in priority order:

### Goal 1 — Cross-Environment Parity ✅
> A user can install Parlei into any supported AI coding environment (Claude Code, Augment, Codex, OpenClaw) and get an **identical agent experience** — same agents, same memory, same personalities, same behavior — with zero manual duplication of files.

**Measured by:** Running the setup script for two different environments and confirming via checksum that all shared agent, memory, and personality files resolve to the same inodes (or identical content via symlink).

---

### Goal 2 — A Functional Parliament 🦉
> The full roster of 10 agents is defined, loaded, and reachable via Speak-er. Each agent can receive a task, perform its role, and return a correctly structured JSON response. The communication hierarchy (upward-only by default, lateral by grant) is enforced.

**Measured by:** A full integration test that sends a representative task to each agent via Speak-er and validates the JSON response structure and content against the agent's defined responsibilities.

---

### Goal 3 — Autonomous Maintenance 🌙
> The system maintains itself without human intervention after initial setup: nightly memory optimization runs, nightly backups are created, old backups are pruned, and the system surfaces any failures to the Spirit of the Forest rather than silently swallowing them.

**Measured by:** After 48 hours from setup, `backups/` contains at least one dated archive, `shared/memory/` shows evidence of optimization (deduplicated episodic logs), and any script failure produces a visible error log.

---

## 🗂️ Feature Areas

The following sections break Parlei into its major functional areas. Each area lists its features, the agents responsible, and any dependencies on other areas. **No implied features are permitted** — if it is not listed here, it does not exist.

---

### 1. 🔗 Installation & Environment Bootstrap

**Purpose:** Get Parlei running in a target AI coding environment with a single command.

**Features:**

#### 1.1 — Setup Script (`scripts/setup.sh`)
- Accepts a single argument: the target environment (`claude`, `augment`, `codex`, `openclaw`).
- Creates all required symlinks from environment-specific config files into `shared/`.
- Creates the `backups/` directory if it does not exist.
- Registers the nightly cron jobs for memory optimization and backup.
- Validates that symlinks resolved correctly after creation and exits non-zero on any failure.
- Is idempotent — safe to run multiple times without creating duplicate cron entries or broken symlinks.

#### 1.2 — Environment Config Files
- One `.md` file per supported environment: `CLAUDE.md`, `AUGGIE.md`, `CODEX.md`, `OPENCLAW.md`.
- Each file contains **only** environment-specific bootstrap instructions and loading directives — no agent logic, no memory, no personalities.
- Each file instructs the host tool to load Speak-er as the entry point.

#### 1.3 — Shared Directory Structure
- `shared/agents/` — one `.md` file per agent defining its role, responsibilities, and behavior.
- `shared/memory/` — one subdirectory per agent containing memory files.
- `shared/personalities/` — one `.md` file per agent defining its voice and character.
- `shared/prompts/` — reusable prompt templates (`.md` files with JSON metadata where needed).
- `shared/tools/` — shared script and tool definitions accessible to all agents.

**Dependencies:** None. This is the foundation everything else builds on.

**Responsible agents:** Architect-er (structure decisions), Deploy-er (script authorship).

---

### 2. 🦉 Agent System

**Purpose:** Define, load, and run the full roster of agents with distinct identities, capabilities, and behaviors.

**Features:**

#### 2.1 — Agent Definition Files
- Each agent has a `.md` file in `shared/agents/` with:
  - Name, role summary, and full responsibilities.
  - A list of inputs it accepts and outputs it produces.
  - Escalation behavior (what to do when it cannot complete a task).
  - Which other agents it is permitted to contact laterally (empty by default).

#### 2.2 — Agent Personality Files
- Each agent has a `.md` file in `shared/personalities/` defining:
  - Communication style and tone (e.g., Speak-er is warm and decisive; Review-er is precise and direct).
  - Any characteristic phrasings, attitudes, or behavioral quirks.
  - How the agent identifies itself when communicating.

#### 2.3 — Speak-er: Orchestrator Behavior
- Receives all input from the Spirit of the Forest.
- Evaluates each task and decides: handle directly, or delegate?
- Maintains a work history log for the current session in `shared/memory/speaker/`.
- Routes inter-agent communication; no agent bypasses Speak-er without an explicit lateral grant.
- Monitors for new agent needs and surfaces recommendations to the Spirit.
- Knows the full agent roster at all times.

#### 2.4 — Specialist Agent Behaviors
Each specialist agent (Plan-er, Task-er, Prompt-er, Check-er, Review-er, Architect-er, Deploy-er, Test-er, Re-Origination-er) must:
- Accept a task from Speak-er.
- Perform its defined role and produce its defined output.
- Return a valid JSON response to Speak-er (see Section 4: Communication Protocol).
- Never initiate contact with another agent unless Speak-er has granted lateral permission.

#### 2.5 — Re-Origination-er: Safety Gate
- Cannot be invoked without an explicit, confirmed instruction from the Spirit of the Forest passed through Speak-er.
- Must produce a `REORIGINATION.md` log documenting every structural change made.
- Speak-er must warn the Spirit before granting Re-Origination-er any permissions.

#### 2.6 — Agent Internal Task Tracking (`current_task.md`)
Every agent — without exception — maintains a `current_task.md` file in its memory directory (`shared/memory/<agent-name>/current_task.md`) for every task it receives. This file serves as the agent's internal task list and the single source of truth for resuming interrupted work.

- **Write first:** The file is created with all subtasks unchecked before any work begins. An agent that cannot write this file must halt and report to Speak-er.
- **Incremental checkoffs:** Each subtask is marked complete immediately upon finishing — never batched at the end.
- **Startup check:** On every startup, an agent's first action is to check for an existing `current_task.md`. If one is found with `Status: in-progress`, the agent notifies Speak-er and resumes from the first unchecked subtask.
- **Embed the original request:** The full JSON request envelope is embedded in `current_task.md` so the agent has complete context without any external dependency.
- **Completion and archival:** When all subtasks are done and the response is sent, the file is moved to `episodic/` (renamed with date and request ID) and removed from the active location.
- **Unresolvable resumption:** If an agent cannot complete a task even after resuming, it escalates to Speak-er with the full `current_task.md` contents attached.

Interruption causes this feature is designed to survive: token exhaustion, API errors, context window resets, process crashes, and session timeouts.

**Dependencies:** 1.3 (shared directory structure must exist before agents can be loaded).

**Responsible agents:** Speak-er (orchestration logic), all specialists (self-definition).

---

### 3. 🧠 Memory System

**Purpose:** Give each agent persistent, queryable memory that survives across sessions and is automatically maintained.

**Features:**

#### 3.1 — Per-Agent Memory Structure
Each agent has a subdirectory in `shared/memory/<agent-name>/` containing:
- `identity.md` — Static. Who this agent is, its core values, what it will and will not do.
- `long_term.md` — Semi-static. Key facts, decisions, and context the agent must always have.
- `episodic/` — Dynamic. Date-stamped `.md` files, one per session, recording what happened.

#### 3.2 — Memory Read/Write Conventions
- Agents read their own memory on startup.
- Agents write to `episodic/` at the end of each session.
- No agent reads or writes another agent's memory directly — all cross-agent memory access goes through Speak-er.
- All memory files are plain Markdown (`.md`). Structured entries within a memory file use embedded JSON code blocks, never YAML.

#### 3.3 — Nightly Memory Optimization (`scripts/memory_optimize.sh`)
- Deduplicates repeated entries across episodic logs.
- Identifies entries in episodic logs that have appeared in 3 or more sessions and promotes them to `long_term.md`.
- Prunes episodic log entries older than a configurable threshold (default: 90 days).
- Makes one LLM API call per agent to summarize and restructure `long_term.md` for conciseness.
- Writes a summary of changes made to `shared/memory/optimize_log.md` (appended, not overwritten).
- Exits non-zero and appends to `shared/memory/error_log.md` if any step fails.

#### 3.4 — LLM Interface for Memory Optimization
- Configurable via a JSON config file (`shared/tools/memory_config.json`).
- Supports local inference via Ollama (open source, preferred) or any OpenAI-compatible API endpoint.
- The config specifies: endpoint URL, model name, and auth token (if needed).
- No proprietary SDK dependency — uses plain HTTP requests.

**Dependencies:** 1.3 (directory structure), 1.1 (cron registration).

**Responsible agents:** All agents (memory consumers), Architect-er (memory schema), Deploy-er (cron + script).

---

### 4. 📡 Agent Communication Protocol

**Purpose:** Define the exact format and rules for how agents exchange information, ensuring reliable, auditable, and self-healing message passing.

**Features:**

#### 4.1 — JSON Message Format
All inter-agent messages use JSON with the following required fields:

**Request envelope:**
```json
{
  "from": "<agent-name>",
  "to": "<agent-name>",
  "request_id": "<unique-id>",
  "items": [
    {
      "id": "<integer>",
      "type": "<task-type>",
      "description": "<what is being asked>",
      "context": "<any relevant file paths, data, or background>"
    }
  ]
}
```

**Response envelope:**
```json
{
  "from": "<agent-name>",
  "to": "<agent-name>",
  "request_id": "<matching-request-id>",
  "items": [
    {
      "id": "<integer matching request>",
      "status": "confirmed | incomplete | failed | deferred",
      "notes": "<explanation, file paths, or output>",
      "output": "<optional: file path or inline content produced>"
    }
  ]
}
```

#### 4.2 — Upward-Only Communication Default
- Agents send responses to Speak-er only.
- Agents do not address messages to other agents unless Speak-er has issued a lateral grant.
- A lateral grant is scoped to a specific task and expires when the task is resolved.

#### 4.3 — Retry & Escalation Protocol
- When an agent receives a response that is missing one or more item IDs from its request, it re-sends **only the missing items**, up to **3 attempts**.
- On the third failure, the agent sends a special escalation message to Speak-er with `"type": "escalation"` and a full log of the failed attempts.
- Speak-er notifies the Spirit of the Forest of the escalation and awaits instruction.

#### 4.4 — Request ID Generation
- Request IDs follow the format: `req-<agent-name>-<YYYYMMDD>-<sequence>` (e.g., `req-tasker-20260327-003`).
- Each agent maintains a per-session sequence counter.

**Dependencies:** 2.3, 2.4 (agents must exist to communicate).

**Responsible agents:** Speak-er (routing), Architect-er (protocol design), all agents (compliance).

---

### 5. 💾 Backup System

**Purpose:** Ensure the entire Parlei shared state is automatically backed up nightly and recoverable without data loss.

**Features:**

#### 5.1 — Nightly Backup Script (`scripts/backup.sh`)
- Runs after `memory_optimize.sh` completes successfully.
- Compresses `shared/` into a `tar.gz` archive (using `gzip` or `zstd` — open source, no external dependencies).
- Names the archive `backups/YYYY-MM-DD.tar.gz`.
- A configurable retention count (default: 30 backups) controls how many archives are kept; older ones are deleted.
- Writes a one-line success entry to `backups/backup_log.md`.
- Exits non-zero and appends to `backups/error_log.md` if compression or file operations fail.

#### 5.2 — Cron Registration
- `scripts/setup.sh` installs both cron jobs (memory optimization and backup) at install time.
- Memory optimization runs at **02:00** local time nightly.
- Backup runs at **02:30** local time nightly (after optimization).
- Cron entries are written to the user's crontab. Setup is idempotent — duplicate entries are not created.

#### 5.3 — Backup Restore
- A `scripts/restore.sh` script accepts a date argument (e.g., `restore.sh 2026-03-26`) and extracts the corresponding archive back into `shared/`, after prompting the user for confirmation.
- The restore script does **not** overwrite `backups/` itself.

**Dependencies:** 1.1 (setup script), 3.3 (memory optimization must complete before backup).

**Responsible agents:** Deploy-er (script authorship), Architect-er (scheduling decisions).

---

### 6. ✍️ Core Document Outputs

**Purpose:** Ensure the agents that produce living documents (`PLAN.md`, `TASKS.md`, `ARCHITECTURE.md`) do so in a consistent, structured, and machine-readable way.

**Features:**

#### 6.1 — `PLAN.md` (this document)
- Maintained by Plan-er.
- Must always contain: at least one measurable goal, a full feature list, a dependency map, and a testing strategy section.
- Updated whenever the Spirit of the Forest changes the project scope.

#### 6.2 — `TASKS.md`
- Maintained by Task-er.
- Derived from `PLAN.md`. Every feature in the plan must have at least one corresponding task.
- Each task has: a unique ID, a description, a clear completion condition, a status (`todo | in-progress | done | blocked`), and the responsible agent.

#### 6.3 — `ARCHITECTURE.md`
- Maintained by Architect-er.
- Documents all infrastructure and technology decisions, with rationale.
- Includes: language choices, communication patterns, deployment targets, and any explicitly rejected alternatives with reasons.

**Dependencies:** All three documents depend on each other for consistency. Check-er is responsible for verifying that consistency.

**Responsible agents:** Plan-er, Task-er, Architect-er, Check-er.

---

## 🔗 Feature Dependency Map

```
[1. Bootstrap & Install]
        │
        ▼
[2. Agent System] ──────────────────────────────────┐
        │                                            │
        ▼                                            ▼
[3. Memory System] ──► [5. Backup System]   [4. Communication Protocol]
        │                                            │
        └──────────────────┬─────────────────────────┘
                           ▼
                  [6. Document Outputs]
```

**Critical path:** Installation → Agent System → Communication Protocol → everything else.

No memory, backup, or document output feature can be built before the agent system and communication protocol are defined and testable.

---

## 🧪 Testing Strategy

> Test-er is the guardian of this section. No feature is complete until its tests are written, passing, and non-trivial.

### Unit Tests 🔬

Each of the following must have isolated unit tests:

| Component | What to Test |
|---|---|
| `scripts/setup.sh` | Symlink creation, idempotency, cron registration, non-zero exit on failure |
| `current_task.md` write behavior | File created before work begins, all subtasks unchecked, original request embedded |
| `current_task.md` checkoff behavior | Each subtask marked complete immediately on finish; final state shows all checked |
| `current_task.md` startup/resume behavior | Existing in-progress file detected, Speak-er notified, work resumes from first unchecked subtask |
| `current_task.md` completion/archival | On completion, file moved to `episodic/` with date+request-ID name; not left in active location |
| `scripts/memory_optimize.sh` | Deduplication logic, promotion threshold, pruning, error logging |
| `scripts/backup.sh` | Archive creation, retention pruning, error logging, correct naming |
| `scripts/restore.sh` | Correct extraction, confirmation prompt, no overwrite of backups/ |
| JSON message format | Valid envelope structure, required fields present, request_id format |
| Request ID generator | Correct format, sequential within session, no collisions |
| Retry counter | Increments correctly, triggers escalation at attempt 3, resets on success |
| Memory read/write | Correct file paths, no cross-agent access, correct Markdown output |
| LLM interface module | Correct HTTP request shape, handles API errors gracefully, falls back cleanly |

### Integration Tests 🔗

| Scenario | What to Verify |
|---|---|
| Full setup → two environments | Both environments resolve all symlinks to the same `shared/` content |
| Task sent to each specialist agent | Each agent returns a valid JSON response with correct `from`, `to`, `request_id`, and all item IDs |
| Missing item in response | Retry fires, escalates after 3 failures, Speak-er receives escalation message |
| Interrupted task resumes correctly | An agent with an in-progress `current_task.md` resumes from the first unchecked subtask and notifies Speak-er |
| Interrupted task that cannot resume | Agent escalates to Speak-er with full `current_task.md` attached |
| Completed task archived | After completion, `current_task.md` is moved to `episodic/` and no longer present at the active path |
| Lateral grant flow | Speak-er grants lateral access; agents communicate directly; grant expires after task |
| Memory optimization run | Episodic logs deduplicated, long_term.md updated, optimize_log.md appended |
| Backup run after optimization | Archive exists in backups/, retention count respected, backup_log.md updated |
| Restore from backup | shared/ content matches the backup archive for the given date |
| Re-Origination-er safety gate | Invocation without Spirit confirmation is blocked; confirmation produces REORIGINATION.md |

### Functionality Tests 🎯

These are end-to-end scenarios that validate the system behaves correctly as a whole:

| Scenario | Pass Condition |
|---|---|
| New project bootstrap | A new developer runs setup.sh and can interact with all agents within 5 minutes |
| Simulated mid-task interruption | An agent's session is killed after 2 of 5 subtasks complete; on restart, it resumes at subtask 3 with no repeated work and no lost output |
| Plan → Tasks coherence | Plan-er produces PLAN.md; Task-er produces TASKS.md; Check-er confirms every plan feature has a task |
| 48-hour autonomous operation | After setup, no human intervention: backups present, memory optimized, no silent failures |
| Agent roster completeness | All 10 agents respond to a "who are you" query with their defined identity and role |
| Environment switch | User switches from Claude Code to Augment; agent behavior, memory, and personalities are identical |
| Escalation visible to human | A deliberately broken agent response triggers the full retry + escalation chain and produces a human-readable notification |

### What We Are Not Testing

- LLM response quality (non-deterministic; out of scope for automated tests).
- Proprietary AI tool internals (Claude, Augment, etc.).
- Operating system cron behavior beyond correct entry registration.

---

## ⚠️ Coherence Notes

*The following are implied dependencies or potential contradictions that Plan-er has identified and resolved explicitly:*

1. **Memory optimization requires a working LLM interface** — the memory system (Feature 3) has a hard dependency on the LLM interface module (Feature 3.4). If the LLM call fails, optimization must degrade gracefully (skip the summarization step, log the error) rather than abort entirely.

2. **Backup depends on memory optimization completing** — `backup.sh` should run after `memory_optimize.sh`. The cron schedule (02:00 / 02:30) enforces this, but `backup.sh` should also check for an error log from optimization and warn if one exists.

3. **Re-Origination-er breaks the memory contract** — since Re-Origination-er may restructure `shared/`, it could invalidate memory file paths. After any Re-Origination-er run, memory optimization must be triggered manually before the nightly schedule resumes.

4. **Lateral grants are session-scoped, not persisted** — a lateral communication grant does not survive a session restart. This is intentional. If a recurring lateral relationship is needed, it should be formalized in the relevant agent definition files instead.

7. **`current_task.md` and Re-Origination-er** — Re-Origination-er may restructure `shared/memory/`, which could move or destroy active `current_task.md` files for other agents. Before Re-Origination-er is granted any permissions, Speak-er must confirm that no other agent has an in-progress `current_task.md`. If any do, those tasks must complete or be explicitly abandoned first.

8. **`current_task.md` must not be backed up mid-task** — the nightly backup script should skip any `current_task.md` file whose `Status` is `in-progress`, since a backup of a half-complete task creates a misleading restore point. Only completed/archived task files (in `episodic/`) are included in backups.

5. **Symlinks require a POSIX-compatible shell environment** — the setup script assumes a Unix-like OS. Windows compatibility is out of scope for v1 but should be flagged to Architect-er if a Windows user is anticipated.

6. **`TASKS.md` is a derivative of `PLAN.md`**, not the other way around. If the plan changes, `TASKS.md` must be regenerated or updated. Check-er is responsible for detecting and flagging drift between them.
