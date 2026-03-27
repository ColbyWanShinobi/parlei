# 🦉 Parlei — OpenClaw: Install, Uninstall & Troubleshooting

> *Environment config: `bootstraps/OPENCLAW.md`*

---

## 📍 Where to Install

Parlei should be installed **once per machine** in a location accessible by every AI tool you intend to use. All bootstrap configs (`CLAUDE.md`, `bootstraps/OPENCLAW.md`, etc.) point into the same `shared/` directory. Two separate Parlei installs means split agent memory — avoid it.

### macOS

Install anywhere in your home directory:

```bash
~/parlei
~/Projects/parlei
~/myproject/parlei        # embedded in a specific project
```

OpenClaw and all scripts run natively on macOS. No special configuration needed.

### Linux

Same as macOS — any path under your home directory works:

```bash
~/parlei
~/dev/parlei
```

Full functionality out of the box. OpenClaw is primarily a Linux/macOS tool, so this is the native environment.

### Windows (native)

> ⚠️ **Limited functionality.** OpenClaw is primarily a Linux/macOS tool. Windows native support depends on your OpenClaw version. Bash scripts require Git Bash. Cron does not exist natively. WSL2 is strongly preferred — see below.

If your version of OpenClaw supports native Windows and you must install there:

```
%USERPROFILE%\parlei       # e.g. C:\Users\you\parlei
```

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

**Accessing Parlei with OpenClaw on WSL2:**

- Run `openclaw` from inside the WSL2 terminal: `cd ~/parlei && openclaw` — it reads files at native WSL2 paths.
- If OpenClaw has a VS Code extension, install the **WSL** extension and open the workspace via `code .` from the WSL2 terminal. The extension will run in the WSL2 context.
- Windows Explorer can browse files at `\\wsl$\<distro>\home\<user>\parlei` if needed.

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
| [OpenClaw](https://github.com/openclaw/openclaw) | Latest | `openclaw --version` or equivalent |
| Git | Any recent version | `git --version` |
| Bash | 4.0+ | `bash --version` |
| Python 3 | 3.8+ | `python3 --version` — required by `memory_optimize.sh` |
| cron | Any | `crontab -l` should not error |

OpenClaw must be installed and configured before Parlei will function. Follow OpenClaw's installation documentation to set up the tool and point it at your LLM backend of choice.

> **Note on OpenClaw:** OpenClaw is an open-source AI coding tool. Its interface may differ across versions. `bootstraps/OPENCLAW.md` is written for any OpenClaw version that supports reading context files and performing file read/write operations. If your version has a dedicated context file mechanism (analogous to `CLAUDE.md` in Claude Code), configure it as described in Step 4 below.

---

## 📦 Install

### Step 1 — Clone the repository

```bash
git clone <parlei-repo-url> parlei
cd parlei
```

### Step 2 — Run the setup script

```bash
bash scripts/setup.sh openclaw
```

The script will:
- Verify all `shared/` subdirectories exist
- Create `backups/` if absent
- Write `.parlei-env` with value `openclaw`
- Validate `bootstraps/OPENCLAW.md` is present
- Register two nightly cron jobs:
  - `02:00` — `memory_optimize.sh`
  - `02:30` — `backup.sh`

Expected output on success:

```
Verified: all shared/ subdirectories present.
Cron registered: parlei-memory
Cron registered: parlei-backup

✓ Parlei setup complete for environment: openclaw
  Config file : /path/to/parlei/bootstraps/OPENCLAW.md
  Shared dir  : /path/to/parlei/shared
  Backups dir : /path/to/parlei/backups

Open your AI coding tool and load OPENCLAW.md.
The parliament is in session. 🦉
```

### Step 3 — Open the project directory

Open `parlei/` in OpenClaw. Ensure OpenClaw is using the `parlei/` directory as its working root so relative file paths resolve correctly.

### Step 4 — Load the bootstrap config

#### Option A — Auto-load via context file (preferred)

If your version of OpenClaw supports a context file or instruction file that is loaded automatically at session start (check OpenClaw's documentation for terms like "context file", "system instructions", or "project config"), configure it to load `bootstraps/OPENCLAW.md`.

For example, if OpenClaw supports a `.openclaw` or `openclaw.md` config file at the project root, create a symlink:

```bash
ln -s bootstraps/OPENCLAW.md .openclaw
```

Adjust the symlink target to match the filename your version expects. After this, OpenClaw will load the bootstrap on every session start without manual intervention.

#### Option B — Manual load at session start

If auto-loading is not supported, send this instruction at the start of each session:

> "Read `bootstraps/OPENCLAW.md` and follow the loading instructions in it."

OpenClaw will read the file and execute each step in the Loading Instructions section — loading Speak-er's agent definition, personality, memory, and communication protocol.

### Step 5 — Verify Speak-er is active

After the bootstrap runs, confirm:

> "Confirm you have loaded your identity and memory files."

Speak-er will respond listing the files it has read.

### Step 6 — Verify shell access

`bootstraps/OPENCLAW.md` notes that scripts in `scripts/` can be executed via shell access if available. Test this:

> "Run `bash scripts/run_tests.sh unit` and show me the output."

If shell access is not available, note this for troubleshooting purposes — certain capabilities (test execution, script-based backup and memory optimization) will require running those scripts manually from your terminal.

### Step 7 — (Optional) Configure LLM summarization

The nightly memory optimizer uses the `openclaw` CLI directly to summarize long-term memory files — no API credentials or separate endpoint configuration required. It pipes the prompt to `openclaw --print`, which uses OpenClaw's already-configured authentication.

This step is optional. To enable it, ensure the `openclaw` binary is in the PATH that cron uses:

```bash
# Confirm openclaw is findable in a non-login shell (cron's environment)
which openclaw

# If not found, add it to cron's PATH:
# PATH=/usr/local/bin:/usr/bin:/bin:/home/youruser/.local/bin
crontab -e
```

To specify a model, set `llm_model` in `shared/tools/memory_config.json`:

```json
{
  "llm_model": "",
  "episodic_retention_days": 90,
  "promotion_threshold": 3,
  "backup_retention_count": 30,
  "compression": "gzip"
}
```

If `llm_model` is empty, the `openclaw` CLI uses its own configured default. No auth token is stored in Parlei — OpenClaw handles authentication via its own config. Consult OpenClaw's documentation for the model identifiers supported by your configured backend.

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

### Step 3 — Remove any OpenClaw context file symlink

If you created a symlink in Step 4 of the install:

```bash
ls -la parlei/ | grep openclaw
rm -f parlei/.openclaw
```

Also check for any OpenClaw-specific config file that references `bootstraps/OPENCLAW.md` (e.g., `~/.openclaw/config.json` or a workspace config) and remove the reference.

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

### OpenClaw does not respond as Speak-er

**Symptom:** OpenClaw answers normally but has no knowledge of the Parliament.

**Causes and fixes:**

1. **Bootstrap was not loaded.** If using manual loading (Option B), send the load instruction:
   > "Read `bootstraps/OPENCLAW.md` and follow the loading instructions."

2. **Context file symlink is broken.** If using Option A:
   ```bash
   readlink -f .openclaw
   # Should resolve to bootstraps/OPENCLAW.md
   ls -la bootstraps/OPENCLAW.md
   ```
   Re-create the symlink if it is broken:
   ```bash
   rm -f .openclaw
   ln -s bootstraps/OPENCLAW.md .openclaw
   ```

3. **OpenClaw version does not support context files.** Fall back to Option B (manual load). If OpenClaw's documentation describes a different context file format, consult it and adapt accordingly.

---

### `setup.sh` fails with "required directory missing"

**Fix:**
```bash
git -C parlei checkout -- shared/
```

---

### OpenClaw cannot find `../shared/` paths

**Symptom:** An agent reports it cannot locate `../shared/agents/speaker.md`.

**Cause:** OpenClaw is resolving paths relative to its own working directory rather than from `bootstraps/`.

**Fix:** Provide the path from the repo root explicitly:

> "The path `../shared/agents/speaker.md` in `OPENCLAW.md` means `parlei/shared/agents/speaker.md`. Read `shared/agents/speaker.md` relative to the `parlei/` root."

If OpenClaw consistently misresolves relative paths from bootstrap files, use absolute paths when manually instructing it:

> "Read `/absolute/path/to/parlei/shared/agents/speaker.md`."

---

### Context file auto-load does not trigger on session start

**Symptom:** You created a `.openclaw` symlink or equivalent context file config, but Speak-er is not active when you open a new session.

**Diagnoses:**

1. **Wrong filename.** Check OpenClaw's documentation for the exact filename it looks for. Common alternatives: `.openclaw`, `openclaw.md`, `.openclaw.md`, `OPENCLAW.md` (at root), or a path specified in a config file.

2. **Symlink not followed.** Some tools don't follow symlinks for context files. Copy instead:
   ```bash
   cp bootstraps/OPENCLAW.md .openclaw
   ```
   Note: if you copy instead of symlink, edits to `bootstraps/OPENCLAW.md` will not be reflected in `.openclaw` automatically.

3. **File not in working directory root.** The context file must be in the directory OpenClaw is opened from. Confirm OpenClaw's working root is `parlei/` and not a subdirectory.

---

### Shell access not available

**Symptom:** Agent cannot execute `scripts/` utilities.

**Impact:** Affects test execution and in-session script calls. Cron jobs still run independently on the host system.

**Workaround:**
- Run scripts from your terminal:
  ```bash
  bash scripts/run_tests.sh
  bash scripts/backup.sh
  bash scripts/memory_optimize.sh
  ```
- Paste output back into OpenClaw for analysis if needed.

---

### Agent loses character mid-session (context window exhaustion)

**Symptom:** After extended conversation, Speak-er stops routing correctly, delegates to wrong agents, or breaks protocol format.

**Cause:** OpenClaw's context window is full and earlier loaded bootstrap content has been evicted.

**Fix:** Re-load the minimum necessary context:

> "Re-read `bootstraps/OPENCLAW.md` loading instructions 1, 5, and 6 — your agent definition, the communication protocol, and the task spec format."

For very long sessions, starting a fresh session and reloading the bootstrap is more reliable than partial re-loads.

---

### Cron jobs not running

```bash
crontab -l | grep parlei
```

If empty, re-run `bash scripts/setup.sh openclaw`. See `docs/install-claude.md` → **Cron jobs are not running** for full diagnostics — the cron infrastructure is identical across all environments.

---

### Memory optimizer fails

See `docs/install-claude.md` — cron infrastructure and error logging are identical across all environments.

---

### Backup archive is empty or missing

See `docs/install-claude.md` — backup infrastructure is identical across all environments.

---

### LLM summarization fails or produces no output

**Symptom:** `shared/memory/error_log.md` shows "tool invocation failed" during the LLM summarization step, or long-term memory files are unchanged after the nightly run.

**Cause:** The `openclaw` binary is not in cron's PATH, or OpenClaw's authentication has expired.

**Diagnoses:**

1. Confirm `openclaw` is in PATH in a non-login shell:
   ```bash
   env -i PATH="$PATH" which openclaw
   ```

2. Test the CLI directly:
   ```bash
   echo "Say hello." | openclaw --print
   ```
   If it prompts for login or errors, re-authenticate OpenClaw before the next cron run.

3. If `openclaw --print` is not the correct invocation for your version, check `openclaw --help` and update the `invoke_tool_llm` function in `scripts/memory_optimize.sh` accordingly.

---

### `.parlei-env` shows wrong environment

**Fix:**
```bash
bash scripts/setup.sh openclaw
```

Idempotent — will not duplicate cron jobs.

---

### OpenClaw version-specific incompatibilities

If you encounter behavior not covered here, check:

1. **OpenClaw's issue tracker** for known bugs related to context file loading or file tool behavior.
2. **OpenClaw's changelog** for breaking changes to file path resolution or context injection.
3. **The Parlei issue tracker** to report a version-specific incompatibility so `bootstraps/OPENCLAW.md` can be updated.
