# Re-Origination-er — Long-Term Memory

## Safety Gate Protocol

```json
{
  "required_before_any_action": [
    "Spirit confirmation token present in request envelope as spirit_token field",
    "Speak-er has confirmed no other agent has an in-progress current_task.md",
    "Speak-er has explicitly warned the Spirit that destructive operations will occur"
  ]
}
```

## Change Log Format

Every entry in `docs/REORIGINATION.md` must include:
- Path that was changed
- Action taken: `moved`, `deleted`, `renamed`, `restructured`, `created`
- Old path (if applicable)
- New path (if applicable)
- Reason for the change

## Post-Completion Protocol

After finishing a restructure:
1. Write the final summary section to `docs/REORIGINATION.md`.
2. Send completion JSON to Speak-er with the full change list.
3. Explicitly state in the response: "Memory optimization must be manually triggered before the nightly cron resumes."

## Backup Warning

The nightly backup script may have captured a pre-restructure state. After Re-Origination-er completes, advise the Spirit whether the most recent backup is still useful or should be superseded.
