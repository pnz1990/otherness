# Boundary File Reference

A BOUNDARY file defines the scope of a bounded standalone session.
You can either place it as `BOUNDARY` in the repo root, or inject the
fields directly in the prompt when starting `/otherness.run.bounded`.

## Fields

| Field | Required | Description |
|---|---|---|
| `AGENT_NAME` | Yes | Human-readable name shown in progress reports and PR titles |
| `AGENT_ID` | Yes | Unique machine ID for state.json (CAPS, no spaces, e.g. `STANDALONE-REFACTOR`) |
| `SCOPE` | Yes | One sentence describing this agent's focus |
| `ALLOWED_AREAS` | Recommended | Comma-separated `area/*` labels — agent only picks issues with at least one matching label |
| `ALLOWED_MILESTONES` | Optional | Comma-separated milestone titles — agent only picks issues in these milestones (empty = all) |
| `ALLOWED_PACKAGES` | Recommended | Comma-separated source paths this agent may modify |
| `DENY_PACKAGES` | Recommended | Source paths this agent must NEVER touch, overrides ALLOWED_PACKAGES |

## Injecting in the prompt (recommended — no file needed)

```
/otherness.run.bounded

AGENT_NAME=Refactor Agent
AGENT_ID=STANDALONE-REFACTOR
SCOPE=Fix logic leaks in the health and scm packages
ALLOWED_AREAS=area/health,area/scm
ALLOWED_MILESTONES=v0.2.1
ALLOWED_PACKAGES=pkg/health,pkg/scm
DENY_PACKAGES=cmd/myapp,api/v1
```

## Using a file (alternative)

```bash
cp ~/.otherness/boundaries/example.boundary BOUNDARY
# edit BOUNDARY, then:
/otherness.run.bounded
```

## Multiple concurrent sessions

Run one session per distinct area. Ensure ALLOWED_PACKAGES and DENY_PACKAGES
have zero overlap between sessions to prevent conflicts.

See `example.boundary` for a fully annotated template.
