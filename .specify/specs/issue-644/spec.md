# Spec: issue-644 — meaningful_prs metric (design doc 21)

## Design reference
- **Design doc**: `docs/design/21-session-throughput.md`
- **Section**: `§ Future`
- **Implements**: Meaningful-work rate tracked as a first-class metric (🔲 → ✅)

---

## Zone 1 — Obligations

**O1** — `docs/aide/metrics.md` gains a `meaningful_prs` column in the metric definitions table and in the batch log header row.

**O2** — `SM §4b` computes `MEANINGFUL_PRS`: count of merged PRs (last 24h, non-excluded) where title or body (first 500 chars) contains `docs/design/`, `🔲 →`, or `design doc` (case-insensitive). This is the same criterion as VISION_PR_COUNT (§35.1). Where VISION_PR_COUNT drives AMBER, MEANINGFUL_PRS is the persistent metric.

**O3** — `MEANINGFUL_PRS` is written to `metrics.md` as the last column in the current batch row.

**O4** — Historical rows without `meaningful_prs` are not modified.

**O5** — scripts/validate.sh PASSED, scripts/lint.sh PASSED.

---

## Zone 2 — Implementer's judgment

- `MEANINGFUL_PRS` reuses the same scan logic as `VISION_PR_COUNT` from §4f. SM §4b runs before §4f, so §4b must compute it independently (can duplicate the logic or refactor — duplication is simpler for this minimal implementation).
- Column position: after `queue_guard_fires` (last existing column) → `meaningful_prs` appended.
- PM §5 stagnation check (2-consecutive-batch AMBER) is a separate item — not in this PR.

---

## Zone 3 — Scoped out

- PM §5 AMBER on consecutive `meaningful_prs=0` batches
- Retroactive calculation on historical rows
- `session_items_completed` column (separate issue)
