# ✅ Parlei — Task List

> *Authored by Task-er, on behalf of the Parliament.*
> *Every task here traces directly to a feature in `PLAN.md`. If a task has no plan reference, it does not belong here. If a plan feature has no task, that is a gap — flag it to Speak-er immediately.*
>
> *Task-er's law: a task is not done when the work is done. It is done when its completion condition is verifiably true.*

---

## 📊 Status Key

| Status | Meaning |
|---|---|
| `todo` | Not started |
| `in-progress` | Actively being worked |
| `done` | Completion condition verified |
| `blocked` | Cannot proceed — see "Blocked by" |

## 🏷️ Type Key

| Type | Meaning |
|---|---|
| `infra` | Directory structure, scripts, tooling, configuration |
| `content` | `.md` files, definitions, agent files, personality files |
| `feature` | Behavioral logic or code |
| `test` | Any test — unit, integration, or functionality |

---

## 📋 Master Index

| ID | Title | Type | Owner | Status |
|---|---|---|---|---|
| **Area 1 — Bootstrap & Installation** |||||
| T-001 | Create `shared/` directory skeleton | `infra` | Deploy-er | `done` |
| T-002 | Write `CLAUDE.md` | `content` | Architect-er | `done` |
| T-003 | Write `bootstraps/AUGGIE.md` | `content` | Architect-er | `done` |
| T-004 | Write `bootstraps/CODEX.md` | `content` | Architect-er | `done` |
| T-005 | Write `bootstraps/OPENCLAW.md` | `content` | Architect-er | `done` |
| T-006 | `setup.sh` — argument parsing & environment validation | `feature` | Deploy-er | `done` |
| T-007 | `setup.sh` — symlink creation for all four environments | `feature` | Deploy-er | `done` |
| T-008 | `setup.sh` — create `backups/` if absent | `feature` | Deploy-er | `done` |
| T-009 | `setup.sh` — register nightly cron jobs | `feature` | Deploy-er | `done` |
| T-010 | `setup.sh` — post-creation symlink validation | `feature` | Deploy-er | `done` |
| T-011 | `setup.sh` — idempotency guard | `feature` | Deploy-er | `done` |
| **Area 2 — Agent System** |||||
| T-012 | Agent definition file: Speak-er | `content` | Speak-er | `done` |
| T-013 | Agent definition file: Plan-er | `content` | Plan-er | `done` |
| T-014 | Agent definition file: Task-er | `content` | Task-er | `done` |
| T-015 | Agent definition file: Prompt-er | `content` | Prompt-er | `done` |
| T-016 | Agent definition file: Check-er | `content` | Check-er | `done` |
| T-017 | Agent definition file: Review-er | `content` | Review-er | `done` |
| T-018 | Agent definition file: Architect-er | `content` | Architect-er | `done` |
| T-019 | Agent definition file: Deploy-er | `content` | Deploy-er | `done` |
| T-020 | Agent definition file: Test-er | `content` | Test-er | `done` |
| T-021 | Agent definition file: Re-Origination-er | `content` | Re-Origination-er | `done` |
| T-022 | Personality file: Speak-er | `content` | Speak-er | `done` |
| T-023 | Personality file: Plan-er | `content` | Plan-er | `done` |
| T-024 | Personality file: Task-er | `content` | Task-er | `done` |
| T-025 | Personality file: Prompt-er | `content` | Prompt-er | `done` |
| T-026 | Personality file: Check-er | `content` | Check-er | `done` |
| T-027 | Personality file: Review-er | `content` | Review-er | `done` |
| T-028 | Personality file: Architect-er | `content` | Architect-er | `done` |
| T-029 | Personality file: Deploy-er | `content` | Deploy-er | `done` |
| T-030 | Personality file: Test-er | `content` | Test-er | `done` |
| T-031 | Personality file: Re-Origination-er | `content` | Re-Origination-er | `done` |
| T-032 | Speak-er: delegation & routing logic spec | `content` | Speak-er | `done` |
| T-033 | Speak-er: lateral grant mechanism spec | `content` | Speak-er | `done` |
| T-034 | Re-Origination-er: safety gate spec | `content` | Re-Origination-er | `done` |
| **Area 3 — Memory System** |||||
| T-035 | Create memory subdirectories for all 10 agents | `infra` | Deploy-er | `done` |
| T-036 | Seed memory files: Speak-er | `content` | Speak-er | `done` |
| T-037 | Seed memory files: Plan-er | `content` | Plan-er | `done` |
| T-038 | Seed memory files: Task-er | `content` | Task-er | `done` |
| T-039 | Seed memory files: Prompt-er | `content` | Prompt-er | `done` |
| T-040 | Seed memory files: Check-er | `content` | Check-er | `done` |
| T-041 | Seed memory files: Review-er | `content` | Review-er | `done` |
| T-042 | Seed memory files: Architect-er | `content` | Architect-er | `done` |
| T-043 | Seed memory files: Deploy-er | `content` | Deploy-er | `done` |
| T-044 | Seed memory files: Test-er | `content` | Test-er | `done` |
| T-045 | Seed memory files: Re-Origination-er | `content` | Re-Origination-er | `done` |
| T-046 | `memory_optimize.sh` — deduplication logic | `feature` | Deploy-er | `done` |
| T-047 | `memory_optimize.sh` — episodic-to-long-term promotion logic | `feature` | Deploy-er | `done` |
| T-048 | `memory_optimize.sh` — age-based pruning logic | `feature` | Deploy-er | `done` |
| T-049 | `memory_optimize.sh` — LLM summarization call | `feature` | Deploy-er | `done` |
| T-050 | `memory_optimize.sh` — logging (`optimize_log.md`, `error_log.md`) | `feature` | Deploy-er | `done` |
| T-051 | Write `shared/tools/memory_config.json` | `content` | Architect-er | `done` |
| T-052 | Write LLM HTTP interface module | `feature` | Deploy-er | `done` |
| **Area 4 — Communication Protocol** |||||
| T-053 | Write JSON schema: request envelope | `content` | Architect-er | `done` |
| T-054 | Write JSON schema: response envelope | `content` | Architect-er | `done` |
| T-055 | Write request ID generator | `feature` | Deploy-er | `done` |
| T-056 | Write retry counter & missing-item re-request logic | `feature` | Deploy-er | `done` |
| T-057 | Write escalation message format & trigger logic | `feature` | Deploy-er | `done` |
| T-058 | Write protocol reference doc (`shared/tools/protocol.md`) | `content` | Architect-er | `done` |
| **Area 5 — Backup System** |||||
| T-059 | `backup.sh` — archive creation (`tar.gz`) | `feature` | Deploy-er | `done` |
| T-060 | `backup.sh` — date-based archive naming | `feature` | Deploy-er | `done` |
| T-061 | `backup.sh` — retention pruning | `feature` | Deploy-er | `done` |
| T-062 | `backup.sh` — success logging (`backup_log.md`) | `feature` | Deploy-er | `done` |
| T-063 | `backup.sh` — error logging & non-zero exit | `feature` | Deploy-er | `done` |
| T-064 | `backup.sh` — optimization error check pre-run | `feature` | Deploy-er | `done` |
| T-065 | `restore.sh` — date argument, confirmation prompt, extraction | `feature` | Deploy-er | `done` |
| T-066 | `restore.sh` — guard against overwriting `backups/` | `feature` | Deploy-er | `done` |
| **Area 6 — Document Outputs** |||||
| **Area 2b — Agent Resilience (current_task.md)** |||||
| T-106 | Define `current_task.md` format spec | `content` | Architect-er | `done` |
| T-107 | Implement `current_task.md` write-on-receive behavior | `feature` | Deploy-er | `done` |
| T-108 | Implement incremental subtask checkoff | `feature` | Deploy-er | `done` |
| T-109 | Implement startup resume check | `feature` | Deploy-er | `done` |
| T-110 | Implement completion archival (move to `episodic/`) | `feature` | Deploy-er | `done` |
| T-111 | Implement unresolvable-resumption escalation | `feature` | Deploy-er | `done` |
| T-112 | Update `backup.sh` to skip in-progress `current_task.md` | `feature` | Deploy-er | `done` |
| T-113 | Unit tests: `current_task.md` write behavior | `test` | Test-er | `done` |
| T-114 | Unit tests: subtask checkoff and state accuracy | `test` | Test-er | `done` |
| T-115 | Unit tests: startup resume detection | `test` | Test-er | `done` |
| T-116 | Unit tests: completion archival | `test` | Test-er | `done` |
| T-117 | Integration test: mid-task interruption and resume | `test` | Test-er | `done` |
| T-118 | Integration test: unresolvable resume triggers escalation | `test` | Test-er | `done` |
| T-119 | Functionality test: simulated mid-task session kill and restart | `test` | Test-er | `done` |
| T-067 | `PLAN.md` authored and complete | `content` | Plan-er | `done` |
| T-068 | `TASKS.md` authored and complete | `content` | Task-er | `done` |
| T-069 | Write `ARCHITECTURE.md` initial structure | `content` | Architect-er | `done` |
| T-070 | Write `REORIGINATION.md` template | `content` | Re-Origination-er | `done` |
| **Area 7 — Test Infrastructure** |||||
| T-071 | Select and configure test framework | `infra` | Test-er | `done` |
| T-072 | Write test runner script (`scripts/run_tests.sh`) | `infra` | Test-er | `done` |
| T-073 | Write shared test fixtures and helper utilities | `infra` | Test-er | `done` |
| **Unit Tests** |||||
| T-074 | Unit tests: `setup.sh` — symlink creation | `test` | Test-er | `done` |
| T-075 | Unit tests: `setup.sh` — idempotency | `test` | Test-er | `done` |
| T-076 | Unit tests: `setup.sh` — cron registration | `test` | Test-er | `done` |
| T-077 | Unit tests: `setup.sh` — non-zero exit on failure | `test` | Test-er | `done` |
| T-078 | Unit tests: `memory_optimize.sh` — deduplication | `test` | Test-er | `done` |
| T-079 | Unit tests: `memory_optimize.sh` — promotion logic | `test` | Test-er | `done` |
| T-080 | Unit tests: `memory_optimize.sh` — pruning | `test` | Test-er | `done` |
| T-081 | Unit tests: `memory_optimize.sh` — error logging | `test` | Test-er | `done` |
| T-082 | Unit tests: `backup.sh` — archive creation & naming | `test` | Test-er | `done` |
| T-083 | Unit tests: `backup.sh` — retention pruning | `test` | Test-er | `done` |
| T-084 | Unit tests: `backup.sh` — error logging | `test` | Test-er | `done` |
| T-085 | Unit tests: `restore.sh` — extraction & confirmation | `test` | Test-er | `done` |
| T-086 | Unit tests: `restore.sh` — no overwrite of `backups/` | `test` | Test-er | `done` |
| T-087 | Unit tests: JSON envelope validation | `test` | Test-er | `done` |
| T-088 | Unit tests: request ID generator | `test` | Test-er | `done` |
| T-089 | Unit tests: retry counter | `test` | Test-er | `done` |
| T-090 | Unit tests: memory read/write conventions | `test` | Test-er | `done` |
| T-091 | Unit tests: LLM interface module | `test` | Test-er | `done` |
| **Integration Tests** |||||
| T-092 | Integration test: full setup → two-environment symlink parity | `test` | Test-er | `done` |
| T-093 | Integration test: task to each specialist returns valid JSON | `test` | Test-er | `done` |
| T-094 | Integration test: missing response item → retry → escalation | `test` | Test-er | `done` |
| T-095 | Integration test: lateral grant flow | `test` | Test-er | `done` |
| T-096 | Integration test: memory optimization full run | `test` | Test-er | `done` |
| T-097 | Integration test: backup run after optimization | `test` | Test-er | `done` |
| T-098 | Integration test: restore from backup | `test` | Test-er | `done` |
| T-099 | Integration test: Re-Origination-er safety gate | `test` | Test-er | `done` |
| **Functionality Tests** |||||
| T-100 | Functionality test: bootstrap completes in under 5 minutes | `test` | Test-er | `done` |
| T-101 | Functionality test: Plan → Tasks coherence via Check-er | `test` | Test-er | `done` |
| T-102 | Functionality test: 48-hour autonomous operation simulation | `test` | Test-er | `done` |
| T-103 | Functionality test: all 10 agents respond to identity query | `test` | Test-er | `done` |
| T-104 | Functionality test: environment switch preserves parity | `test` | Test-er | `done` |
| T-105 | Functionality test: escalation chain produces human-visible output | `test` | Test-er | `done` |

---

## 📁 Area 1 — Bootstrap & Installation

*Plan reference: PLAN.md §1*
*Dependency: None — this is the foundation. Nothing else can start until T-001 is done.*

---

### T-001 — Create `shared/` directory skeleton
- **Type:** `infra`
- **Owner:** Deploy-er
- **Status:** `todo`
- **Blocked by:** —
- **Completion condition:** The following directories all exist on disk: `shared/agents/`, `shared/memory/`, `shared/personalities/`, `shared/prompts/`, `shared/tools/`, `backups/`, `scripts/`. Each is empty but present. A `tree` or `ls -R` of the repo root confirms all paths.

---

### T-002 — Write `CLAUDE.md`
- **Type:** `content`
- **Owner:** Architect-er
- **Status:** `todo`
- **Blocked by:** T-001
- **Completion condition:** `CLAUDE.md` exists at the repo root. It contains: (1) Claude Code-specific loading instructions, (2) a directive to load Speak-er as the sole entry point, (3) symlink instructions pointing to `shared/`. It contains zero agent logic, zero memory, and zero personality content. A reviewer can confirm all three sections are present and no shared content is duplicated inline.

---

### T-003 — Write `bootstraps/AUGGIE.md`
- **Type:** `content`
- **Owner:** Architect-er
- **Status:** `todo`
- **Blocked by:** T-001
- **Completion condition:** Same structural requirements as T-002, scoped to the Augment environment. File exists at `bootstraps/AUGGIE.md`, contains Augment-specific bootstrap instructions and a Speak-er load directive, and contains nothing that duplicates `../shared/`.

---

### T-004 — Write `bootstraps/CODEX.md`
- **Type:** `content`
- **Owner:** Architect-er
- **Status:** `todo`
- **Blocked by:** T-001
- **Completion condition:** Same structural requirements as T-002, scoped to the Codex environment. File exists at `bootstraps/CODEX.md`.

---

### T-005 — Write `bootstraps/OPENCLAW.md`
- **Type:** `content`
- **Owner:** Architect-er
- **Status:** `todo`
- **Blocked by:** T-001
- **Completion condition:** Same structural requirements as T-002, scoped to the OpenClaw environment. File exists at `bootstraps/OPENCLAW.md`.

---

### T-006 — `setup.sh` — argument parsing & environment validation
- **Type:** `feature`
- **Owner:** Deploy-er
- **Status:** `todo`
- **Blocked by:** T-001
- **Completion condition:** Running `setup.sh` with no arguments prints a usage message and exits with code `1`. Running it with an unrecognized argument (e.g., `setup.sh vscode`) prints an error naming the unrecognized value and exits with code `1`. Running it with a valid argument (`claude`, `augment`, `codex`, `openclaw`) proceeds without error.

---

### T-007 — `setup.sh` — symlink creation for all four environments
- **Type:** `feature`
- **Owner:** Deploy-er
- **Status:** `todo`
- **Blocked by:** T-006
- **Completion condition:** After running `setup.sh claude`, all paths that the `CLAUDE.md` file expects to reference in `shared/` resolve correctly as symlinks pointing into `shared/`. Running `readlink -f` on each symlink returns the correct absolute path inside `shared/`. Repeated for each of the four environment values.

---

### T-008 — `setup.sh` — create `backups/` if absent
- **Type:** `feature`
- **Owner:** Deploy-er
- **Status:** `todo`
- **Blocked by:** T-006
- **Completion condition:** Running `setup.sh` on a clean repo where `backups/` does not exist results in `backups/` being created. Running it again when `backups/` already exists does not error or alter the directory's contents.

---

### T-009 — `setup.sh` — register nightly cron jobs
- **Type:** `feature`
- **Owner:** Deploy-er
- **Status:** `todo`
- **Blocked by:** T-006
- **Completion condition:** After running `setup.sh`, `crontab -l` shows exactly two new entries: one running `memory_optimize.sh` at `02:00` and one running `backup.sh` at `02:30`, both using absolute paths. No other crontab entries are altered.

---

### T-010 — `setup.sh` — post-creation symlink validation
- **Type:** `feature`
- **Owner:** Deploy-er
- **Status:** `todo`
- **Blocked by:** T-007
- **Completion condition:** After symlink creation, the script tests each symlink with `-L` and `-e` checks. If any symlink is broken or missing, the script prints the failing path, exits with code `1`, and does not proceed to cron registration.

---

### T-011 — `setup.sh` — idempotency guard
- **Type:** `feature`
- **Owner:** Deploy-er
- **Status:** `todo`
- **Blocked by:** T-007, T-009
- **Completion condition:** Running `setup.sh claude` twice in succession produces identical state both times. `crontab -l` shows exactly two Parlei entries (not four). All symlinks exist and point to the correct targets. No errors are emitted on the second run.

---

## 🦉 Area 2 — Agent System

*Plan reference: PLAN.md §2*
*Dependency: T-001 (shared/ structure must exist)*

---

### T-012 — Agent definition file: Speak-er
- **Type:** `content`
- **Owner:** Speak-er
- **Status:** `todo`
- **Blocked by:** T-001
- **Completion condition:** `shared/agents/speaker.md` exists and contains all five required sections: (1) name and role summary, (2) full responsibilities list, (3) accepted inputs and produced outputs, (4) escalation behavior, (5) lateral communication permissions (default: none). The delegation and routing logic described in T-032 is either included here or explicitly referenced.

---

### T-013 — Agent definition file: Plan-er
- **Type:** `content`
- **Owner:** Plan-er
- **Status:** `todo`
- **Blocked by:** T-001
- **Completion condition:** `shared/agents/planer.md` exists with all five required sections. Output section explicitly names `PLAN.md` and its required contents (goals, features, dependencies, testing strategy). Escalation behavior states what Plan-er does when a plan has logical contradictions it cannot resolve alone.

---

### T-014 — Agent definition file: Task-er
- **Type:** `content`
- **Owner:** Task-er
- **Status:** `todo`
- **Blocked by:** T-001
- **Completion condition:** `shared/agents/tasker.md` exists with all five required sections. Output section explicitly names `TASKS.md`. Definition includes the rule that every plan feature must have at least one task, and that vague completion conditions are grounds for task decomposition.

---

### T-015 — Agent definition file: Prompt-er
- **Type:** `content`
- **Owner:** Prompt-er
- **Status:** `todo`
- **Blocked by:** T-001
- **Completion condition:** `shared/agents/prompter.md` exists with all five required sections. Responsibilities include token minimization, caching structure guidance, and the prompt template library in `shared/prompts/`.

---

### T-016 — Agent definition file: Check-er
- **Type:** `content`
- **Owner:** Check-er
- **Status:** `todo`
- **Blocked by:** T-001
- **Completion condition:** `shared/agents/checker.md` exists with all five required sections. Definition explicitly states Check-er's scope: plan-task drift and completeness of implementation — not style (that is Review-er's domain). The distinction is written explicitly to prevent overlap.

---

### T-017 — Agent definition file: Review-er
- **Type:** `content`
- **Owner:** Review-er
- **Status:** `todo`
- **Blocked by:** T-001
- **Completion condition:** `shared/agents/reviewer.md` exists with all five required sections. Responsibilities explicitly include: code/syntax consistency, complexity, linting, security (injection, validation, secrets). Explicitly states it does not assess feature completeness.

---

### T-018 — Agent definition file: Architect-er
- **Type:** `content`
- **Owner:** Architect-er
- **Status:** `todo`
- **Blocked by:** T-001
- **Completion condition:** `shared/agents/architecter.md` exists with all five required sections. Output section names `ARCHITECTURE.md`. Definition includes the open-source-first mandate and the rule that YAML is a last resort — JSON and Markdown are always preferred.

---

### T-019 — Agent definition file: Deploy-er
- **Type:** `content`
- **Owner:** Deploy-er
- **Status:** `todo`
- **Blocked by:** T-001
- **Completion condition:** `shared/agents/deployer.md` exists with all five required sections. Responsibilities include script authorship, cron management, and CI/CD setup. Definition names Podman as the preferred containerization tool (fully open source).

---

### T-020 — Agent definition file: Test-er
- **Type:** `content`
- **Owner:** Test-er
- **Status:** `todo`
- **Blocked by:** T-001
- **Completion condition:** `shared/agents/tester.md` exists with all five required sections. Responsibilities cover unit, integration, and functionality tests. Definition includes the rule that Test-er validates tests are non-trivial (not stubs) and not brittle.

---

### T-021 — Agent definition file: Re-Origination-er
- **Type:** `content`
- **Owner:** Re-Origination-er
- **Status:** `todo`
- **Blocked by:** T-001
- **Completion condition:** `shared/agents/reoriginator.md` exists with all five required sections. Definition includes the safety gate requirement (Spirit confirmation required), the `REORIGINATION.md` logging obligation, and a prominent warning that this agent may deliberately break things.

---

### T-022 — Personality file: Speak-er
- **Type:** `content`
- **Owner:** Speak-er
- **Status:** `todo`
- **Blocked by:** T-001
- **Completion condition:** `shared/personalities/speaker.md` exists and defines: (1) communication tone (warm, decisive), (2) at least two characteristic phrasings or behavioral traits, (3) how Speak-er identifies itself at the start of a response.

---

### T-023 — Personality file: Plan-er
- **Type:** `content`
- **Owner:** Plan-er
- **Status:** `todo`
- **Blocked by:** T-001
- **Completion condition:** `shared/personalities/planer.md` exists with tone, characteristic traits, and self-identification. Tone should reflect careful, thorough thinking — no gaps tolerated.

---

### T-024 — Personality file: Task-er
- **Type:** `content`
- **Owner:** Task-er
- **Status:** `todo`
- **Blocked by:** T-001
- **Completion condition:** `shared/personalities/tasker.md` exists with tone, characteristic traits, and self-identification. Tone should reflect precision and a low tolerance for vagueness.

---

### T-025 — Personality file: Prompt-er
- **Type:** `content`
- **Owner:** Prompt-er
- **Status:** `todo`
- **Blocked by:** T-001
- **Completion condition:** `shared/personalities/prompter.md` exists with tone, characteristic traits, and self-identification. Tone reflects conciseness and economy of language.

---

### T-026 — Personality file: Check-er
- **Type:** `content`
- **Owner:** Check-er
- **Status:** `todo`
- **Blocked by:** T-001
- **Completion condition:** `shared/personalities/checker.md` exists with tone, characteristic traits, and self-identification. Tone reflects skepticism and an evidence-first approach.

---

### T-027 — Personality file: Review-er
- **Type:** `content`
- **Owner:** Review-er
- **Status:** `todo`
- **Blocked by:** T-001
- **Completion condition:** `shared/personalities/reviewer.md` exists with tone, characteristic traits, and self-identification. Tone is precise, direct, and critical without being unkind.

---

### T-028 — Personality file: Architect-er
- **Type:** `content`
- **Owner:** Architect-er
- **Status:** `todo`
- **Blocked by:** T-001
- **Completion condition:** `shared/personalities/architecter.md` exists with tone, characteristic traits, and self-identification. Tone reflects long-horizon thinking and strong opinions held loosely.

---

### T-029 — Personality file: Deploy-er
- **Type:** `content`
- **Owner:** Deploy-er
- **Status:** `todo`
- **Blocked by:** T-001
- **Completion condition:** `shared/personalities/deployer.md` exists with tone, characteristic traits, and self-identification. Tone is practical and automation-focused — if it can be scripted, it should be scripted.

---

### T-030 — Personality file: Test-er
- **Type:** `content`
- **Owner:** Test-er
- **Status:** `todo`
- **Blocked by:** T-001
- **Completion condition:** `shared/personalities/tester.md` exists with tone, characteristic traits, and self-identification. Tone is methodical and suspicious of untested assumptions.

---

### T-031 — Personality file: Re-Origination-er
- **Type:** `content`
- **Owner:** Re-Origination-er
- **Status:** `todo`
- **Blocked by:** T-001
- **Completion condition:** `shared/personalities/reoriginator.md` exists with tone, characteristic traits, and self-identification. Tone reflects bold decisiveness and comfort with controlled chaos. The personality should make clear this agent welcomes destruction in service of renewal.

---

### T-032 — Speak-er: delegation & routing logic spec
- **Type:** `content`
- **Owner:** Speak-er
- **Status:** `todo`
- **Blocked by:** T-012
- **Completion condition:** `shared/agents/speaker.md` (or a referenced section) describes the delegation decision process: (1) evaluate task against agent roster, (2) handle directly if no specialist is better suited, (3) delegate if a specialist would be more effective or efficient. The criteria for "more effective or efficient" are stated explicitly — not left to inference. The work history logging behavior is also described.

---

### T-033 — Speak-er: lateral grant mechanism spec
- **Type:** `content`
- **Owner:** Speak-er
- **Status:** `todo`
- **Blocked by:** T-012
- **Completion condition:** `shared/agents/speaker.md` contains a section describing: (1) the conditions under which a lateral grant is issued, (2) that grants are session-scoped and expire when the task resolves, (3) that the grant is communicated to both agents in a JSON message with `"type": "lateral_grant"`, (4) that both agents report back to Speak-er when the lateral task is complete.

---

### T-034 — Re-Origination-er: safety gate spec
- **Type:** `content`
- **Owner:** Re-Origination-er
- **Status:** `todo`
- **Blocked by:** T-021
- **Completion condition:** `shared/agents/reoriginator.md` contains a safety gate section stating: (1) the agent refuses any invocation that does not include an explicit confirmation token from the Spirit of the Forest passed through Speak-er, (2) Speak-er must issue a warning to the Spirit before forwarding any Re-Origination-er task, (3) after any run, nightly memory optimization must be manually triggered before the cron schedule resumes.

---

## 🧠 Area 3 — Memory System

*Plan reference: PLAN.md §3*
*Dependency: T-001 (directory structure), T-012–T-021 (agents must be defined before their memory is seeded)*

---

### T-035 — Create memory subdirectories for all 10 agents
- **Type:** `infra`
- **Owner:** Deploy-er
- **Status:** `todo`
- **Blocked by:** T-001
- **Completion condition:** The following directories all exist: `shared/memory/speaker/`, `shared/memory/planer/`, `shared/memory/tasker/`, `shared/memory/prompter/`, `shared/memory/checker/`, `shared/memory/reviewer/`, `shared/memory/architecter/`, `shared/memory/deployer/`, `shared/memory/tester/`, `shared/memory/reoriginator/`. Each directory contains an `episodic/` subdirectory.

---

### T-036 — Seed memory files: Speak-er
- **Type:** `content`
- **Owner:** Speak-er
- **Status:** `todo`
- **Blocked by:** T-035, T-012
- **Completion condition:** `shared/memory/speaker/identity.md` and `shared/memory/speaker/long_term.md` both exist and are non-empty. `identity.md` states who Speak-er is and what it will not do. `long_term.md` contains at least the agent roster and the routing rules. Neither file contains YAML — any structured data uses JSON code blocks.

---

### T-037 — Seed memory files: Plan-er
- **Type:** `content`
- **Owner:** Plan-er
- **Status:** `todo`
- **Blocked by:** T-035, T-013
- **Completion condition:** `identity.md` and `long_term.md` exist in `shared/memory/planer/`, are non-empty, and contain no YAML. `long_term.md` includes at minimum: what a valid plan must contain, and the rule that at least one measurable goal is required.

---

### T-038 — Seed memory files: Task-er
- **Type:** `content`
- **Owner:** Task-er
- **Status:** `todo`
- **Blocked by:** T-035, T-014
- **Completion condition:** Same structural requirements as T-037. `long_term.md` includes at minimum: the task field requirements (ID, description, completion condition, status, owner) and the rule that vague completion conditions require decomposition.

---

### T-039 — Seed memory files: Prompt-er
- **Type:** `content`
- **Owner:** Prompt-er
- **Status:** `todo`
- **Blocked by:** T-035, T-015
- **Completion condition:** Same structural requirements as T-037.

---

### T-040 — Seed memory files: Check-er
- **Type:** `content`
- **Owner:** Check-er
- **Status:** `todo`
- **Blocked by:** T-035, T-016
- **Completion condition:** Same structural requirements as T-037. `long_term.md` includes the explicit scope boundary: completeness only, not style.

---

### T-041 — Seed memory files: Review-er
- **Type:** `content`
- **Owner:** Review-er
- **Status:** `todo`
- **Blocked by:** T-035, T-017
- **Completion condition:** Same structural requirements as T-037.

---

### T-042 — Seed memory files: Architect-er
- **Type:** `content`
- **Owner:** Architect-er
- **Status:** `todo`
- **Blocked by:** T-035, T-018
- **Completion condition:** Same structural requirements as T-037. `long_term.md` includes the open-source-first mandate and the file format hierarchy (Markdown > JSON > TOML > YAML as last resort).

---

### T-043 — Seed memory files: Deploy-er
- **Type:** `content`
- **Owner:** Deploy-er
- **Status:** `todo`
- **Blocked by:** T-035, T-019
- **Completion condition:** Same structural requirements as T-037.

---

### T-044 — Seed memory files: Test-er
- **Type:** `content`
- **Owner:** Test-er
- **Status:** `todo`
- **Blocked by:** T-035, T-020
- **Completion condition:** Same structural requirements as T-037.

---

### T-045 — Seed memory files: Re-Origination-er
- **Type:** `content`
- **Owner:** Re-Origination-er
- **Status:** `todo`
- **Blocked by:** T-035, T-021
- **Completion condition:** Same structural requirements as T-037. `identity.md` prominently states that the safety gate applies even to the agent's own invocation — it cannot self-authorize.

---

### T-046 — `memory_optimize.sh` — deduplication logic
- **Type:** `feature`
- **Owner:** Deploy-er
- **Status:** `todo`
- **Blocked by:** T-035
- **Completion condition:** Given two episodic log files for the same agent with identical paragraphs, running the script results in a single copy of each paragraph across the logs. The original files are modified in place (or replaced); no content is silently discarded. A diff of before/after state confirms only duplicate lines were removed.

---

### T-047 — `memory_optimize.sh` — episodic-to-long-term promotion logic
- **Type:** `feature`
- **Owner:** Deploy-er
- **Status:** `todo`
- **Blocked by:** T-046
- **Completion condition:** Given an agent's episodic logs where a specific entry appears in 3 or more distinct session files, running the script appends that entry to `long_term.md` (if not already present) and removes it from the episodic files. The threshold of 3 is read from `memory_config.json` and can be changed without modifying the script.

---

### T-048 — `memory_optimize.sh` — age-based pruning logic
- **Type:** `feature`
- **Owner:** Deploy-er
- **Status:** `todo`
- **Blocked by:** T-046
- **Completion condition:** Episodic log files with a date-stamp older than the configured threshold (default 90 days) are deleted by the script. The threshold is read from `memory_config.json`. A file dated exactly at the threshold boundary is retained (not deleted). Files in `long_term.md` are never pruned by this logic.

---

### T-049 — `memory_optimize.sh` — LLM summarization call
- **Type:** `feature`
- **Owner:** Deploy-er
- **Status:** `todo`
- **Blocked by:** T-048, T-052
- **Completion condition:** The script makes one HTTP POST to the configured LLM endpoint per agent, passing the current contents of `long_term.md` and a summarization prompt. The response replaces the contents of `long_term.md`. If the HTTP call fails (non-2xx, timeout, or malformed response), the script logs the error to `error_log.md`, skips the summarization step for that agent, and continues — it does not abort the entire run.

---

### T-050 — `memory_optimize.sh` — logging
- **Type:** `feature`
- **Owner:** Deploy-er
- **Status:** `todo`
- **Blocked by:** T-046, T-047, T-048, T-049
- **Completion condition:** After a successful run, a new line is appended to `shared/memory/optimize_log.md` containing: date, number of agents processed, number of entries deduplicated, number of entries promoted, number of entries pruned. After any failed step, a line is appended to `shared/memory/error_log.md` containing: date, agent name, step that failed, and the error message. Neither file is overwritten — both are append-only.

---

### T-051 — Write `shared/tools/memory_config.json`
- **Type:** `content`
- **Owner:** Architect-er
- **Status:** `todo`
- **Blocked by:** T-001
- **Completion condition:** `shared/tools/memory_config.json` exists and is valid JSON. It contains at minimum: `llm_model` (string, may be empty), `episodic_retention_days` (integer, default 90), `promotion_threshold` (integer, default 3), `backup_retention_count` (integer, default 30). Running `python3 -m json.tool shared/tools/memory_config.json` (or equivalent) exits without error.

---

### T-052 — Write LLM HTTP interface module
- **Type:** `feature`
- **Owner:** Deploy-er
- **Status:** `todo`
- **Blocked by:** T-051
- **Completion condition:** A script or module in `shared/tools/` accepts: endpoint URL, model name, auth token, and prompt text. It sends a plain HTTP POST with a JSON body (no proprietary SDK) and returns the response text. It handles and reports: HTTP errors (non-2xx), timeouts, and malformed JSON responses. A unit test (T-091) passes against a mock endpoint.

---

## 📡 Area 4 — Communication Protocol

*Plan reference: PLAN.md §4*
*Dependency: T-012–T-021 (agents must be defined before the protocol is codified)*

---

### T-053 — Write JSON schema: request envelope
- **Type:** `content`
- **Owner:** Architect-er
- **Status:** `todo`
- **Blocked by:** T-001
- **Completion condition:** `shared/tools/schema_request.json` exists, is valid JSON Schema (draft-07 or later), and enforces: required fields `from`, `to`, `request_id`, `items`; `items` is a non-empty array; each item requires `id` (integer), `type` (string), `description` (string); `context` is optional. A valid example message passes schema validation; a message missing `request_id` fails validation.

---

### T-054 — Write JSON schema: response envelope
- **Type:** `content`
- **Owner:** Architect-er
- **Status:** `todo`
- **Blocked by:** T-001
- **Completion condition:** `shared/tools/schema_response.json` exists, is valid JSON Schema, and enforces: required fields `from`, `to`, `request_id`, `items`; each item requires `id` (integer), `status` (enum: `confirmed`, `incomplete`, `failed`, `deferred`), `notes` (string); `output` is optional. A valid response passes; a response with an invalid `status` value fails.

---

### T-055 — Write request ID generator
- **Type:** `feature`
- **Owner:** Deploy-er
- **Status:** `todo`
- **Blocked by:** T-001
- **Completion condition:** A function or script in `shared/tools/` generates IDs in the format `req-<agent-name>-<YYYYMMDD>-<NNN>` where `NNN` is a zero-padded 3-digit sequence number. Within a single session the sequence increments correctly (001, 002, 003…). Two calls with the same agent name on the same day produce different IDs. Output of 5 sequential calls for agent `tasker` on `2026-03-27` is: `req-tasker-20260327-001` through `req-tasker-20260327-005`.

---

### T-056 — Write retry counter & missing-item re-request logic
- **Type:** `feature`
- **Owner:** Deploy-er
- **Status:** `todo`
- **Blocked by:** T-053, T-054, T-055
- **Completion condition:** Given a response that is missing item IDs present in the original request, the logic: (1) identifies only the missing item IDs, (2) constructs a new request containing only those items, (3) increments a per-request-ID retry counter. After 3 retries on the same `request_id`, the counter stops retrying and sets a flag that triggers T-057. A counter that receives a complete response resets to 0.

---

### T-057 — Write escalation message format & trigger logic
- **Type:** `feature`
- **Owner:** Deploy-er
- **Status:** `todo`
- **Blocked by:** T-056
- **Completion condition:** When the retry counter (T-056) hits 3 failures, an escalation message is sent to Speak-er. The message is valid JSON conforming to the request envelope schema with `"type": "escalation"`, containing: the original `request_id`, the agent that failed to respond, a list of item IDs that were never resolved, and the full history of retry attempts (timestamps and partial responses received). Speak-er's agent definition (T-032) acknowledges receipt of this message type and describes the human notification behavior.

---

### T-058 — Write protocol reference doc
- **Type:** `content`
- **Owner:** Architect-er
- **Status:** `todo`
- **Blocked by:** T-053, T-054, T-055, T-056, T-057
- **Completion condition:** `shared/tools/protocol.md` exists and documents in plain Markdown: (1) the request envelope format with a worked example, (2) the response envelope format with a worked example, (3) the request ID format, (4) the retry and escalation rules with a sequence diagram or step-by-step walkthrough, (5) the lateral grant message format. Any agent can read this file and understand the complete communication protocol without referencing any other file.

---

## 💾 Area 5 — Backup System

*Plan reference: PLAN.md §5*
*Dependency: T-001 (directory structure), T-009 (cron registration in setup.sh)*

---

### T-059 — `backup.sh` — archive creation
- **Type:** `feature`
- **Owner:** Deploy-er
- **Status:** `todo`
- **Blocked by:** T-001
- **Completion condition:** Running `backup.sh` produces a `.tar.gz` archive of the `shared/` directory. The archive is created using `tar` and `gzip` (or `zstd` if configured). The archive is not empty, and extracting it to a temp directory produces a file tree identical to `shared/`.

---

### T-060 — `backup.sh` — date-based archive naming
- **Type:** `feature`
- **Owner:** Deploy-er
- **Status:** `todo`
- **Blocked by:** T-059
- **Completion condition:** The archive is saved to `backups/YYYY-MM-DD.tar.gz` where the date reflects the date the script was run. Running the script twice on the same day overwrites the existing archive for that date (not creates a second file). Running it on a different date creates a new file.

---

### T-061 — `backup.sh` — retention pruning
- **Type:** `feature`
- **Owner:** Deploy-er
- **Status:** `todo`
- **Blocked by:** T-060
- **Completion condition:** After creating today's archive, the script counts `.tar.gz` files in `backups/` sorted by name (oldest first). If the count exceeds `backup_retention_count` from `memory_config.json` (default 30), the oldest files are deleted until the count equals the limit. With 31 archives present and a limit of 30, exactly one file (the oldest) is deleted.

---

### T-062 — `backup.sh` — success logging
- **Type:** `feature`
- **Owner:** Deploy-er
- **Status:** `todo`
- **Blocked by:** T-059
- **Completion condition:** After a successful backup, a single line is appended to `backups/backup_log.md` in the format: `YYYY-MM-DD HH:MM — backup successful — <archive_size>`. The file is never overwritten, only appended to.

---

### T-063 — `backup.sh` — error logging & non-zero exit
- **Type:** `feature`
- **Owner:** Deploy-er
- **Status:** `todo`
- **Blocked by:** T-059
- **Completion condition:** If `tar` fails, if `gzip`/`zstd` fails, or if the output archive is zero bytes, the script appends a line to `backups/error_log.md` with: date, step that failed, and the shell error message. The script exits with code `1`. The incomplete archive (if any) is deleted.

---

### T-064 — `backup.sh` — optimization error check pre-run
- **Type:** `feature`
- **Owner:** Deploy-er
- **Status:** `todo`
- **Blocked by:** T-050, T-063
- **Completion condition:** At startup, `backup.sh` checks whether `shared/memory/error_log.md` was modified today (using `find` with `-newer` or by checking the file's modification time). If it was, the script prints a warning (does not abort) stating that memory optimization encountered errors and the backup may reflect incomplete optimization. This warning is also appended to `backups/backup_log.md`.

---

### T-065 — `restore.sh` — date argument, confirmation prompt, extraction
- **Type:** `feature`
- **Owner:** Deploy-er
- **Status:** `todo`
- **Blocked by:** T-059
- **Completion condition:** Running `restore.sh 2026-03-26` finds `backups/2026-03-26.tar.gz`. Before extracting, the script prints: "This will overwrite shared/ with the backup from 2026-03-26. Type YES to confirm:" and waits for input. If the user types `YES`, it extracts the archive into `shared/` (replacing its contents). Any other input aborts with a message and exit code `1`. Running with a date that has no matching archive exits with a clear error message and code `1`.

---

### T-066 — `restore.sh` — guard against overwriting `backups/`
- **Type:** `feature`
- **Owner:** Deploy-er
- **Status:** `todo`
- **Blocked by:** T-065
- **Completion condition:** The extraction in T-065 passes `--strip-components` or equivalent to `tar` such that the `backups/` directory is never modified during a restore. After a full restore, all files in `backups/` are unchanged (verified by checksum before and after).

---

## ✍️ Area 6 — Document Outputs

*Plan reference: PLAN.md §6*

---

### T-067 — `docs/PLAN.md` authored and complete
- **Type:** `content`
- **Owner:** Plan-er
- **Status:** `done`
- **Blocked by:** —
- **Completion condition:** `docs/PLAN.md` exists. Contains: at least one measurable goal, a full feature list with all six areas, a dependency map, and a testing strategy with unit, integration, and functionality sections. ✅

---

### T-068 — `docs/TASKS.md` authored and complete
- **Type:** `content`
- **Owner:** Task-er
- **Status:** `in-progress`
- **Blocked by:** T-067
- **Completion condition:** `docs/TASKS.md` exists. Every feature in `docs/PLAN.md` has at least one corresponding task in this file. Every task has: a unique ID, a type, an owner, a status, a "blocked by" field, and a completion condition that is specific and verifiable. This document itself is the artifact.

---

### T-069 — Write `docs/ARCHITECTURE.md` initial structure
- **Type:** `content`
- **Owner:** Architect-er
- **Status:** `todo`
- **Blocked by:** T-001
- **Completion condition:** `docs/ARCHITECTURE.md` exists with the following sections present (may be populated with TBD stubs): (1) Language & Runtime choices with rationale, (2) Communication patterns, (3) Deployment targets, (4) Explicitly rejected alternatives with reasons, (5) File format policy (Markdown > JSON > TOML > YAML as last resort). The open-source-first principle is stated explicitly in the document.

---

### T-070 — Write `docs/REORIGINATION.md` template
- **Type:** `content`
- **Owner:** Re-Origination-er
- **Status:** `todo`
- **Blocked by:** T-001
- **Completion condition:** `docs/REORIGINATION.md` exists as a template. It contains: a header section for date and Spirit confirmation token, a table with columns for "path changed", "action taken" (moved/deleted/renamed/restructured), and "reason", and a footer section for a post-run summary. It is clearly marked as a template — no actual changes are logged in the initial version.

---

## 🧰 Area 7 — Test Infrastructure

*Plan reference: PLAN.md §Testing Strategy*
*Dependency: T-001. Tests must be written alongside or immediately after the features they cover.*

---

### T-071 — Select and configure test framework
- **Type:** `infra`
- **Owner:** Test-er
- **Status:** `todo`
- **Blocked by:** T-001
- **Completion condition:** A test framework is selected (open source; e.g., `bats` for shell scripts, `pytest` for Python modules, or equivalent). The choice is documented in `ARCHITECTURE.md` with rationale. The framework is installable via a standard open source package manager. Running the framework with zero test files exits cleanly with no errors.

---

### T-072 — Write test runner script (`scripts/run_tests.sh`)
- **Type:** `infra`
- **Owner:** Test-er
- **Status:** `todo`
- **Blocked by:** T-071
- **Completion condition:** `scripts/run_tests.sh` exists and is executable. Running it with no arguments runs all tests and outputs a pass/fail summary. Running it with an argument (e.g., `run_tests.sh unit`) runs only that category of tests. The script exits with code `0` if all tests pass and `1` if any fail.

---

### T-073 — Write shared test fixtures and helper utilities
- **Type:** `infra`
- **Owner:** Test-er
- **Status:** `todo`
- **Blocked by:** T-071
- **Completion condition:** A `tests/fixtures/` directory exists containing: (1) a minimal valid `shared/` directory skeleton for use in isolation tests, (2) a mock LLM endpoint script that returns a configurable canned response, (3) helper functions for creating and tearing down temp directories. All tests that need an isolated environment use these fixtures rather than the live `shared/` directory.

---

## 🔬 Unit Tests

*Plan reference: PLAN.md §Testing Strategy — Unit Tests*
*All unit tests must be isolated (no live filesystem changes to `shared/`, no real LLM calls, no real cron modifications).*

---

### T-074 — Unit tests: `setup.sh` — symlink creation
- **Type:** `test`
- **Owner:** Test-er
- **Status:** `todo`
- **Blocked by:** T-007, T-073
- **Completion condition:** Tests run in a temp directory. Given a valid environment argument, the test confirms each expected symlink is created and resolves to the correct target path. Tests pass for all four valid environment values.

---

### T-075 — Unit tests: `setup.sh` — idempotency
- **Type:** `test`
- **Owner:** Test-er
- **Status:** `todo`
- **Blocked by:** T-011, T-073
- **Completion condition:** Running `setup.sh claude` twice in a temp environment produces the same file state both times. The test confirms: symlink count is unchanged after the second run, cron entry count is unchanged, and exit code is `0` on both runs.

---

### T-076 — Unit tests: `setup.sh` — cron registration
- **Type:** `test`
- **Owner:** Test-er
- **Status:** `todo`
- **Blocked by:** T-009, T-073
- **Completion condition:** Using a mock `crontab` command, the test confirms two entries are written with the correct times (02:00, 02:30) and correct script paths. The test runs without modifying the real user crontab.

---

### T-077 — Unit tests: `setup.sh` — non-zero exit on failure
- **Type:** `test`
- **Owner:** Test-er
- **Status:** `todo`
- **Blocked by:** T-010, T-073
- **Completion condition:** Given a scenario where a symlink cannot be created (e.g., target path does not exist), the script exits with code `1` and prints an error message identifying the failing path. The cron registration step is not reached.

---

### T-078 — Unit tests: `memory_optimize.sh` — deduplication
- **Type:** `test`
- **Owner:** Test-er
- **Status:** `todo`
- **Blocked by:** T-046, T-073
- **Completion condition:** Given two episodic log files for the same agent containing identical lines, after running the script the duplicate lines are removed and each unique line appears exactly once across the logs. A file with no duplicates is unchanged.

---

### T-079 — Unit tests: `memory_optimize.sh` — promotion logic
- **Type:** `test`
- **Owner:** Test-er
- **Status:** `todo`
- **Blocked by:** T-047, T-073
- **Completion condition:** Given episodic logs where entry X appears in exactly 2 sessions, it is not promoted. Given logs where entry X appears in 3 sessions, it is appended to `long_term.md` and removed from the episodic files. If the entry is already in `long_term.md`, it is not duplicated.

---

### T-080 — Unit tests: `memory_optimize.sh` — pruning
- **Type:** `test`
- **Owner:** Test-er
- **Status:** `todo`
- **Blocked by:** T-048, T-073
- **Completion condition:** Given episodic log files at ages: 89 days, 90 days, 91 days (relative to today), the script deletes the 91-day file, retains the 90-day file, and retains the 89-day file. The threshold is read from a test-specific `memory_config.json`, not hardcoded.

---

### T-081 — Unit tests: `memory_optimize.sh` — error logging
- **Type:** `test`
- **Owner:** Test-er
- **Status:** `todo`
- **Blocked by:** T-050, T-073
- **Completion condition:** Given a scenario where the LLM call returns a non-2xx response, the test confirms: (1) the error is appended to `error_log.md`, (2) `long_term.md` is not modified, (3) the script continues to the next agent rather than aborting, (4) `optimize_log.md` records the partial run.

---

### T-082 — Unit tests: `backup.sh` — archive creation & naming
- **Type:** `test`
- **Owner:** Test-er
- **Status:** `todo`
- **Blocked by:** T-059, T-060, T-073
- **Completion condition:** Running the script in a temp environment creates a file named `backups/YYYY-MM-DD.tar.gz` matching today's date. The file is non-empty. Extracting it to a temp dir and diffing against the fixture `shared/` skeleton shows no differences.

---

### T-083 — Unit tests: `backup.sh` — retention pruning
- **Type:** `test`
- **Owner:** Test-er
- **Status:** `todo`
- **Blocked by:** T-061, T-073
- **Completion condition:** Given 35 pre-existing `.tar.gz` files in `backups/` and a retention limit of 30, after running the script, `backups/` contains exactly 30 files — the 5 files with the oldest names are gone, and today's new archive is present.

---

### T-084 — Unit tests: `backup.sh` — error logging
- **Type:** `test`
- **Owner:** Test-er
- **Status:** `todo`
- **Blocked by:** T-063, T-073
- **Completion condition:** Given a scenario where `tar` is forced to fail (e.g., source directory does not exist), the script exits with code `1`, appends an error entry to `backups/error_log.md`, and does not create a zero-byte archive in `backups/`.

---

### T-085 — Unit tests: `restore.sh` — extraction & confirmation
- **Type:** `test`
- **Owner:** Test-er
- **Status:** `todo`
- **Blocked by:** T-065, T-073
- **Completion condition:** Using a test harness that pipes `YES` to stdin, the script extracts the target archive into `shared/`. The test confirms `shared/` contents match the archive. Using a harness that pipes `NO`, the script aborts and `shared/` is unchanged.

---

### T-086 — Unit tests: `restore.sh` — no overwrite of `backups/`
- **Type:** `test`
- **Owner:** Test-er
- **Status:** `todo`
- **Blocked by:** T-066, T-073
- **Completion condition:** After a restore, a checksum of all files in `backups/` is identical to the checksum taken before the restore. No files in `backups/` are modified, added, or deleted during the restore operation.

---

### T-087 — Unit tests: JSON envelope validation
- **Type:** `test`
- **Owner:** Test-er
- **Status:** `todo`
- **Blocked by:** T-053, T-054, T-073
- **Completion condition:** Using the schemas from T-053 and T-054, the following are tested: a fully valid request passes; a request missing `request_id` fails; a request with an empty `items` array fails; a valid response passes; a response with `status: "unknown"` fails; a response with a missing `id` in an item fails. All assertions use a JSON Schema validation library, not hand-rolled string checks.

---

### T-088 — Unit tests: request ID generator
- **Type:** `test`
- **Owner:** Test-er
- **Status:** `todo`
- **Blocked by:** T-055, T-073
- **Completion condition:** Five sequential calls for agent `tasker` on `2026-03-27` return exactly `req-tasker-20260327-001` through `req-tasker-20260327-005`. A call for agent `checker` returns an ID starting with `req-checker-`. Two calls on different simulated dates produce IDs with different date components.

---

### T-089 — Unit tests: retry counter
- **Type:** `test`
- **Owner:** Test-er
- **Status:** `todo`
- **Blocked by:** T-056, T-073
- **Completion condition:** Given a request with 3 items and a response missing item 2, the retry logic sends a new request containing only item 2. After 3 such failures, the escalation flag is set and no further retries are attempted. If a retry receives a complete response, the counter resets to 0 and the escalation flag is not set.

---

### T-090 — Unit tests: memory read/write conventions
- **Type:** `test`
- **Owner:** Test-er
- **Status:** `todo`
- **Blocked by:** T-035, T-073
- **Completion condition:** A test agent writes a session log to its own `episodic/` directory. The test confirms: the file is created at the correct path, the file is valid Markdown, and no YAML is present in the file (checked by scanning for `---` YAML frontmatter or `: ` key-value pairs outside of JSON code blocks). An attempt to write to another agent's memory directory fails with an error.

---

### T-091 — Unit tests: LLM interface module
- **Type:** `test`
- **Owner:** Test-er
- **Status:** `todo`
- **Blocked by:** T-052, T-073
- **Completion condition:** Using the mock LLM endpoint from T-073: (1) a successful call returns the mock response text, (2) a 500 response raises/returns an error without crashing, (3) a timeout raises/returns an error without hanging indefinitely (timeout threshold set to 2 seconds in test config), (4) a malformed JSON response body is handled gracefully and the error is reported.

---

## 🔗 Integration Tests

*Plan reference: PLAN.md §Testing Strategy — Integration Tests*
*Integration tests may use the real filesystem in isolated temp environments. No real LLM calls; use the mock endpoint.*

---

### T-092 — Integration test: two-environment symlink parity
- **Type:** `test`
- **Owner:** Test-er
- **Status:** `todo`
- **Blocked by:** T-007, T-011, T-073
- **Completion condition:** Run `setup.sh claude` and `setup.sh augment` in isolated temp environments against the same `shared/` fixture. For each file that both environments reference, confirm that resolving the symlink (`readlink -f`) in both environments points to an identical file path inside `shared/`. No shared file has two different real paths.

---

### T-093 — Integration test: each specialist returns valid JSON
- **Type:** `test`
- **Owner:** Test-er
- **Status:** `todo`
- **Blocked by:** T-012–T-021, T-053, T-054
- **Completion condition:** For each of the 9 specialist agents (all except Speak-er), a representative task message is constructed and passed to the agent. Each agent returns a JSON response that passes schema validation against `schema_response.json`. The `from` field matches the agent's name. The `request_id` matches the request. All item IDs from the request are present in the response.

---

### T-094 — Integration test: retry and escalation chain
- **Type:** `test`
- **Owner:** Test-er
- **Status:** `todo`
- **Blocked by:** T-056, T-057, T-073
- **Completion condition:** A mock agent is configured to respond with a response missing item ID 2 every time. The retry logic sends three retries, each containing only item 2. After the third failure, Speak-er receives an escalation message with `"type": "escalation"` that includes the `request_id`, the failing agent name, the unresolved item IDs, and the retry history. The test confirms no fourth retry is sent.

---

### T-095 — Integration test: lateral grant flow
- **Type:** `test`
- **Owner:** Test-er
- **Status:** `todo`
- **Blocked by:** T-033, T-057
- **Completion condition:** Speak-er sends a lateral grant message to two agents. Both agents exchange messages directly (without routing through Speak-er) for the duration of a test task. When the task resolves, both agents send completion messages to Speak-er. A subsequent message from either agent (simulating a new task after the grant expired) is routed through Speak-er, not sent directly.

---

### T-096 — Integration test: memory optimization full run
- **Type:** `test`
- **Owner:** Test-er
- **Status:** `todo`
- **Blocked by:** T-046, T-047, T-048, T-049, T-050, T-073
- **Completion condition:** Given a realistic agent memory fixture (2 agents, each with 5 episodic logs, some containing duplicates, some entries appearing 3+ times), run `memory_optimize.sh` using the mock LLM endpoint. Verify: duplicates removed, promoted entries in `long_term.md`, old entries pruned (if any), `optimize_log.md` appended with correct stats, `error_log.md` not written (no errors).

---

### T-097 — Integration test: backup run after optimization
- **Type:** `test`
- **Owner:** Test-er
- **Status:** `todo`
- **Blocked by:** T-059, T-060, T-061, T-062, T-064, T-073
- **Completion condition:** Run `memory_optimize.sh` (with mock LLM), then `backup.sh` in sequence in a temp environment. Verify: archive exists with today's date, `backup_log.md` contains a success entry, retention pruning occurred if over the limit. Then run `memory_optimize.sh` again with a forced error (mock LLM returns 500). Run `backup.sh` again. Verify: backup still completes, but `backup_log.md` contains the optimization-error warning.

---

### T-098 — Integration test: restore from backup
- **Type:** `test`
- **Owner:** Test-er
- **Status:** `todo`
- **Blocked by:** T-065, T-066, T-073
- **Completion condition:** Create a `shared/` fixture, run `backup.sh`, modify `shared/` (add and delete files), run `restore.sh <today's date>` with `YES` piped to stdin. Verify `shared/` matches the original fixture exactly (checksum comparison). Verify `backups/` contents are unchanged.

---

### T-099 — Integration test: Re-Origination-er safety gate
- **Type:** `test`
- **Owner:** Test-er
- **Status:** `todo`
- **Blocked by:** T-034
- **Completion condition:** Attempt to invoke Re-Origination-er without a Spirit confirmation token — confirm the agent refuses and returns a `"status": "failed"` response with a note explaining the safety gate. Then invoke with a valid confirmation token (as defined in T-034) passed through Speak-er — confirm the agent accepts the task, performs it, and produces a `REORIGINATION.md` log entry.

---

## 🎯 Functionality Tests

*Plan reference: PLAN.md §Testing Strategy — Functionality Tests*
*These are end-to-end tests. They may be run manually or semi-automated. Each has a binary pass/fail condition.*

---

### T-100 — Functionality test: bootstrap under 5 minutes
- **Type:** `test`
- **Owner:** Test-er
- **Status:** `todo`
- **Blocked by:** T-001–T-011
- **Completion condition:** A person (or timed automated script) who has never used Parlei runs `git clone` followed by `scripts/setup.sh claude`. Within 5 minutes from the start of `setup.sh`, Speak-er is reachable and responds to a test message. "Reachable" means the AI coding tool has loaded and returned a response — not just that the files exist.

---

### T-101 — Functionality test: Plan → Tasks coherence via Check-er
- **Type:** `test`
- **Owner:** Test-er
- **Status:** `todo`
- **Blocked by:** T-016, T-067, T-068
- **Completion condition:** Check-er is given `PLAN.md` and `TASKS.md` and asked to verify coherence. Check-er must confirm: every numbered feature section in the plan has at least one task referencing it, no task references a plan section that does not exist, and all tasks marked `done` have a completion condition that is verifiably true (not just "written"). Check-er produces a JSON response with `"status": "confirmed"` or a list of gaps found.

---

### T-102 — Functionality test: 48-hour autonomous operation
- **Type:** `test`
- **Owner:** Test-er
- **Status:** `todo`
- **Blocked by:** T-009, T-050, T-059, T-062
- **Completion condition:** After running `setup.sh` and waiting 48 hours without manual intervention: `backups/` contains at least 2 dated archives (one per night), `shared/memory/optimize_log.md` has at least 2 append entries, `shared/memory/error_log.md` either does not exist or is empty (no failures), and no script left a zombie process or broken cron entry.

---

### T-103 — Functionality test: all 10 agents respond to identity query
- **Type:** `test`
- **Owner:** Test-er
- **Status:** `todo`
- **Blocked by:** T-012–T-031, T-036–T-045
- **Completion condition:** Each of the 10 agents is sent the prompt "Who are you and what is your role in the parliament?" via Speak-er. Each agent responds with: its name, a summary of its role matching its definition file, and at least one element of its personality (tone or characteristic phrasing). No agent returns a generic or off-topic response.

---

### T-104 — Functionality test: environment switch preserves parity
- **Type:** `test`
- **Owner:** Test-er
- **Status:** `todo`
- **Blocked by:** T-007, T-011
- **Completion condition:** Run `setup.sh claude`, send a task to Speak-er, record the response. Run `setup.sh augment` (against the same `shared/`), send the identical task to Speak-er, record the response. The two responses are functionally equivalent — same agent identity, same capabilities, same memory visible. Any environment-specific differences are limited to the bootstrap instructions in the respective `.md` files, not in agent behavior or memory.

---

### T-105 — Functionality test: escalation chain produces human-visible output
- **Type:** `test`
- **Owner:** Test-er
- **Status:** `todo`
- **Blocked by:** T-057, T-094
- **Completion condition:** An agent is deliberately configured to never return item ID 2. A task containing item 2 is submitted through Speak-er. After 3 retries, Speak-er surfaces a human-readable notification to the Spirit of the Forest — not a raw JSON blob, but a plain-language message stating which agent failed, what it was asked to do, and what action the Spirit should take. The escalation message is readable to a non-technical person.

---

## 🔁 Area 2b — Agent Resilience (`current_task.md`)

*Plan reference: PLAN.md §2.6*
*Dependency: T-001 (directory structure), T-035 (agent memory subdirectories)*

---

### T-106 — Define `current_task.md` format spec
- **Type:** `content`
- **Owner:** Architect-er
- **Status:** `todo`
- **Blocked by:** T-035
- **Completion condition:** `shared/tools/current_task_spec.md` exists and defines the canonical format for `current_task.md` files. It specifies: all required header fields (`Request ID`, `Status`, `Started`, `Received from`, `Interrupt reason`), the subtask list format using `- [ ]` / `- [x]` Markdown checkboxes, the `Context` section, and the `Original Request` section (embedded JSON code block). It includes a complete filled-in example. No YAML appears anywhere in the spec.

---

### T-107 — Implement `current_task.md` write-on-receive behavior
- **Type:** `feature`
- **Owner:** Deploy-er
- **Status:** `todo`
- **Blocked by:** T-106
- **Completion condition:** A shared module or function in `shared/tools/` accepts: agent name, request ID, received-from agent, and a list of subtask strings. It writes a valid `current_task.md` to `shared/memory/<agent-name>/current_task.md` with all subtasks unchecked and `Status: in-progress` before returning. If the write fails (permissions, disk full, etc.), the function raises an error — it does not silently continue. The calling agent is expected to halt and report to Speak-er on any write failure.

---

### T-108 — Implement incremental subtask checkoff
- **Type:** `feature`
- **Owner:** Deploy-er
- **Status:** `todo`
- **Blocked by:** T-107
- **Completion condition:** A function accepts an agent name and a subtask index (1-based). It reads the agent's `current_task.md`, marks the specified subtask `[x]`, and writes the file back. Calling it twice with the same index does not duplicate the checkmark. Calling it with an out-of-range index returns an error without modifying the file. After calling it for all subtasks, every list item in the file shows `[x]`.

---

### T-109 — Implement startup resume check
- **Type:** `feature`
- **Owner:** Deploy-er
- **Status:** `todo`
- **Blocked by:** T-107
- **Completion condition:** A function that agents call at startup checks for `shared/memory/<agent-name>/current_task.md`. If the file does not exist, the function returns `null` (nothing to resume). If it exists with `Status: in-progress`, the function returns: the `Request ID`, the index of the first unchecked subtask, and the full `Context` section content. The calling agent is responsible for notifying Speak-er that a resume is occurring before continuing work.

---

### T-110 — Implement completion archival
- **Type:** `feature`
- **Owner:** Deploy-er
- **Status:** `todo`
- **Blocked by:** T-108, T-109
- **Completion condition:** A function accepts an agent name. It: (1) reads `current_task.md` and confirms all subtasks are checked (errors if any remain unchecked), (2) sets `Status: completed` in the file, (3) moves the file to `shared/memory/<agent-name>/episodic/` renamed as `<YYYY-MM-DD>-<request-id>.md`, (4) confirms the active path `current_task.md` no longer exists. If the move fails, it logs the error and leaves the file in place — it does not delete it.

---

### T-111 — Implement unresolvable-resumption escalation
- **Type:** `feature`
- **Owner:** Deploy-er
- **Status:** `todo`
- **Blocked by:** T-109, T-057
- **Completion condition:** When an agent resumes a task (via T-109) and subsequently fails to complete it (e.g., encounters an error that prevents forward progress), it constructs an escalation message to Speak-er. The message includes `"type": "resume_escalation"`, the full contents of `current_task.md` as an embedded string, the reason resumption failed, and the request ID. The `current_task.md` file is not deleted or modified during this escalation — Speak-er or the Spirit may need to inspect it.

---

### T-112 — Update `backup.sh` to skip in-progress `current_task.md`
- **Type:** `feature`
- **Owner:** Deploy-er
- **Status:** `todo`
- **Blocked by:** T-059, T-107
- **Completion condition:** `backup.sh` uses `tar --exclude` (or equivalent) to omit any file named `current_task.md` whose `Status` line reads `in-progress` from the archive. Completed/archived task files in `episodic/` (which have been renamed and moved) are included normally. A test backup of a `shared/` fixture containing one in-progress and one completed (archived) task file confirms: the in-progress file is absent from the archive, the archived episodic file is present.

---

## 🔬 Unit Tests — Resilience

*Plan reference: PLAN.md §Testing Strategy — Unit Tests (current_task.md rows)*

---

### T-113 — Unit tests: `current_task.md` write behavior
- **Type:** `test`
- **Owner:** Test-er
- **Status:** `todo`
- **Blocked by:** T-107, T-073
- **Completion condition:** In an isolated temp environment: (1) calling the write function produces a file at the correct path with all required header fields present and all subtasks unchecked, (2) the file is valid Markdown with no YAML, (3) the `Original Request` section contains the full JSON request envelope passed to the function, (4) simulating a write failure (read-only directory) causes the function to return an error, not silently succeed.

---

### T-114 — Unit tests: subtask checkoff and state accuracy
- **Type:** `test`
- **Owner:** Test-er
- **Status:** `todo`
- **Blocked by:** T-108, T-073
- **Completion condition:** Given a `current_task.md` with 4 subtasks: (1) checking off subtask 2 results in only subtask 2 marked `[x]`; (2) checking off subtask 2 again does not change the file; (3) checking off all 4 subtasks results in all showing `[x]`; (4) providing an index of 5 on a 4-item list returns an error and the file is unchanged.

---

### T-115 — Unit tests: startup resume detection
- **Type:** `test`
- **Owner:** Test-er
- **Status:** `todo`
- **Blocked by:** T-109, T-073
- **Completion condition:** (1) Given no `current_task.md` file, the function returns `null`. (2) Given a file with `Status: in-progress` and subtasks 1–2 checked, the function returns: the correct `Request ID`, first unchecked index of 3, and the `Context` section text. (3) Given a file with `Status: completed`, the function returns `null` (nothing to resume — completed files should not be at the active path, but this guards against edge cases).

---

### T-116 — Unit tests: completion archival
- **Type:** `test`
- **Owner:** Test-er
- **Status:** `todo`
- **Blocked by:** T-110, T-073
- **Completion condition:** (1) Given all subtasks checked, the function moves the file to `episodic/` with the correct filename (`YYYY-MM-DD-<request-id>.md`) and the active `current_task.md` no longer exists. (2) Given any unchecked subtask remaining, the function returns an error and the file is not moved. (3) Simulating a move failure (target directory missing) causes the function to log an error and leave the file in place rather than deleting it.

---

## 🔗 Integration Tests — Resilience

*Plan reference: PLAN.md §Testing Strategy — Integration Tests (resumability rows)*

---

### T-117 — Integration test: mid-task interruption and resume
- **Type:** `test`
- **Owner:** Test-er
- **Status:** `todo`
- **Blocked by:** T-107, T-108, T-109, T-110, T-073
- **Completion condition:** Simulate a 5-subtask task for a test agent. After subtasks 1–2 are checked off, the "session" is killed (process terminated or context cleared). On the next startup, the resume check finds the in-progress file, returns index 3 as the resume point, and the agent continues from subtask 3 — subtasks 1–2 are not repeated. After subtasks 3–5 complete, `current_task.md` is archived to `episodic/` and no longer present at the active path. The output produced during subtasks 1–2 and during subtasks 3–5 is consistent — no duplication or gaps.

---

### T-118 — Integration test: unresolvable resume triggers escalation
- **Type:** `test`
- **Owner:** Test-er
- **Status:** `todo`
- **Blocked by:** T-111, T-073
- **Completion condition:** An agent resumes an in-progress task (via T-109) and is then forced to fail (simulated error injected at subtask 4 of 5). The agent sends an escalation message to Speak-er with `"type": "resume_escalation"`. The message contains the `Request ID`, the failure reason, and the full `current_task.md` content. The `current_task.md` file remains unmodified at the active path after the escalation is sent.

---

## 🎯 Functionality Tests — Resilience

*Plan reference: PLAN.md §Testing Strategy — Functionality Tests (interruption row)*

---

### T-119 — Functionality test: simulated mid-task session kill and restart
- **Type:** `test`
- **Owner:** Test-er
- **Status:** `todo`
- **Blocked by:** T-107, T-108, T-109, T-110, T-111
- **Completion condition:** A real agent (not mocked) is given a multi-step task through Speak-er. After the first 2 subtasks are complete (confirmed by `current_task.md` checkboxes), the AI coding tool session is manually reset or closed. The session is reopened. The agent detects the in-progress `current_task.md`, notifies Speak-er with a plain-language resume notice (e.g., "Resuming interrupted task req-tasker-20260327-005 from subtask 3"), and completes the remaining subtasks. The final output is identical to what a non-interrupted run would have produced. No subtask is performed twice.
