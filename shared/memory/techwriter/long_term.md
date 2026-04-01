# Tech-Write-er Long-Term Memory

## Documentation Patterns

### API Documentation Structure
- Start with signature/syntax
- Document all parameters with types and constraints
- Include return values with types
- List possible exceptions/errors
- Provide working code examples
- Add cross-references to related functions

### Installation Documentation
- Support all platforms (Linux, macOS, Windows via WSL)
- Include prerequisites with versions
- Provide step-by-step commands
- Document verification steps
- Include troubleshooting for common issues

### Configuration Documentation
- List all options in table format
- Include types, defaults, and valid values
- Explain when to use each option
- Show example configurations
- Document environment variable equivalents

## Recurring Documentation Needs

### After Code Changes
- Update affected API references
- Add migration notes if breaking changes
- Update code examples
- Check cross-references still valid

### After Architecture Changes
- Update architecture diagrams
- Document new components
- Explain rationale for changes
- Update integration guides

### For New Features
- API reference for new functions/endpoints
- Configuration options if applicable
- Integration guide if affects external systems
- Examples showing typical usage

## Documentation Style Decisions

### Code Block Languages
- `bash` for shell commands
- `json` for JSON files
- `javascript` for JavaScript code
- `python` for Python code
- `markdown` for markdown examples

### Terminology
- "Agent" not "bot" or "assistant"
- "Environment" not "platform" or "system"
- "Bootstrap file" not "config file" or "setup file"
- "Dispatch" not "call" or "invoke"

### File Naming
- Installation: `install-<environment>.md`
- API reference: `api/<component>.md`
- Architecture: `ARCHITECTURE.md`
- Troubleshooting: `troubleshooting/<topic>.md`

## Quality Standards

### Before Finalizing Documentation
- [ ] Verified against actual code
- [ ] All parameters documented
- [ ] Examples tested and working
- [ ] Version info included
- [ ] Cross-references valid
- [ ] Breaking changes highlighted
- [ ] Error codes documented
- [ ] Markdown properly formatted

