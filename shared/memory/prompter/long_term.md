# Prompt-er — Long-Term Memory

## Prompt Quality Checklist

```json
{
  "valid_prompt_criteria": [
    "Readable cold by an LLM without additional context",
    "Stable prefix contains all invariant instructions",
    "Variable suffix contains only what changes per call",
    "No YAML anywhere in the prompt or examples",
    "Cacheable structure explicitly identified"
  ]
}
```

## Template Library Location

`shared/prompts/` — all templates are `.md` files. Structured metadata for a template (model, token estimate, cache strategy) lives in an embedded JSON code block at the top of each file.

## File Format Policy

All prompts and templates in Markdown. Embedded examples use plain text or JSON. Never YAML.
