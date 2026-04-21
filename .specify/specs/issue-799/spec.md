# Spec: Stuck-item detection and abandonment

**Item**: issue-799  
**Branch**: feat/issue-799  
**Date**: 2026-04-21

## Design reference
- **Design doc**: `docs/design/21-session-throughput.md`
- **Section**: `§ Future`
- **Implements**: Stuck-item detection and abandonment (🔲 → ✅)

---

## Zone 1 — Obligations (falsifiable)

**O1 — SM §4b increments `state.json.features[ITEM_ID].failed_attempts` when `VISION_PRS==0` and a closed-unmerged PR exists for that item.**  
Violation: `failed_attempts` not incremented after a session with a failed PR for an item.

**O2 — When `failed_attempts == 3`, the issue is labelled `blocked` on GitHub and a deprioritisation comment is posted.**  
Violation: item reaches 3 failed sessions without being labelled `blocked`.

**O3 — COORD §1e skips items with `'blocked' in labels` or `failed_attempts >= 3`.**  
Violation: a blocked item is claimed in §1e.

**O4 — SM §4b stuck-item detection is fail-open.**  
Violation: stuck-item check error prevents SM §4b from completing.

---

## Zone 2 — Implementer's judgment

- Detection trigger: `VISION_PRS==0` AND a closed-unmerged PR search by issue number. This may produce false positives (closed PRs from other reasons) — acceptable for a fail-soft mechanism.
- Only fires when `ITEM_ID` env var is set (non-empty) — skips when running standalone.
- Whether to also decrement `failed_attempts` on successful merge (not in scope — reset is handled by state cleanup).

---

## Zone 3 — Scoped out

- Automatic diagnosis of why the item failed (human review required).
- Automatic priority downgrade to `priority/low` (the `blocked` label is sufficient signal).
- Clearing `failed_attempts` when the item is manually unblocked (state reset by human).
