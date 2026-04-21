# Spec: Queue guard enrichment effectiveness tracking

## Design reference
- **Design doc**: `docs/design/21-session-throughput.md`
- **Section**: `§ Future`
- **Implements**: Queue guard firing frequency tracked and acted on: `coord.md §1c` queue refusal guard fires when all queue items are chores (🔲 → ✅)

---

## Zone 1 — Obligations (falsifiable)

**O1 — SM §4b records `guard_enrichment_produced` per session in metrics.md.**
When SM §4b runs, it must check whether `chore_only_guard_count > 0` (guard fired this
session) and if so, count how many new issues were created as a result (by checking
the guard's output in state.json or comparing issue counts). This count must be written
to `metrics.md` as a new `guard_enrichment_produced` column.
Violation: metrics.md does not contain a `guard_enrichment_produced` column.

**O2 — SM §4b opens a bug issue when guard fires but produces no items for 3 consecutive sessions.**
If the last 3 rows of `metrics.md` all show `queue_guard_fires > 0` AND
`guard_enrichment_produced == 0`, SM must open a deduplicated `kind/bug priority/high`
issue: "[BUG] Queue guard fires but enrichment produces 0 items — vision synthesis fallback may be broken."
Violation: 3 consecutive fire-no-enrich sessions without a bug issue being opened.

**O3 — The check is fail-open.**
If `metrics.md` is unreadable, the column is absent in older rows, or the API call
to count new issues fails: SM logs a warning and continues. The bug detection is
informational — it must never block queue claiming.
Violation: SM crashes or blocks when metrics.md is malformed.

**O4 — `guard_enrichment_produced` defaults to 0 in `metrics.md` when guard did not fire.**
Sessions where `queue_guard_fires == 0` should write `0` for `guard_enrichment_produced`
(not blank, not missing) so the column is consistently populated.
Violation: blank entries in `guard_enrichment_produced` column.

---

## Zone 2 — Implementer's judgment

- How to count enrichment produced: read `chore_only_guard_count` from state.json at
  SM §4b start. If >0: compare issues opened in last 24h matching "queue refusal guard"
  or "enriched" patterns. Fall back to `chore_only_guard_count > 0 → guard_enrichment_produced=?`
  if issue API fails (fail-open).
- Where in metrics.md: add column after `queue_guard_fires` (existing column added in PR #638).
- The `guard_enrichment_produced` column header must be added to `docs/aide/metrics.md`
  alongside `queue_guard_fires`.

---

## Zone 3 — Scoped out

- Tracking whether the enriched items were eventually claimed (separate concern)
- Retroactively populating `guard_enrichment_produced` for historical rows
- Changing the guard logic itself (this spec is observability only)
