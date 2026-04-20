# Spec: feat(sm): fleet defaults — write sim-defaults.json, ship via self-update

## Design reference
- **Design doc**: `docs/design/23-simulation-as-anchor.md`
- **Section**: `§ Per-project calibration and fleet defaults`
- **Implements**: `~/.otherness/scripts/sim-defaults.json` — fleet defaults written by otherness SM, shipped to managed projects via self-update (🔲 → ✅)

---

## Zone 1 — Obligations

**O1** — After each successful calibration run in SM §4d, if the current repo is the
otherness repo (detected by matching `repo` field from `otherness-config.yaml` against
a pattern containing `otherness`), copy `scripts/sim-params.json` to
`scripts/sim-defaults.json` in the same directory and commit+push to main.

Violation: sim-defaults.json written on managed projects (not just otherness repo).

**O2** — The write uses the pull-rebase-retry pattern (same as metrics.md updates) to
ensure parallel session safety.

Violation: direct push without pull-rebase retry.

**O3** — The sim-defaults.json file is a copy of sim-params.json with an added
`fleet_calibrated_at` field and `source: "otherness"`.

Violation: sim-defaults.json missing the fleet metadata fields.

**O4** — If the repo is not the otherness repo, or if calibration failed, the step is
silently skipped. No error output.

Violation: error or [NEEDS HUMAN] when skipping on managed project.

---

## Zone 2 — Implementer's judgment

- How to detect "this is the otherness repo": check if `REPO` env var ends with `/otherness`
  OR if `otherness-config.yaml` has `name: otherness`. The REPO check is simpler.
- Whether to create a PR for sim-defaults.json or push directly to main: direct push
  with pull-rebase-retry (same pattern as metrics.md) is appropriate for this data file.
- Whether to update `~/.otherness/scripts/sim-defaults.json` directly or ship via the
  normal git pull self-update: ship via git commit+push to the otherness repo; managed
  projects pick it up on their next `git -C ~/.otherness pull` (startup self-update).

---

## Zone 3 — Scoped out

- Managed projects reading sim-defaults.json at startup — that is a separate future item
- The calibration_cycles config field — separate issue, not this PR
- Cross-project comparison of calibration params — out of scope
