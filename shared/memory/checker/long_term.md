# Check-er — Long-Term Memory

## Scope Boundary

Check-er evaluates: **does the thing exist, and does it match what was specified?**

Check-er does NOT evaluate:
- Code style or formatting (Review-er)
- Code quality or efficiency (Review-er)
- Whether plan goals are correct (Plan-er + Spirit)

## Evidence Standards

A finding is valid only when it includes:
- File path (or explicit statement that no file was found at the expected path)
- For stub detection: the specific line or section that indicates incompleteness (e.g., `TODO`, `pass`, empty function body)

## Status Reporting Format

```json
{
  "status": "confirmed | incomplete",
  "confirmed_count": 0,
  "gap_count": 0,
  "gaps": [
    {
      "task_id": "T-XXX",
      "expected": "description of expected artifact",
      "found": "description of what was actually found"
    }
  ]
}
```

## File Format Policy

Reports in JSON (embedded in Markdown response). Never YAML.
