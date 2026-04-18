# Spec: Phase 2a — per-project calibration

> Item: 270 | Created: 2026-04-18 | Status: Active

## Design reference
- **Design doc**: `docs/design/11-simulation-feedback-loop.md`
- **Section**: `## Future`
- **Implements**: Phase 2a: per-project calibration (🔲 → ✅)

---

## Zone 1 — Obligations

**O1 — SM §4d calibration checks for project-specific metrics before running default calibration.**
The §4d calibration block in sm.md must check whether `docs/aide/metrics.md`
exists and contains ≥10 data rows. If yes: run `scripts/calibrate.py` using the
local metrics as input. If no: run with otherness default parameters.

Behavior that violates this: calibration always uses otherness defaults regardless
of whether local project metrics are available.

**O2 — The result (sim-params.json) is committed to the `_state` branch.**
After calibration runs with project metrics, write `scripts/sim-params.json` to
the `_state` branch as `.otherness/sim-params.json`. This allows the calibrated
parameters to persist across sessions.

Behavior that violates this: sim-params.json is written to the working tree only
and lost between sessions.

**O3 — Per-project calibration only runs when ≥10 batches of metrics exist.**
The check is: count data rows in docs/aide/metrics.md (lines matching
`^\|\s*\d{4}-\d{2}-\d{2}`). If count < 10: use otherness defaults.

Behavior that violates this: calibration runs with 1-2 rows of project data
(too few to be statistically meaningful).

**O4 — Design doc 11 marks Phase 2a as ✅ Present.**

---

## Zone 2 — Implementer's judgment

- How to pass local metrics to calibrate.py: `scripts/calibrate.py` should accept
  a `--metrics-file` parameter. If the file is provided: use those rows. If not:
  use default parameters. Implementation: add [AI-STEP] comment in §4d that
  reads metrics.md row count and conditionally passes `--metrics-file`.
- Whether to change calibrate.py itself: yes — add `--metrics-file` argument.
  The script already parses real metrics; extend it to accept external input.
- Storage of sim-params in _state: write using the same worktree pattern as state.json.

---

## Zone 3 — Scoped out

- Cross-project parameter sharing (all projects share defaults from otherness main)
- Per-project storage of learn session history
- Retroactive calibration from historical metrics
