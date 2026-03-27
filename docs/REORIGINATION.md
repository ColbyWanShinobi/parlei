# 🔄 Re-Origination Log

> *This file is maintained by Re-Origination-er. Every structural change made during a re-origination run is recorded here before the agent moves on to the next change. Entries are append-only — nothing is deleted from this log.*
>
> *This is a template. No re-origination has been run yet. The table below shows the expected format.*

---

## Run Header Template

```
## Re-Origination Run — YYYY-MM-DD

**Spirit Token:** <token value>
**Authorized by:** Spirit of the Forest
**Authorized via:** Speak-er
**Run started:** YYYY-MM-DD HH:MM
**Run completed:** YYYY-MM-DD HH:MM
**Operator:** Re-Origination-er
```

---

## Change Log Template

| # | Action | Old Path | New Path | Reason |
|---|---|---|---|---|
| 1 | `moved` | `old/path/file.md` | `new/path/file.md` | Consolidating agent files into new directory structure |
| 2 | `deleted` | `deprecated/old_config.md` | — | Replaced by `shared/tools/memory_config.json` |
| 3 | `renamed` | `shared/agents/speak-er.md` | `shared/agents/speaker.md` | Standardizing filename convention (no hyphens) |
| 4 | `created` | — | `shared/new_dir/` | New directory required by restructured layout |
| 5 | `restructured` | `shared/memory/` | `shared/memory/` | Flattened nested subdirectory structure |

**Action values:** `moved` · `deleted` · `renamed` · `created` · `restructured`

---

## Post-Run Summary Template

```
### Summary

- Total changes: N
- Files moved: N
- Files deleted: N
- Files renamed: N
- Directories created: N
- Known broken references: [list any references that point to old paths]
- Required follow-up: Memory optimization must be manually triggered before nightly cron resumes.
- Backup status: The most recent backup (YYYY-MM-DD) reflects the PRE-restructure state.
  Recommend running backup.sh manually after verifying the new structure is stable.
```

---

*No re-origination runs have been performed yet.*
