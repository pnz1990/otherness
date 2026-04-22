# Spec: issue-790 — chore(sm) reduce python block duplication in §4f managed velocity check

## Design reference
- N/A — infrastructure refactor with no user-visible behavior change.

## Zone 1 — Obligations

**O1**: The managed velocity check runs the gh pr list API call exactly once per §4f call (not twice).
**O2**: Functional behavior is preserved: same MANAGED_VELOCITY_LABEL, MANAGED_VELOCITY_WARN, and HEALTH downgrade logic.
**O3**: The unified block both logs (`[SM §4f] Managed velocity: ...`) and emits env var markers on the same stdout.

## Zone 2 — Implementer's judgment
- Single block pattern: combine both MGMT_VEL_EOF and MGMT_PARSE_EOF into one block (MGMT_VEL_EOF) that both logs and outputs env var markers.
- Capture to `$_MGMT_OUTPUT` before parsing the while loop.

## Zone 3 — Scoped out
- Deduplicating other python blocks in sm.md (design doc 45 scope)
