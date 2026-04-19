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

- 🔲 definition-of-done.md: Journey 2 gains automated check command using the existing test.sh check 5b

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
