# Spec: PM §5m ⚠️ Inferred ratio check

> Item: 315 | Created: 2026-04-19 | Status: Active

## Design reference
- **Design doc**: `docs/design/18-autonomous-vision-synthesis.md`
- **Section**: `§ Future`
- **Implements**: PM §5m: `⚠️ Inferred` ratio check (🔲 → ✅)

---

## Zone 1 — Obligations

**O1 — PM §5m checks the ratio of ⚠️ Inferred to total Future items.**
New PM §5m section. Counts: total `🔲` items across all design docs, and of those
how many contain `⚠️ Inferred`. If ratio >80%: post one vibe-vision suggestion per
period on REPORT_ISSUE.

**O2 — The suggestion is informational, not a [NEEDS HUMAN] blocker.**
Same pattern as PM §5k (vision age check). One post per period. Loop continues.

**O3 — Design doc 18 marks this ✅ Present.**

---

## Zone 2 — Implementer's judgment

- CRITICAL-B: new section in pm.md, all [AI-STEP] comments.
- Period = N_PM_CYCLES (same cadence as other PM checks).

---

## Zone 3 — Scoped out

- Blocking the queue when ratio is high
- Per-doc ⚠️ Inferred ratios (aggregate only)
