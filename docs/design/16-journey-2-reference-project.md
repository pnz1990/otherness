# 16: Journey 2 — Reference Project Health

> Status: Active | Created: 2026-04-19
> Applies to: otherness itself

---

## The problem this solves

Journey 2 has been ❌ Failing since 2026-04-14. The alibi `_state` branch shows
no commits in 5 days. This is the primary unmet condition for the STOP CONDITION
and for an honest GREEN health signal.

More importantly: if the reference project (alibi) is the validation that otherness
is running correctly on real projects, a 5-day stale reference means the health
monitoring is measuring nothing. The system claims it works but isn't checking.

There are two sub-problems:

1. **Recovery**: alibi needs to run. This requires a human action (restart the session)
   OR a mechanism for otherness to self-recover a stalled reference project.

2. **Detection**: the current test.sh checks alibi's _state once. If alibi stalls,
   the test starts failing but nobody fixes it because the system is focused on
   shipping features, not on monitoring itself.

---

## The fix: automated reference project health gate

### What "healthy" means for the reference project

The reference project is healthy when its `_state` branch has at least one commit
in the last 72 hours. This is already measured in `scripts/test.sh` check 5b.

The missing piece: **what the system does when it detects unhealthiness**.

### Self-recovery protocol

When PM §5 detects Journey 2 is failing (test.sh check 5b fails):

1. **First occurrence**: open a `[NEEDS HUMAN]` issue on the otherness report issue:
   `"[NEEDS HUMAN] Journey 2: reference project stalled — restart otherness on alibi"`
   Post this once. Do not repeat every cycle.

2. **After 24h with no recovery**: PM §5g health signal is automatically AMBER
   (regardless of other signals). This triggers the learn cycle (see doc 13).
   The rationale: a stalled reference project is a symptom of reduced system
   vitality, same as a low Type B rate.

3. **After 72h with no recovery**: PM §5g health signal is automatically RED.
   The system cannot validate itself. This requires human judgment.

### Why alibi specifically

The reference project is the **first non-otherness project in `otherness-config.yaml`
under `monitor.projects`**. Currently that is `pnz1990/alibi`. The reference project
is not hardcoded — it is the first project in the monitor list that is not otherness
itself. If alibi is replaced or removed, the next project becomes the reference.

If there is no reference project (monitor.projects contains only otherness), Journey 2
cannot be validated. In that state: PM must open a `[NEEDS HUMAN]` issue requesting
that a reference project be added to the monitor list.

---

## What the human needs to do to fix Journey 2 right now

```bash
# From the project directory that has otherness set up (pnz1990/alibi)
# Run /otherness.run to restart the agent loop
```

This is a one-time human action. After that, the automated detection and AMBER/RED
escalation handles future stalls.

---

## Present (✅)

- ✅ PM §5j: reference project health check — reads ref project from config, checks _state age >72h, opens [NEEDS HUMAN] issue once per stall (duplicate-suppressed) (PR #301, 2026-04-19)
- ✅ PM §5j Step 3b: AMBER/RED escalation — Journey 2 stall >72h maps to AMBER; >7d maps to RED; propagates to PM §5g overall health signal (PR #302-303, 2026-04-19)
- ✅ test.sh check 5b: outputs STALE_REASON with specific stall duration + exports JOURNEY2_STALE_HOURS for PM consumption (PR #302-303, 2026-04-19)

## Future (🔲)
- ✅ ⚠️ Inferred: cross-project improvement proposals — pm.md §5c [AI-STEP] converted to executable Python: reads monitor.projects, checks needs-human/CI per project, opens improvement issues for common blockers across ≥2 projects. Fail-open. (PR #TBD, 2026-04-20)

- ✅ definition-of-done.md: Journey 2 has automated check command — reads reference project from config, checks _state age, outputs STALE_REASON (2026-04-19)

- 🔲 PM §5j: managed project feature velocity gate — the current reference project health check only measures `_state` activity (was the loop alive?). It does not measure whether the managed project is advancing: shipping feat/* PRs, not just chore/SM housekeeping. The SM health signal on otherness can be GREEN while the managed reference project has shipped zero feat PRs in 7 days. PM §5j must add a second check: count `kind/enhancement` or `feat/*` PRs merged in the last 7 days on the reference project. If zero: downgrade Journey 2 to AMBER regardless of `_state` freshness. A loop that is alive but only shipping chores on the reference project is not demonstrating value — it is demonstrating the housekeeping-only failure mode on someone else's codebase. A loop is only healthy if the managed projects are advancing toward their vision, not just running. The health signal must say GREEN only when the reference project shipped at least one meaningful feature PR in the last 7 days. ⚠️ Inferred from honesty lens: the SM health signal says GREEN but the products it manages are not advancing fast enough; the loop is alive but feature velocity on managed projects is not measured.

- 🔲 PM §5: otherness self-improvement rate vs. managed project improvement rate — report both separately: the SM health signal merges otherness-self improvements with managed-project improvements into a single GREEN/AMBER/RED. This conflation hides a critical distinction: otherness can be shipping PRs to improve itself while the managed projects (alibi, kardinal-promoter, kro-ui) receive zero feature improvements. PM §5 must compute and report two distinct rates per batch: (1) `self_feat_prs`: feat PRs merged to the otherness repo in the last 7 days, (2) `managed_feat_prs`: feat PRs merged to non-otherness monitor.projects in the last 7 days. SM §4f health comment must include both values. When `managed_feat_prs == 0` for 3 consecutive batches while `self_feat_prs > 0`: PM §5 must open a `kind/chore priority/high` issue: "otherness is improving itself but not its managed projects — the value delivered to users has stalled." A system that only improves its own infrastructure while the projects it manages stagnate is not delivering the core promise of otherness. ⚠️ Inferred from honesty lens: the loop is honest about itself but not about the value it delivers to managed projects.

---

## Zone 1 — Obligations

**O1 — Journey 2 failure triggers a [NEEDS HUMAN] issue exactly once per stall event.**
Not on every PM cycle. Open once. Do not open again until the previous issue is closed
and a new stall starts.

**O2 — After 24h of Journey 2 failure, PM §5g health is AMBER regardless of other signals.**
Reference project stall is a system health signal, not just a documentation gap.

**O3 — After 72h, RED.**
At RED, the system cannot validate its own operation. Human must restart.

**O4 — The reference project is not hardcoded.**
It is always the first non-otherness entry in `otherness-config.yaml` `monitor.projects`.
