# 🦉 Parlei — A Parliament of Owls

> *A wise gathering of noble and capable AI agents, working in concert.*

Parlei (a riff on "parley") is a multi-agent AI orchestration framework styled after the collective noun for owls: a **parliament**. It is a portable, cross-platform agent system that works identically across multiple AI coding tools, powered by shared configuration, memory, and personality files.

---

## 🌲 Philosophy & Design Principles

- **Open source first** — Every tool, runtime, format, and dependency should be open source unless no viable open source alternative exists. The only exception to this rule is the choice of LLM backend, where proprietary models may offer significantly better results.
- **Portability** — The system must work across AI coding environments with zero duplication of core logic.
- **Hierarchy with flexibility** — All agents operate within a clear chain of command, but the orchestrator can grant lateral communication when efficiency demands it.
- **Minimal lock-in** — File formats should be plain text. **Markdown and JSON are the default choices for all files.** YAML is a last resort — only use it when a tool requires it and no JSON or Markdown alternative is practical. No proprietary databases or cloud-only tools unless there is no meaningful open source alternative.
- **Graceful degradation** — If an agent or tool is unavailable, the system should surface that clearly rather than silently fail.
- **Resilience by default** — Every agent must be able to survive an interruption — token exhaustion, API failure, context reset — and resume exactly where it left off. No agent may begin a task without first writing a recoverable state file.

---

## 🖥️ Supported Environments

Parlei is designed to run in the following AI coding environments:

| Environment | Config File     |
|-------------|-----------------|
| Claude Code | `CLAUDE.md`     |
| Augment     | `AUGGIE.md`     |
| Codex       | `CODEX.md`      |
| OpenClaw    | `OPENCLAW.md`   |

Each environment config file contains **only** environment-specific setup instructions and loading behavior. All shared logic, agent definitions, personality files, memory, and tooling live in a shared directory and are accessed via **symlinks**, ensuring every environment uses the exact same set of agents and data.

### 🔗 Shared File Strategy

```
parlei/
├── CLAUDE.md            # Claude-specific bootstrap (symlinks or sources shared/)
├── AUGGIE.md            # Augment-specific bootstrap
├── CODEX.md             # Codex-specific bootstrap
├── OPENCLAW.md          # OpenClaw-specific bootstrap
├── shared/
│   ├── agents/          # Agent definition files (.md)
│   ├── memory/          # All agent memory files (includes current_task.md per agent)
│   ├── personalities/   # Personality files per agent
│   ├── tools/           # Shared tool/script definitions
│   └── prompts/         # Reusable prompt templates
├── backups/             # Nightly compressed backups
└── scripts/
    ├── setup.sh         # Bootstraps symlinks for a given environment
    ├── memory_optimize.sh
    └── backup.sh
```

Symlinks in each environment config point into `shared/`, meaning agents, memories, and personalities are **never duplicated**.

---

## 🌳 Hierarchy

### The Spirit of the Forest 👤

The **Spirit of the Forest** sits at the top of the hierarchy. This is the originating intelligence giving direction — typically a human, but may be another AI system. Any text-based interface qualifies. All agents are subordinate to the Spirit and must follow its commands above all other impulses.

```
Spirit of the Forest (Human or external AI)
        │
        ▼
    🦉 Speak-er  (Orchestrator — the only agent the Spirit talks to directly)
        │
        ├──► 📋 Plan-er
        ├──► ✅ Task-er
        ├──► 💬 Prompt-er
        ├──► 🔍 Check-er
        ├──► 🧐 Review-er
        ├──► 🏛️  Architect-er
        ├──► 🚀 Deploy-er
        ├──► 🧪 Test-er
        └──► 🔄 Re-Origination-er
```

By default, **all agents only communicate upward to Speak-er**. The Speak-er may explicitly grant an agent permission to consult laterally with another agent when the task warrants it. This keeps the communication graph simple and the Speak-er as the sole routing intelligence.

---

## 🔁 Universal Agent Behavior: Resilience & Resumability

**Every agent in the parliament — without exception — follows this protocol for every task it receives:**

### The `current_task.md` File

Before doing any work, an agent writes a `current_task.md` file to its own memory directory (`shared/memory/<agent-name>/current_task.md`). This file is the agent's internal task list and recovery checkpoint. It is always plain Markdown.

**Format:**

```markdown
# Current Task

**Request ID:** req-tasker-20260327-005
**Status:** in-progress
**Started:** 2026-03-27 14:32
**Received from:** speaker
**Interrupt reason:**

## Subtasks
- [x] Subtask 1 — parse incoming request
- [x] Subtask 2 — load relevant context from long_term.md
- [ ] Subtask 3 — perform core work  ← resume here
- [ ] Subtask 4 — write output file
- [ ] Subtask 5 — send response to Speak-er

## Context
Any state, intermediate values, or data the agent needs to resume
work exactly where it left off. Written in plain prose or embedded
JSON code blocks. Never YAML.

## Original Request
​```json
{ ...embedded copy of the full JSON request envelope... }
​```
```

### Lifecycle Rules

1. **Write first, work second.** The file is created with all subtasks in an unchecked state before any work begins. If the file cannot be written, the agent must report the failure to Speak-er and halt.
2. **Check off incrementally.** Each subtask is marked `[x]` immediately upon completion — not in a batch at the end. This ensures the file always reflects the true state of progress.
3. **Startup check.** When an agent starts, the first thing it does is check for an existing `current_task.md`. If one exists with `Status: in-progress`, the agent notifies Speak-er that it is resuming an interrupted task, identifies the first unchecked subtask, and continues from there.
4. **Complete and clear.** When all subtasks are checked off and the response has been sent, the agent moves `current_task.md` to its `episodic/` log (renamed with the date and request ID) and removes it from the active location. A completed file must not linger.
5. **Interrupted tasks are never silently abandoned.** If an agent resumes a task and cannot complete it even after resumption, it escalates to Speak-er with the full contents of `current_task.md` attached.

### Why This Matters

Agents operate inside LLM context windows that can be exhausted. APIs can fail. Sessions can be reset. Without a durable, file-based progress record, any interruption means starting over — wasting work and potentially producing duplicate or inconsistent output. The `current_task.md` file ensures that **every agent can always answer the question: "where was I?"**

---

## 🦉 Agent Roster

### Speak-er — The Facilitator & Orchestrator
- **Role:** Primary interface between the Spirit of the Forest and the rest of the parliament. Receives all tasks and either handles them directly or delegates to the right specialist.
- **Capabilities:** General-purpose reasoning, task triage, delegation, work history tracking.
- **Responsibilities:**
  - Evaluate each incoming task against the list of available agents.
  - Delegate when a specialist would be more effective or efficient.
  - Maintain a running log of work history across the session.
  - Identify when a new agent type should be created and recommend it to the Spirit.
  - Act as the sole router for inter-agent communication (unless lateral access is explicitly granted).

---

### Plan-er — The Architect of Intent 📋
- **Role:** Produces and maintains `PLAN.md`.
- **Responsibilities:**
  - Ensure all major features and functionality cohere — no gaps, no implied-but-unstated pieces.
  - Guarantee the plan contains at least one clear, measurable goal.
  - Include a dedicated section for testing strategy: unit tests, UI tests, and functionality/integration tests.
  - Flag any logical contradictions or missing dependencies between features.
- **Output:** `PLAN.md` — a structured document with goals, features, dependencies, and a testing section.

---

### Task-er — The Translator of Plans ✅
- **Role:** Produces and maintains `TASKS.md`.
- **Responsibilities:**
  - Translate `PLAN.md` into a flat or hierarchical list of concrete tasks.
  - Each task must have a clear, unambiguous completion condition (e.g., "function returns X given Y", not "implement auth").
  - Break down vague or overly large tasks into smaller atomic units.
  - Tag tasks by type (feature, fix, test, infra, etc.) and owning agent where applicable.
- **Output:** `TASKS.md` — a task list with IDs, descriptions, completion criteria, and status.

---

### Prompt-er — The Token Whisperer 💬
- **Role:** Translates natural language requests into optimized AI prompts.
- **Responsibilities:**
  - Maximize accuracy and conciseness to reduce token usage.
  - Structure prompts to maximize backend caching potential (stable prefixes, variable suffixes).
  - Maintain a library of reusable prompt templates in `shared/prompts/`.
  - Advise other agents on prompt structure when asked by Speak-er.

---

### Check-er — The Sanity Inspector 🔍
- **Role:** Verifies that `PLAN.md` and `TASKS.md` are in alignment, and that implemented code actually reflects what was asked for.
- **Responsibilities:**
  - Cross-reference tasks against the plan to catch drift.
  - Distinguish between placeholder/stub code and genuine implementation.
  - Flag tasks marked complete that don't have corresponding, functioning code.
  - Light-pass code review focused on completeness, not style.

---

### Review-er — The Code Critic 🧐
- **Role:** Full code review with a focus on quality, consistency, and correctness.
- **Responsibilities:**
  - Check for code and syntax consistency across the codebase.
  - Identify overly complex or inefficient functions.
  - Flag linting issues, missing comments on non-obvious logic, and anti-patterns.
  - Review for security issues: injection, improper input validation, exposed secrets, etc.
  - Does **not** concern itself with whether features are complete — that is Check-er's domain.

---

### Architect-er — The Infrastructure Mind 🏛️
- **Role:** Big-picture technical decision-making.
- **Responsibilities:**
  - Recommend languages, frameworks, and runtimes — **preferring open source options**.
  - Design how system components communicate (APIs, message queues, file-based IPC, etc.).
  - Establish DevOps conventions: branching strategy, environment management, secrets handling.
  - Ensure security, scalability, and maintainability are considered at the architecture level.
  - Produce or update an `ARCHITECTURE.md` document as decisions are made.

---

### Deploy-er — The DevOps Expert 🚀
- **Role:** Manages deployment and infrastructure provisioning.
- **Responsibilities:**
  - Write and maintain deployment scripts — **preferring open source tooling** (e.g., Ansible, Terraform, Docker, Podman).
  - Set up CI/CD pipelines using open source runners (e.g., Forgejo Actions, GitHub Actions, Woodpecker CI).
  - Manage environment configs, secrets injection, and rollback procedures.
  - Coordinate with Architect-er on infrastructure decisions.

---

### Test-er — The Quality Guardian 🧪
- **Role:** Ensures all test code is thorough, clean, and effective.
- **Responsibilities:**
  - Write or review unit, integration, and UI/E2E tests.
  - Prefer open source testing frameworks appropriate to the stack.
  - Ensure test coverage aligns with the testing section in `PLAN.md`.
  - Flag gaps in coverage and recommend remediation.
  - Validate that tests are not brittle, overly mocked, or tied to implementation details.

---

### Re-Origination-er — The Chaos Agent 🔄
- **Role:** Enters an existing project and restructures it in preparation for a new major version.
- **Responsibilities:**
  - Has broad authority to reorganize, rename, and restructure files.
  - May deliberately break things to enable a cleaner rebuild.
  - Documents what was changed and why in a `REORIGINATION.md` log.
  - Should not be invoked without explicit Spirit of the Forest approval.
- **⚠️ Warning:** This agent has **free reign to break things**. Only invoke with explicit intent.

---

## 🧠 Memory System

Each agent maintains its own persistent memory. Memory is stored as plain-text Markdown (`.md`) files in `shared/memory/`, organized by agent name. Structured data that can't be expressed cleanly in Markdown uses JSON — never YAML.

### Memory Structure

```
shared/memory/
├── speaker/
├── planer/
├── tasker/
├── prompter/
├── checker/
├── reviewer/
├── architecter/
├── deployer/
├── tester/
└── reoriginator/
```

Each agent memory directory may contain:
- `identity.md` — Who this agent is and its core values/personality
- `long_term.md` — Persistent facts and decisions the agent should always remember
- `current_task.md` — Active task list and recovery checkpoint (see Universal Agent Behavior above); deleted and moved to `episodic/` on completion
- `episodic/` — Per-session memory logs (date-stamped), including completed `current_task.md` archives

### 🌙 Nightly Memory Optimization

A nightly cron job runs `scripts/memory_optimize.sh`, which:
1. Compresses and deduplicates episodic memory logs.
2. Promotes frequently referenced episodic items to `long_term.md`.
3. Prunes stale or redundant entries.
4. Uses an LLM call (via a configurable open source LLM interface, e.g., [Ollama](https://ollama.com/) or direct API) to summarize and restructure memory for efficiency.

### 💾 Nightly Backup

`scripts/backup.sh` runs nightly after memory optimization:
1. Compresses the entire `shared/` directory using `tar + gzip` or `zstd` (open source, widely available).
2. Saves the archive to `backups/YYYY-MM-DD.tar.gz`.
3. Retains the last N backups (configurable), pruning older ones.

Both scripts are registered via a setup-time cron job installed by `scripts/setup.sh`.

---

## 📡 Agent Communication Protocol

### Default: Upward-Only Communication

By default:
- All agents report results **up to Speak-er only**.
- No agent directly contacts another agent without Speak-er's explicit grant.
- This keeps the communication topology simple and Speak-er as the sole router.

### Lateral Communication (Granted by Speak-er)

When Speak-er determines that two agents should collaborate directly, it grants a **temporary lateral communication token** for that session or task. The agents communicate directly until the task resolves, then report back to Speak-er.

### 📨 Message Format

All inter-agent communication uses a **structured JSON request/response format**. Every message includes:

**Request:**
```json
{
  "from": "tasker",
  "to": "checker",
  "request_id": "req-20240315-001",
  "items": [
    {
      "id": 1,
      "type": "verification",
      "description": "Confirm task TASK-042 has corresponding implementation",
      "context": "File: src/auth/login.ts"
    },
    {
      "id": 2,
      "type": "verification",
      "description": "Confirm task TASK-043 has corresponding implementation",
      "context": "File: src/auth/logout.ts"
    }
  ]
}
```

**Response:**
```json
{
  "from": "checker",
  "to": "tasker",
  "request_id": "req-20240315-001",
  "items": [
    {
      "id": 1,
      "status": "confirmed",
      "notes": "Implementation found at src/auth/login.ts:42"
    },
    {
      "id": 2,
      "status": "incomplete",
      "notes": "Logout function is a stub — returns TODO"
    }
  ]
}
```

### Retry & Escalation Protocol

- Each requesting agent **tracks what it asked for** and expects a matching response.
- If a response is missing items, the agent **re-requests** the missing items (up to **3 attempts**).
- After 3 failed attempts, the requesting agent escalates to Speak-er, which notifies the Spirit of the Forest.

---

## 🛠️ Tech Stack Guidance

All technology choices should trend toward **open source solutions** unless a proprietary tool offers a substantial, irreplaceable advantage. The exception is LLM backends, where model quality may justify using proprietary APIs.

### Recommended Open Source Stack

| Layer | Preferred Open Source Option | Notes |
|---|---|---|
| Language | Python, TypeScript, Go, Rust | All open source runtimes |
| Agent memory storage | Plain Markdown `.md` files; JSON for structured data | No database needed for v1; YAML is never used here |
| Prompt templating | [Jinja2](https://jinja.palletsprojects.com/) (Python) or [Handlebars](https://handlebarsjs.com/) (JS) | Open source |
| LLM interface (local) | [Ollama](https://ollama.com/), [LM Studio](https://lmstudio.ai/) | Open source local inference |
| LLM interface (API) | Any API (Anthropic, OpenAI, etc.) | LLM choice exempt from OSS rule |
| Task scheduling | `cron` (system) or [Ofelia](https://github.com/mcuadros/ofelia) | Open source |
| Compression | `gzip`, `zstd`, `tar` | Standard open source |
| CI/CD | [Forgejo Actions](https://forgejo.org/), [Woodpecker CI](https://woodpecker-ci.org/), GitHub Actions | Open source preferred |
| Containerization | [Docker](https://www.docker.com/), [Podman](https://podman.io/) | Podman preferred (fully OSS) |
| Config format | Markdown or JSON; TOML acceptable; **YAML is a last resort** | Prefer formats that are human-readable without a spec reference |
| IPC / messaging | File-based or [NATS](https://nats.io/) | NATS is open source |

---

## 📁 Key Files Reference

| File | Owner | Purpose |
|------|-------|---------|
| `PLAN.md` | Plan-er | High-level feature plan with goals and test strategy |
| `TASKS.md` | Task-er | Concrete, trackable task list |
| `ARCHITECTURE.md` | Architect-er | Infrastructure and tech decisions |
| `REORIGINATION.md` | Re-Origination-er | Log of restructuring actions |
| `DESIGN.md` | — | This document — system design reference |
| `shared/memory/` | All agents | Persistent per-agent memory |
| `shared/memory/<agent>/current_task.md` | Each agent | Active task list and interruption recovery checkpoint |
| `backups/` | backup.sh | Nightly compressed backups |
| `scripts/setup.sh` | — | Bootstrap script: symlinks + cron install |

---

## 🚀 Getting Started

1. Clone the repository into your project root.
2. Run `scripts/setup.sh <environment>` (e.g., `setup.sh claude`) to:
   - Create symlinks from the environment config to `shared/`.
   - Install nightly cron jobs for memory optimization and backup.
3. Open your AI coding tool and load the corresponding environment config (`CLAUDE.md`, `AUGGIE.md`, etc.).
4. Speak to **Speak-er**. The parliament is in session. 🦉

---

## 🔮 Future Considerations

- **Web UI** — An optional open source dashboard (e.g., built with [SvelteKit](https://kit.svelte.dev/)) for visualizing agent activity, memory, and task status.
- **Agent spawning** — Allow Speak-er to dynamically instantiate new specialized agents based on project needs.
- **Multi-project support** — A single Parlei instance managing multiple projects simultaneously.
- **Vector memory** — Optionally upgrade memory search using an open source vector store (e.g., [Chroma](https://www.trychroma.com/), [Qdrant](https://qdrant.tech/)) for semantic recall at scale.
- **Audit log** — Immutable append-only log of all inter-agent communications for debugging and replay.
