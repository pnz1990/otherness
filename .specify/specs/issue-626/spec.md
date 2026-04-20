# Spec: /otherness.status enhanced health dashboard

## Design reference
- **Design doc**: `docs/design/35-quality-of-output-gaps.md`
- **Section**: `§ Future`
- **Implements**: New command `/otherness.status` enhanced output — structured health dashboard (🔲 → ✅)

---

## Zone 1 — Obligations (falsifiable)

**O1 — The enhanced output shows 6 sections.**
The status command must show: (1) health signal with trend (last 5 batches from metrics.md),
(2) skills count + last learn date from PROVENANCE.md, (3) queue depth + next item title,
(4) journey status table from definition-of-done.md, (5) simulation status (calibrated?,
arch_convergence score), (6) reference project health (_state age).
Violation: any of the 6 sections absent.

**O2 — The output fits in ≤40 lines.**
A human checking status should read it in 30 seconds. The output must be compact.
Violation: output exceeds 40 lines without a `--verbose` flag.

**O3 — Trend uses last 5 batches from metrics.md.**
Trend is calculated as: count of "feature-rich" + "mixed" outcomes in last 5 rows of
docs/aide/metrics.md vs total. Shows as: ADVANCING (≥3 feature/mixed), STEADY (2),
STALLING (≤1). Violation: trend not computed from metrics.md.

**O4 — Simulation section shows calibration age and arch_convergence.**
Read `sim-prediction.json` from `_state`. Show: source (calibrated/fleet-defaults),
calibrated_at age in days, arch_convergence_score with AMBER indicator if >= 0.7.
Violation: simulation section shows placeholder or is absent when sim-prediction.json exists.

---

## Zone 2 — Implementer's judgment

- Whether to replace the existing Step 1-4 or add a new Step 0 dashboard header:
  add a Step 0 that prints the dashboard, then existing steps follow for detailed views.
- Single-project mode only (--fleet mode unchanged).
- Graceful fallback for missing files: each section shows "unavailable" if its source
  file is absent or cannot be parsed.

---

## Zone 3 — Scoped out

- Interactive/curses UI
- Real-time refresh mode
- Detailed journey validation (journey status is pass/fail from definition-of-done.md)
