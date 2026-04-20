# Spec: PDCA runs daily (not weekly) — design doc correction

## Design reference
- **Design doc**: `docs/design/25-anchor-kardinal-promoter.md`
- **Section**: `§ Future`
- **Implements**: PDCA runs daily (not weekly) — change cron to `0 2 * * *` (🔲 → ✅)

---

## Zone 1 — Obligations

**O1 — Design doc 25 reflects current state accurately.**
The design doc MUST NOT describe PDCA as "weekly" since it already runs daily (`0 2 * * *`).
Lines describing weekly cadence must be updated to daily.
Violation: design doc still says "weekly" after this PR.

**O2 — 🔲 Future item promoted to ✅ Present.**
The item "PDCA runs daily (not weekly)" must move from Future to Present with (PR #N, date).
Violation: 🔲 marker still present after merge.

**O3 — N/A for runtime implementation.**
No code change is needed — the PDCA workflow in kardinal-promoter already has `cron: '0 2 * * *'`.
This is a documentation-only PR correcting a stale design doc.

---

## Zone 2 — Implementer's judgment

- Update line 29 (anchor workflow description) from "weekly (Sundays 04:00 UTC)" to "daily (02:00 UTC)"
- Update line 205 (✅ Present entry) from "weekly execution" to "daily execution (0 2 * * *)"
- Move 🔲 item to ✅ Present

---

## Zone 3 — Scoped out

- Changing the actual PDCA cron schedule (already done in kardinal-promoter)
- Adding PDCA to PR trigger (separate issue 188 scope)
