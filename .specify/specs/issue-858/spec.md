# Spec: issue-858 — Configurable pressure_max_age_days (37.12)

## Design reference
- **Design doc**: `docs/design/37-self-updating-pressure-prompts.md`
- **Section**: `§ Future`
- **Implements**: 37.12 — Pressure context maximum age contract (🔲 → ✅)

---

## Zone 1 — Obligations

**O1 — `otherness-config.yaml` must accept `vision.pressure_max_age_days`**
The `otherness-config.yaml` schema must support a `vision:` section with a
`pressure_max_age_days:` field (integer, default: 14). This field controls the
maximum number of days a pressure context may remain unchanged before SCAN 5
treats it as a mandatory rewrite trigger — regardless of addressed ratio.

**O2 — SCAN 5 must read `vision.pressure_max_age_days` from config**
`vibe-vision-auto.md` SCAN 5 §42.4 must read this field from `otherness-config.yaml`.
If the field is absent or unreadable: use default 14. If the field is present: use
its value as `PRESSURE_STALE_DAYS` (replacing the hardcoded 30).

**O3 — The trigger is mandatory, not optional**
When `pressure_age_days > PRESSURE_STALE_DAYS` (where PRESSURE_STALE_DAYS = value
from config, default 14), SCAN 5 MUST add a rewrite reminder regardless of addressed
ratio. The current code checks `ratio < STALENESS_THRESHOLD` before firing — this
condition must be removed from the max-age path. The time-based trigger is
independent of (not subordinate to) the ratio trigger.

**O4 — `otherness-config-template.yaml` must document the new field**
The template must include `vision.pressure_max_age_days: 14` with a comment
explaining it.

---

## Zone 2 — Implementer's judgment

- Default 14 days (two weeks) as specified in the design doc.
- The existing `PRESSURE_STALE_DAYS = 30` constant is replaced by config-read value.
- The duplicate-item guard (checking if the rewrite item already exists) still applies.

---

## Zone 3 — Scoped out

- Backfilling pressure rewrite history
- Retroactive application to projects without the config field
- Changing the ratio-based trigger (STALENESS_THRESHOLD stays at 0.60)
