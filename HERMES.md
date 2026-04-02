# Hermes Compatibility Notes

Parlei is currently designed around Claude Code/Codex/OpenClaw bootstraps and dispatch logic. The root `CLAUDE.md`, `bootstraps/CODEX.md`/`OPENCLAW.md`, and `shared/tools/dispatch.sh` assume Speak-er delegates work via `dispatch.sh <agent>` and the specialist agents read/write `shared/memory/<agent>` files.

To make Parlei compatible with Hermes Agent, implement the following adapters:

1. **Hermes bootstrap:** add a Hermes-specific bootstrap (e.g., `bootstraps/HERMES.md`) plus a `scripts/setup.sh hermes` branch so Hermes knows how to load Speak-er and invoke the specialised agents.
2. **Hermes-friendly dispatch:** wrap or replace `shared/tools/dispatch.sh` with a Hermes-compatible dispatcher that maps Hermes skill invocations to the JSON protocol (`shared/tools/protocol.md`) already used between Speak-er and the specialists.
3. **Agent skills:** port each agent (Speak-er, Plan-er, Task-er, etc.) into Hermes skills or subprocesses that still honor `shared/memory/<agent>/current_task.md`, maintain their personalities (`shared/personalities/*.md`), and write their outputs into the existing docs (`docs/PLAN.md`, `docs/TASKS.md`, etc.).
4. **Persistence & maintenance:** keep the nightly cron jobs (`scripts/memory_optimize.sh`, `scripts/backup.sh`) and ensure the Hermes skills can read/write the shared memory files they rely on.
5. **Docs:** add Hermes-specific install guide (e.g., `docs/install-hermes.md`), mention Hermes in the README/DESIGN, and describe how to adapt the existing protocols to Hermes.

With those changes, Parlei’s shared logic remains intact while Hermes provides the execution layer rather than Claude/Codex/OpenClaw.
