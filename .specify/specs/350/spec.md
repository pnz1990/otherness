# Spec: feat(sm): §4e divergence detection

## Design reference
- **Design doc**: `docs/design/23-simulation-as-anchor.md`
- **Section**: `§ Step 3: Reality vs prediction → signal`
- **Implements**: `SM §4e`: compare actual `todo_shipped` to predicted floor — post `[⚠️ Simulation divergence]` after 3 consecutive below-floor batches (🔲 → ✅)

---

## Zone 1 — Obligations

**O1** — After each SM batch, compare actual `todo_shipped` (last metrics.md row) to the
predicted floor. The predicted floor is derived from `scripts/sim-params.json` field
`observed_completion_rate` (fallback: 1.0 if file missing). Floor = floor(observed_completion_rate * 0.5)
to account for variance.

Violation: floor not read from sim-params.json; hard-coded constant used instead.

**O2** — Count of consecutive below-floor batches is tracked across sessions via
`.otherness/divergence_count.json` on the `_state` branch. Read on startup, increment if
below-floor, reset to 0 if at-or-above floor.

Violation: consecutive count resets every SM cycle (not persistent).

**O3** — After 3 consecutive below-floor batches, post `[⚠️ Simulation divergence]` comment
on REPORT_ISSUE with: actual shipped count, predicted floor, consecutive count, and
possible causes from design doc 23 §Step 4.

Violation: divergence signal not posted after 3 consecutive batches.

**O4** — The divergence signal is informational only. It does not block CI, prevent merges,
or create `[NEEDS HUMAN]` issues.

Violation: `needs-human` label on divergence signal, or any blocking behavior.

**O5** — If `docs/aide/metrics.md` has fewer than 3 rows or the last row's `todo_shipped`
column is not parseable, the check is skipped silently (no error, no false alarm).

Violation: error output when metrics.md is missing or malformed.

---

## Zone 2 — Implementer's judgment

- Where to store `divergence_count`: `.otherness/divergence_count.json` on `_state` branch
  is the right location (parallel-safe via the worktree pattern). Simple JSON: `{"count": N, "updated_at": "..."}`.
- Whether to use `observed_completion_rate` as floor source or run a simulation:
  `observed_completion_rate` from sim-params.json is simpler and already calibrated.
  Use `floor(observed_completion_rate * 0.5)` as the lower bound signal threshold.
- Frequency: run every SM cycle (not just calibration cycles) to detect drift quickly.

---

## Zone 3 — Scoped out

- Writing `sim-prediction.json` — that is issue 349 (separate spec)
- Autonomous recovery from divergence (queue adjustment, vision trigger) — that is design doc 23 §Step 4
- Cross-project divergence comparison — out of scope for this item
