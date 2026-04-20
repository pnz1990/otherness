# Spec: SM §4d Phase 2a + 2c — Per-project calibration and sim-results persistence

## Design reference
- **Design doc**: `docs/design/11-simulation-feedback-loop.md`
- **Section**: `§ Present — Phase 2a and Phase 2c`
- **Implements**: Per-project calibration + sim-results.json to _state (🔲 → ✅)

---

## Zone 1 — Obligations (falsifiable)

**O1** — SM §4d must check metrics.md row count before calibration. If ≥10 rows: pass `--metrics docs/aide/metrics.md` to calibrate.py. If <10: run default calibration. Violation: always uses default regardless of metrics count.

**O2** — After successful calibration, SM §4d must persist `scripts/sim-params.json` to the `_state` branch as `.otherness/sim-params.json` using the worktree pattern. Violation: sim-params.json not on _state after calibration.

**O3** — SM §4d must write `sim-results.json` to _state branch with fields: calibrated_at, best_rmse, source ("project-specific" or "otherness-defaults"), params. Violation: field missing from written JSON.

**O4** — All persistence operations are non-fatal: if write fails, log and continue. Violation: exception propagates and halts SM phase.

**O5** — validate.sh and lint.sh pass in worktree. Violation: non-zero exit.

---

## Zone 2 — Implementer's judgment

- Use `os.environ.get('METRICS_ROWS', '0')` in python3 blocks; pass from bash as env var.
- Worktree pattern is the same as state.json writes (worktree add → write → commit → push → worktree remove).

---

## Zone 3 — Scoped out

- Reading sim-results.json from _state in PM §5g (separate issue)
- Handling concurrent calibration from parallel sessions (worktree commit NOP if unchanged)
