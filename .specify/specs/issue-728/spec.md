# Spec: issue-728 — SM §4f design doc integrity spot-check (41.1)

## Design reference
- **Design doc**: `docs/design/41-design-doc-integrity.md`
- **Section**: `§ Future`
- **Implements**: 41.1 — SM §4f design doc integrity spot-check (🔲 → ✅)

---

## Zone 1 — Obligations

**O1 — Runs every 5 SM batches (modulo gate).**
SM §4f includes a design doc integrity spot-check block that runs when
`batch_count % 5 == 0` (or `batch_count` is unset). It reads this value from
`state.json`.

**O2 — Checks every ✅ Present item that names a state.json field.**
For each design doc in `docs/design/*.md`, find `✅ Present` items matching the
pattern: references to `state.json` field (e.g. "write `foo` to state.json" or
"state.json`: add `foo` field" or "`state.json.foo`"). Extract the field name(s).

**O3 — Compares against actual state.json content.**
For each extracted field name, check whether the key exists in `state.json` (from
the `_state` branch). If the key is absent: log `[DOC-DRIFT] ✅ Present item claims
state.json.<field> exists — not found`.

**O4 — After 3 spot-checks with the same drift: open a kind/bug priority/high issue.**
Track drift counts in `state.json` under `doc_drift_counts` (dict: field → count).
When count reaches 3: open issue "Design doc integrity: ✅ Present item not reflected
in state.json — possible implementation drift." Deduplicate: check for open issue
before creating. Reset count to 0 after opening.

**O5 — The check is non-blocking.**
Drift findings are informational. The SM loop continues regardless.

**O6 — Log format: `[SM §4f-integrity]` prefix for all output.**

---

## Zone 2 — Implementer's judgment

- Field name extraction: use regex to find `state.json` field references.
  Patterns: `` `state.json.foo` ``, `state.json` add `foo`, write `foo` to state.json.
- `state.json` access: read from `_state` branch via `git show origin/_state:.otherness/state.json`.
- Where in SM §4f to add: append as a new sub-section after the existing §4f block.
  Keep it short — this is a guard, not a rewrite.

---

## Zone 3 — Scoped out

- Full-sweep audit of all ✅ Present items (item 41.5)
- ENG phase gate verification step (item 41.4)
- Metrics schema conformance (item 41.2)
