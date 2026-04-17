# Spec: cross-project fleet health dashboard

**Issue:** #45
**Size:** M
**Risk tier:** HIGH (otherness.status.md, otherness-config-template.yaml)

## Obligations (Zone 1)

1. `/otherness.status` when run from any directory (not necessarily a project repo) must detect and query all projects in the fleet registry.

2. The fleet registry lives in `~/.otherness/otherness-config.yaml` under a `fleet.projects` key. Each entry has `repo` (owner/repo slug) and `name` (human label).

3. The fleet health table must show for each project: name, `_state` last-seen age, CI status on main, open PR count, needs-human issue count, and TODO item count from state.json.

4. Any project with `_state` older than 24 hours must be visually marked as `⚠️ STALE`.

5. Any project with `needs-human > 0` must be visually marked.

6. Any project with CI status `failure` must be visually marked.

7. If `fleet.projects` is not configured, `/otherness.status` falls back to the current project only (existing behavior).

8. `otherness-config-template.yaml` must include a commented-out `fleet:` section showing the format.

## Implementer's judgment (Zone 2)

- Exact column widths and formatting in the table.
- Whether to use python3 or bash for the fleet query.
- Whether to parallelize the per-project queries (nice to have but not required).

## Scoped out (Zone 3)

- This spec does not create a persistent dashboard — it is a point-in-time query.
- This spec does not send alerts or notifications.
- This spec does not add fleet info to any CI check.

## Interfaces

### ~/.otherness/otherness-config.yaml — new fleet section

```yaml
# In ~/.otherness/otherness-config.yaml — this is the local instance config,
# not part of the otherness source code. Add your own managed projects here.
monitor:
  projects:
    - owner/your-main-project
    - owner/another-project
    - owner/otherness          # the otherness repo itself
  stale_hours: 24
  idle_hours: 4
```

### Expected output

```
=== otherness fleet health ===
2026-04-14 21:30 UTC

PROJECT                  _STATE        CI        PRS  🚨  TODO
--------------------------------------------------------------
your-main-project        2h ago        ✅         1    0    2
another-project          5h ago        ✅         0    0    0
otherness                3h ago        ✅         0    0    0

🚨 = needs-human issues open
⚠️ = _state stale or CI red
```

### otherness.status.md — fleet query step

```bash
## Step 0 — Detect fleet mode

FLEET_CONFIG="$HOME/.otherness/otherness-config.yaml"
FLEET_PROJECTS=""
if [ -f "$FLEET_CONFIG" ]; then
  FLEET_PROJECTS=$(python3 - << 'EOF'
import re
projects = []
in_fleet = in_projects = False
for line in open("$HOME/.otherness/otherness-config.yaml"):
    if re.match(r'^fleet:', line): in_fleet = True
    if in_fleet and re.match(r'^\s+projects:', line): in_projects = True
    if in_projects:
        m = re.match(r'\s+- repo:\s*(\S+)', line)
        if m: projects.append(m.group(1))
for p in projects: print(p)
EOF
)
fi

if [ -n "$FLEET_PROJECTS" ]; then
  # Run fleet query
  python3 ~/.otherness/agents/fleet-health.py
else
  # Fall back to single-project status (existing behavior)
  ...
fi
```

## Files to change

| File | Change | Risk tier |
|---|---|---|
| `.opencode/command/otherness.status.md` | Add Step 0 (fleet detection) and fleet query | HIGH |
| `~/.otherness/otherness-config.yaml` | Add `fleet.projects` section | LOW |
| `otherness-config-template.yaml` | Add commented `fleet:` section | HIGH |

## Verification

```bash
# Configure fleet in ~/.otherness/otherness-config.yaml
# Run /otherness.status
# Verify output contains a table with all 4 projects
# Verify a stale project shows ⚠️ STALE
```

---

## Design reference
- N/A — pre-DDDD item (written before design doc system, PR #144)
