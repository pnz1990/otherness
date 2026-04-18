# Spec: COORD self-seeding gate (#242)

## Design reference
- **Design doc**: `docs/design/04-documentation-health.md`
- **Section**: `§ Future — Self-seeding check in COORD startup`
- **Implements**: 🔲 Self-seeding check in COORD startup (🔲→✅)

## Zone 1 — Obligations

**O1** — COORD §1b checks for docs/aide/vision.md before queue generation.
Falsifiable: `grep "Vision check\|vision.md" agents/phases/coord.md` → match.

**O2** — When absent: opens a [NEEDS HUMAN] issue (once, not every run).
Falsifiable: second run with no vision.md does not open a second issue.

**O3** — When vision.md absent: proceeds with empty queue (no crash, no exit).
Falsifiable: session completes normally.

**O4** — AGENTS.md section labels remain consistent (1a, 1b, 1c, 1d, 1e).
Falsifiable: `grep "^## 1[a-e]\." agents/phases/coord.md` → exactly 5 unique matches.

## Zone 2 — Implementer's judgment
- Empty string vision.md also triggers the gate ([ ! -s ] check)
- Deduplication via existing open needs-human issues with "no vision" in title

## Zone 3 — Scoped out
- Auto-running /otherness.onboard or /otherness.vibe-vision — those are human-initiated
- Blocking queue generation entirely — gate is advisory, execution continues
