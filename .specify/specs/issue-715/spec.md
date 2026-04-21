# Spec: SM §4e-ii — sim_floor_delta rolling average feeds recovery_action

**Item**: issue-715
**Design doc**: `docs/design/23-simulation-as-anchor.md`
**Section**: `§ Future` (🔲 → ✅)

## Design reference

- **Design doc**: `docs/design/23-simulation-as-anchor.md`
- **Section**: `§ Future`
- **Implements**: "`sim_floor_delta` must feed into `recovery_action` computation" (🔲 → ✅)

---

## Zone 1 — Obligations (falsifiable)

**O1**: SM §4e-ii reads the `sim_floor_delta` column from the last 5 rows of `docs/aide/metrics.md`. If fewer than 5 rows have a numeric `sim_floor_delta` value, the rolling average check is skipped (fail-open).

**O2**: SM §4e-ii computes a rolling average of the last 5 `sim_floor_delta` values. If the rolling average is ≤ −1.5, a `negative_floor_delta_avg` flag is set.

**O3**: When the `negative_floor_delta_avg` flag is set AND the flag has been set for 3 consecutive SM cycles (tracked via `sim_floor_delta_negative_streak` in `sim-prediction.json` on `_state`), `recovery_action` is overridden to `trigger_vision_synthesis` regardless of `consecutive_below_floor_count`.

**O4**: The `sim_floor_delta_negative_streak` counter in `sim-prediction.json` is incremented when the rolling average ≤ −1.5 and reset to 0 when it rises above −1.5. The counter is written to `sim-prediction.json` at the same time as `recovery_action`.

**O5**: The existing `consecutive_below_floor_count`-based logic is not removed — the new rolling-average check is additive (an additional override path). If `consecutive_count >= 3` OR `sim_floor_delta_negative_streak >= 3`, `recovery_action` becomes `trigger_vision_synthesis` (provided no higher-priority override fires: the priority order `vision_synthesis > needs_human > ci_fix > learn > none` is respected — `trigger_vision_synthesis` is the highest priority and takes precedence).

**O6**: The implementation is entirely within `agents/phases/sm.md` §4e-ii bash block. No other executable file is modified except `docs/design/23-simulation-as-anchor.md` (design doc update: 🔲 → ✅). The log line `[SM §4e] sim_floor_delta rolling avg: N.N (streak=K)` appears every SM cycle.

---

## Zone 2 — Implementer's judgment

- Where to read `sim_floor_delta` from metrics.md: the column is at index 11 (0-indexed) in the Batch Log table. Use the same row-parsing pattern as the existing §4e-ii code.
- The `sim_floor_delta_negative_streak` counter is stored in `sim-prediction.json` alongside `recovery_action`. It is written in the same git commit as `recovery_action`.
- The `trigger_vision_synthesis` action is already in the priority order — the existing `if todo_count < 5: recovery_action = 'trigger_vision_synthesis'` line means the magnitude-based path produces the same action. The new code adds a second triggering condition.

---

## Zone 3 — Scoped out

- Changes to `standalone.md` (CRITICAL tier — not in scope).
- Changes to `scripts/calibrate.py` (separate item).
- Changing the rolling-average window beyond 5 rows.
- Tracking `sim_floor_delta` delta-of-delta (velocity of divergence).
