# Spec: issue-638 — coord.md §1c guard-firing frequency in session metrics

## Design reference
- **Design doc**: `docs/design/35-quality-of-output-gaps.md`
- **Section**: `§ Future`
- **Implements**: `coord.md §1c`: track guard-firing frequency in session metrics (🔲 → ✅)

---

## Zone 1 — Obligations

**O1** — `coord.md §1c-guard` increments a `chore_only_guard_count` counter in `state.json` each time the guard detects a chore-only queue. The counter is an integer, default 0 if absent. The increment is atomic (read-modify-write on the local state.json file).

**O2** — `sm.md §4b` reads `chore_only_guard_count` from `state.json` when writing the batch metrics row to `docs/aide/metrics.md`. The value is written as a column `queue_guard_fires` in the metrics row and then reset to 0 in state.json.

**O3** — `docs/aide/metrics.md` header row gains the `queue_guard_fires` column between `todo_shipped` and `time_to_merge_avg_min`. Existing rows are unchanged (they have no value for this column — backward compatible).

**O4** — The change tier is CRITICAL-A (modifies executable instructions in `phases/coord.md` and `phases/sm.md`). The PR must be labeled `needs-human` and post `[NEEDS HUMAN: critical-tier-change]`. In `AUTONOMOUS_MODE=true`, a 5-check self-review is run before merge.

**O5** — `scripts/validate.sh` and `scripts/lint.sh` pass with the changes applied.

---

## Zone 2 — Implementer's judgment

- Counter increment goes in the GUARD_EOF python block, after the `injected > 0` log line.
- SM §4b reads the counter at the start of the batch row write, uses 0 as default if absent.
- The column is inserted at the end of the SM §4b row (after existing columns) to minimize disruption to existing row parsing.

---

## Zone 3 — Scoped out

- Alerting when guard fires too frequently
- Per-item-type breakdown of guard enrichment
- Historical analysis of guard-firing trends
