# Spec: issue-635 — Simulation predictions visibly change agent behavior

## Design reference
- **Design doc**: `docs/design/23-simulation-as-anchor.md`
- **Section**: `§ Future`
- **Implements**: Simulation predictions must visibly change agent behavior — SM §4e writes `recovery_action` to `sim-prediction.json`; `coord.md §1b` reads and acts on it.

---

## Zone 1 — Obligations (falsifiable)

**O1** — SM §4e divergence detection must compute a `recovery_action` field after each divergence check. Valid values: `trigger_learn`, `escalate_oldest_needs_human`, `prioritize_ci_fix`, `trigger_vision_synthesis`, or `none`. `none` means no action needed (not diverging).

Violation: `sim-prediction.json` on `_state` branch does not contain `recovery_action` field after SM §4e runs.

**O2** — The `recovery_action` selection logic must match the design doc §Step 4:
- Queue empty/low (< 5 todo items) → `trigger_vision_synthesis`
- `needs_human` open issues > 0 → `escalate_oldest_needs_human`
- CI red (failed run within 24h) → `prioritize_ci_fix`
- consecutive_count >= 3 AND not covered by above → `trigger_learn`
- Not diverging → `none`

Violation: `recovery_action` says `trigger_ci_fix` when `needs_human` issues are open (priority ordering violated).

**O3** — `coord.md §1b` must read `recovery_action` from `_state:.otherness/sim-prediction.json` at session start (after the vision check) and log what action was taken.

Violation: COORD session starts and `recovery_action` field is never read, or logged.

**O4** — When `recovery_action == trigger_learn`: COORD §1b must log `[COORD §1b-sim] recovery_action=trigger_learn — queue priority adjusted to favor skill-growth items` and set a flag `SIM_RECOVERY_ACTION=trigger_learn` so downstream coord/claim logic can see it.

**O5** — When `recovery_action == prioritize_ci_fix`: COORD §1b must log the action and set `SIM_RECOVERY_ACTION=prioritize_ci_fix`; claim logic in §1e must prefer `kind/bug` or CI-fix items over `kind/enhancement`.

**O6** — When `recovery_action == escalate_oldest_needs_human`: COORD §1b must log the action and post a comment on the oldest open `needs-human` issue reminding it needs attention.

**O7** — When `recovery_action == trigger_vision_synthesis`: COORD §1b must log the action; coord's queue-empty path in §1e already handles this — the flag is informational.

**O8** — `recovery_action` must be written to `sim-prediction.json` on the `_state` branch (not just in-memory). It persists across sessions.

---

## Zone 2 — Implementer's judgment

- Whether to use a Python sub-block or inline bash for the recovery_action computation in SM §4e
- Exact log format for COORD §1b messages (must include `[COORD §1b-sim]` prefix)
- Whether to expose `SIM_RECOVERY_ACTION` as an env var or shell variable

---

## Zone 3 — Scoped out

- Automated execution of recovery (e.g. auto-triggering `/otherness.learn`) — this PR only
  wires the signal; existing paths in coord already handle the actions
- Changing simulation calibration frequency or parameters
- Visualizing recovery_action history
