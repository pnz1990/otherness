# Boundary File Templates

Copy the appropriate template, fill in any project-specific values,
and place it as `BOUNDARY` in the repo root before starting a bounded session.

## Usage

```bash
cp ~/.otherness/boundaries/refactor.boundary BOUNDARY
# Edit BOUNDARY if needed
/speckit.maqa.bounded-standalone
```

## Fields

AGENT_ID       — unique name for this session (no spaces)
SCOPE          — human-readable description (shown in PR titles and comments)
ALLOWED_AREAS  — comma-separated area/* labels from AGENTS.md (issues must have at least one)
ALLOWED_MILESTONES — comma-separated milestone titles (leave empty = all milestones)
ALLOWED_PACKAGES   — comma-separated Go package paths this session may modify
DENY_PACKAGES      — comma-separated Go package paths this session must never touch
