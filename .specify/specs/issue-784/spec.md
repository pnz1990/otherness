# Spec: Housekeeping-streak auto-escalation in SM §4b

**Item**: issue-784  
**Branch**: feat/issue-784  
**Date**: 2026-04-21

## Design reference
- **Design doc**: `docs/design/21-session-throughput.md`
- **Section**: `§ Future`
- **Implements**: Housekeeping-streak auto-escalation (🔲 → ✅)

---

## Zone 1 — Obligations (falsifiable)

**O1 — SM §4b increments `housekeeping_streak` in `state.json` when `session_outcome == chore-only`.**  
Violation: `state.json.housekeeping_streak` does not increase after a chore-only session.

**O2 — SM §4b resets `housekeeping_streak` to 0 when `session_outcome != chore-only`.**  
Violation: streak does not reset after a feature-rich session.

**O3 — When streak reaches 3, SM §4b opens a `kind/bug priority/high` issue.**  
Issue title must contain "HOUSEKEEPING-STREAK".  
Violation: no such issue is opened after 3 consecutive chore-only sessions.

**O4 — The streak issue is deduplicated (one open issue per streak event).**  
Violation: multiple "HOUSEKEEPING-STREAK" issues are opened in the same streak.

**O5 — `housekeeping_streak` is written to `state.json` so COORD §1b can detect it.**  
Violation: `housekeeping_streak` is not present in `state.json` after a chore-only session.

**O6 — The escalation is fail-open (errors do not block SM §4b from completing).**  
Violation: an API error or JSON parse error halts SM §4b processing.

---

## Zone 2 — Implementer's judgment

- Whether to post a REPORT_ISSUE comment on every streak increment (only at streak=3 is required).
- Exact body text of the streak issue beyond what's required by O3.
- Whether to decrement the streak when mixed sessions occur vs. resetting to 0 (reset is simpler).

---

## Zone 3 — Scoped out

- COORD §1b acting on `housekeeping_streak` (that is a separate item, session pre-flight checks).
- Automatic vision synthesis triggered by COORD reading the streak value (out of scope here).
- Persisting streak to metrics.md (state.json is sufficient per design doc).
