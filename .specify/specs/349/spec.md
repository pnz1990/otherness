# Spec: feat(sm): §4e write sim-prediction.json

## Design reference
- **Design doc**: `docs/design/23-simulation-as-anchor.md`
- **Section**: `§ Step 2: Calibrated parameters → prediction`
- **Implements**: `SM §4e`: write calibrated parameters to `.otherness/sim-prediction.json` (🔲 → ✅)

---

## Zone 1 — Obligations

**O1** — After each successful calibration run in SM §4d, produce `.otherness/sim-prediction.json`
with the following fields: `prs_next_batch_floor` (int), `prs_next_batch_ceiling` (int),
`arch_convergence_score` (float), `skill_growth_rate` (float), `calibrated_params` (dict),
`calibrated_at` (ISO8601 string).

Violation: any of the 6 fields missing from the output JSON.

**O2** — The prediction is computed by running `scripts/simulate.py` with the calibrated
parameters from `scripts/sim-params.json`. Floor = 10th percentile of `completion_rate`
over the last 10 simulation cycles. Ceiling = 90th percentile.

Violation: floor/ceiling derived from a hard-coded value rather than simulation output.

**O3** — `sim-prediction.json` is written to the `_state` branch at `.otherness/sim-prediction.json`
using the existing worktree write pattern (parallel-safe).

Violation: file written only locally, not persisted to `_state`.

**O4** — If `scripts/simulate.py` or `scripts/sim-params.json` is unavailable, the step is
skipped silently. No error output. No crash.

Violation: error logged when optional dependencies are missing.

---

## Zone 2 — Implementer's judgment

- Run frequency: same as calibration (every 10 SM cycles) — prediction is derived from
  calibrated params, so there's no value in running more frequently.
- Number of simulation cycles for prediction: 50 is sufficient for stable statistics.
- Whether to use n_agents from sim-params.json or default: use 4 (the simulation default).

---

## Zone 3 — Scoped out

- Reading sim-prediction.json in divergence detection (issue 350 already handles this via sim-params.json)
- Fleet defaults (`~/.otherness/scripts/sim-defaults.json`) — separate issue 353
- PM §5 simulation health score integration — already implemented separately
