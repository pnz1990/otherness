# 45: Loop Honesty Audit — The System Must Not Lie to Itself

> Status: Active | Created: 2026-04-22
> Applies to: otherness itself and all managed projects

---

## The problem

The SM health signal says GREEN. The products otherness manages are not advancing fast
enough. The simulation exists but its predictions are not visibly changing agent behavior
every session. Metrics are being collected but the loop between "metric signals a problem"
and "agent behavior changes" requires human intervention. Skills are growing but no
mechanism confirms agents are actually smarter.

The system is operationally healthy (CI passes, _state commits, no [NEEDS HUMAN]) while
being strategically dishonest (roadmap is frozen, managed projects stall, simulation
is decorative).

This is not a monitoring gap — it is an honesty architecture problem. The health signal
was designed to answer "is the loop running?" but the operator needs it to answer
"is the loop *working*?" These are different questions and the current architecture
answers only the first.

This design doc defines the missing honesty checks: the ones that confirm the system
is not just alive but actually doing what it claims to be doing.

---

## Present (✅)

*(Nothing shipped yet.)*

---

## Future (🔲)

- 🔲 45.0 — Internal data consistency check must precede health signal computation — progress.md vs metrics.md contradiction is a currently-occurring detectable lie: `docs/aide/progress.md` currently states "SM cycle: 6 | Agent: otherness@e541da8" while `docs/aide/metrics.md` has 10+ data rows (batch 10 has run). The health signal is computed as GREEN despite these two authoritative files disagreeing on basic facts. SM §4f must, before writing `health: GREEN` to `_state`, run a consistency check: (1) read `sm_cycle_count` from `docs/aide/progress.md` and compare to row count in `docs/aide/metrics.md`; (2) read `agent_hash` from `progress.md` and compare to `git -C ~/.otherness rev-parse --short HEAD`; (3) if either diverges by more than 2: the health signal must be AMBER with note "⚠️ AMBER — internal data inconsistency: progress.md says SM cycle N but metrics.md has M rows. Run SM §4f to regenerate." This is not a new feature — the data is there. The inconsistency is detectable in 3 lines of Python and represents a currently-occurring observable dishonesty (the system tells the human SM cycle is 6 when it is actually 10+). A health signal that is GREEN while two authoritative files in the same repo contradict each other is not honest. The consistency check is the minimum gate to call the signal "verified." ⚠️ Inferred from honesty and visibility lenses: docs/aide/progress.md shows SM cycle: 6 while batch count is 10+; the health signal is GREEN; a human reading progress.md is actively misled; the fix requires exactly one pre-flight consistency check in SM §4f.

- 🔲 45.1 — Whole-system honesty score: PM §5 must compute a `loop_honesty_score` (0–100) every 10 batches that measures how many of the system's own claims are verifiably true. The score has four components: (a) `delivery_honesty` — ratio of sessions where `health=GREEN` AND `meaningful_prs >= 1` vs. sessions where `health=GREEN` AND `meaningful_prs == 0` (GREEN without delivery = dishonest, contributes 0 to this component); (b) `sim_honesty` — ratio of batches where `recovery_action` written by simulation was actually executed vs. total batches with a non-`none` recovery action (simulation recommends but agent ignores = dishonest); (c) `skills_honesty` — ratio of learn sessions that produced a new `agents/skills/*.md` file vs. total learn sessions (learning that extracts no skill = dishonest about self-improvement); (d) `doc_honesty` — ratio of `✅ Present` items that can be verified against agent files vs. total `✅ Present` items (claiming done without implementing = dishonest). The overall score = mean of all four components × 100. SM §4f must include "Honesty: N/100" in the health comment. When the score drops below 70: health must be AMBER regardless of other signals. The principle: a system that lies to itself about its own progress is the most dangerous failure mode — it looks GREEN while falling further behind. ⚠️ Inferred from honesty lens: the SM health signal says GREEN but the products it manages are not advancing fast enough; collecting and displaying a composite honesty score is the structural fix that converts GREEN from "loop is alive" to "loop is doing what it claims."

- 🔲 45.2 — Simulation action trace must be auditable from the report issue — not just from `sim-prediction.json`: the simulation computes `recovery_action` and writes it to `_state:sim-prediction.json`. COORD reads it and (sometimes) acts on it. But the entire simulation-to-behavior chain is invisible to anyone not reading raw `_state` branch files. A human opening the report issue today cannot tell: (a) what the simulation predicted, (b) what `recovery_action` was set, (c) whether COORD acted on it, or (d) whether acting on it produced an improvement. SM §4e must post a one-line trace to the report issue at the end of each calibration run: "🔬 Sim: predicted floor=N | actual=M | arch_convergence=K | recovery_action=<action> [executed: yes/no]". The `[executed: yes/no]` field is determined by checking state.json for the action flag written by COORD §1b-sim in the previous session. When `executed=no` for a non-`none` action: include "⚠️ action not observed — COORD §1b-sim may not be running." Without this trace, the simulation is a background computation that influences nothing visible. The claim "predictions visibly change agent behavior" requires *visible* evidence — the trace is that evidence. ⚠️ Inferred from honesty lens: the simulation exists but its predictions are not visibly changing agent behavior; "visibly" is the key word — the simulation may be running correctly while being invisible to the operator.

- ✅ 45.3 — Health signal GREEN must require independently verifiable evidence, not only self-reported SM data: SM §4f computes the health signal by reading `_state:state.json` — a file that SM itself writes. This is circular: the health signal's inputs are produced by the same system that computes the signal. A genuinely independent health check must read from a source that is not written by SM §4f. The strongest available independent source: GitHub's own PR and issue API. SM §4f must add an independence gate before declaring GREEN: (1) query `gh pr list --state merged --json mergedAt` for the last 24 hours; (2) if this returns ≥1 PR merged in the last 24 hours: `independent_delivery_verified=true`; (3) if 0 PRs returned by the API: health cannot be GREEN — set AMBER with note "⚠️ No PRs verified via GitHub API in last 24h — self-reported metrics unconfirmed." The independence gate is not a replacement for the existing metrics — it is an additional confirmation. A system that claims to have shipped PRs must be able to prove it via GitHub's API. If the API disagrees with state.json: state.json is suspect. ⚠️ Inferred from honesty lens: the SM health signal is self-referential; a health signal that is GREEN because the system wrote GREEN to a file it owns is not an honest signal; one independent verification query per batch is the minimum required to call the signal "verified." (PR #789)

- ✅ 45.4 — Managed projects must have their own independent honesty check, not just a liveness check: PM §5 Scenario 1 checks `_state` activity within 72 hours for the reference project. This answers "did otherness run on this project?" — not "is this project actually advancing?" A managed project that runs 50 batches in 7 days with `meaningful_prs=0` every batch passes the liveness check while being strategically stalled. PM §5 must add a `managed_project_honesty_check` alongside Scenario 1: for each project in `monitor.projects`, (1) count `feat/` prefix PRs merged in the last 7 days via `gh pr list --repo $PROJECT --state merged --json title,mergedAt`; (2) if count < 2 for 7 days: the project is shipping fewer than 2 meaningful PRs/week — this is a strategic stall even if the loop is alive; (3) post to the otherness report issue: "⚠️ FLEET STALL: [project] — 0 meaningful PRs in 7 days (alive: yes, advancing: no). Review queue and vision pressure for that project." A fleet monitor that only checks liveness cannot distinguish a thriving project from one that runs batches while going nowhere. otherness's credibility as an autonomous system depends on all projects it manages actually advancing, not just running. ⚠️ Inferred from honesty lens: the loop is not honest enough; the system monitors managed projects for liveness but not for actual delivery; a strategically stalled managed project is reported as HEALTHY because it has recent `_state` commits. (PR #789)

- 🔲 45.5 — "Metrics collected but not acted on" must become a detectable and reported state: SM §4b detects regressions (needs_human up, todo_shipped down) and opens issues. The issues sit in the queue for days. COORD claims them when priority dictates. But between detection and resolution, the metrics continue to show the same regression — and the health signal can be GREEN the entire time. There is a state the system cannot currently detect: "regression detected AND issue is open AND metrics have not improved in N batches." This state means the system identified a problem, created a task to fix it, but the fix is either not being worked on or is not working. SM §4b must track: for each open regression-detection issue (title matching `kind/chore priority/high` + regression description), check if the corresponding metric has improved since the issue was opened. If metric unchanged for 10 batches while issue is open: SM §4b must comment on the issue "⚠️ Regression persists 10 batches since detection — this issue has not resolved the underlying metric. Consider escalating or changing approach." and set health to AMBER. Metrics that open issues without the issues eventually fixing the metrics are an accountability gap: the detection loop fired but the repair loop is broken. Without this check, the system can perpetually detect the same regression and open (or re-open) the same issue while the health signal says GREEN and nothing improves. ⚠️ Inferred from honesty lens: metrics are being collected but not acted on — this is the specific loop that must close: regression detected → issue opened → metric tracked for improvement → AMBER if improvement absent after 10 batches.

- 🔲 45.6 — Self-improvement claims must be falsifiable: the system claims to be self-improving. But no mechanism exists that would allow an honest assessment of "is the system actually smarter than it was 30 days ago?" An unfalsifiable claim of self-improvement is not honesty — it is branding. PM §5 must, every 30 days (tracked via `state.json: last_improvement_audit_at`), run an improvement audit: (1) record the current `needs_human` rolling 10-batch average and `time_to_merge_avg_min`; (2) compare to the values from 30 days ago (stored in `state.json: improvement_baseline`); (3) if neither metric improved by ≥10%: PM §5 must post to the report issue: "📊 30-day improvement audit: needs_human: N→M (delta: D%), TTM: A→B minutes (delta: E%). Conclusion: [IMPROVING / FLAT / REGRESSING]." The audit must appear regardless of the conclusion — it must be posted even when the system is flat or regressing. A system that only reports its successes is not honest. The 30-day audit is the minimum cadence at which the self-improvement claim becomes falsifiable. If the audit shows flat or regressing for 3 consecutive months: PM §5 must open a `[NEEDS HUMAN: improvement-stalled]` issue: "30-day audits show no measurable improvement for 3 consecutive months — the self-improvement loop is not working." ⚠️ Inferred from self-improvement and honesty lenses: the agents are not meaningfully smarter than two weeks ago; no mechanism produces a falsifiable assessment of whether improvement is actually occurring; all self-improvement claims are currently unfalsifiable assertions.

- 🔲 45.7 — Design doc `✅ Present` marks must be verified against observable artifacts quarterly: design docs mark features `✅ Present` when a PR is merged. But PRs can partially implement a spec, remove an implementation in a later refactor, or implement the spec incorrectly. After 100+ batches, the `✅ Present` items are unverified claims about what the system does. PM §5 must, every 50 batches (tracked via `state.json: last_spec_audit_at`), sample 10 random `✅ Present` items from across all design docs and attempt to verify each against the actual agent files. Verification heuristic: if the item names a specific SM section (e.g. "SM §4b: writes X column to metrics.md"), check if (a) the column header exists in `metrics.md`, and (b) the last data row has the correct column count. For items that reference specific files or behaviors: check if the file exists and contains a section matching the described behavior. For each item that fails verification: mark it `⚠️ Unverified — spec claim not confirmed in agent files` in the design doc. If ≥3 of 10 sampled items fail verification: PM §5 must open a `kind/bug priority/high` issue: "Spec audit: 30%+ of sampled ✅ Present items are unverifiable — design doc honesty degraded. Review agent files against design doc claims." Without this audit, the design docs become an honorary record of intentions rather than an accurate record of what the system actually does. ⚠️ Inferred from honesty lens: design docs mark items ✅ Present but no periodic verification confirms the implementations are still present and correct after subsequent PRs.

- 🔲 45.9 — The system's self-assessment of "GREEN health" must be externally benchmarked, not just self-referential: the current health signal is computed from internal metrics (state.json, metrics.md, PR counts) — all written by the system itself. A genuine honesty check requires comparing the system's self-assessment to external ground truth that the system does not control. The highest-integrity external signal available is: "what percentage of the work claimed as shipped can be verified by a third party reading only GitHub, with no access to state.json?" PM §5 must, every 20 batches, run a "GitHub-only audit": (1) read the last 20 merged PRs via `gh pr list --state merged --limit 20 --json title,body,number`; (2) for each PR: check if the GitHub issue it references is now closed (`gh issue view <N> --json state --jq .state == "closed"`); (3) compute `closure_rate = closed_issues / total_pr_referenced_issues`; (4) if `closure_rate < 0.7` (less than 70% of referenced issues are actually closed): post to report issue: "⚠️ GitHub-only audit: N of M referenced issues still open after PR merge — work is claimed but issues are not being closed. Self-report says GREEN; GitHub external audit says issue closure is broken." This audit cannot be manipulated by the system because it reads GitHub's API independently of state.json. A system that claims GREEN while 30%+ of its referenced issues remain open is not honest — it is claiming completion without completing. ⚠️ Inferred from honesty lens: the SM health signal is self-referential; 45.3 adds one GitHub API verification per batch; 45.9 adds the deeper check — are the GitHub issues actually being closed after PRs merge, which is the ultimate external proof of delivery.

- 🔲 45.8 — The health signal must distinguish "loop alive" from "loop working": the current health signal answers "is the loop alive?" (GREEN = CI passes, no [NEEDS HUMAN], _state commits). But the operator's actual question is "is the loop *working*?" (is the roadmap advancing? are managed projects improving? is the system getting smarter?). These are different questions with different answers. The health signal must evolve from a binary alive/stalled signal into a dual signal: `ALIVE: GREEN/AMBER/RED` (current) + `WORKING: GREEN/AMBER/RED` (new). `WORKING=GREEN` requires ALL of: (1) `meaningful_prs >= 1` in last 3 sessions, (2) `current_stage_pct` increased in last 10 batches, (3) at least one managed project shipped a feature PR in the last 7 days, (4) `loop_honesty_score >= 70` (from 45.1). `WORKING=AMBER` when 1–2 conditions fail. `WORKING=RED` when 3+ conditions fail or any managed project has been STALL-detected for >5 days. SM §4f must include BOTH signals in the health comment. The current single GREEN/AMBER/RED is reframed as the `ALIVE` signal; the new dual signal adds the `WORKING` dimension. A system that is ALIVE=GREEN, WORKING=AMBER is the most important state to make visible — it is the "spinning in circles" condition the pressure context names explicitly. ⚠️ Inferred from all five pressure lenses: the SM health signal says GREEN but the products are not advancing; the single-dimension health signal cannot express "alive but not working"; adding a second dimension is the architectural change that makes this state visible without redesigning the existing signal.

- 🔲 45.10 — The WORKING dual signal (45.8) has no enforced delivery deadline — it can remain unimplemented for 100 batches with no escalation: the `features.dual_health_signal` flag (Zone 2) defaults to `false` until the WORKING signal components are all implemented. But there is no mechanism that enforces when the flag must be set to `true` — no deadline, no escalation, no forced implementation. A feature behind a disabled flag is not a Future item — it is an indefinitely-deferred promise. The system can run in ALIVE-only mode for 200 batches while WORKING=unknown and no mechanism surfaces this deferral as a gap. SM §4c must track `dual_health_signal_deferred_since` in `state.json` — set when 45.8 is first added to the design doc as a `🔲 Future` item. When `dual_health_signal_deferred_since` is older than 30 days AND `features.dual_health_signal: false`: SM §4c must open a `priority/high kind/enhancement` issue: "[WORKING signal overdue] 45.8 (ALIVE+WORKING dual signal) has been deferred for >30 days. The system cannot honestly claim to know whether the loop is working without implementing the WORKING dimension. Set `features.dual_health_signal: true` and implement the four WORKING conditions." Without this escalation deadline, the WORKING signal will remain behind a feature flag indefinitely — the most important honesty improvement in this doc is also the one with the softest delivery pressure. ⚠️ Inferred from all five pressure lenses: the SM health signal says GREEN but the products are not advancing; the WORKING signal is the architectural fix; a fix that can be deferred indefinitely behind a feature flag is not a fix — it is a plan; the escalation deadline makes the plan a commitment.

---

## Zone 1 — Obligations

**O1 — Honesty checks must be fail-open.**
If any honesty check fails to execute (API timeout, missing file, Python error): log
the failure and skip the honesty component for that batch. Never let a honesty check
failure block the main loop or produce a false score.

**O2 — The honesty score is informational, not a gate.**
`loop_honesty_score < 70` triggers AMBER but does not prevent COORD from claiming
items. The loop must continue to operate while the honesty gap is being diagnosed.

**O3 — Never suppress a failing honesty result.**
If the 30-day audit shows regression, it must be posted. If the spec audit shows
3 failing items, it must be opened as an issue. The honesty checks exist to surface
uncomfortable truths, not to validate the narrative that everything is improving.

**O4 — The dual health signal (ALIVE + WORKING) must not duplicate conditions.**
ALIVE checks operational status (CI, _state, [NEEDS HUMAN]).
WORKING checks strategic progress (roadmap, delivery, self-improvement).
An item that belongs in ALIVE must not appear in WORKING, and vice versa.
The two signals are orthogonal dimensions — a system can be ALIVE=GREEN, WORKING=RED.

---

## Zone 2 — Implementer's judgment

- The `loop_honesty_score` components can be weighted differently as empirical data
  emerges. Equal weighting is the starting point.
- The `simulation action trace` post to the report issue should be a separate comment
  from the SM health comment — it is triggered by SM §4e (calibration), not SM §4f
  (batch summary). Calibration runs every 10 batches; the health comment runs every batch.
- The quarterly spec audit (45.7) can be deferred until the design doc count stabilizes
  (≥50 docs with ≥50% `✅ Present` items). Until then, sampled audits are too small
  to be meaningful.
- The dual health signal (45.8) should be gated behind a `features.dual_health_signal`
  flag in `otherness-config.yaml`, defaulting to `false` until the WORKING signal
  components are all implemented. Premature dual signal with missing components is
  misleading.

---

## Zone 3 — Scoped out

- Replacing the existing GREEN/AMBER/RED signal with the dual signal in the short term
  (the transition must be additive, not a replacement, until WORKING is stable)
- External audit by a human reviewer (this doc is about automated honesty checks)
- Per-item honesty scoring (too fine-grained; honesty is a system property, not a
  per-item property)
