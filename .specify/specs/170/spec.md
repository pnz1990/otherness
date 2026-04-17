# Spec: feat(sm): difficulty-ledger.md tracking

> Item: 170 | Risk: medium | Size: s | Tier: CRITICAL (sm.md — phases file)

## Design reference
- N/A — new skill file creation + SM phase integration (docs/future-ideas.md Idea 3)

---

## Zone 1 — Obligations

**O1**: `~/.otherness/agents/skills/difficulty-ledger.md` must be created if it doesn't exist.
- **Falsified by**: skill file doesn't exist after PR merges.

**O2**: sm.md §4b must include a step that appends to difficulty-ledger.md when any of these conditions are detected: needs_human > 0 in last batch, or todo_shipped = 0 for 2+ batches, or time_to_merge > 60 min in last batch.
- **Falsified by**: SM phase completes without checking/updating difficulty-ledger.md.

**O3**: Each ledger entry must be abstract (no project names) and include: situation, what resolved it, guard for future.
- **Falsified by**: Entry contains a specific project name or repo slug.

**O4**: The change is a 5-8 line addition to sm.md §4b — no restructuring.
- **Falsified by**: More than 12 lines of sm.md changed.

---

## Zone 2 — Implementer's judgment

- Format: `## YYYY-MM-DD: <abstract situation title>` + body
- Where in §4b: after the REGEOF block, before §4c
- Initial skill file content: empty template with format explanation

---

## Zone 3 — Scoped out

- Does NOT implement automatic extraction from all managed projects (that's Idea 8)
- Does NOT validate ledger entry quality
