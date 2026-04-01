# 🦉 Parlei — A Parliament of Owls

> *A wise gathering of specialist AI agents working in harmony*

Parlei (from "parley" — a conference or discussion) is a multi-agent AI system designed to run in modern AI coding environments. Instead of a single general-purpose assistant, Parlei gives you a **parliament of specialist agents**, each with distinct expertise, personality, and responsibilities.

---

## 🎯 What is Parlei?

Parlei transforms your AI coding environment into a coordinated team of specialists:

- **Plan-er** maintains the project vision and ensures feature coherence
- **Task-er** breaks plans into discrete, measurable tasks
- **Code-er** implements features at a principal engineer level
- **Review-er** performs deep security and quality reviews (uses the most capable model)
- **Test-er** writes comprehensive, clean test coverage
- **Architect-er** makes infrastructure and technology decisions
- **Deploy-er** handles DevOps and deployment operations
- **Tech-Write-er** creates API docs, architecture documentation, and technical references
- **Prose-Write-er** writes marketing content, blog posts, and user-facing documentation
- **Check-er** verifies plan-task-code coherence
- **Prompt-er** optimizes prompts for efficiency and caching
- **Re-Origination-er** restructures codebases for major versions
- **Speak-er** orchestrates everything and communicates with you (the "Spirit of the Forest")

Each agent runs as an **isolated subprocess with its own model**, persistent memory, and defined personality. You interact only with **Speak-er**, who routes work to the right specialist.

---

## ⚡ Key Features

### 🎭 **True Multi-Agent Architecture**
- Each agent runs in its own subprocess with its own context
- No shared conversation history between agents
- Clean isolation ensures focused, expert outputs

### 💰 **Cost-Optimized Model Routing** (Claude Code only)
- Lightweight tasks use fast, cheap models (Haiku for routing)
- Complex work uses balanced models (Sonnet for implementation)
- High-stakes reviews use premium models (Opus for security)
- **Saves money** without sacrificing quality where it matters
- *Note: Codex and OpenClaw use persona-switching with a single model (no tier optimization)*

### 🧠 **Persistent Memory**
- Each agent maintains long-term memory of decisions and patterns
- Memory automatically optimizes and compresses nightly
- Survives across sessions and environment switches

### 🌍 **Multi-Environment Support**
- **Use Claude and Codex simultaneously** on the same system!
- Auto-detects which AI CLI is available at runtime
- Same agents, same behavior, same memory across all environments
- No configuration needed - just install the CLI tools you want
- **Architecture differences**:
  - **Claude Code**: Subprocess delegation with true model-tier optimization
  - **Codex/OpenClaw**: Persona-switching with single model (faster, no cost optimization)

### 🔄 **Automated Maintenance**
- Nightly memory optimization removes duplicates and cruft
- Automated backups with configurable retention
- Runs autonomously once set up

### 🛡️ **Built-in Safety**
- Agents retry failed requests automatically (up to 3 attempts)
- Escalation to human on persistent failures
- Task interruption recovery (resume from where you left off)

---

## 📦 Installation

### Prerequisites

- **Bash** 4.0+ (`bash --version`)
- **Python 3** 3.8+ (`python3 --version`)
- **Git** (any recent version)
- **cron** (for automated maintenance)
- One of:
  - [Claude Code](https://claude.ai/code) (recommended)
  - [Codex](https://github.com/openai/codex)
  - [OpenClaw](https://openclaw.ai) (if available)

### Quick Start

```bash
# Clone the repository
git clone <parlei-repo-url> parlei
cd parlei

# Install the global CLI (optional but recommended)
bash scripts/install_global.sh

# Run setup (enables ALL environments by default)
parlei setup          # Auto-detects Claude, Codex, OpenClaw

# Open your AI coding tool and load the bootstrap file
# For Claude Code: CLAUDE.md (auto-loaded from repo root)
# For Codex: codex "Read bootstraps/CODEX.md and follow all instructions"
# For others: See docs/install-<environment>.md
```

**That's it.** The parliament is in session. 🦉

### Global CLI Commands

Once installed globally, you can use `parlei` from anywhere:

```bash
parlei status           # Show current configuration
parlei setup codex      # Set up environment
parlei test unit        # Run unit tests
parlei backup           # Create memory backup
parlei optimize         # Optimize agent memory
parlei help             # Show all commands
```

---

## 🚀 Quick Example

```
You: "I need to build a user authentication system"

Speak-er: I'll coordinate this for you.
  → Delegating to Plan-er to create the high-level plan...
  → Plan-er has created docs/PLAN.md with security considerations
  → Delegating to Task-er to break this into tasks...
  → Task-er has created docs/TASKS.md with 12 discrete tasks
  → Delegating to Architect-er for infrastructure decisions...
  → Architect-er recommends JWT + bcrypt + rate limiting
  
  Ready to proceed with implementation?
```

Each specialist brings domain expertise. You get thoughtful, structured work instead of ad-hoc responses.

---

## 📚 Documentation

| Document | Purpose |
|----------|---------|
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Technical decisions and ADRs |
| [docs/DESIGN.md](docs/DESIGN.md) | System design and file structure |
| [docs/PLAN.md](docs/PLAN.md) | Project goals and feature plan |
| [docs/install-claude.md](docs/install-claude.md) | Claude Code setup guide |
| [docs/install-codex.md](docs/install-codex.md) | Codex setup guide |
| [docs/install-openclaw.md](docs/install-openclaw.md) | OpenClaw setup guide |

---

## 🏗️ Architecture Overview

```
Spirit of the Forest (You)
       ↕
   Speak-er (Lightweight tier — fast routing)
   ↙  ↓  ↘
Plan-er  Task-er  Code-er  ...
(Balanced tier)
    ↓
Review-er  Architect-er
(Premium tier)
```

**Model tiers adapt to your environment:**

| Tier | Claude Code | Codex | OpenClaw | Codex Pricing |
|------|-------------|-------|----------|---------------|
| **Lightweight** (routing) | Haiku 4.5 | GPT-5.1-Codex-Mini | Haiku 4.5 | $0.25/$2.00/M |
| **Balanced** (general work) | Sonnet 4.6 | GPT-5.4 | Sonnet 4.6 | $2.50/$15.00/M |
| **Premium** (high-stakes) | Opus 4.6 | GPT-5.1-Codex-Max | Opus 4.6 | $1.25/$10.00/M |

- **Speak-er & Check-er** use lightweight models for fast routing and verification
- **Most agents** use balanced models for coding, planning, testing, and technical documentation
- **Review-er, Architect-er, Re-Origination-er, Prose-Write-er** use premium models for critical decisions and high-quality prose

Each agent is a **real subprocess** invoked via `dispatch.sh` with its own model and context.

---

## 🧩 How It Works

1. **You send a request** to Speak-er (the only agent you talk to)
2. **Speak-er evaluates** whether to handle it or delegate to a specialist
3. **If delegating**, Speak-er creates a JSON request and calls `dispatch.sh`
4. **dispatch.sh** invokes the specialist as a subprocess with its own model
5. **The specialist** responds with a JSON envelope
6. **Speak-er** translates the response into plain language for you

All communication happens via structured JSON following `shared/tools/protocol.md`. Agents can retry failed requests, escalate to you on persistent failures, and maintain their own persistent memory.

---

## 🎨 Agent Personalities

Each agent has a distinct personality defined in `shared/personalities/`:

- **Plan-er**: Methodical, completeness-focused, thinks in systems
- **Task-er**: Clarity-obsessed, measurability-driven, breaks things down
- **Code-er**: Pragmatic, correctness-first, minimal footprint
- **Review-er**: Skeptical, security-conscious, detail-oriented
- **Test-er**: Thorough, edge-case hunter, loves breaking things
- **Architect-er**: Strategic, rationale-driven, records everything
- **Deploy-er**: Reliability-focused, automation-first, rollback-ready
- **Check-er**: Neutral verifier, evidence-based, no assumptions
- **Prompt-er**: Concise, cache-aware, token-conscious
- **Re-Origination-er**: Fearless restructurer, breaks to improve
- **Speak-er**: Diplomatic orchestrator, translates between you and specialists

These aren't just prompt variations — they're persistent identities with their own memory and decision-making patterns.

---

## 🗂️ Directory Structure

```
parlei/
├── CLAUDE.md                    # Claude Code bootstrap
├── bootstraps/
│   ├── CODEX.md                 # Codex bootstrap
│   └── OPENCLAW.md              # OpenClaw bootstrap
├── docs/                        # Project documentation
├── scripts/
│   ├── setup.sh                 # One-command installation
│   ├── backup.sh                # Nightly backup (cron)
│   ├── memory_optimize.sh       # Nightly memory cleanup (cron)
│   ├── restore.sh               # Restore from backup
│   └── run_tests.sh             # Test suite runner
├── shared/                      # Shared across all environments
│   ├── agents/                  # Agent definitions (.md)
│   ├── memory/                  # Persistent agent memory
│   ├── personalities/           # Agent personalities (.md)
│   ├── prompts/                 # Reusable prompt library
│   └── tools/                   # Dispatch scripts and protocols
├── tests/                       # Test suite (bats-core)
└── backups/                     # Created by setup.sh
```

---

## 🛠️ Commands

### Global CLI (Recommended)

```bash
# Setup and configuration
parlei setup codex                # Set up for Codex environment
parlei status                     # Show current configuration
parlei bootstrap codex            # Display bootstrap instructions

# Testing
parlei test                       # Run all tests
parlei test unit                  # Run unit tests only

# Maintenance
parlei backup                     # Create memory backup
parlei restore 2026-04-01         # Restore from backup
parlei optimize                   # Optimize agent memory

# Help
parlei help                       # Show all commands
```

### Direct Script Access (Alternative)

```bash
# Setup for an environment
bash scripts/setup.sh claude

# Run all tests
bash scripts/run_tests.sh

# Manually optimize memory
bash scripts/memory_optimize.sh

# Restore from a backup
bash scripts/restore.sh backups/parlei-backup-20260401-0230.tar.gz

# Check cron jobs are registered
crontab -l | grep parlei

# Install/uninstall global CLI
bash scripts/install_global.sh    # Install
bash scripts/uninstall_global.sh  # Uninstall
```

---

## 🔧 Configuration

All configuration lives in `shared/tools/`:

- **`model_routing.json`** — Which model each agent uses
- **`memory_config.json`** — Memory optimization settings, backup retention
- **`protocol.md`** — Inter-agent communication rules
- **`schema_request.json`** — Request message format
- **`schema_response.json`** — Response message format

---

## 🧪 Testing

Parlei includes three types of tests:

- **Unit tests** (`tests/unit/`) — Test individual scripts
- **Integration tests** (`tests/integration/`) — Test dispatch pipeline
- **Functionality tests** (`tests/functionality/`) — End-to-end workflows

Run the test suite:

```bash
bash scripts/run_tests.sh
```

Requires [bats-core](https://github.com/bats-core/bats-core). Install via:

```bash
brew install bats-core          # macOS
apt-get install bats            # Linux
```

---

## 🐛 Troubleshooting

### "Agent does not respond"

Check that the bootstrap file was loaded. For Claude Code, `CLAUDE.md` should auto-load. For others, manually load the bootstrap:

```
Read bootstraps/CODEX.md and follow the loading instructions.
```

### "Dispatch script not found"

Run setup again:

```bash
bash scripts/setup.sh claude
```

### "Cron jobs not running"

Verify they're registered:

```bash
crontab -l | grep parlei
```

Re-run setup if missing.

### More help

See environment-specific install guides in `docs/install-<environment>.md`.

---

## 🤝 Contributing

Parlei is designed to be extended. To add a new agent:

1. Create `shared/agents/<agent-name>.md` with role definition
2. Create `shared/personalities/<agent-name>.md` with personality
3. Create `shared/memory/<agent-name>/` directory with `identity.md` and `long_term.md`
4. Add entry to `shared/tools/model_routing.json`
5. Add to `AGENTS` array in `scripts/setup.sh`
6. Update bootstrap files to include the new agent in the roster

---

## 📜 License

[Specify your license here]

---

## 🙏 Acknowledgments

Inspired by the concept of a parliament of owls — a gathering of wise, specialized beings working in concert toward a common goal.

Built on the principle that **specialization > generalization** when the overhead of coordination is low enough.

---

## 🦉 The Parliament Awaits

Install Parlei, load the bootstrap, and say hello to Speak-er. The parliament is in session.

```
You: "Hello, Speak-er."

Speak-er: "The parliament is in session. I am Speak-er, your
facilitator and orchestrator. Behind me stand ten specialist
agents, each a master of their domain. What would you like
us to help you build today?"
```


