# 🏛️ Parlei — Architecture

> *Authored and maintained by Architect-er.*
> *Every decision recorded here includes rationale and rejected alternatives. If you are adding a decision, use the format in §1.*

---

## 🧭 Open Source First

Every tool, dependency, runtime, and service in Parlei must default to open source. Proprietary tools may only be used when:
1. No open source alternative exists, or
2. The open source alternative creates a meaningful, documented limitation.

LLM backends are the **only exempt category** — model quality may justify proprietary APIs.

---

## 📝 File Format Policy

This is non-negotiable. Violations should be raised with Architect-er immediately.

| Priority | Format | Use for |
|---|---|---|
| 1st | Markdown (`.md`) | All human-readable content, documentation, agent files, memory |
| 2nd | JSON | All structured data, schemas, configs, message envelopes |
| 3rd | TOML | Configuration only, when JSON becomes awkward |
| 4th | YAML | **Last resort** — only when a specific tool mandates it and no alternative exists |

---

## 📐 Architecture Decision Records

---

### ADR-001 — Agent definitions as Markdown files

**Decision:** Agent definitions, personality files, and memory files are plain Markdown (`.md`).

**Why:** Markdown is human-readable without tooling, editable by any text editor, diffable in version control, and requires no parser to understand. It is the most portable format available.

**Alternatives considered:**
- JSON: Rejected. Structured data format is poor for prose-heavy content like agent personalities.
- YAML: Rejected. Unnecessary for this use case and violates the file format policy.

---

### ADR-002 — Inter-agent messages as JSON

**Decision:** All inter-agent request and response envelopes are JSON, validated against schemas in `shared/tools/`.

**Why:** JSON is structured, machine-readable, widely supported in every language, and has a mature schema ecosystem (JSON Schema). The message format is structured data — the right tool for the job.

**Alternatives considered:**
- Plain text: Rejected. Unstructured and unparseable reliably.
- YAML: Rejected. File format policy violation and parsing footgun.

---

### ADR-003 — File-based memory (no database)

**Decision:** All agent memory is stored as files on disk in `shared/memory/`. No database.

**Why:** The system operates at a scale where a database would add complexity without benefit. Files are transparent, diffable, backupable with standard tools, and require no daemon. Memory optimization and backup are trivially scriptable against files.

**Alternatives considered:**
- SQLite: Rejected for v1. Adds a binary format dependency; harder to inspect and debug.
- PostgreSQL: Rejected. Overkill for this use case; requires a running service.
- Vector databases (Chroma, Qdrant): Considered for v2 for semantic recall. Not needed for v1.

---

### ADR-004 — System cron for scheduling

**Decision:** Nightly memory optimization and backup are scheduled via the user's system crontab, registered by `scripts/setup.sh`.

**Why:** `cron` is universally available on POSIX systems, requires no additional software, and is fully open source. It is the simplest tool for the job.

**Alternatives considered:**
- Ofelia: Open source, Docker-native cron alternative. Rejected for v1 — adds Docker dependency unnecessarily.
- Systemd timers: More powerful than cron but more complex to set up portably. Not yet needed.

---

### ADR-005 — Shell scripts for all automation

**Decision:** All operational scripts (`setup.sh`, `backup.sh`, `memory_optimize.sh`, `restore.sh`, `run_tests.sh`) are POSIX-compatible bash scripts.

**Why:** Bash is universally available, has no installation requirements, and is the most portable scripting environment on POSIX systems. Scripts start with `#!/usr/bin/env bash` and `set -euo pipefail` to ensure failure safety.

**Alternatives considered:**
- Python: Considered. Would offer better string handling and JSON parsing. Deferred to v2 if script complexity grows.
- Make: Rejected. Makefile syntax is opaque and not suited for operational scripts.

---

### ADR-006 — Podman preferred over Docker

**Decision:** When containerization is needed, Podman is the preferred tool.

**Why:** Podman is fully open source (no proprietary components), daemonless, rootless-capable, and uses the same CLI interface as Docker. Docker's daemon is proprietary-licensed in some configurations.

**Alternatives considered:**
- Docker: Available as fallback if Podman is not installed on the host.

---

### ADR-007 — gzip as default compression (zstd as optional upgrade)

**Decision:** Backup archives use `gzip` compression by default. `zstd` is supported as an optional faster/better alternative.

**Why:** `gzip` is universally available on all POSIX systems. `zstd` offers significantly better compression ratios and speed but is not universally pre-installed. Both are fully open source.

**Alternatives considered:**
- bzip2: Better compression than gzip but slower. Superseded by zstd.
- xz: Best compression ratio but very slow. Not appropriate for nightly automated backups.

---

### ADR-008 — Cross-environment parity via symlinks

**Decision:** All environment config files (`CLAUDE.md` at repo root, `bootstraps/AUGGIE.md`, `bootstraps/CODEX.md`, `bootstraps/OPENCLAW.md`) contain only environment-specific bootstrap instructions. All shared content lives in `shared/` and is referenced by path.

**Why:** Symlinks (and direct path references) ensure that agent definitions, memory, and personalities are never duplicated. A change to `shared/agents/speaker.md` is instantly reflected in all four environments.

**Alternatives considered:**
- Copying files per environment: Rejected. Creates divergence risk and maintenance burden.
- Template generation: Rejected. Adds tooling complexity with no benefit over direct path references.

---

### ADR-009 — bats-core as the test framework

**Decision:** All automated tests are written as [bats-core](https://github.com/bats-core/bats-core) test files (`.bats`).

**Why:** The project's primary artifacts are bash scripts. `bats-core` is an open source Bash testing framework that integrates naturally — tests are written in bash, test bash behavior, and produce TAP-compatible output. No language mismatch between tests and the code under test.

**Alternatives considered:**
- pytest: Better for Python code. No significant Python code exists in v1.
- ShellSpec: Open source alternative to bats. `bats-core` has broader adoption and documentation.

**Installation:** `brew install bats-core` or `apt-get install bats` or clone to `vendor/bats/`. `scripts/run_tests.sh` handles all three locations.

---

### ADR-010 — Python3 for JSON parsing in shell scripts

**Decision:** Shell scripts use `python3 -c "import json..."` for JSON parsing rather than `jq`.

**Why:** `python3` is more universally available than `jq` on stock Linux/macOS installs and supports the same operations. No additional package installation required on most systems.

**Alternatives considered:**
- `jq`: Excellent tool, but not universally pre-installed. Users would need to install it.
- Regex/awk JSON parsing: Rejected. Fragile and error-prone.

---

## 🔮 Future Architecture Considerations

| Topic | Current Decision | Potential v2 Change |
|---|---|---|
| Memory storage | Flat Markdown files | Vector DB (Chroma/Qdrant) for semantic recall |
| Script language | Bash | Python for complex logic |
| CI/CD | Not yet configured | Forgejo Actions or Woodpecker CI |
| IPC | File-based | NATS for high-throughput multi-agent scenarios |
| Web UI | None | SvelteKit dashboard (open source) |
