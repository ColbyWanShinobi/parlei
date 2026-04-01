# 🦉 Parlei — Codex: Install, Uninstall & Troubleshooting

> *Environment config: `bootstraps/CODEX.md`*

---

## 📍 Where to Install

Parlei should be installed **once per machine** in a location accessible by every AI tool you intend to use. All bootstrap configs (`CLAUDE.md`, `bootstraps/CODEX.md`, etc.) point into the same `shared/` directory. Two separate Parlei installs means split agent memory — avoid it.

### macOS

Install anywhere in your home directory:

```bash
~/parlei
~/Projects/parlei
~/myproject/parlei        # embedded in a specific project
```

The Codex CLI and all scripts run natively on macOS. No special configuration needed.

### Linux

Same as macOS — any path under your home directory works:

```bash
~/parlei
~/dev/parlei
```

Full functionality out of the box.

### Windows (native)

> ⚠️ **Limited functionality.** Bash scripts require Git Bash. Cron does not exist natively. WSL2 is strongly preferred — see below.

If you must install on native Windows:

```
%USERPROFILE%\parlei       # e.g. C:\Users\you\parlei
```

- The Codex CLI has Windows support; check OpenAI's documentation for the Windows installation path.
- All scripts must be run from **Git Bash**.
- Replace cron with **Windows Task Scheduler**: create two tasks that run `bash.exe scripts/memory_optimize.sh` and `bash.exe scripts/backup.sh` at 02:00 and 02:30, using the absolute path to `bash.exe` (typically `C:\Program Files\Git\bin\bash.exe`).

### WSL2 (recommended for Windows)

Install inside the **WSL2 filesystem**, not on the Windows filesystem:

```bash
# ✅ Correct — inside WSL2
~/parlei                  # resolves to /home/<user>/parlei inside WSL2

# ❌ Avoid — Windows filesystem mounted in WSL2
/mnt/c/Users/<user>/parlei
```

File I/O on `/mnt/c/` paths is significantly slower inside WSL2, `inotify` does not work reliably across the boundary, and cron can have issues with Windows-mounted paths. Keep everything in the WSL2 native filesystem.

**Accessing Parlei with Codex on WSL2:**

- Run the Codex CLI from inside the WSL2 terminal: `cd ~/parlei && codex "..."` — it reads files at native WSL2 paths.
- If using GitHub Copilot Workspace (browser-based), access Parlei files via a connected repository rather than the local filesystem.
- If using VS Code with a Codex integration, install the **WSL** extension and open the workspace via `code .` from the WSL2 terminal.

**Cron in WSL2** — cron does not start automatically. Choose one of:

```bash
# Option A: start manually each time you open WSL2
sudo service cron start

# Option B: auto-start on WSL2 login (add to ~/.bashrc or ~/.profile)
sudo service cron start 2>/dev/null
```

Or configure WSL2 to start cron at boot (requires WSL2 version 0.67.6+ and passwordless sudo for `service`):

```ini
# /etc/wsl.conf
[boot]
command = service cron start
```

---

## 📋 Prerequisites

| Requirement | Minimum | Notes |
|---|---|---|
| [OpenAI Codex](https://openai.com/codex) / Codex CLI | Latest | `codex --version` or equivalent |
| Git | Any recent version | `git --version` |
| Bash | 4.0+ | `bash --version` |
| Python 3 | 3.8+ | `python3 --version` — required by `memory_optimize.sh` |
| cron | Any | `crontab -l` should not error |

Codex must be installed and authenticated before Parlei will function. Follow OpenAI's documentation to install and authenticate the Codex CLI or integration you are using.

> **Note on Codex variants:** "Codex" may refer to the OpenAI Codex model (accessed via the API), the Codex CLI tool, or GitHub Copilot Workspace (which uses Codex-family models). `bootstraps/CODEX.md` is written for any Codex-based environment that supports reading context files and executing file operations. Adapt the loading step (Step 4) to match the interface your specific tool provides.

---

## 📦 Install

### Step 1 — Clone the repository

```bash
git clone <parlei-repo-url> parlei
cd parlei
```

### Step 2 — Run the setup script

```bash
bash scripts/setup.sh codex
```

The script will:
- Verify all `shared/` subdirectories exist
- Create `backups/` if absent
- Write `.parlei-env` with value `codex`
- Validate `bootstraps/CODEX.md` is present
- Register two nightly cron jobs:
  - `02:00` — `memory_optimize.sh`
  - `02:30` — `backup.sh`

Expected output on success:

```
Verified: all shared/ subdirectories present.
Cron registered: parlei-memory
Cron registered: parlei-backup

✓ Parlei setup complete for environment: codex
  Config file : /path/to/parlei/bootstraps/CODEX.md
  Shared dir  : /path/to/parlei/shared
  Backups dir : /path/to/parlei/backups

Open your AI coding tool and load CODEX.md.
The parliament is in session. 🦉
```

### Step 3 — Open the project directory

Open `parlei/` in your editor or terminal environment with Codex access.

### Step 4 — Load the bootstrap config

Codex does not auto-detect bootstrap files. At the start of each session, instruct Codex to load the config:

**Via Codex CLI:**
```bash
codex "Read bootstraps/CODEX.md and follow all loading instructions in it."
```

**Via GitHub Copilot Workspace or similar UI:**
In the task or context panel, add a reference to `bootstraps/CODEX.md` and include the instruction:
> "Read `bootstraps/CODEX.md` and follow the loading instructions."

**Via API / programmatic use:**
Include the contents of `bootstraps/CODEX.md` in the system prompt or as a user turn before your first request.

Codex will execute each step in the Loading Instructions section: loading Speak-er's definition, personality, memory, and communication protocol.

### Step 5 — Verify Speak-er is active

After bootstrap, confirm:

> "Confirm you have loaded your identity and memory files."

Speak-er will list the files it has read.

### Step 6 — Grant shell access (if available)

`bootstraps/CODEX.md` notes that scripts in `scripts/` can be executed via shell access if the environment supports it. If your Codex interface provides a terminal or code execution environment, confirm that `bash scripts/run_tests.sh` and similar commands work from the `parlei/` root.

If shell access is not available in your Codex environment, agents will rely entirely on file reading and writing rather than script execution. The parliament functions correctly without it — only test execution and manual script invocation are affected.

### Step 7 — (Optional) Configure LLM summarization

The nightly memory optimizer uses the `codex` CLI directly to summarize long-term memory files — no API credentials or separate endpoint configuration required. It pipes the prompt to `codex --quiet`, which uses the Codex CLI's already-configured authentication.

This step is optional. To enable it, ensure the `codex` binary is in the PATH that cron uses:

```bash
# Confirm codex is findable in a non-login shell (cron's environment)
which codex

# If not found, add it to cron's PATH:
# PATH=/usr/local/bin:/usr/bin:/bin:/home/youruser/.local/bin
crontab -e
```

To specify a model, set `llm_model` in `shared/tools/memory_config.json`:

```json
{
  "llm_model": "gpt-5.4-mini",
  "episodic_retention_days": 90,
  "promotion_threshold": 3,
  "backup_retention_count": 30,
  "compression": "gzip"
}
```

If `llm_model` is empty, the `codex` CLI uses its own default model. No auth token is stored in Parlei — the Codex CLI handles authentication via its own config (typically `~/.codex/config.json` or environment variables set at login).

**Model Tier Strategy for Codex:**

Parlei uses a three-tier model strategy optimized for cost and capability:

- **Lightweight** (`gpt-5.4-mini`): Fast routing and mechanical verification (Speak-er, Check-er)
- **Balanced** (`gpt-5.4`): General coding, planning, testing (Plan-er, Task-er, Code-er, Test-er, etc.)
- **Premium** (`gpt-5.3-codex`): High-stakes work requiring deep expertise (Review-er, Architect-er, Re-Origination-er)

This mapping is defined in `shared/tools/model_routing.json` and automatically applied when running in Codex mode.

---

## 🗑️ Uninstall

### Step 1 — Remove cron jobs

```bash
crontab -l | grep -v "parlei-memory" | grep -v "parlei-backup" | crontab -
```

Verify:
```bash
crontab -l | grep parlei
# Should produce no output
```

### Step 2 — Remove the environment marker

```bash
rm -f parlei/.parlei-env
```

### Step 3 — Remove any Codex system prompt or context file references

If you added `bootstraps/CODEX.md` to a persistent system prompt, context file, or workspace configuration in your Codex tool, remove it. The exact location depends on your tool:

- **Codex CLI config:** Check `~/.codex/config.json` or equivalent for any reference to `CODEX.md`.
- **GitHub Copilot Workspace:** Remove Parlei from any saved workspace context.
- **Custom API integrations:** Remove the CODEX.md content from your system prompt.

### Step 4 — (Optional) Clear agent memory

```bash
# Clear episodic logs only
find parlei/shared/memory -type d -name "episodic" -exec rm -rf {} +

# Full reset to repo baseline (destructive)
git -C parlei checkout -- shared/memory/
```

### Step 5 — Remove the repository

```bash
cd ..
rm -rf parlei
```

---

## 🔧 Troubleshooting

### Codex does not respond as Speak-er

**Symptom:** Codex answers in its default mode with no reference to the Parliament.

**Causes and fixes:**

1. **Bootstrap was not loaded.** Codex has no auto-detection mechanism for `CODEX.md`. You must include the load instruction at the start of every session.

2. **Context was not retained.** If using the Codex API directly, the bootstrap load must be in the same conversation thread. Codex does not persist state between API calls unless you manage conversation history yourself.

3. **File was read but instructions not followed.** Be more explicit:
   > "Read `bootstraps/CODEX.md`. Then, sequentially, read each file listed in its Loading Instructions section. Do not skip any step. After reading each file, confirm its name. Then confirm you are ready to act as Speak-er."

---

### `setup.sh` fails with "required directory missing"

**Fix:**
```bash
git -C parlei checkout -- shared/
```

---

### Shell access not available in Codex environment

**Symptom:** Running `bash scripts/run_tests.sh` from within Codex returns an error or is not supported.

**Impact:** Automated test execution and the `current_task.sh` helper script cannot run in-session. This affects:
- Test-er's ability to execute test suites

**Workaround:**
- Run scripts manually from your terminal outside the Codex session.
- For test results, run `bash scripts/run_tests.sh` in your terminal and paste the output into Codex for analysis.
- The parliament's core function (reading files, writing files, agent-to-agent communication via JSON) works without shell access.

---

### Agent file operations fail silently

**Symptom:** An agent claims to have written a file, but the file does not exist or is empty on disk.

**Cause:** Some Codex interfaces operate in a sandboxed or read-only environment where writes do not persist to the local filesystem.

**Diagnoses:**

1. Confirm whether your Codex environment has write access to the project directory:
   ```bash
   # From a terminal, check if Codex-created files appear
   ls -la docs/
   ```

2. If your environment is read-only, agents cannot maintain persistent memory or task files. Consider switching to Claude Code (which has full filesystem access via its built-in tools) for tasks that require persistent state.

---

### Path resolution errors (agent reads `../shared/` literally)

**Symptom:** An agent reports it cannot find `../shared/agents/speaker.md`.

**Cause:** The agent is treating the relative path literally rather than resolving it from the `bootstraps/` directory.

**Fix:** Clarify the resolution context explicitly:

> "In `bootstraps/CODEX.md`, the path `../shared/agents/speaker.md` means `parlei/shared/agents/speaker.md` — one level up from `bootstraps/`, then into `shared/agents/`. Read `parlei/shared/agents/speaker.md` now."

Or provide the absolute path directly:
> "Read `/absolute/path/to/parlei/shared/agents/speaker.md`."

---

### Cron jobs not running

```bash
crontab -l | grep parlei
```

If empty, re-run `bash scripts/setup.sh codex`. See `docs/install-claude.md` → **Cron jobs are not running** for full diagnostics.

---

### Memory optimizer or backup fails

See `docs/install-claude.md` — cron infrastructure is identical across environments.

---

### LLM summarization fails or produces no output

**Symptom:** `shared/memory/error_log.md` shows "tool invocation failed" during the LLM summarization step, or long-term memory files are unchanged after the nightly run.

**Cause:** The `codex` binary is not in cron's PATH, or the Codex CLI's authentication has expired.

**Diagnoses:**

1. Confirm `codex` is in PATH in a non-login shell:
   ```bash
   env -i PATH="$PATH" which codex
   ```

2. Test the CLI directly:
   ```bash
   echo "Say hello." | codex --quiet
   ```
   If it prompts for login or errors, re-authenticate the Codex CLI before the next cron run.

3. If `codex --quiet` is not the correct invocation for your version, check `codex --help` and update the `invoke_tool_llm` function in `scripts/memory_optimize.sh` accordingly.

---

### `.parlei-env` shows wrong environment

**Fix:**
```bash
bash scripts/setup.sh codex
```
