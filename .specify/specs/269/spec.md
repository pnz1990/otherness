# Spec: Phase 1c — SM triggers /otherness.learn from simulation output

> Item: 269 | Created: 2026-04-18 | Status: Active

## Design reference
- **Design doc**: `docs/design/11-simulation-feedback-loop.md`
- **Section**: `## Future`
- **Implements**: Phase 1c: SM uses simulation output to trigger `/otherness.learn` (🔲 → ✅)

---

## Zone 1 — Obligations

**O1 — SM phase includes a learn trigger check running every 10 SM cycles.**
`agents/phases/sm.md` must include a section (§4d-learn or appended to §4d) that
checks whether real Type B rate is dropping below the simulated floor. Runs at the
same cadence as §4d (every 10 SM cycles).

Behavior that violates this: the learn trigger check is absent from sm.md.

**O2 — The check compares real Type B rate from metrics.md against simulated floor.**
"Type B rate" proxy: the `needs_human` column from metrics.md last 3 rows.
The simulated floor is read from `scripts/sim-params.json` (or defaults to 0.1
if the file doesn't exist). If real rate < simulated floor for 3 consecutive batches:
trigger.

Behavior that violates this: the check only looks at 1 batch, not 3 consecutive.

**O3 — When triggered, SM schedules an automatic /otherness.learn cycle.**
The learn trigger creates a `feat/learn-<date>` branch (same pattern as the
existing COORD learn scheduling in §1e), posts a notice on REPORT_ISSUE, and
proceeds to run the learn protocol.

Behavior that violates this: the trigger fires but doesn't actually start a learn cycle.

**O4 — The trigger only fires if needs_human has been 0 for at least 3 batches.**
The learn trigger should not fire when the system is already escalating. If
needs_human > 0 in any of the last 3 batches, skip the learn trigger.

Behavior that violates this: learn trigger fires even when there are open escalations.

**O5 — Duplicate prevention: don't trigger if a learn branch already exists.**
Before creating `feat/learn-<date>`, check whether the branch already exists
(`git ls-remote --heads origin feat/learn-`). If yes: skip.

Behavior that violates this: multiple learn branches are created simultaneously.

---

## Zone 2 — Implementer's judgment

- How to detect "Type B rate": `needs_human` column is a reasonable proxy. A 0
  needs_human means no escalation (agents handled everything themselves).
  A sustained 0 may indicate low surprise/novelty (Type B deficit).
- The simulated floor: default 0.1 means roughly 1 escalation per 10 batches is
  "healthy". If real rate stays at 0 for 3+ batches AND sim floor is 0.1+: trigger.
- Placement in sm.md: extend §4d or add a new §4d-learn sub-section immediately
  after the calibration block.

---

## Zone 3 — Scoped out

- Measuring Type B rate directly from code (pure metrics.md proxy)
- Suppressing the trigger when autonomous_mode is false
- Configuring the trigger threshold via otherness-config.yaml (default only)
