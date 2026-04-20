# Spec: SM §4e / PM §5g — Simulation-behavior coupling gate

## Design reference
- **Design doc**: `docs/design/23-simulation-as-anchor.md`
- **Section**: `§ Future`
- **Implements**: SM §4e / PM §5g: simulation-behavior coupling gate — verify that simulation signals actually change agent behavior (🔲 → ✅)

---

## Zone 1 — Obligations (falsifiable)

**O1 — The gate checks whether high arch_convergence triggered a learn session.**
After each calibration (SM §4e-i), SM must read `arch_convergence_score` from
`sim-prediction.json`. If `arch_convergence_score >= 0.7` (AMBER threshold), SM
must check whether a `learn` branch or learn issue was opened in the last 10 batches.
If no learn evidence found: post `[⚠️ Simulation loop unclosed]` on REPORT_ISSUE.
Violation: arch_convergence AMBER with no learn evidence passes silently.

**O2 — The gate checks whether a completed learn session changed arch_convergence.**
If a learn session ran (PROVENANCE.md has a recent entry), SM must compare the
`arch_convergence_score` before and after the learn (read from the last 2 sm-prediction
entries on `_state`). If convergence did not decrease: post `[⚠️ Simulation loop unclosed
— learn ran but arch_convergence unchanged]`. Violation: learn ran but convergence unchanged,
no signal posted.

**O3 — The coupling gate runs at the same cadence as calibration.**
The check runs only when `(sm_cycle % calibration_cycles) == 0` and `sm_cycle > 0`.
It does not run on every SM cycle (would be noisy). Violation: gate runs every cycle.

**O4 — The gate is informational only — does not block work.**
The `[⚠️ Simulation loop unclosed]` comment is posted as a flag. It does not open
`[NEEDS HUMAN]` issues or block queue claiming. Violation: gate raises a needs-human.

**O5 — The gate logs its checks with a consistent prefix.**
All gate output uses `[SM §4e-coupling]` prefix so it is easily searchable.
Violation: output uses different prefix.

---

## Zone 2 — Implementer's judgment

- arch_convergence AMBER threshold: 0.7 (matching existing AMBER definition in sm.md)
- "No learn evidence": no feat/learn-* branch in last 7 days AND no open learn issue
  with "learn(arch)" in title
- How to compare before/after convergence: read the last 2 `sim-prediction.json` entries
  from the `_state` branch git log. If only 1 entry exists (first calibration): skip
  the before/after check.
- Whether to run on non-otherness projects: yes — simulation is available on managed
  projects too. Gracefully skip if sim-prediction.json absent on _state.

---

## Zone 3 — Scoped out

- Automatically triggering a learn session (the gate flags, does not act)
- Tracking arch_convergence history beyond the last 2 calibration runs
- Checking whether coord.md §1b actually read the recovery_action field (that is a
  separate spec concern)
