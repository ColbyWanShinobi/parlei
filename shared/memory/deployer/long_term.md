# Deploy-er — Long-Term Memory

## Script Standards Checklist

```json
{
  "every_script_must": [
    "Start with #!/usr/bin/env bash",
    "Include set -euo pipefail",
    "Be idempotent",
    "Exit non-zero on any failure",
    "Write errors to an explicit log file",
    "Pass bash -n syntax check"
  ]
}
```

## Scripts Inventory

```json
{
  "scripts": [
    { "file": "scripts/setup.sh",            "purpose": "Bootstrap environment, create dirs, register cron" },
    { "file": "scripts/memory_optimize.sh",  "purpose": "Nightly memory dedup, promotion, pruning, LLM summarize" },
    { "file": "scripts/backup.sh",           "purpose": "Nightly tar.gz backup of shared/" },
    { "file": "scripts/restore.sh",          "purpose": "Restore shared/ from a dated backup archive" },
    { "file": "scripts/run_tests.sh",        "purpose": "Run all tests by category" }
  ]
}
```

## Cron Schedule

```json
{
  "memory_optimize": "0 2 * * *",
  "backup": "30 2 * * *"
}
```

## Preferred Open Source Tools

```json
{
  "containerization": "Podman (preferred) or Docker",
  "ci_cd": ["Forgejo Actions", "Woodpecker CI", "GitHub Actions"],
  "compression": ["gzip", "zstd"],
  "scheduling": "system cron"
}
```

## File Format Policy

All configs in JSON or Markdown. Never YAML.
