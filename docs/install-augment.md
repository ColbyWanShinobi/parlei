# 🦉 Parlei — Augment: Install, Uninstall & Troubleshooting

> *Environment config: `bootstraps/AUGGIE.md`*

---

## 📍 Where to Install

Parlei should be installed **once per machine** in a location accessible by every AI tool you intend to use. All bootstrap configs (`CLAUDE.md`, `bootstraps/AUGGIE.md`, etc.) point into the same `shared/` directory. Two separate Parlei installs means split agent memory — avoid it.

### macOS

Install anywhere in your home directory:

```bash
~/parlei
~/Projects/parlei
~/myproject/parlei        # embedded in a specific project
```

Augment in VS Code or JetBrains will open this directory directly. No special configuration needed.

### Linux

Same as macOS — any path under your home directory works:

```bash
~/parlei
~/dev/parlei
```

Full functionality out of the box.

### Windows (native)

> ⚠️ **Limited functionality.** Bash scripts require Git Bash. Cron does not exist natively on Windows. WSL2 is strongly preferred — see below.

If you must install on native Windows:

```
%USERPROFILE%\parlei       # e.g. C:\Users\you\parlei
```

- Augment works via VS Code on Windows and will access files from the Windows filesystem normally.
- All scripts must be run from **Git Bash**.
- Replace cron with **Windows Task Scheduler**: create two tasks that run `bash.exe scripts/memory_optimize.sh` and `bash.exe scripts/backup.sh` at 02:00 and 02:30 respectively, using the absolute path to `bash.exe` (typically `C:\Program Files\Git\bin\bash.exe`).

### WSL2 (recommended for Windows)

Install inside the **WSL2 filesystem**, not on the Windows filesystem:

```bash
# ✅ Correct — inside WSL2
~/parlei                  # resolves to /home/<user>/parlei inside WSL2

# ❌ Avoid — Windows filesystem mounted in WSL2
/mnt/c/Users/<user>/parlei
```

File I/O on `/mnt/c/` paths is significantly slower inside WSL2, `inotify` does not work reliably across the boundary, and cron can have issues with Windows-mounted paths. Keep everything in the WSL2 native filesystem.

**Accessing Parlei from Augment:**

Augment runs inside VS Code. Install the **WSL** extension in VS Code, then:

1. Open a WSL2 terminal and `cd ~/parlei`
2. Run `code .` — this opens VS Code connected to the WSL2 remote with Parlei as the workspace root
3. The Augment extension runs in the WSL2 context and accesses files natively at their WSL2 paths

This is the smoothest setup for Augment on Windows. The extension sees the WSL2 filesystem as if it were a local Linux machine.

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
| [Augment Code](https://augmentcode.com) | Latest | VS Code or JetBrains extension |
| Git | Any recent version | `git --version` |
| Bash | 4.0+ | `bash --version` |
| Python 3 | 3.8+ | `python3 --version` — required by `memory_optimize.sh` |
| cron | Any | `crontab -l` should not error |

Augment Code must be installed and authenticated in your editor before Parlei will function. Install it from the VS Code Marketplace or JetBrains Marketplace and sign in with your Augment account.

---

## 📦 Install

### Step 1 — Clone the repository

```bash
git clone <parlei-repo-url> parlei
cd parlei
```

### Step 2 — Run the setup script

```bash
bash scripts/setup.sh augment
```

The script will:
- Verify all `shared/` subdirectories exist
- Create `backups/` if absent
- Write `.parlei-env` with value `augment`
- Validate `bootstraps/AUGGIE.md` is present
- Register two nightly cron jobs:
  - `02:00` — `memory_optimize.sh`
  - `02:30` — `backup.sh`

Expected output on success:

```
Verified: all shared/ subdirectories present.
Cron registered: parlei-memory
Cron registered: parlei-backup

✓ Parlei setup complete for environment: augment
  Config file : /path/to/parlei/bootstraps/AUGGIE.md
  Shared dir  : /path/to/parlei/shared
  Backups dir : /path/to/parlei/backups

Open your AI coding tool and load AUGGIE.md.
The parliament is in session. 🦉
```

### Step 3 — Open the project in Augment Code

Open the `parlei/` directory in your editor (VS Code or JetBrains) with the Augment extension active.

### Step 4 — Load the bootstrap config

Augment Code does not auto-detect bootstrap files the way Claude Code reads `CLAUDE.md`. You must manually instruct Augment to read the config at the start of each session.

In the Augment chat panel, send:

> "Read `bootstraps/AUGGIE.md` and follow the loading instructions in it."

Augment will read the file and execute each step in the Loading Instructions section — loading Speak-er's agent definition, personality, and memory.

**Tip:** If your editor or Augment version supports persistent context files or instruction files (sometimes called "system prompts" or "context injections"), configure it to automatically include `bootstraps/AUGGIE.md` as a context source. This avoids manual loading each session.

### Step 5 — Verify Speak-er is active

After the bootstrap completes, confirm Parlei is running:

> "Confirm you have loaded your identity and memory files."

Speak-er will list the files it has read and confirm it is the active agent.

### Step 6 — LLM summarization (not available via cron)

Augment is a VS Code/JetBrains extension with no standalone CLI. The nightly memory optimizer (`memory_optimize.sh`) runs as a cron job in a shell context where the Augment extension is not accessible, so automated LLM summarization is **not supported** for this environment.

The other three memory optimization steps (deduplication, episodic-to-long-term promotion, and age pruning) run normally.

**Alternative — manual summarization during a session:**
You can ask Speak-er to trigger summarization manually at any time:

> "Ask each agent to read their `long_term.md` file and produce a more concise version, removing any duplicated or superseded entries."

This uses Augment's in-session LLM access and writes the result back to the memory files. Run it periodically (e.g., after major work sessions) to keep memory files compact.

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

### Step 3 — Remove the Augment context configuration

If you added `bootstraps/AUGGIE.md` as a persistent context source in your editor or Augment settings, remove it from that configuration. This is specific to how you set it up — check Augment's extension settings in VS Code (`Settings > Extensions > Augment`) or in JetBrains (`Preferences > Augment`).

### Step 4 — (Optional) Clear agent memory

To clear session-accumulated episodic memory while preserving baseline identity files:

```bash
find parlei/shared/memory -type d -name "episodic" -exec rm -rf {} +
```

To reset all memory to repo baseline (destructive):

```bash
git -C parlei checkout -- shared/memory/
```

### Step 5 — Remove the repository

```bash
cd ..
rm -rf parlei
```

---

## 🔧 Troubleshooting

### Augment does not respond as Speak-er

**Symptom:** Augment answers normally but shows no knowledge of the Parliament or the agent roster.

**Causes and fixes:**

1. **Bootstrap was not loaded this session.** Augment does not persist loaded file context across chat sessions by default. At the start of every new session, send:
   > "Read `bootstraps/AUGGIE.md` and follow the loading instructions."

2. **Augment could not find the file.** Confirm the working directory is `parlei/` and the file exists:
   ```bash
   cat bootstraps/AUGGIE.md
   ```

3. **The file was read but loading instructions were not followed.** Be explicit:
   > "Read `bootstraps/AUGGIE.md`. Then read each file listed in its Loading Instructions section, in order. Then confirm which files you have loaded."

---

### `setup.sh` fails with "required directory missing"

**Fix:** The `shared/` skeleton must exist. Restore it from git:

```bash
git -C parlei status
git -C parlei checkout -- shared/
```

---

### Agent reads files from the wrong paths

**Symptom:** Speak-er or a delegated agent tries to read `shared/agents/speaker.md` instead of `../shared/agents/speaker.md` and reports the file not found.

**Cause:** The agent's working directory context may be `parlei/bootstraps/` instead of `parlei/`. Clarify:

> "Your current working directory for file paths is the `parlei/` repo root. All `../shared/` paths in `AUGGIE.md` resolve relative to `parlei/bootstraps/` — so `../shared/agents/speaker.md` means `parlei/shared/agents/speaker.md`. Read that file now."

Alternatively, provide the absolute path:

> "Read `/absolute/path/to/parlei/shared/agents/speaker.md`."

---

### Augment loses context mid-session

**Symptom:** After a long conversation, Speak-er stops referencing agent roles correctly or forgets the communication protocol.

**Cause:** Augment's context window has a limit. Long sessions can push earlier loaded files out of context.

**Fix:** Re-load only what is needed for the current task:

> "Re-read `bootstraps/AUGGIE.md` loading instructions 1 and 5 — your identity and the communication protocol."

For very long sessions, consider starting a fresh session and re-loading the bootstrap.

---

### Cron jobs are not running

**Diagnoses:**

1. **Confirm jobs are registered:**
   ```bash
   crontab -l | grep parlei
   ```
   If empty, re-run `bash scripts/setup.sh augment`.

2. **Check cron daemon is running:**
   ```bash
   # Linux (systemd)
   systemctl status cron || systemctl status crond
   # macOS
   sudo launchctl list | grep cron
   ```

3. **Check error logs:**
   ```bash
   cat backups/error_log.md
   cat shared/memory/error_log.md
   ```

---

### Memory optimizer fails

See the **Memory optimizer fails** entries in `docs/install-claude.md` — the cron infrastructure is identical across all environments.

---

### Backup archive is empty or missing

See the **Backup archive is empty or missing** entry in `docs/install-claude.md` — the backup infrastructure is identical across all environments.

---

### An agent writes files to the wrong path

**Symptom:** An agent creates `PLAN.md` at the root instead of `docs/PLAN.md`.

**Fix:** The agent's definition file specifies the correct path. Ask Speak-er to correct it:

> "Ask Plan-er to re-read `shared/agents/planer.md`, then move any `PLAN.md` at the repo root to `docs/PLAN.md`."

---

### `.parlei-env` shows wrong environment

**Fix:**
```bash
bash scripts/setup.sh augment
```

Idempotent — will not duplicate cron jobs.

---

### Persistent context injection not working (VS Code)

**Symptom:** You configured `bootstraps/AUGGIE.md` as a context file in Augment's VS Code settings, but Speak-er is not active on session start.

**Diagnoses:**

1. Verify the path in Augment's context settings is absolute or correctly relative to the workspace root.
2. Confirm `bootstraps/AUGGIE.md` is included in the workspace (not gitignored or excluded from the editor's file watcher).
3. Check Augment extension version — context file injection may require a specific minimum version. Consult Augment's changelog.
