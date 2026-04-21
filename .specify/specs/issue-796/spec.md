# Spec: Session minimum meaningful-PR contract (levels 2 and 3)

**Item**: issue-796  
**Branch**: feat/issue-796  
**Date**: 2026-04-21

## Design reference
- **Design doc**: `docs/design/35-quality-of-output-gaps.md`
- **Section**: `§ Future`
- **Implements**: Session minimum meaningful-PR contract (🔲 → ✅)

---

## Zone 1 — Obligations (falsifiable)

**O1 — When level-1 recovery was attempted but ITEMS_COMPLETED still 0, level-2 fires once.**  
Level 2: inline queue-gen creates a vision item and claims it.  
Violation: level-2 never fires after level-1 recovery fails.

**O2 — Level-2 only fires once per session (`CONTRACT_L2_ATTEMPTED` guard).**  
Violation: level-2 fires multiple times in one session.

**O3 — When all recovery levels are exhausted and ITEMS_COMPLETED still 0, level-3 fires once and posts an in-session `[DEFECT]` comment on REPORT_ISSUE.**  
Violation: session exits with 0 PRs without posting an in-session DEFECT comment.

**O4 — Level-3 only fires once per session (`CONTRACT_L3_POSTED` guard).**  
Violation: multiple DEFECT comments posted in one session.

**O5 — All levels are fail-open.**  
Violation: any level failure prevents the session from reaching SM/PM.

---

## Zone 2 — Implementer's judgment

- Level-2 implementation: re-uses the same design doc scan logic as §1f-recovery.
- Level-3 comment format: `[DEFECT | in-session | ...]` to distinguish from SM §4b detection.
- Whether to block SM/PM when level-3 fires (no — SM must still run).

---

## Zone 3 — Scoped out

- Level-2 ENG implementation (that is Phase 2's job — this only claims the item).
- Tracking `recovery_level_reached` in state.json (separate item: issue 796-tracking).
- Removing SM §4b DEFECT detection (it stays as the post-session fallback).
