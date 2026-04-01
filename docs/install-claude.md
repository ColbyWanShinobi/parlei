# 🦉 Parlei — Claude Code: Install, Uninstall & Troubleshooting

> *Environment config: `CLAUDE.md` (repo root)*

---

## 📍 Where to Install

Parlei should be installed **once per machine** in a location accessible by every AI tool you intend to use. All bootstrap configs (`CLAUDE.md`, `bootstraps/CODEX.md`, `bootstraps/OPENCLAW.md`) point into the same `shared/` directory. Two separate Parlei installs means split agent memory — avoid it.

### macOS

Install anywhere in your home directory:

```bash
~/parlei                  # standalone
~/Projects/parlei         # alongside other projects
~/myproject/parlei        # embedded in a specific project
```

All tools, scripts, and cron work natively on macOS. No special configuration needed.

### Linux

Same as macOS — any path under your home directory works:

```bash
~/parlei
~/dev/parlei
```

Full functionality out of the box. Cron runs as written.

### Windows (native)

> ⚠️ **Limited functionality.** Bash scripts require Git Bash or a compatible shell. Cron does not exist natively on Windows. WSL2 is strongly preferred — see below.

If you must install on native Windows:

```
%USERPROFILE%\parlei       # e.g. C:\Users\you\parlei
```

- Claude Code (Windows app) will load `CLAUDE.md` from the Windows filesystem.
- All scripts must be run from **Git Bash** — the Windows Command Prompt and PowerShell will not work.
- Replace cron with **Windows Task Scheduler**: create two tasks that run `bash.exe scripts/memory_optimize.sh` and `bash.exe scripts/backup.sh` at 02:00 and 02:30 respectively, using the absolute Windows path to `bash.exe` (typically `C:\Program Files\Git\bin\bash.exe`).

### WSL2 (recommended for Windows)

Install inside the **WSL2 filesystem**, not on the Windows filesystem:

```bash
# ✅ Correct — inside WSL2
~/parlei                  # resolves to /home/<user>/parlei inside WSL2

# ❌ Avoid — Windows filesystem mounted in WSL2
/mnt/c/Users/<user>/parlei
```

File I/O on `/mnt/c/` paths is significantly slower inside WSL2, `inotify` (used by some editors) does not work reliably across the boundary, and cron can have issues with Windows-mounted paths. Keep everything in the WSL2 native filesystem.

**Accessing Parlei from Windows tools:**

| Tool | How to access WSL2 files |
|---|---|
| Claude Code (Windows app) | Open via the WSL network path: `\\wsl$\<distro>\home\<user>\parlei` |
| VS Code | Install the **WSL** extension → `Remote: Reopen Folder in WSL` → open `~/parlei` |
| Windows Explorer | Navigate to `\\wsl$\<distro>\home\<user>\parlei` |
| Any Windows app | Use the `\\wsl$\` UNC path above |

**Cron in WSL2** — cron does not start automatically. Choose one of:

```bash
# Option A: start manually each time you open WSL2
sudo service cron start

# Option B: auto-start on WSL2 login (add to ~/.bashrc or ~/.profile)
sudo service cron start 2>/dev/null

# Option C: configure WSL2 to start cron at boot via /etc/wsl.conf
# Add to /etc/wsl.conf (requires passwordless sudo for service, or sudoers entry):
# [boot]
# command = service cron start
```

The cleanest persistent option on modern WSL2 (version 0.67.6+) is `/etc/wsl.conf` with `[boot] command`:

```ini
# /etc/wsl.conf
[boot]
command = service cron start
```

---

## 📋 Prerequisites

Before installing Parlei for Claude Code, confirm the following are available on your system:

| Requirement | Minimum | Notes |
|---|---|---|
| [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) | Latest | `claude --version` |
| Git | Any recent version | `git --version` |
| Bash | 4.0+ | `bash --version` |
| Python 3 | 3.8+ | `python3 --version` — required by `memory_optimize.sh` |
| cron | Any | `crontab -l` should not error |

Claude Code must be installed and authenticated before Parlei will function. If you have not yet installed it, see the [Claude Code documentation](https://docs.anthropic.com/en/docs/claude-code).

---

## 📦 Install

### Step 1 — Clone the repository

Clone Parlei into the root of your project (or any working directory you intend to use with Claude Code):

```bash
git clone <parlei-repo-url> parlei
cd parlei
```

### Step 2 — Run the setup script

```bash
bash scripts/setup.sh claude
```

The script will:
- Verify all `shared/` subdirectories exist
- Create the `backups/` directory if it is absent
- Write a `.parlei-env` marker file recording the active environment
- Register two nightly cron jobs:
  - `02:00` — `memory_optimize.sh` (deduplication, promotion, pruning, LLM summarization)
  - `02:30` — `backup.sh` (compresses `shared/` to a dated `.tar.gz` in `backups/`)
- Validate that `CLAUDE.md` is present and `shared/` is intact

Expected output on success:

```
Verified: all shared/ subdirectories present.
Cron registered: parlei-memory
Cron registered: parlei-backup

✓ Parlei setup complete for environment: claude
  Config file : /path/to/parlei/CLAUDE.md
  Shared dir  : /path/to/parlei/shared
  Backups dir : /path/to/parlei/backups

Open your AI coding tool and load CLAUDE.md.
The parliament is in session. 🦉
```

### Step 3 — Open the project in Claude Code

Claude Code automatically reads `CLAUDE.md` from the working directory when you open a project. Navigate to the `parlei/` directory and open Claude Code:

```bash
cd parlei
claude
```

Claude Code will load `CLAUDE.md` on startup. No manual file loading is required.

### Step 4 — Verify Speak-er is active

On first interaction, Claude Code will have loaded `CLAUDE.md` and executed its loading instructions. Confirm Parlei is active by sending any message. Speak-er should respond in character. You can also explicitly verify by saying:

> "Confirm you have loaded your identity and memory files."

Speak-er will confirm which files it has read and its current state.

### Step 5 — (Optional) Configure LLM summarization

The nightly memory optimizer uses the `claude` CLI directly to summarize long-term memory files — no API credentials or separate endpoint configuration required. It pipes the prompt to `claude --print`, which uses Claude Code's already-authenticated session.

This step is optional. The optimizer runs without it, skipping only the summarization step. To enable it, ensure the `claude` binary is in the PATH that cron uses:

```bash
# Confirm claude is findable in a non-login shell (cron's environment)
which claude

# If not found, add it to cron's PATH by prepending to the crontab:
# PATH=/usr/local/bin:/usr/bin:/bin:/home/youruser/.local/bin
# (adjust to wherever 'claude' lives on your system)
crontab -e
```

To specify a model, set `llm_model` in `shared/tools/memory_config.json`:

```json
{
  "llm_model": "claude-sonnet-4-6",
  "episodic_retention_days": 90,
  "promotion_threshold": 3,
  "backup_retention_count": 30,
  "compression": "gzip"
}
```

If `llm_model` is empty, `claude --print` uses its own default model. No auth token is needed — Claude Code's existing login handles authentication.

---

## 🗑️ Uninstall

### Step 1 — Remove cron jobs

```bash
crontab -l | grep -v "parlei-memory" | grep -v "parlei-backup" | crontab -
```

Verify the jobs are gone:

```bash
crontab -l | grep parlei
# Should produce no output
```

### Step 2 — Remove the environment marker

```bash
rm -f parlei/.parlei-env
```

### Step 3 — (Optional) Clear agent memory

If you want a clean slate for future reinstalls, delete the episodic memory logs. This preserves the identity and long-term memory files (which are part of the repo) but removes session-accumulated data:

```bash
find parlei/shared/memory -type d -name "episodic" -exec rm -rf {} +
```

To wipe all memory entirely (destructive — resets all agents to baseline):

```bash
git -C parlei checkout -- shared/memory/
```

### Step 4 — Remove the repository

```bash
cd ..
rm -rf parlei
```

This removes the entire Parlei installation including all agent memory, backups, and configuration.

---

## 🔧 Troubleshooting

### Speak-er does not respond in character

**Symptom:** Claude Code responds normally but does not identify as Speak-er or reference the Parliament.

**Causes and fixes:**

1. **`CLAUDE.md` was not loaded.** Claude Code must be opened from the `parlei/` directory (or a subdirectory of it). The file is only loaded when it is in the working directory hierarchy.
   ```bash
   cd /path/to/parlei
   claude
   ```

2. **Context window was reset.** Claude Code may not re-read `CLAUDE.md` after a `/clear`. Restart the session or explicitly ask Claude to re-read the loading instructions:
   > "Please re-read `CLAUDE.md` and reload your identity."

3. **`shared/agents/speaker.md` is missing or unreadable.**
   ```bash
   cat shared/agents/speaker.md
   ```
   If the file is missing, re-clone or restore from `backups/`.

---

### `setup.sh` fails with "required directory missing"

**Symptom:**
```
Error: required directory missing: /path/to/parlei/shared/agents
```

**Fix:** The `shared/` skeleton must exist before running setup. The directory structure is part of the repository. If it is missing, your clone is incomplete:

```bash
git -C parlei status
git -C parlei checkout -- shared/
```

---

### Cron jobs are not running

**Symptom:** No entries in `backups/backup_log.md` or `shared/memory/optimize_log.md` after 03:00.

**Diagnoses:**

1. **Confirm jobs are registered:**
   ```bash
   crontab -l | grep parlei
   ```
   If empty, re-run `bash scripts/setup.sh claude`.

2. **Check cron daemon is running:**
   ```bash
   # Linux (systemd)
   systemctl status cron || systemctl status crond
   # macOS
   sudo launchctl list | grep cron
   # WSL2 — cron must be started manually (does not auto-start)
   sudo service cron start
   sudo service cron status
   ```
   On WSL2 specifically, cron will not be running unless you started it this session or configured `/etc/wsl.conf` to start it at boot. See the **Where to Install → WSL2** section above.

   On Windows (native), cron is not available — use Windows Task Scheduler instead.

3. **Check error logs:**
   ```bash
   cat backups/error_log.md
   cat shared/memory/error_log.md
   ```

4. **Verify script paths are absolute in crontab:**
   ```bash
   crontab -l | grep parlei
   ```
   The paths must be absolute (starting with `/`). If they are relative, re-run `setup.sh` from inside the `parlei/` directory.

---

### Memory optimizer fails with "memory_config.json not found"

**Symptom:** `shared/memory/error_log.md` contains:
```
global | config | memory_config.json not found
```

**Fix:**
```bash
ls shared/tools/memory_config.json
```

If missing, restore from the repo:
```bash
git -C . checkout -- shared/tools/memory_config.json
```

---

### Memory optimizer fails with Python error

**Symptom:** Error log shows a Python traceback or "command not found: python3".

**Fix:** Install Python 3:
```bash
# Debian/Ubuntu
sudo apt install python3
# Fedora
sudo dnf install python3
# macOS (Homebrew)
brew install python3
```

---

### Backup archive is empty or missing

**Symptom:** `backups/` contains no `.tar.gz` files, or `backup_log.md` shows "Archive is zero bytes".

**Diagnoses:**

1. **`backups/` directory missing** — re-run `setup.sh`.
2. **`shared/` directory missing or empty** — restore from git.
3. **tar not available** — `which tar` should return a path. If not, install it via your package manager.
4. **All `current_task.md` files were marked in-progress** — the backup script excludes in-progress task files. If all of `shared/` is covered by exclusions, the archive can be near-empty. Check for stale `current_task.md` files:
   ```bash
   grep -rl "Status: in-progress" shared/memory/
   ```
   Resolve or clean them up, then run the backup manually:
   ```bash
   bash scripts/backup.sh
   ```

---

### An agent writes the wrong file path

**Symptom:** An agent creates `PLAN.md` at the repo root instead of `docs/PLAN.md`.

**Fix:** The agent's definition file instructs it to write to `docs/PLAN.md`. If it wrote to the wrong path, the agent may not have loaded its current definition. Ask Speak-er to have the relevant agent re-read its definition file, then redo the task:

> "Ask Plan-er to re-read `shared/agents/planer.md` and then move any misplaced `PLAN.md` to `docs/PLAN.md`."

---

### Interrupted task not detected on startup

**Symptom:** An agent's task was interrupted mid-run, but on the next session Speak-er does not mention it.

**Fix:** Speak-er checks for `shared/memory/speaker/current_task.md` with `Status: in-progress`. Verify the file exists and has the correct status:

```bash
cat shared/memory/speaker/current_task.md | grep Status
```

If the file exists but the status field is missing or malformed, Speak-er will not detect the interruption. Manually notify Speak-er:

> "Check `shared/memory/speaker/current_task.md` — it may contain an interrupted task."

---

### `.parlei-env` shows wrong environment

**Symptom:** `.parlei-env` contains `codex` but you are using Claude Code.

**Fix:**
```bash
bash scripts/setup.sh claude
```

This overwrites `.parlei-env` with the correct value. It is idempotent — running it again will not duplicate cron jobs.
