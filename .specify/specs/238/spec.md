# Spec: scripts/calibrate.py (#238)

## Design reference
- **Design doc**: `docs/design/11-simulation-feedback-loop.md`
- **Section**: Phase 1a — calibration script
- **Implements**: 🔲 Phase 1a: calibrate.py (🔲→✅)

## Zone 1 — Obligations

**O1** — `python3 scripts/calibrate.py` reads `docs/aide/metrics.md`, runs a
parameter grid search, and writes `scripts/sim-params.json`.

Falsifiable: after running, `scripts/sim-params.json` exists and is valid JSON
with keys: decay_rate, jump_multiplier, skill_boldness_coefficient, calibrated_at,
n_batches, rmse.

**O2** — Grid search covers: decay_rate ∈ {0.88, 0.90, 0.92, 0.94},
jump_multiplier ∈ {1.3, 1.5, 1.6, 1.8, 2.0},
skill_boldness_coefficient ∈ {0.010, 0.013, 0.015, 0.018}.

Falsifiable: `python3 scripts/calibrate.py --dry-run` prints the grid size (80 combos).

**O3** — Best-fit criterion: minimize RMSE between simulated completion_rate
and observed completion rate from metrics.md (prs/items per batch).

**O4** — Deterministic given same metrics.md input and same seed.

Falsifiable: two runs with same input produce identical sim-params.json.

**O5** — Pure Python stdlib. No external dependencies.

**O6** — validate.sh required file list includes scripts/calibrate.py and
scripts/sim-params.json.

## Zone 2 — Implementer's judgment
- Use 5 runs per combination (not 50 — calibration needs speed, not precision)
- n_cycles=100 per run (matches the validated baseline)
- Print progress to stderr, JSON to file only

## Zone 3 — Scoped out
- Per-project calibration (Phase 2) — that is #239 scope
- Automatic parameter application to simulate.py defaults — sim-params.json is
  read by the SM phase; simulate.py still uses its own defaults unless explicitly
  overridden with --params flag
