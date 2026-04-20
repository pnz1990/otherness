# Spec: feat(coord): §1b hygiene routing — prioritize features over hygiene items

## Design reference
- **Design doc**: `docs/design/29-continuous-code-hygiene.md`
- **Section**: `§ Future`
- **Implements**: `agents/phases/coord.md §1e`: route hygiene items with lower priority than features (🔲 → ✅)

---

## Zone 1 — Obligations (falsifiable)

**O1 — COORD §1e claims feature items (`kind/enhancement`, `kind/bug`) before hygiene items (`kind/chore`, labeled `hygiene`).**
Violation: A hygiene item is claimed when a feature item with `kind/enhancement` or `kind/bug` is available in the queue.

**O2 — The priority ordering is: critical > high > medium > low for all items, with hygiene items deprioritized below non-hygiene items of the same priority level.**
Violation: A lower-priority feature item is passed over in favor of a same-priority hygiene item.

**O3 — The change is implemented as a sort key on the candidates list, not as a filter that drops items.**
Violation: Hygiene items are excluded from claiming entirely instead of being deprioritized.

**O4 — `scripts/validate.sh` passes.**
Violation: validate.sh exits non-zero.

**O5 — `scripts/lint.sh` passes.**
Violation: lint.sh exits non-zero.

---

## Zone 2 — Implementer's judgment

- How to detect "hygiene" items: check if `kind/chore` label is in the item's `labels` field in state, OR if `chore` appears in the title, OR if the state has no `priority` (unlabeled). Primary signal: title contains `hygiene:` prefix.
- The sort key should extend the existing PRIORITY_ORDER dict concept: add a secondary key that deprioritizes `kind/chore` items.
- The existing `features.items()` loop should be converted to a sorted candidates list (similar to what my session already implemented in the standalone loop, but this changes the phase instruction for all sessions).

---

## Zone 3 — Scoped out

- Reading GitHub issue labels at claim time (too slow — use state.json title/labels fields only)
- Separate queues for hygiene vs features (over-engineering)
- CI/CD enforcement that hygiene items cannot be claimed before features (validation script change)
