# 🔧 Parlei — Fix & Upgrade Task List

> *This document tracks all required fixes to known bugs and the architectural upgrade to real multi-process agents with per-agent model routing.*
>
> *Every task has a clear completion condition. A task is not done when the work is done — it is done when its completion condition is verifiably true.*

---

## 📊 Status Key

| Status | Meaning |
|---|---|
| `todo` | Not started |
| `in-progress` | Actively being worked |
| `done` | Completion condition verified |
| `blocked` | Cannot proceed — see "Blocked by" |

## 🏷️ Priority Key

| Priority | Meaning |
|---|---|
| `P0` | Blocker — system cannot run without this |
| `P1` | High — significant breakage or data loss risk |
| `P2` | Medium — behavioral bug or degraded capability |
| `P3` | Low — polish, consistency, or future-proofing |

---

## 📋 Master Index

| ID | Title | Priority | Status |
|---|---|---|---|
| **Phase 1 — Critical Bug Fixes** ||||
| FIX-001 | Create missing `shared/prompts/` directory | `P0` | `done` |
| FIX-002 | Add missing fields to `memory_config.json` | `P0` | `done` |
| FIX-003 | Fix `grep -Pn` → `grep -En` in test fixtures | `P1` | `done` |
| FIX-004 | Add `.gitignore` for generated and runtime files | `P2` | `done` |
| FIX-005 | Add Anthropic native response format to `llm_call.sh` | `P1` | `done` |
| **Phase 2 — Model Routing Configuration** ||||
| FIX-006 | Create `shared/tools/model_routing.json` | `P0` | `done` |
| FIX-007 | Add `model` field to each agent definition file | `P1` | `done` |
| FIX-008 | Record model routing decisions as ADR-011 in `ARCHITECTURE.md` | `P2` | `done` |
| **Phase 3 — Real Multi-Process Agent Dispatch** ||||
| FIX-009 | Create inbox and outbox directories for all agents | `P0` | `done` |
| FIX-010 | Write `shared/tools/build_system_prompt.sh` | `P0` | `done` |
| FIX-011 | Write `shared/tools/agent_runner.sh` | `P0` | `done` |
| FIX-012 | Write `shared/tools/dispatch.sh` | `P0` | `done` |
| FIX-013 | Fix `codex --quiet` invocation in `memory_optimize.sh` | `P1` | `done` |
| FIX-014 | Update `memory_optimize.sh` to use `dispatch.sh` for LLM summarization | `P1` | `done` |
| **Phase 4 — Update Bootstrap Files & Agent Specs** ||||
| FIX-015 | Update `CLAUDE.md` — dispatch-aware Speak-er instructions | `P0` | `done` |
| FIX-016 | Update `bootstraps/AUGGIE.md` — dispatch-aware Speak-er instructions | `P1` | `done` |
| FIX-017 | Update `bootstraps/CODEX.md` — dispatch-aware + correct relative paths | `P1` | `done` |
| FIX-018 | Update `bootstraps/OPENCLAW.md` — dispatch-aware + correct relative paths | `P1` | `done` |
| FIX-019 | Update `shared/agents/speaker.md` — document dispatch delegation workflow | `P1` | `done` |
| FIX-020 | Update `shared/tools/protocol.md` — add real dispatch invocation section | `P1` | `done` |
| **Phase 5 — Setup Script & Infrastructure** ||||
| FIX-021 | Update `setup.sh` — create inbox/outbox dirs, validate new tool scripts | `P0` | `todo` |
| **Phase 6 — Tests** ||||
| FIX-022 | Fix all existing failing tests (prompts dir, grep -P, config fields) | `P0` | `todo` |
| FIX-023 | Unit tests for `build_system_prompt.sh` | `P1` | `todo` |
| FIX-024 | Unit tests for `agent_runner.sh` | `P1` | `todo` |
| FIX-025 | Unit tests for `dispatch.sh` | `P1` | `todo` |
| FIX-026 | Unit test: model routing — correct model selected per agent | `P1` | `todo` |
| FIX-027 | Integration test: Speak-er dispatches to a specialist, gets a valid response | `P1` | `todo` |
| FIX-028 | Integration test: dispatch respects model_routing.json | `P2` | `todo` |
| **Phase 7 — Concurrency & Safety** ||||
| FIX-029 | Add file lock to `dispatch.sh` to prevent concurrent inbox/outbox collisions | `P2` | `done` |

---

## 📁 Phase 1 — Critical Bug Fixes

---

### FIX-001 — Create missing `shared/prompts/` directory

**Priority:** P0
**Type:** `infra`

**Problem:** `setup.sh` checks for `shared/prompts/` in `REQUIRED_DIRS` at line 74 and exits with an error if it is missing. The test fixture creates it (line 32 of `tests/fixtures/setup.bash`). Prompt-er's entire purpose depends on maintaining this library. The directory does not exist in the repo.

**Work:**
- Create `shared/prompts/.gitkeep` so the directory is tracked by git.

**Completion condition:** `ls shared/prompts/` succeeds. `bash scripts/setup.sh claude` exits 0.

---

### FIX-002 — Add missing fields to `memory_config.json`

**Priority:** P0
**Type:** `infra`

**Problem:** `shared/tools/memory_config.json` (the production config) is missing `llm_endpoint`, `llm_auth_token`, and `llm_timeout_seconds`. These three fields are read by `llm_call.sh`. The test fixture's fallback defines them correctly but the real config does not. Any path through the code that calls `llm_call.sh` will silently receive an empty endpoint and fail or hang.

**Current production config:**
```json
{
  "llm_model": "",
  "episodic_retention_days": 90,
  "promotion_threshold": 3,
  "backup_retention_count": 30,
  "compression": "gzip"
}
```

**Required config:**
```json
{
  "llm_endpoint": "",
  "llm_model": "",
  "llm_auth_token": "",
  "llm_timeout_seconds": 30,
  "episodic_retention_days": 90,
  "promotion_threshold": 3,
  "backup_retention_count": 30,
  "compression": "gzip"
}
```

**Work:**
- Add the three missing keys to `shared/tools/memory_config.json`.
- Empty strings are intentional — users configure their own endpoint.

**Completion condition:** `python3 -c "import json; d=json.load(open('shared/tools/memory_config.json')); assert 'llm_endpoint' in d and 'llm_auth_token' in d and 'llm_timeout_seconds' in d; print('ok')"` prints `ok`.

---

### FIX-003 — Fix `grep -Pn` → `grep -En` in test fixtures

**Priority:** P1
**Type:** `test`

**Problem:** `tests/fixtures/setup.bash` line 163 uses `grep -Pn` (Perl-compatible regex). macOS ships BSD grep, which does not support the `-P` flag. Every test that calls `assert_no_yaml` will fail on macOS with `grep: invalid option -- P`.

**Work:**
- In `tests/fixtures/setup.bash`, change `grep -Pn '^---\s*$'` to `grep -En '^---[[:space:]]*$'`.
- The `\s` Perl class becomes `[[:space:]]` in POSIX extended regex.

**Completion condition:** `assert_no_yaml` passes on macOS. Running `bash -c "grep -En '^---[[:space:]]*$' /dev/null"` exits 0.

---

### FIX-004 — Add `.gitignore` for generated and runtime files

**Priority:** P2
**Type:** `infra`

**Problem:** Several paths will be generated at runtime and must not be committed:
- `backups/` — contains potentially large `.tar.gz` archives
- `.parlei-env` — machine-specific environment marker written by `setup.sh`
- `shared/memory/*/episodic/` — session logs that accumulate over time
- `shared/memory/*/.retry_state/` — transient retry state written by `retry.sh`
- `shared/memory/*/.request_id_state` — sequence counter written by `request_id.sh`
- `shared/memory/*/inbox/` and `shared/memory/*/outbox/` — runtime IPC directories (see Phase 3)
- `shared/memory/optimize_log.md` and `shared/memory/error_log.md` — runtime logs
- `shared/memory/*/current_task.md` — active task files (should never be committed mid-run)

**Work:**
- Create a `.gitignore` at the repo root with all of the above patterns.
- Verify with `git status` that no runtime artifacts are staged.

**Completion condition:** `.gitignore` exists. `git status` shows none of the above patterns as untracked or staged after a `setup.sh` run.

---

### FIX-005 — Add Anthropic native response format to `llm_call.sh`

**Priority:** P1
**Type:** `feature`

**Problem:** `shared/tools/llm_call.sh` parses three response shapes: OpenAI `choices[0].message.content`, Ollama `message.content`, and generic `response`. Anthropic's Messages API returns `content[0].text` (the first content block when `type == "text"`). Pointing `llm_call.sh` at `api.anthropic.com` will hit the unhandled fallback branch and print raw JSON to stderr, returning exit code 1.

**Work:**
- In the `python3` response parsing block in `llm_call.sh`, add a fourth branch:
  ```python
  # Anthropic Messages API: content[0].text
  elif 'content' in data and isinstance(data['content'], list) and data['content']:
      print(data['content'][0].get('text', ''))
  ```
- Place this branch before the generic `response` fallback.

**Completion condition:** Sending a mock response shaped like `{"content": [{"type": "text", "text": "hello"}]}` through the parsing logic returns `hello` with exit code 0.

---

## 🤖 Phase 2 — Model Routing Configuration

The core problem: every agent is currently loaded into the same LLM context. There is no mechanism to run a specialist agent on a different model. This phase establishes the configuration that Phase 3 will execute against.

---

### FIX-006 — Create `shared/tools/model_routing.json`

**Priority:** P0
**Type:** `infra`

**Problem:** No per-agent model assignment exists. Every agent defaults to whatever model the user has open. The design goal is: Speak-er runs on a lightweight model for cost-efficient routing; specialists run on models appropriate to the complexity of their work.

**Work:** Create `shared/tools/model_routing.json` with the following content and rationale:

```json
{
  "_comment": "Model routing table. Each entry maps an agent to its default model and describes why that model was chosen. Override any entry with an environment-specific value — the dispatch script reads this file at invocation time.",
  "speaker": {
    "model": "claude-haiku-4-5-20251001",
    "description": "Lightweight orchestrator — routes tasks, synthesizes results, communicates with the Spirit",
    "rationale": "Speak-er's job is routing, coordination, and communication. Deep reasoning is not required. Haiku provides fast, low-cost responses appropriate for an orchestrator that handles every message."
  },
  "checker": {
    "model": "claude-haiku-4-5-20251001",
    "description": "Mechanical verification — confirms tasks have corresponding implementations",
    "rationale": "Check-er does pattern matching and presence/absence verification. It does not need to reason deeply — it needs to be fast and cheap."
  },
  "tasker": {
    "model": "claude-sonnet-4-6",
    "description": "Task decomposition and clarity — translates plan features into discrete, measurable tasks",
    "rationale": "Task decomposition requires judgment about ambiguity and measurability. Sonnet provides good reasoning at moderate cost."
  },
  "planer": {
    "model": "claude-sonnet-4-6",
    "description": "Structured planning — maintains PLAN.md, ensures feature coherence",
    "rationale": "Planning requires multi-step reasoning about dependencies and gaps. Sonnet is appropriate."
  },
  "prompter": {
    "model": "claude-sonnet-4-6",
    "description": "Prompt engineering — optimizes prompts for accuracy, concision, and caching",
    "rationale": "Prompter must understand how LLMs process text at a meta level. Sonnet has sufficient capability for this."
  },
  "deployer": {
    "model": "claude-sonnet-4-6",
    "description": "DevOps and deployment — scripts, CI/CD, infrastructure operations",
    "rationale": "Deployer handles technical but well-defined work. Sonnet is appropriate."
  },
  "tester": {
    "model": "claude-sonnet-4-6",
    "description": "Test authorship — writes unit, integration, and functionality tests",
    "rationale": "Good test coverage requires judgment about edge cases. Sonnet provides this at reasonable cost."
  },
  "reviewer": {
    "model": "claude-opus-4-6",
    "description": "Deep code review — analyzes code quality, security, consistency, and correctness",
    "rationale": "Code review has high consequence. Subtle security flaws and architectural problems require the best available reasoning. Opus is justified here."
  },
  "architecter": {
    "model": "claude-opus-4-6",
    "description": "System design — infrastructure decisions, technology choices, communication patterns",
    "rationale": "Architectural decisions are hard to reverse and have long-term consequences. Opus provides the best judgment for high-stakes decisions."
  },
  "reoriginator": {
    "model": "claude-opus-4-6",
    "description": "Major restructuring — reorganizes the repo for a new major version, may break things intentionally",
    "rationale": "Re-Origination-er makes broad, potentially destructive changes. The highest model quality is appropriate when stakes are maximum."
  }
}
```

**Completion condition:** `python3 -c "import json; d=json.load(open('shared/tools/model_routing.json')); assert all(a in d for a in ['speaker','reviewer','architecter','reoriginator','checker']); print('ok')"` prints `ok`.

---

### FIX-007 — Add `model` field to each agent definition file

**Priority:** P1
**Type:** `content`

**Problem:** Each agent's `.md` file in `shared/agents/` does not document which model it runs on. This is operational information that belongs in the agent spec — if a new agent file is added without a corresponding entry in `model_routing.json`, the system will silently fall back to a default.

**Work:**
- Add a `## Default Model` section to each agent definition file in `shared/agents/`.
- The section should name the model and briefly state the rationale (matching the rationale in `model_routing.json`).
- All ten agents: `speaker.md`, `planer.md`, `tasker.md`, `prompter.md`, `checker.md`, `reviewer.md`, `architecter.md`, `deployer.md`, `tester.md`, `reoriginator.md`.

**Completion condition:** `grep -l "## Default Model" shared/agents/*.md | wc -l` prints `10`.

---

### FIX-008 — Record model routing decisions as ADR-011 in `ARCHITECTURE.md`

**Priority:** P2
**Type:** `content`

**Problem:** The decision to assign different models to different agents is a significant architectural choice with cost, quality, and maintenance implications. Per the project's conventions, every significant decision belongs in `ARCHITECTURE.md` as an ADR with rationale and rejected alternatives.

**Work:** Add ADR-011 to `docs/ARCHITECTURE.md`:

```
ADR-011 — Per-agent model routing

Decision: Each agent is assigned a default model in shared/tools/model_routing.json.
Speak-er and Check-er use Haiku (low-cost, fast). Task-er, Plan-er, Prompt-er,
Deploy-er, and Test-er use Sonnet (balanced). Review-er, Architect-er, and
Re-Origination-er use Opus (highest capability for high-consequence work).

Why: Not all agent tasks require the same reasoning depth. Using the cheapest model
sufficient for each task reduces cost without reducing quality where it matters.
An orchestrator routing messages does not need the same capability as an agent
doing a deep code security review.

Alternatives considered:
- Single model for all agents: Rejected. Over-spends on simple tasks; under-spends
  on complex ones.
- User-chosen model for all: Rejected. Provides no cost control and leaves model
  selection as an uninformed user burden.
- Dynamic model selection per-task: Considered for v2. Adds complexity; static
  per-agent routing is the right starting point.
```

**Completion condition:** `grep "ADR-011" docs/ARCHITECTURE.md` exits 0 with output.

---

## 🚀 Phase 3 — Real Multi-Process Agent Dispatch

This is the core architectural upgrade. The current system runs all "agents" inside a single LLM context — they are personas, not processes. This phase makes each specialist agent a real subprocess invoked with its own model, system prompt, and isolated context.

**Architecture overview:**

```
Spirit of the Forest
        ↓
   [CLAUDE.md / AUGGIE.md / etc.]
        ↓
    Speak-er (Haiku)
     uses Bash tool to call:
        ↓
   dispatch.sh <agent> <request.json>
        ↓
   build_system_prompt.sh <agent>
        ↓ (assembled system prompt)
   agent_runner.sh <agent> <model> <system_prompt> <request.json>
        ↓ (invokes: claude --print --model <model> ...)
   Specialist Agent (own model, own context)
        ↓ (returns JSON to stdout)
   response written to outbox/<request_id>.json
        ↓
   dispatch.sh returns JSON to Speak-er
        ↓
   Speak-er synthesizes and responds to Spirit
```

---

### FIX-009 — Create inbox and outbox directories for all agents

**Priority:** P0
**Type:** `infra`

**Problem:** The dispatch system (FIX-011, FIX-012) writes requests to `shared/memory/<agent>/inbox/` and responses to `shared/memory/<agent>/outbox/`. These directories do not exist.

**Work:**
- For each of the 10 agents, create:
  - `shared/memory/<agent>/inbox/.gitkeep`
  - `shared/memory/<agent>/outbox/.gitkeep`
- Add inbox and outbox patterns to `.gitignore` (see FIX-004) so the message files themselves are not committed.

**Completion condition:** `ls shared/memory/speaker/inbox/ shared/memory/speaker/outbox/` exits 0 for all 10 agents.

---

### FIX-010 — Write `shared/tools/build_system_prompt.sh`

**Priority:** P0
**Type:** `feature`

**Problem:** No mechanism exists to assemble an agent's full system prompt from its component files. The dispatch pipeline needs to concatenate an agent's role, personality, identity, long-term memory, protocol rules, and task spec into a single coherent system prompt before invoking the LLM subprocess.

**Work:** Create `shared/tools/build_system_prompt.sh` with the following behavior:

- **Usage:** `build_system_prompt.sh <agent-name>`
- **Output:** A single assembled system prompt printed to stdout. No files written.
- **Assembly order:**
  1. `shared/agents/<agent>.md` — role, responsibilities, escalation behavior
  2. `shared/personalities/<agent>.md` — tone and communication style
  3. `shared/memory/<agent>/identity.md` — who the agent is at its core
  4. `shared/memory/<agent>/long_term.md` — accumulated knowledge and decisions (if non-empty)
  5. `shared/tools/protocol.md` — inter-agent communication rules
  6. `shared/tools/current_task_spec.md` — task tracking format
- **Section headers:** Each file is preceded by a Markdown heading so the agent can orient itself (e.g., `## Role & Responsibilities`, `## Personality`, `## Identity`, `## Long-Term Memory`, `## Communication Protocol`, `## Task Tracking`).
- **Missing files:** If any file is absent, print a warning to stderr and skip it (do not abort).
- **Exit codes:** 0 on success, 1 if the agent directory does not exist.

**Completion condition:** `bash shared/tools/build_system_prompt.sh speaker` exits 0 and its output contains text from `shared/agents/speaker.md` and `shared/personalities/speaker.md`. Running it for a nonexistent agent exits 1.

---

### FIX-011 — Write `shared/tools/agent_runner.sh`

**Priority:** P0
**Type:** `feature`

**Problem:** No mechanism exists to invoke a specialist agent as a real subprocess with its own model. This is the execution layer — it takes a built system prompt and a request, finds the right model, and calls the LLM CLI.

**Work:** Create `shared/tools/agent_runner.sh` with the following behavior:

- **Usage:** `agent_runner.sh <agent-name> <request-json-file>`
- **Steps:**
  1. Read the agent's model from `shared/tools/model_routing.json`. If the agent is not in the routing table, exit 1 with a clear error.
  2. Read the active environment from `.parlei-env` (written by `setup.sh`). Default to `claude` if the file does not exist.
  3. Call `build_system_prompt.sh <agent>` to assemble the system prompt. Capture to a variable.
  4. Validate that `<request-json-file>` exists and is valid JSON. Exit 1 if not.
  5. Invoke the LLM CLI appropriate to the active environment:
     - **claude:** `claude --print --model <model> -p "<system_prompt>" < <request-json-file>`
     - **codex:** `llm_call.sh <endpoint> <model> "<system_prompt>\n\nRequest:\n$(cat <request-json-file>)"` (Codex CLI does not support non-interactive `--print` equivalent; fall back to `llm_call.sh`)
     - **openclaw:** `openclaw --print --model <model> -p "<system_prompt>" < <request-json-file>`
     - **augment:** `llm_call.sh <endpoint> <model> "<system_prompt>\n\nRequest:\n$(cat <request-json-file>)"` (no CLI)
  6. Validate that the output is non-empty JSON. If not, exit 1 with the raw output in the error message.
  7. Print the JSON response to stdout.
- **Exit codes:** 0 on success, 1 on any failure. Failures print descriptive messages to stderr.
- **No side effects:** Does not write to inbox/outbox. That is `dispatch.sh`'s job.

**Completion condition:** With a mock request JSON and a mock `claude` binary in PATH that echoes a valid JSON response, `agent_runner.sh checker <mock-request.json>` exits 0 and its stdout is valid JSON. Running with a nonexistent agent exits 1.

---

### FIX-012 — Write `shared/tools/dispatch.sh`

**Priority:** P0
**Type:** `feature`

**Problem:** No mechanism exists to route a request from Speak-er to a specialist agent, run the agent, and return the response. This is the orchestration layer that Speak-er calls via the Bash tool.

**Work:** Create `shared/tools/dispatch.sh` with the following behavior:

- **Usage:** `dispatch.sh <agent-name> <request-json-file>`
- **Steps:**
  1. Validate arguments. Agent must exist in `shared/agents/`. Request file must exist and be valid JSON.
  2. Extract `request_id` from the JSON file. If absent, generate one via `request_id.sh`.
  3. Copy the request file to `shared/memory/<agent>/inbox/<request_id>.json`.
  4. Call `agent_runner.sh <agent> shared/memory/<agent>/inbox/<request_id>.json`.
     - If `agent_runner.sh` exits non-zero, write an escalation JSON to stdout (format: standard escalation envelope per `protocol.md`) and exit 1.
  5. Write the response to `shared/memory/<agent>/outbox/<request_id>.json`.
  6. Validate the response matches the response schema (`schema_response.json`). If validation fails, log a warning to stderr but still return the response — the caller can decide whether to retry.
  7. Print the response JSON to stdout.
  8. Clean up: remove the inbox file after successful dispatch. The outbox file is retained for audit purposes.
- **Exit codes:** 0 on success (even if the response contains `"status": "failed"` items — that is a protocol-level failure, not a dispatch failure). 1 on a dispatch-level failure (runner crashed, no response returned, schema catastrophically invalid).

**Completion condition:** With a mocked `agent_runner.sh` that returns a valid JSON response, `dispatch.sh checker <request.json>` exits 0, writes to the outbox, removes the inbox file, and prints the response to stdout. A mocked runner that exits 1 causes `dispatch.sh` to print an escalation envelope and exit 1.

---

### FIX-013 — Fix `codex --quiet` invocation in `memory_optimize.sh`

**Priority:** P1
**Type:** `feature`

**Problem:** `memory_optimize.sh` invokes the Codex CLI as `codex --quiet`. The actual OpenAI Codex CLI (`github.com/openai/codex`) is an interactive REPL with no `--quiet` non-interactive pipe mode. This invocation will hang or error in a cron context.

**Work:**
- Remove the `codex` case from the `invoke_tool_llm` function in `memory_optimize.sh`.
- Replace it with a call to `llm_call.sh` using the configured `llm_endpoint` and `llm_model` from `memory_config.json`. This is already the approach used for Augment and serves as the generic fallback.
- Document in a comment that Codex environment uses `llm_call.sh` (OpenAI-compatible endpoint) rather than the interactive Codex CLI.

**Completion condition:** The `codex` case in `invoke_tool_llm` does not reference the `codex` binary. The function for the `codex` environment calls `llm_call.sh` with the configured endpoint.

---

### FIX-014 — Update `memory_optimize.sh` to use `dispatch.sh` for LLM summarization

**Priority:** P1
**Type:** `feature`

**Problem:** `memory_optimize.sh` directly invokes the LLM CLI (`claude --print`, etc.) to summarize agent memory. This bypasses the new dispatch system, ignores per-agent model routing, and duplicates invocation logic. After Phase 3, the canonical way to make a single-shot LLM call through the agent system is `dispatch.sh`.

**Work:**
- Replace the direct CLI invocation in the `llm_summarize` step with a call to `dispatch.sh prompter <summarization-request.json>`, where Prompt-er is asked to summarize and condense the target agent's `long_term.md`.
- The request JSON should include the memory content as context and clearly specify the output format (overwrite the original `long_term.md`).
- This means summarization now runs on Prompt-er's model (Sonnet) rather than a direct pipe to the CLI.

**Completion condition:** `memory_optimize.sh` does not contain any direct calls to `claude`, `openclaw`, or `invoke_tool_llm`. The summarization step builds a dispatch request and calls `dispatch.sh prompter`.

---

## 🔄 Phase 4 — Update Bootstrap Files & Agent Specs

---

### FIX-015 — Update `CLAUDE.md` — dispatch-aware Speak-er instructions

**Priority:** P0
**Type:** `content`

**Problem:** `CLAUDE.md` instructs Speak-er to "Read `shared/agents/<specialist>.md`" when delegating — i.e., load the specialist's definition into its own context and roleplay as that agent. This defeats the purpose of real multi-process dispatch.

**Work:** Revise `CLAUDE.md` loading instructions to:
1. Instruct Speak-er to load only its own files (speaker.md, personalities/speaker.md, memory/speaker/\*) — not all agents.
2. Instruct Speak-er that delegation means calling `bash shared/tools/dispatch.sh <agent> <request-json-file>` using the Bash tool — not reading and roleplaying as the agent.
3. Explain that the specialist agent runs as a real subprocess in its own context with its own model, and Speak-er should treat the JSON response as authoritative.
4. Add a note that Speak-er's model is Haiku by default; it should keep routing prompts short and delegate reasoning to specialist subprocesses.

**Completion condition:** `CLAUDE.md` contains the phrase `dispatch.sh` and does not instruct Speak-er to read any specialist agent file except via dispatch.

---

### FIX-016 — Update `bootstraps/AUGGIE.md`

**Priority:** P1
**Type:** `content`

**Problem:** Same issue as FIX-015. Additionally, Augment-specific notes should reference the `llm_call.sh` fallback for dispatch since Augment has no standalone CLI.

**Work:** Mirror the changes from FIX-015. Add an Augment-specific note that since there is no standalone CLI, `agent_runner.sh` will use `llm_call.sh` for all dispatches.

**Completion condition:** `bootstraps/AUGGIE.md` contains `dispatch.sh` and does not instruct loading specialist agent files directly.

---

### FIX-017 — Update `bootstraps/CODEX.md`

**Priority:** P1
**Type:** `content`

**Problem:** Same as FIX-015. Also: the current file references paths as `../shared/` (relative from `bootstraps/`), but paths in tool calls within the session should be relative to the repo root. This is a subtle but real confusion risk.

**Work:**
- Mirror dispatch-aware changes from FIX-015.
- Clarify in the Codex-specific notes that all file paths in tool calls are relative to the repo root (the directory where `setup.sh` was run), not relative to the `bootstraps/` directory.

**Completion condition:** `bootstraps/CODEX.md` contains `dispatch.sh` and includes a path-resolution note.

---

### FIX-018 — Update `bootstraps/OPENCLAW.md`

**Priority:** P1
**Type:** `content`

**Same as FIX-017**, substituting OpenClaw CLI invocation in `agent_runner.sh` notes.

**Completion condition:** `bootstraps/OPENCLAW.md` contains `dispatch.sh` and includes a path-resolution note.

---

### FIX-019 — Update `shared/agents/speaker.md` — dispatch delegation workflow

**Priority:** P1
**Type:** `content`

**Problem:** `speaker.md` describes delegation in abstract terms. It does not specify the mechanical process: write a request JSON, call dispatch.sh, read the response. Without this, Speak-er has no concrete procedure.

**Work:** Add a `## Delegation Procedure` section to `shared/agents/speaker.md`:

```
## Delegation Procedure

When Speak-er decides to delegate a task to a specialist:

1. Write a request JSON to a temp file following schema_request.json.
   Use request_id.sh to generate the request_id.
2. Call: bash shared/tools/dispatch.sh <agent> <request-file>
3. Read the JSON response from stdout.
4. Check all item IDs are present in the response. If any are missing,
   use retry.sh and re-dispatch with only the missing items.
5. After 3 failures, send an escalation to the Spirit of the Forest.
6. Translate the final response into plain language for the Spirit.
7. Never pass raw JSON to the Spirit of the Forest.
```

**Completion condition:** `grep -A 10 "Delegation Procedure" shared/agents/speaker.md` returns the procedure.

---

### FIX-020 — Update `shared/tools/protocol.md` — add dispatch invocation section

**Priority:** P1
**Type:** `content`

**Problem:** `protocol.md` documents message formats, retry logic, and topology — but not the mechanical invocation step. Agents that read this document do not know *how* to invoke each other, only the format of messages.

**Work:** Add a new `§8 — Dispatch Invocation` section to `protocol.md`:

```
## 8. Dispatch Invocation

All agent-to-agent communication occurs through the dispatch system. Speak-er
is the only agent that initiates dispatches. No specialist invokes another
specialist directly.

### Invoking a specialist:

    bash shared/tools/dispatch.sh <agent-name> <request-json-file>

The dispatch script handles model selection, system prompt assembly, subprocess
invocation, and outbox archiving. The response JSON is returned on stdout.

### Specialist agent context:

Each specialist agent runs in its own isolated subprocess with:
- Its own model (from model_routing.json)
- Its own assembled system prompt (from build_system_prompt.sh)
- Only the request JSON as input — no shared context with Speak-er

This means specialists cannot read Speak-er's conversation history. All
necessary context must be provided in the request envelope's "context" field.
```

**Completion condition:** `grep "§8" shared/tools/protocol.md` or `grep "Dispatch Invocation" shared/tools/protocol.md` exits 0.

---

## 🛠️ Phase 5 — Setup Script & Infrastructure

---

### FIX-021 — Update `setup.sh` — inbox/outbox dirs, validate new scripts

**Priority:** P0
**Type:** `feature`

**Problem:** `setup.sh` does not create inbox/outbox directories and does not verify that the new dispatch scripts exist and are executable.

**Work:**
- In the directory creation section, add inbox and outbox directories for all 10 agents.
- In the validation section, verify that `shared/tools/dispatch.sh`, `shared/tools/agent_runner.sh`, and `shared/tools/build_system_prompt.sh` exist and are executable (`-x`).
- Add `shared/tools/model_routing.json` to the list of required files to validate.

**Completion condition:** `bash scripts/setup.sh claude` exits 0. `ls shared/memory/speaker/inbox shared/memory/speaker/outbox` succeeds. The validation section checks for all three new scripts.

---

## 🧪 Phase 6 — Tests

---

### FIX-022 — Fix all existing failing tests

**Priority:** P0
**Type:** `test`

**Problem:** The following tests are known to fail before Phase 1 and 2 fixes are applied:
- `test_setup_parity.bats` — fails because `shared/prompts/` is missing
- `test_setup.bats` — same
- `assert_no_yaml` in any test — fails on macOS due to `grep -Pn`
- Any test that calls `llm_call.sh` — fails due to missing config fields

**Work:**
- Apply FIX-001 through FIX-005 first.
- Then run the full test suite: `bash scripts/run_tests.sh`
- Fix any additional failures revealed by the run that are not already covered by FIX-001 to FIX-005.

**Completion condition:** `bash scripts/run_tests.sh` exits 0 with all pre-existing tests passing.

---

### FIX-023 — Unit tests for `build_system_prompt.sh`

**Priority:** P1
**Type:** `test`

**File:** `tests/unit/test_build_system_prompt.bats`

**Tests to cover:**
- Output contains content from all six source files when all exist.
- Missing files are skipped with a warning to stderr; script still exits 0.
- Nonexistent agent exits 1.
- Output contains correct section header for each source file.
- Output is non-empty for all 10 known agents.

**Completion condition:** `bats tests/unit/test_build_system_prompt.bats` exits 0 with all tests passing.

---

### FIX-024 — Unit tests for `agent_runner.sh`

**Priority:** P1
**Type:** `test`

**File:** `tests/unit/test_agent_runner.bats`

**Tests to cover:**
- Correct model is read from `model_routing.json` for each agent tier (haiku/sonnet/opus spot-checks).
- Missing agent in routing table exits 1 with a descriptive error.
- Invalid request JSON file exits 1.
- Nonexistent request file exits 1.
- With a mock LLM binary in PATH that returns a valid JSON response, exits 0 and stdout is valid JSON.
- With a mock LLM binary that returns empty output, exits 1.
- Active environment is read from `.parlei-env` and the correct CLI invocation is chosen.

**Note:** Tests must not make real LLM API calls. Use the `parlei_start_mock_llm` helper from `tests/fixtures/setup.bash` for any test that requires an LLM response.

**Completion condition:** `bats tests/unit/test_agent_runner.bats` exits 0 with all tests passing.

---

### FIX-025 — Unit tests for `dispatch.sh`

**Priority:** P1
**Type:** `test`

**File:** `tests/unit/test_dispatch.bats`

**Tests to cover:**
- Valid request is written to inbox before invocation.
- Inbox file is removed after successful dispatch.
- Response is written to outbox after successful dispatch.
- stdout contains the response JSON on success.
- When `agent_runner.sh` exits 1, `dispatch.sh` exits 1 and stdout is an escalation envelope.
- Nonexistent agent exits 1.
- Invalid request JSON exits 1.
- `request_id` is used as the filename for inbox/outbox files.

**Completion condition:** `bats tests/unit/test_dispatch.bats` exits 0 with all tests passing.

---

### FIX-026 — Unit test: correct model selected per agent

**Priority:** P1
**Type:** `test`

**File:** `tests/unit/test_model_routing.bats`

**Tests to cover:**
- `speaker` → `claude-haiku-4-5-20251001`
- `checker` → `claude-haiku-4-5-20251001`
- `reviewer` → `claude-opus-4-6`
- `architecter` → `claude-opus-4-6`
- `reoriginator` → `claude-opus-4-6`
- All Sonnet agents return `claude-sonnet-4-6`
- All 10 agents are present in `model_routing.json`
- No agent references a model that does not match the format `claude-[a-z]+-[0-9]+(-[0-9]+)?`

**Completion condition:** `bats tests/unit/test_model_routing.bats` exits 0 with all tests passing.

---

### FIX-027 — Integration test: end-to-end dispatch through Speak-er to a specialist

**Priority:** P1
**Type:** `test`

**File:** `tests/integration/test_dispatch_pipeline.bats`

**Tests to cover:**
- Full pipeline: request JSON created → `dispatch.sh checker` called with mock LLM → valid JSON response returned → outbox file exists.
- Dispatch pipeline with a missing-item response triggers retry correctly (use `retry.sh` output to verify).
- After 3 failed dispatches, escalation JSON is returned and contains all three attempt records.
- Two agents dispatched sequentially produce separate outbox files with different request IDs.

**Completion condition:** `bats tests/integration/test_dispatch_pipeline.bats` exits 0 with all tests passing.

---

### FIX-028 — Integration test: model routing respected in dispatch

**Priority:** P2
**Type:** `test`

**File:** Part of `tests/integration/test_dispatch_pipeline.bats` or a new file.

**Approach:** Use a mock `agent_runner.sh` replacement in the test PATH that records which model it was invoked with (by reading `model_routing.json` the same way the real script does). Assert that:
- Dispatching to `speaker` records model `claude-haiku-4-5-20251001`.
- Dispatching to `reviewer` records model `claude-opus-4-6`.
- Dispatching to `planer` records model `claude-sonnet-4-6`.

**Completion condition:** The test file exists and all model-routing assertions pass.

---

## 🔒 Phase 7 — Concurrency & Safety

---

### FIX-029 — Add file lock to `dispatch.sh` to prevent concurrent inbox/outbox collisions

**Priority:** P2
**Type:** `feature`
**Blocked by:** FIX-012 (`dispatch.sh` must exist first)

**Problem:** `dispatch.sh` writes to `shared/memory/<agent>/inbox/<request_id>.json` and reads from `shared/memory/<agent>/outbox/<request_id>.json`. If two Speak-er sessions dispatch to the same agent simultaneously, or if a long-running session issues two parallel dispatches, a race condition can occur:

1. Both processes generate the same request ID (unlikely but possible if both run in the same second before `request_id.sh` increments the counter).
2. Both processes write to the same inbox path, with the second overwriting the first.
3. The outbox response for request A is consumed by the waiter for request B.

The result is a silently corrupted response delivered to the wrong caller.

**Work:**

Use `flock` (available on Linux and macOS via `util-linux` / `brew install util-linux`) to acquire a per-agent lock file before writing to the inbox and release it after the outbox response is written.

- **Lock file location:** `shared/memory/<agent>/.dispatch.lock` — one lock per agent, not one per request.
- **Lock scope:** Held from inbox write through outbox read. This serializes concurrent dispatches to the same agent, which is correct behavior — the agent subprocess is a single-process LLM call and cannot handle parallel requests anyway.
- **Lock acquisition:** Use a timeout (default: 60 seconds) so a hung dispatch does not permanently block other callers. If the lock cannot be acquired within the timeout, exit 1 with a clear error message indicating which agent is locked and how long was waited.
- **Portability:** `flock` is not available on macOS by default. Detect its presence; if absent, fall back to a `mkdir`-based lock (atomic on POSIX: `mkdir .dispatch.lock.d` succeeds only once).

**Lock implementation in `dispatch.sh`:**

```bash
LOCK_FILE="$AGENT_DIR/.dispatch.lock"
LOCK_TIMEOUT=60

# Prefer flock if available; fall back to mkdir-based lock
if command -v flock &>/dev/null; then
  exec {LOCK_FD}>"$LOCK_FILE"
  flock --timeout "$LOCK_TIMEOUT" "$LOCK_FD" || {
    echo "Error: could not acquire lock for agent $AGENT after ${LOCK_TIMEOUT}s" >&2
    exit 1
  }
  # ... dispatch work ...
  flock --unlock "$LOCK_FD"
else
  LOCK_DIR="${LOCK_FILE}.d"
  DEADLINE=$(( $(date +%s) + LOCK_TIMEOUT ))
  until mkdir "$LOCK_DIR" 2>/dev/null; do
    [[ $(date +%s) -lt $DEADLINE ]] || {
      echo "Error: could not acquire lock for agent $AGENT after ${LOCK_TIMEOUT}s" >&2
      exit 1
    }
    sleep 0.5
  done
  trap 'rmdir "$LOCK_DIR" 2>/dev/null || true' EXIT
  # ... dispatch work ...
  rmdir "$LOCK_DIR" 2>/dev/null || true
  trap - EXIT
fi
```

**Add `.dispatch.lock` and `.dispatch.lock.d` to `.gitignore`** (see FIX-004 — update that task if already complete).

**Unit tests to add to `tests/unit/test_dispatch.bats`** (extend FIX-025):
- Lock file is created during dispatch and removed (or released) after.
- A second concurrent dispatch to the same agent blocks until the first completes.
- A dispatch that cannot acquire the lock within the timeout exits 1 with a descriptive error.
- `flock` fallback: if `flock` is not in PATH, the `mkdir` lock mechanism is used instead.

**Completion condition:** Two concurrent `dispatch.sh` calls to the same agent (using a slow mock runner that sleeps 1 second) produce two separate, correct outbox files with no interleaving. Lock file is absent after both dispatches complete. Timeout test exits 1 within `LOCK_TIMEOUT + 1` seconds when a lock is held by a background process.

---

## 🔗 Dependency Order

Execute phases in order. Within a phase, complete P0 tasks before P1, P1 before P2.

```
Phase 1 (Bug Fixes)
    → Phase 2 (Model Routing)
        → Phase 3 (Dispatch Infrastructure)   ← FIX-009 through FIX-014
            → Phase 4 (Bootstrap Updates)     ← FIX-015 through FIX-020
                → Phase 5 (Setup Script)      ← FIX-021
                    → Phase 6 (Tests)         ← FIX-022 through FIX-028
```

FIX-022 (fixing existing tests) can be done in parallel with Phase 2 once Phase 1 is complete.
FIX-008 (ADR) can be done at any point after FIX-006.

---

## 📐 Architecture Diagram After All Fixes

```
Spirit of the Forest
       │
       ▼
┌─────────────────────────────────────────────────────────┐
│  Bootstrap Layer (CLAUDE.md / AUGGIE.md / CODEX.md /    │
│  OPENCLAW.md)                                           │
│  → loads only speaker agent files                       │
└─────────────────────┬───────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────┐
│  Speak-er subprocess                                    │
│  Model: claude-haiku-4-5-20251001                       │
│  Role: routing, synthesis, communication                │
│  Tools: Bash (dispatch.sh), Read, Write                 │
└──────────┬──────────────────────────────────────────────┘
           │ bash shared/tools/dispatch.sh <agent> <req.json>
           ▼
┌─────────────────────────────────────────────────────────┐
│  dispatch.sh                                            │
│  1. writes req  → shared/memory/<agent>/inbox/<id>.json │
│  2. calls agent_runner.sh                               │
│  3. writes resp → shared/memory/<agent>/outbox/<id>.json│
│  4. returns resp JSON to Speak-er                       │
└──────────┬──────────────────────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────────────────────────┐
│  agent_runner.sh                                        │
│  1. reads model from model_routing.json                 │
│  2. calls build_system_prompt.sh → assembles prompt     │
│  3. invokes: claude --print --model <model> -p <prompt> │
│              (or llm_call.sh for non-claude envs)       │
└──────────┬──────────────────────────────────────────────┘
           │
           ▼
┌──────────────────────────┐  ┌──────────────────────────┐
│  Specialist subprocess   │  │  Specialist subprocess   │
│  (e.g. Review-er)        │  │  (e.g. Plan-er)          │
│  Model: claude-opus-4-6  │  │  Model: claude-sonnet-4-6│
│  Context: own files only │  │  Context: own files only │
│  Input: request JSON     │  │  Input: request JSON     │
│  Output: response JSON   │  │  Output: response JSON   │
└──────────────────────────┘  └──────────────────────────┘
```

Each specialist runs in **complete isolation**: its own model, its own assembled system prompt, its own context window. It receives only the request JSON. It cannot see Speak-er's conversation. It cannot call other agents. It returns JSON and exits.

---

## ⚠️ Known Risks and Open Questions

| Risk | Detail | Mitigation |
|---|---|---|
| `claude --print -p` flag availability | The `-p` flag for system prompt injection may vary by Claude Code version | Test on current CLI version; fall back to a temp file with `--system-prompt-file` flag if needed |
| Token limits in system prompts | `build_system_prompt.sh` concatenates 6 files — if `long_term.md` is large, the assembled prompt may exceed model limits | Add a `--max-tokens` guard to `build_system_prompt.sh`; run memory optimization before dispatch if prompt is too large |
| Codex CLI interface instability | OpenAI's Codex CLI is a newer tool; its non-interactive interface is less stable than Claude Code's | `codex` env falls back to `llm_call.sh` (FIX-013); if the Codex CLI gains a `--print` equivalent, update `agent_runner.sh` |
| OpenClaw availability | OpenClaw is a newer tool; its `--print` interface may not exist yet | `openclaw` env can fall back to `llm_call.sh` if needed; update when stable CLI is confirmed |
| Concurrent dispatch race conditions | Two parallel dispatches to the same agent could collide on inbox/outbox filenames | Addressed by FIX-029: per-agent `flock`/`mkdir` lock with configurable timeout |
