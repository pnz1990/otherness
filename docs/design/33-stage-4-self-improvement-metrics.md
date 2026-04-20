# 33: Stage 4 — Self-Improvement Metrics

> Status: Complete | Created: 2026-04-20

---

## What this does

Generates quantitative evidence of the system's own improvement over time. The SM
phase updates metrics after every batch. PM validates metrics for stagnation and
opens proactive improvement issues.

---

## Present (✅)

- ✅ `docs/aide/metrics.md` — batch log with 6 tracked metrics: prs_merged, needs_human, ci_red_hours, skills_count, todo_shipped, time_to_merge_avg_min (2026-04-14)
- ✅ SM §4b: metrics update every batch — appends new row, regression detection (2-batch regression opens issue) (2026-04-14)
- ✅ PM §5 stagnation check — checks last 2 batches for `todo_shipped=0` (velocity stall) and `needs_human>0` (escalation spike) (2026-04-14)
- ✅ Regression detection: SM auto-opens `kind/chore` issue when `needs_human` or `todo_shipped` regresses for 2 consecutive batches (2026-04-14)
- ✅ SM §4e calibration: reads `metrics.md` to calibrate simulation parameters (PR #421, 2026-04-20) ⚠️ Stale — referenced file not found

## Future (🔲)

*(Stage 4 is complete. All deliverables shipped.)*

---

## Zone 1 — Obligations

**O1 — `docs/aide/metrics.md` is updated every batch without human intervention.**
SM §4b appends a row on every Phase 4 execution.

**O2 — Regression detection is automatic.**
When `needs_human` or `todo_shipped` regresses for 2 consecutive batches, SM opens
a `kind/chore` issue with the specific metrics.

**O3 — Metrics are used for simulation calibration.**
SM §4e reads `metrics.md` every 5 cycles and updates `sim-params.json`.

---

## Zone 2 — Implementer's judgment

- Batch rows include free-form notes for qualitative context.
- The 6 tracked metrics are the minimum; additional metrics may be added as design needs evolve.

---

## Zone 3 — Scoped out

- External metrics dashboards (Grafana, Datadog)
- Per-project metrics isolation
- Automated improvement recommendations based on metrics trends
