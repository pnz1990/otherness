# Spec: Session type declared at session START in COORD §1b

**Item**: issue-775  
**Branch**: feat/issue-775  
**Date**: 2026-04-21

## Design reference
- **Design doc**: `docs/design/35-quality-of-output-gaps.md`
- **Section**: `§ Future`
- **Implements**: Session type must be declared at session START (🔲 → ✅)

---

## Zone 1 — Obligations (falsifiable)

**O1 — COORD inspects the top 3 queue items before any claim and writes `session_type_declared` to `state.json`.**  
Violation: a session starts without `session_type_declared` in `state.json`.

**O2 — `session_type_declared` is one of: `feature-rich`, `mixed`, `chore-only`, `unknown`.**  
Violation: any other value written to `state.json.session_type_declared`.

**O3 — When `session_type_declared=chore-only`, `QUEUE_NEEDS_ENRICHMENT=true` is set before §1c.**  
Violation: a chore-only queue declaration does not trigger the enrichment guard.

**O4 — The session type declaration is fail-open.**  
Violation: an error in the declaration block prevents COORD from proceeding.

---

## Zone 2 — Implementer's judgment

- Whether to count the current session's in-flight items as features or chores (current: look at `state=todo` unclaimed items only).
- Exact threshold for `feature-rich` vs `mixed` (current: all 3 of top-3 are features = feature-rich, any mix = mixed).
- Whether items with no labels are treated as features or chores (current: treated as features — conservative, avoids false chore-only declarations).

---

## Zone 3 — Scoped out

- The enrichment guard itself (that lives in §1c — this item only sets the flag).
- Persisting `session_type_declared` to metrics.md (state.json is sufficient per design doc).
- The actual claim decision being gated by declared type (§1e continues to use existing priority ordering).
