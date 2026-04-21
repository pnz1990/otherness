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
- 🔲 Metrics schema must include `meaningful_prs` and `session_items_completed` columns: the existing schema tracks `prs_merged` (total) but cannot distinguish a session that shipped 5 feature PRs from one that shipped 5 chore PRs. `meaningful_prs` (count of PRs advancing a 🔲→✅ transition) and `session_items_completed` (items attempted in the multi-item loop) are the two columns needed to detect the "housekeeping-only" failure mode described in doc 21. SM §4b must write both. PM §5 stagnation check uses `meaningful_prs` as its primary velocity signal. Without these columns, the stagnation check is a proxy (todo_shipped) that cannot distinguish real forward progress from chore accumulation. ⚠️ Inferred from honesty lens: current metrics schema cannot prove the system is shipping meaningful work.
- 🔲 Metrics data must drive agent behavior changes, not just observations: today, when SM detects a regression (needs_human up 2 consecutive batches), it opens an issue. But it does not adjust agent behavior in the current session or the next. The loop between "metrics indicate a problem" and "agent changes behavior to fix it" requires a human to read the issue and act. This loop must be closed. SM §4b must write a `next_session_directive` field to `state.json` when it detects a regression — e.g. `{"directive": "prioritize_ci_fix", "reason": "ci_red_hours > 2 for 3 batches"}`. COORD §1b must read this field at session start and reorder claims accordingly. Metrics that do not change behavior are dashboards, not instruments. ⚠️ Inferred from honesty lens: simulation exists and metrics are collected but predictions are not visibly changing agent behavior.
- 🔲 `skills_count` trajectory tracked in metrics.md: the schema tracks `prs_merged`, `needs_human`, `ci_red_hours` and others, but `skills_count` (total skills in `agents/skills/`) is not recorded per batch. A system that claims self-improvement should show skills growing over time — but this trajectory is invisible in the current schema. SM §4b must add a `skills_count` column (count of `*.md` files in `agents/skills/` minus `README.md` and `PROVENANCE.md`) written every batch. PM §5 stagnation check must flag when `skills_count` has not changed in 30 batches — this is strong evidence that `/otherness.learn` has stopped running. A flat `skills_count` for 30 batches + no PROVENANCE.md update = the self-improvement loop has silently stopped. ⚠️ Inferred from self-improvement lens: skills library grows slowly; no metric currently captures the rate or flatness of skill growth to trigger automated intervention.
- 🔲 Agent intelligence delta measurement — the system must prove it is smarter than 30 batches ago: today, skill counts grow and `needs_human` is tracked, but there is no metric that captures whether the agents are actually making better decisions over time. A proxy: compare the `needs_human` rate and `time_to_merge_avg_min` from the first 10 batches after each major learn session against the 10 batches before it. If neither improves after 3 consecutive learn sessions, it is evidence that the learning is not transferring to agent decisions. SM §4b must compute this `intelligence_delta` score every 10 batches (after each learn session) and write it to `metrics.md`. PM §5 must flag when `intelligence_delta` is neutral for 2 consecutive learn cycles — a `kind/chore priority/high` issue must be opened: "Skills growing but agent decisions not improving — review skill applicability and ENG skill-load discipline." ⚠️ Inferred from self-improvement lens: agents are not measurably smarter; the system claims self-improvement but has no metric that confirms the claim.
- 🔲 Metrics schema-execution drift detection: the `docs/aide/metrics.md` header defines 9 columns (`prs_merged`, `needs_human`, `ci_red_hours`, `skills_count`, `todo_shipped`, `time_to_merge_avg_min`, `vision_prs`, `session_outcome`, `arch_convergence`) but actual data rows for batches 90–94 contain only 8 columns — `vision_prs` and `session_outcome` are in the schema but not written. SM §4b states it writes these columns (PR #655), but the evidence (data rows) contradicts this. SM §4a must run a schema-conformance check on every batch: count the pipe-separated columns in the last row of `metrics.md` and compare to the count in the header row. If they differ: SM must open a `kind/bug priority/high` issue "metrics.md schema drift: N columns defined, M columns written — design doc says ✅ Present but implementation is incomplete." This is the minimum honesty gate: the system must self-detect when its claims and its data disagree. ⚠️ Inferred from honesty lens: design docs mark features ✅ Present but the observable data (metrics rows) shows the implementation is not running.
- 🔲 Learn session skill-extraction verification: SM §4c learn-cadence enforcement opens a learn issue when PROVENANCE.md is >14 days stale — but it does not verify the learn PR was merged and a new skill file was actually created in `agents/skills/`. SM §4c must: (1) after opening a learn issue, record the issue number as `pending_learn_issue: N` in `state.json`; (2) every SM cycle, check if that issue is closed with a merged PR; (3) if closed: verify `agents/skills/` has a file newer than the issue creation date (via `git log --since` on the skills directory); (4) if closed but no new skill file found: open a `kind/bug priority/medium` issue "learn session closed but no new skill extracted — PROVENANCE.md updated without adding a skill file." Currently the learn cadence loop fires but has no feedback: a learn issue can be closed without producing any learnable artifact, and the system moves on silently. ⚠️ Inferred from self-improvement lens: /otherness.learn runs rarely; when it does run, there is no mechanism confirming the learning was captured as a reusable skill.

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
