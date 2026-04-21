# Spec: issue-646 — SM health signal STALLING/STALLED consecutive-batch tracking

## Design reference
- **Design doc**: `docs/design/23-simulation-as-anchor.md`
- **Section**: `§ Future`
- **Implements**: SM §4f `PROGRESS_CLASS`: replace `STEADY` with `STALLING` (2 consecutive batches with `meaningful_prs == 0`) and add `STALLED` (3+ consecutive batches). The health signal must not show GREEN when meaningful work has stalled.

---

## Zone 1 — Obligations (falsifiable)

**O1** — SM §4f computes `PROGRESS_CLASS` using: ADVANCING (this batch has meaningful_prs > 0), STALLING (this batch + last 1 batch both have meaningful_prs == 0), STALLED (this + last 2 consecutive batches all have meaningful_prs == 0). STEADY is replaced by STALLING for the 1-batch no-meaningful-PR case. Violation: STEADY still used, or STALLING/STALLED not based on meaningful_prs column.

**O2** — When PROGRESS_CLASS is STALLING or STALLED and HEALTH is GREEN, the health signal is upgraded to AMBER. A GREEN + STALLING combination must not be emitted. Violation: GREEN + STALLING in the batch report.

**O3** — Graceful: if metrics.md is absent or has <2 rows, PROGRESS_CLASS defaults to ADVANCING (fail-open). Violation: crash or incorrect classification when metrics are sparse.

**O4** — The `STALLING_STREAK` count (number of consecutive batches with meaningful_prs == 0) is computed from the last 3 rows of metrics.md and logged. Violation: streak count not computed or not logged.

---

## Zone 2 — Implementer's judgment

- Reading the last 3 rows of metrics.md is sufficient for 3-tier ADVANCING/STALLING/STALLED classification.
- The `meaningful_prs` column is at index 13 (same as PM §5 — just merged in PR #696). If the column is absent in older rows, treat as 0 (conservative: assume no meaningful work).
- The existing `VISION_PRS` check (ADVANCING if vision_prs > 0) can coexist — ADVANCING means either meaningful_prs > 0 OR vision_prs > 0. This avoids regressing the existing signal.

---

## Zone 3 — Scoped out

- Real-time stall detection during session (before SM phase) — that's the §1f-recovery block (issue-645, just merged).
- Auto-triggering vision synthesis when STALLED — that's housekeeping-streak escalation (separate item in design doc 21 Future).
