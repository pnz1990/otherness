# Spec: docs/aide/progress.md automated update (SM §4f)

## Design reference
- **Design doc**: `docs/design/35-quality-of-output-gaps.md`
- **Section**: `§ Future`
- **Implements**: SM §4f must update progress.md after every batch with last 3 batch outcomes (🔲 → ✅)

---

## Zone 1 — Obligations (falsifiable)

**O1 — SM §4f includes "Last 3 batch outcomes" in progress.md header.**
The dynamic header written to progress.md by SM §4f must include a "Last 3 batch outcomes"
field populated from the last 3 rows of docs/aide/metrics.md (date + outcome column).
Violation: field absent from the generated header.

**O2 — Batch outcomes read from metrics.md outcome column.**
The outcomes must come from the `session_outcome` column (column 10, index 9) of
docs/aide/metrics.md. Graceful fallback if file is absent or has no rows.
Violation: outcomes hardcoded or taken from wrong source.

---

## Zone 2 — Implementer's judgment
- Column index: cells[9] (0-indexed after splitting on '|')
- Graceful fallback: '(no batch data yet)' if metrics.md absent or empty

## Zone 3 — Scoped out
- Showing outcomes in a table format (inline string is sufficient)
