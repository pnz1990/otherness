# Spec: Managed project adoption — fleet simulation defaults inheritance

## Design reference
- **Design doc**: `docs/design/23-simulation-as-anchor.md`
- **Section**: `§ Per-project calibration and fleet defaults` + `§ Future`
- **Implements**: Managed project adoption: kardinal-promoter and kro-ui SM inherit otherness defaults, re-calibrate after ≥5 batches (🔲 → ✅)

---

## Zone 1 — Obligations

**O1 — Fleet defaults are available as starting parameters.**
When a managed project's SM §4e-i runs and `scripts/calibrate.py` is absent but
`~/.otherness/scripts/sim-defaults.json` exists, SM MUST read that file and write its
contents as `sim-prediction.json` to the `_state` branch with `source: "fleet-defaults"`.
Violation: managed project has no `sim-prediction.json` after first SM cycle.

**O2 — ≥5 local batches triggers local calibration preference.**
When a managed project has ≥5 rows in `docs/aide/metrics.md` AND `scripts/calibrate.py`
exists, SM MUST use local metrics for calibration (not fleet defaults).
Violation: local calibration runs with <5 batches, or is skipped with ≥5 batches.

**O3 — otherness-config-template.yaml includes simulation section.**
The template file MUST contain a `simulation:` section with `calibration_cycles: 5`
so new projects onboarded with the template inherit the correct default.
Violation: template is missing simulation section after this PR.

**O4 — Design doc 23 is updated.**
The 🔲 Future item for managed project adoption MUST be moved to ✅ Present in
`docs/design/23-simulation-as-anchor.md`.
Violation: 🔲 marker still present after PR merge.

**O5 — Fleet defaults inheritance does not violate Zone 3 (O3 of design doc).**
Managed projects MUST NOT overwrite `~/.otherness/scripts/sim-defaults.json`.
Only the otherness SM §4d writes that file (IS_OTHERNESS gate already in place).
Violation: non-otherness repo writes to `~/.otherness/scripts/sim-defaults.json`.

---

## Zone 2 — Implementer's judgment

- Where to add the fallback path: SM §4e-i, after the calibrate.py existence check fails.
- Fields to copy from fleet defaults to sim-prediction.json: all standard fields
  (prs_next_batch_floor derived from params, arch_convergence_score, skill_growth_rate)
  or a simplified passthrough of fleet defaults with source="fleet-defaults".
- Whether to add simulation section to managed projects' configs directly:
  only the otherness-config-template.yaml needs updating here (managed projects
  update their own configs; this is out of scope for the otherness repo).

---

## Zone 3 — Scoped out

- Modifying kardinal-promoter or kro-ui repo files directly (those are separate repos; this PR works on the otherness agent infrastructure)
- Adding `scripts/calibrate.py` to managed projects (they use fleet defaults path)
- Fleet default computation frequency changes (SM §4d already handles this)
- Simulation parameter validation or bounds checking
