# Spec: SM §4b — session_items_completed tracking and single-item-mode flag

**Item**: issue-714
**Design doc**: `docs/design/21-session-throughput.md`
**Section**: `§ Future` (🔲 → ✅)

## Design reference

- **Design doc**: `docs/design/21-session-throughput.md`
- **Section**: `§ Future`
- **Implements**: "Multi-item loop execution verified in SM health signal" (🔲 → ✅)

---

## Zone 1 — Obligations (falsifiable)

**O1**: SM §4b appends a `session_items_completed` column to every new row it writes in `docs/aide/metrics.md`. The value is an integer count of items completed this session, sourced from the `ITEMS_COMPLETED` env var (set by the loop gate in `standalone.md §1f`). If `ITEMS_COMPLETED` is unset or empty, the value written is `1` (single-item default, not `0` or `?`).

**O2**: `docs/aide/metrics.md` header table gains one new column: `session_items_completed` with definition "Items completed in this session before SM/PM gate fired; ≥1 per session". This column appears after `meaningful_prs` and before `Notes`.

**O3**: After appending the new row, SM §4b checks the last 3 rows of `metrics.md`. If all 3 most recent `session_items_completed` values equal `1`, SM opens a `kind/bug priority/high` issue titled `[SINGLE-ITEM-MODE] Multi-item loop may not be executing — 3 consecutive sessions completed exactly 1 item`. This issue is deduplicated (not opened if one already exists). It is a soft signal, not a `[NEEDS HUMAN]` block.

**O4**: The regression check (O3) is fail-open: if `metrics.md` is unreadable, fewer than 3 rows exist, or parsing fails, the check is skipped silently and no issue is opened.

**O5**: Existing rows in `metrics.md` are never modified. New rows have the `session_items_completed` column appended; historical rows are left as-is. The column appears only in new rows.

**O6**: The Metric Definitions table in `metrics.md` gains an entry for `session_items_completed`: "Number of items (PRs) completed in this session before SM/PM gate fired; target ≥3 for healthy multi-item sessions" with target direction ↑.

---

## Zone 2 — Implementer's judgment

- Where in the `metrics.md` row to place the new column: after `meaningful_prs`, before `Notes`.
- Whether to update the header row in the Batch Log table: yes, add the column to match O2 + O5.
- The exact column name in the header: `session_items_completed`.
- The regression check window: last 3 rows (not last N days), as sessions may be sparse.

---

## Zone 3 — Scoped out

- Changes to `standalone.md` (CRITICAL tier — not in scope).
- Autonomous `session_item_limit` tuning (separate design doc 21 future item).
- Housekeeping-streak auto-escalation (separate future item).
- Retroactively backfilling historical `metrics.md` rows.
