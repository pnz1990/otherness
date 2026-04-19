# Spec: Phase 2c — simulation results in _state

> Item: 271 | Created: 2026-04-18 | Status: Active

## Design reference
- **Design doc**: `docs/design/11-simulation-feedback-loop.md`
- **Section**: `## Future`
- **Implements**: Phase 2c: simulation results in `_state` (🔲 → ✅)

---

## Zone 1 — Obligations

**O1 — SM §4d writes sim-results.json to _state after calibration.**
After a successful calibration run, SM §4d must commit `.otherness/sim-results.json`
to the `_state` branch. The file must contain: calibration timestamp, best RMSE,
best params, and the calibration source (project-specific or otherness defaults).

Behavior that violates this: calibration runs but results are not persisted to _state.

**O2 — PM §5b reads sim-results.json from _state for product validation.**
When PM §5b product validation runs, it reads `.otherness/sim-results.json` from
`_state` (if it exists) and includes the simulation health score in the validation
report. If the file doesn't exist: skip simulation health without error.

Behavior that violates this: PM §5b never reads sim-results.json even after it's written.

**O3 — sim-results.json format is machine-readable.**
The file must be valid JSON with at least: `calibrated_at`, `best_rmse`, `source`,
and `params` (the best parameter set). PM can parse this without error.

**O4 — Design doc 11 marks Phase 2c as ✅ Present.**

---

## Zone 2 — Implementer's judgment

- Where in §4d to add the _state write: after the existing calibration success block,
  alongside the sim-params.json write from Phase 2a.
- What to include in sim-results.json: `{calibrated_at, best_rmse, source, params}`.
- How PM reads it: `git show origin/_state:.otherness/sim-results.json` — same as
  reading state.json. If the file doesn't exist: no error, skip.
- Whether PM opens issues based on sim-results: no — PM reports the health score
  informationally. Issues from sim health are handled by SM §4d arch-convergence alarm.

---

## Zone 3 — Scoped out

- Comparing sim-results across batches (single current result only)
- Automatic PM actions based on sim health score (informational only)
- PM modifications to calibration parameters
