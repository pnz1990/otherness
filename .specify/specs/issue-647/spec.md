# Spec: Simulation calibration staleness visible in health signal

**Issue**: #647

## Design reference

- **Design doc**: `docs/design/23-simulation-as-anchor.md`
- **Section**: `§ Future`
- **Implements**: Simulation calibration staleness visible in health signal (🔲 → ✅)

---

## Intent

`sim-prediction.json` stores a `calibrated_at` timestamp but this is never surfaced to
the human. SM §4f health comment must include "Sim calibrated: N days ago" and downgrade
to AMBER if calibration is >14 days old. A prediction based on 14-day-old data may be
systematically wrong — the human should know when the anchor is stale.

---

## Zone 1 — Obligations (must ALL be satisfied for QA to approve)

**O1** — SM §4f reads `calibrated_at` from `_state:sim-prediction.json`. Computes age in
days. Appends to health comment as "Sim calibrated: N days ago" (or "never" if absent).

**O2** — If `calibrated_at` age > 14 days, HEALTH is set to AMBER and a warning suffix
"⚠️ Sim anchor stale (Nd)" is appended to the health comment.

**O3** — If `sim-prediction.json` is absent from `_state`, health is not downgraded (fail-open).
Comment shows "Sim calibrated: unknown".

**O4** — Implementation is in SM §4f (the health signal section), before the `gh issue comment`
line that posts the batch health comment.

**O5** — Design doc `docs/design/23-simulation-as-anchor.md` has this item flipped from 🔲 to ✅.

---

## Tasks

- [CMD] Read `_state:sim-prediction.json` for `calibrated_at` field
- [AI] Compute age in days from `calibrated_at` to now
- [AI] Add bash variable `SIM_CALIB_LABEL` with human-readable "N days ago" or "unknown"
- [AI] Set HEALTH=AMBER if age > 14 days
- [AI] Add `SIM_CALIB_LABEL` to the `gh issue comment` body line in §4f
- [CMD] Flip design doc item 🔲 → ✅
- [CMD] Run validate.sh + lint.sh to verify

---

## Non-scope

- Not changing calibration frequency (§4d/§4e)
- Not adding new state fields beyond what `sim-prediction.json` already provides
- Not modifying the COORD phase
