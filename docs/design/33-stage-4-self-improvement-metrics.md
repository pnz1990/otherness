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

- 🔲 Metrics trend surfacing in SM health comment: metrics are collected every batch but SM only posts the most recent row in its health comment. A human reading the report sees a snapshot, not a trajectory. SM §4f must compute and post a 5-batch rolling trend for the two most actionable metrics: `time_to_merge_avg_min` and `needs_human`. Format: "⬆️ time-to-merge up 40% over last 5 batches (trend: bad)" or "⬇️ needs-human down 60% over last 5 batches (trend: good)". The trend is computed from the last 5 rows of `docs/aide/metrics.md`. If a trend is unfavorable for 3 consecutive batches (worsening): SM must open a `kind/chore priority/high` issue flagging the specific metric and the observed slope. Collecting metrics without surfacing trends is the same as not collecting them — the human never gets the "is it getting better or worse?" signal they need. ⚠️ Inferred from honesty lens: metrics are being collected but not acted on; no mechanism converts trend data into agent behavior change.

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
