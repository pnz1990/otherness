# Spec: Hygiene scan block in sm.md (issue-441)

## Design reference
- **Design doc**: `docs/design/29-continuous-code-hygiene.md`
- **Section**: `§ Future`
- **Implements**: `agents/phases/sm.md §4h` (implemented as §4g): add hygiene scan block — executable, not [AI-STEP] (🔲 → ✅)

## Context

The hygiene scan was already implemented in `sm.md §4g` as fully executable Python code
(not [AI-STEP]). The design doc listed it as §4h Future but the implementation already
exists with the right properties. This item updates the design doc to match reality.

---

## Zone 1 — Obligations

**O1 — Design doc 29 updated: hygiene scan block moved from 🔲 Future to ✅ Present.**
The implementation reference is corrected to §4g (the actual section name in sm.md).

**O2 — N/A — no agent code changes required.**
The hygiene scan is already fully implemented.

---

## Zone 2 — Implementer's judgment
- N/A

## Zone 3 — Scoped out
- Remaining Future items in design doc 29
