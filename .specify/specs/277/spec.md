# Spec: PM §5g simulation health score

> Item: 277 | Created: 2026-04-18 | Status: Active

## Design reference
- **Design doc**: `docs/design/12-perpetual-validation.md`
- **Section**: `## Future`
- **Implements**: PM §5g: simulation health score (🔲 → ✅)

---

## Zone 1 — Obligations

**O1 — PM phase has a §5g section that produces a GREEN/AMBER/RED health signal.**
`agents/phases/pm.md` must include `## 5g. Simulation health score` that runs every
N_PM_CYCLES cycles and produces one of three signals:
- GREEN: simulated completion_rate matches real rate within tolerance, arch_convergence < 0.5
- AMBER: completion_rate drift detected OR arch_convergence 0.5–0.7
- RED: genuine stall (todo_shipped = 0 for ≥2 batches OR arch_convergence > 0.7)

Behavior that violates this: §5g is absent from pm.md or only produces GREEN.

**O2 — §5g reads sim-results.json from _state and metrics.md.**
The simulation health check reads `.otherness/sim-results.json` (from _state, written
by SM §4d) for calibrated parameters. It reads `docs/aide/metrics.md` for the last
3 batches of real data. Graceful fallback: if either file missing, log and skip.

Behavior that violates this: §5g tries to run simulate.py without checking for
sim-results.json or metrics.md.

**O3 — AMBER triggers a comment on REPORT_ISSUE, not a [NEEDS HUMAN] issue.**
AMBER means "self-correct in progress" — it is informational, not a human escalation.
RED triggers `[NEEDS HUMAN]` only if arch_convergence > 0.7 OR todo_shipped = 0 for
≥3 consecutive batches.

Behavior that violates this: AMBER opens a [NEEDS HUMAN] issue (too aggressive).

**O4 — Design doc 12 marks §5g as ✅ Present.**

---

## Zone 2 — Implementer's judgment

- Whether to actually run simulate.py in §5g: yes, but briefly — `--runs 1 --cycles 30`
  for a fast health check (not the full calibration grid). Use calibrated sim-params.json
  for initial params.
- Whether to run simulate.py every PM cycle: no — cadence gate (N_PM_CYCLES).
- What tolerance for "completion rate match": ±15% is reasonable.
- Placement in pm.md: after §5f (doc health scan), before §5d (PM review post).

---

## Zone 3 — Scoped out

- Full calibration grid in §5g (that's §4d's job — §5g uses quick health check only)
- Historical health score tracking (single snapshot per cycle)
- Automatic parameter tuning based on health score
