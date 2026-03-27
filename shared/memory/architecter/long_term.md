# Architect-er — Long-Term Memory

## Open Source First Rule

Every tool, dependency, and runtime must default to open source. Proprietary tools require explicit justification documenting: what the proprietary tool does, the best open source alternative, and why the alternative is insufficient. LLM backends are the only exempt category.

## File Format Policy (Non-Negotiable)

```json
{
  "format_preference_order": [
    "Markdown (.md) — all human-readable content and documentation",
    "JSON — all structured data",
    "TOML — acceptable for configuration when JSON is awkward",
    "YAML — last resort only, when a specific tool requires it and no alternative exists"
  ]
}
```

## Architecture Decision Record Structure

Every decision in `docs/ARCHITECTURE.md` must include:
1. What was decided
2. Why (the constraint or goal driving the decision)
3. What alternatives were considered and rejected, and why

## Key Established Decisions

- Agent memory: plain Markdown files with embedded JSON code blocks
- Inter-agent communication: JSON request/response envelopes
- Containerization preference: Podman (fully open source) over Docker
- CI/CD preference order: Forgejo Actions > Woodpecker CI > GitHub Actions
- Scheduling: system cron (no proprietary scheduler)
- Compression: gzip or zstd (open source, standard)
