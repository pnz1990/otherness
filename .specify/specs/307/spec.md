# Spec: Vision Evolution Cadence — items 307-310

> Items: 307, 308, 309, 310 | Created: 2026-04-19 | Status: Active

## Design reference
- **Design doc**: `docs/design/17-vision-evolution-cadence.md`
- **Implements**: PM §5 vision age check + §5c inferred stubs + §5h emergent patterns + marker conventions (🔲 → ✅)

---

## Zone 1 — Obligations

**O1 — PM §5k: vision age check posts vibe-vision suggestion when queue is empty >30 days.**
New PM §5k section. When queue has been empty AND no new design doc activity for >30 days:
post one suggestion on REPORT_ISSUE. Not a [NEEDS HUMAN]. Not a blocker. One post per period.

**O2 — PM §5c: competitive gap findings are written as ⚠️ Inferred design doc stubs.**
When PM §5c finds a competitor capability gap, it writes a design doc stub to
`docs/design/<area>-competitive-gaps.md` with `⚠️ Inferred` marker on each item.
These become visible to COORD queue gen immediately, without requiring a vibe-vision session.

**O3 — PM §5h extension: emergent patterns in Present items become ⚠️ Observed stubs.**
PM §5h already scans Present items for journey gaps. Extend it to also check if any
Present item has no corresponding design doc entry at all (shipped without a design doc).
These become `⚠️ Observed` entries in the appropriate design doc.

**O4 — ⚠️ Inferred and ⚠️ Observed conventions documented in a skills entry or design doc.**
A brief note in `docs/design/` or `agents/skills/` explains the three markers:
- ✅ Present: shipped, intentional, documented
- 🔲 Future: planned, not yet implemented
- ⚠️ Inferred: COORD or PM generated this entry; human has not reviewed it
- ⚠️ Observed: found in code with no prior design intent; human should confirm or deprecate

---

## Zone 2 — Implementer's judgment

- All 4 changes are [AI-STEP] additions to pm.md (§5k, §5c extension, §5h extension)
  plus a docs/design/ conventions note.
- CRITICAL-B for pm.md additions.
- The ⚠️ marker conventions note is LOW tier (docs/design/).

---

## Zone 3 — Scoped out

- Acting on ⚠️ Inferred items without human review
- Retroactive classification of existing Present items as ⚠️ Observed
