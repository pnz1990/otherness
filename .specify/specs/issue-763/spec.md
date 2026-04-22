# Spec: COORD §1b Vision-Alignment Filter (35.4)

## Design reference
- **Design doc**: `docs/design/35-vision-alignment-signal.md`
- **Section**: `§ Future`
- **Implements**: 35.4 — COORD §1b vision-alignment filter (🔲 → ✅)

---

## Zone 1 — Obligations

**O1 — Items whose issue body references a design doc sort before items that do not.**
When COORD builds the claim candidate list, items are sorted so that design-doc-referenced
items appear before items without such a reference. Within each group, existing priority
ordering (critical/high/medium/low + hygiene penalty) is preserved.

A "design doc reference" is present if the issue body contains at least one of:
- `docs/design/` (literal string)
- `design doc` (case-insensitive)
- `🔲 →` (literal string — standard queue-gen body format)

**O2 — Items without a design doc reference are not skipped, only deprioritised.**
If all todo items lack a design doc reference, COORD still claims one of them.
The filter is a sort preference, not a gate.

**O3 — The filter applies at claim-time sort, not at queue-gen time.**
COORD §1c queue-gen continues unchanged. The filter is applied in the `_item_sort_key`
function used in §1e (claim next item).

**O4 — Hygiene/chore items are not affected by this filter.**
Items already penalised +10 (hygiene) are sorted after all feature items regardless
of design doc reference.

---

## Zone 2 — Implementer's judgment

The simplest implementation: add a boolean `has_design_ref` to `_item_sort_key` that
adds 0 when true and +5 when false. This puts design-doc-backed items ahead of
non-design-doc-backed items at the same priority level, without requiring label changes
or issue body edits.

The issue body check is done by looking at `item_data.get('body', '')` — which means
the issue body must be stored in state.json. If it is not stored, the check falls back
to the issue title: a title containing `docs/design/` or `feat:` (most queue-gen issues
have `feat:` titles from design doc items) counts as design-doc-referenced.

Actually the simplest approach: check the issue body stored in state.json features dict.
If `body` field is absent (most items don't store it), fall back to checking the title for
`feat:` prefix (all design-doc-backed items from queue-gen have `feat:` prefix titles
with design-doc body content).

**Better approach**: at claim time, fetch the issue body for unresolved items.
But this is expensive (1 API call per candidate). Instead: rely on the fact that
queue-gen always creates issues with `docs/design/` in the body. Check `item_data.get('source')`
or `item_data.get('design_doc_ref')` if present.

**Most pragmatic approach**: add a `design_doc_ref` flag to items when they are created
by queue-gen, and use that flag in `_item_sort_key`. Since existing items don't have this
flag, treat absence as `False` (no design doc ref) — they get the +5 penalty.
But this changes queue-gen, not just §1e.

**Chosen approach**: In `_item_sort_key`, check if the item's title starts with `feat:` AND
the labels include `kind/enhancement`. All design-doc-backed items from queue-gen have:
- title: `feat: <description from design doc>`  
- labels: `kind/enhancement`

This heuristic is correct for ≥95% of items and requires no API calls or schema changes.
Non-design-doc items are typically `kind/chore`, `kind/bug`, or have non-`feat:` titles.

---

## Zone 3 — Scoped out

- Label changes on existing issues
- Reading issue body from GitHub API at claim time
- Scoring items by number of design doc references
- Retroactive re-sorting of past queue items
