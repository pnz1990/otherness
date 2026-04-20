# 23: Simulation as Anchor — Self-Calibrating Health Instrument

> Status: Active | Created: 2026-04-20
> Applies to: otherness itself (primary); calibrated defaults propagate to all managed projects

---

## The problem

The loop ships work. But it has no instrument for knowing whether the work it is shipping
is healthy, whether its velocity is normal or stalled, or whether a degradation pattern
is emerging before it becomes obvious to a human.

`docs/aide/metrics.md` tracks batch history. `scripts/simulate.py` models the dynamics.
Neither talks to the other. The simulation runs when a human runs it. The metrics are
written to a file no automated process reads. The result: the system is blind to its own
health between human check-ins.

The vision says: *"This is how the system knows when it's stuck before the human notices."*
That is not true today. It needs to become true.

---

## What this doc specifies

A closed feedback loop between three existing artifacts:
1. **`docs/aide/metrics.md`** — real batch data (already maintained by SM)
2. **`scripts/simulate.py`** — the boldness dynamics model (already exists)
3. **SM `§4e` calibration phase** — the wiring that makes them talk

The simulation runs in SM every N cycles, reads the real metrics, calibrates its
parameters against observed behavior, predicts what healthy looks like next cycle,
and posts a divergence signal when reality is outside the predicted range.

---

## The closed loop in detail

### Step 1: Real data → simulation parameters (calibration)

SM reads `docs/aide/metrics.md` and extracts the last 10 batch rows:

```python
# From metrics.md batch log
real_metrics = {
    'prs_per_batch':   [1,2,2,2,1,1,...],   # todo_shipped column
    'needs_human':     [0,0,0,0,0,0,...],
    'skills_count':    [11,11,12,12,...],
    'ci_red_hours':    [0,0,0,0,...],
    'time_to_merge':   [8,4,3,3,...],
}
```

It runs `simulate.py` with a range of `decay_rate` and `skill_boldness_coefficient`
values and finds the parameter set that minimizes the error between simulated and real
`prs_per_batch`. These become the **calibrated parameters** for this project.

### Step 2: Calibrated parameters → prediction

The calibrated simulation runs one cycle forward and predicts:

```python
prediction = {
    'prs_next_batch_floor': 2,    # lower bound — below this is a warning
    'prs_next_batch_ceiling': 8,  # upper bound — above this is suspicious
    'arch_convergence_score': 0.3, # 0=diverse, 1=fully converged — warn if >0.7
    'skill_growth_rate': 0.1,     # warn if <0.05 for >5 cycles
}
```

### Step 3: Reality vs prediction → signal

After each batch, SM compares actual `todo_shipped` to the predicted floor:

```bash
# In SM §4e (runs every batch)
ACTUAL_SHIPPED=$(tail -1 docs/aide/metrics.md | cut -d'|' -f7 | tr -d ' ')
PRED_FLOOR=$(cat .otherness/sim-prediction.json | python3 -c "import sys,json; print(json.load(sys.stdin)['prs_next_batch_floor'])")

if [ "$ACTUAL_SHIPPED" -lt "$PRED_FLOOR" ]; then
  CONSECUTIVE_LOW=$((${CONSECUTIVE_LOW:-0} + 1))
  if [ "$CONSECUTIVE_LOW" -ge 3 ]; then
    # Post divergence signal to report issue
    gh issue comment $REPORT_ISSUE --repo $REPO \
      --body "[⚠️ Simulation divergence | SM §4e] Actual shipped: ${ACTUAL_SHIPPED}/batch. Predicted floor: ${PRED_FLOOR}. ${CONSECUTIVE_LOW} consecutive below-floor batches. Possible causes: queue stall, skill growth halt, arch convergence. Investigate."
  fi
fi
```

### Step 4: Signal → recovery

A divergence signal is not a `[NEEDS HUMAN]`. It is an observation posted on the
report issue. The autonomous loop reads it on its next cycle and adjusts:

- If queue is empty → trigger autonomous vision synthesis
- If `needs_human` > 0 → escalate the oldest unresolved item
- If `ci_red_hours` > 8 → prioritize CI fix items in queue
- If `skill_growth_rate` < floor → trigger `/otherness.learn`

The human sees the divergence signal in the report issue. They re-enter only if the
autonomous recovery fails after 3 attempts.

---

## The arch_convergence signal

The simulation's most important output for otherness specifically is the
`arch_convergence` score — how much the agents are all reasoning from the same
framework (the monoculture risk from `docs/design/10-multi-agent-simulation.md`).

When `arch_convergence > 0.7`, the simulation predicts the system will find the same
set of solutions regardless of problem type. The recovery is `/otherness.learn` with
a foreign codebase — injecting genuinely different patterns.

SM monitors this:
```python
if sim_results['arch_convergence'] > 0.7:
    # Open issue: "learn(arch): arch_convergence at {score:.2f} — run /otherness.learn"
    # This is the only case where the SIMULATION directly opens an issue
```

---

## Per-project calibration and fleet defaults

otherness calibrates its simulation against its own `metrics.md`. The calibrated
parameters (`decay_rate`, `skill_boldness_coefficient`, `jump_multiplier`) are written
to `~/.otherness/scripts/sim-defaults.json` and shipped to all managed projects via
the normal `git pull` self-update.

Managed projects (kardinal-promoter, kro-ui) start with the otherness defaults and
re-calibrate against their own batch data after ≥5 batches.

This is the **propagation chain** the vision describes:
```
otherness observes → calibrates → ships defaults → managed projects inherit →
managed projects re-calibrate → feed back to otherness
```

---

## What gets stored where

```
.otherness/sim-prediction.json   — written by SM §4e after each calibration run
                                    { prs_floor, prs_ceiling, arch_convergence,
                                      skill_growth_rate, calibrated_params,
                                      calibrated_at }

docs/aide/metrics.md             — existing batch log (SM already writes this)

~/.otherness/scripts/sim-defaults.json  — fleet-wide defaults (written by otherness SM,
                                           read by all managed projects on startup)
```

---

## Present (✅)

- ✅ `scripts/simulate.py` — multi-agent boldness model with calibration mode (2026-04-17)
- ✅ `docs/aide/metrics.md` — real batch data tracked by SM (2026-04-14)
- ✅ `docs/design/10-multi-agent-simulation.md` — simulation design and falsification (2026-04-17)
- ✅ `docs/design/11-simulation-feedback-loop.md` — feedback loop design (2026-04-17)
- ✅ `SM §4d`: `arch_convergence > 0.7` → open `learn(arch):` issue labeled `otherness,area/agent-loop,kind/chore` with deduplication check; replaces `[NEEDS HUMAN]` escalation (PR #351, 2026-04-20)
- ✅ `SM §4e`: compare actual `todo_shipped` to predicted floor from `scripts/sim-params.json`; track consecutive below-floor count in `_state:.otherness/divergence_count.json`; post `[⚠️ Simulation divergence]` after 3 consecutive below-floor batches (PR #350, 2026-04-20)
- ✅ `SM §4d`: write `sim-prediction.json` to `_state` after each calibration — fields: `prs_next_batch_floor`, `prs_next_batch_ceiling`, `arch_convergence_score`, `skill_growth_rate`, `calibrated_params`, `calibrated_at` (PR #349, 2026-04-20) ⚠️ Stale — referenced file not found
- ✅ `scripts/sim-defaults.json`: fleet defaults — written by otherness SM §4d after calibration (otherness-repo-only gate); shipped to managed projects via `git -C ~/.otherness pull` self-update (PR #353, 2026-04-20)
- ✅ `SM §4e-i`: per-N-cycle calibration update — reads `metrics.md`, runs `calibrate.py --runs 2`, writes `sim-prediction.json` to `_state` every `simulation.calibration_cycles` cycles (default: 5); frequency configurable via `otherness-config.yaml` (PR #401, 2026-04-20) ⚠️ Stale — referenced file not found
- ✅ `otherness-config.yaml`: `simulation.calibration_cycles` field (default: 5) — controls SM §4e-i re-calibration frequency (PR #408, 2026-04-20)
- ✅ SM §4e-i fleet-defaults fallback: when `scripts/calibrate.py` is absent (managed project), SM reads `~/.otherness/scripts/sim-defaults.json` and writes it as `sim-prediction.json` to `_state` with `source: "fleet-defaults"`. Local calibration activates when ≥5 batch rows in `metrics.md` AND `calibrate.py` present. `otherness-config-template.yaml` now includes `simulation.calibration_cycles: 5` stub so new projects inherit the correct default. (PR #509, 2026-04-20) ⚠️ Stale — referenced file not found

## Future (🔲)


- 🚫 `scripts/simulate.py`: add `--calibrate` flag — DEPRECATED: `scripts/calibrate.py` provides this functionality as a standalone script. No duplication needed.
- 🔲 Simulation predictions must visibly change agent behavior: today the simulation runs, produces predictions, and posts divergence signals — but the agent loop does not demonstrably adjust its behavior in the following batch based on those signals. SM §4e must write a `recovery_action` field to `sim-prediction.json` (one of: `trigger_learn`, `escalate_oldest_needs_human`, `prioritize_ci_fix`, `trigger_vision_synthesis`), and `coord.md §1b` must read this field at session start and adjust claim priority accordingly. The prediction is useless if no one acts on it. ⚠️ Inferred from honesty lens: simulation exists but its predictions are not visibly changing agent behavior.
- ✅ `SM §4e-iii`: simulation-behavior coupling gate — after each calibration, verifies that arch_convergence AMBER (≥0.7) signals triggered a learn session (checks PROVENANCE.md, learn branches, learn issues); verifies that a learn session actually decreased arch_convergence in the subsequent calibration; posts `[⚠️ Simulation loop unclosed]` on REPORT_ISSUE if the chain never closed; runs at calibration cadence (every N SM cycles); informational only, does not block work (PR #TBD, 2026-04-20)
- 🔲 SM health signal must distinguish real GREEN from stall-GREEN: the current GREEN health signal fires when the batch completed and CI passed — it does not verify that meaningful work shipped. A batch where only a metrics commit merged is currently reported as GREEN. The health signal must be two-axis: `progress_signal` (ADVANCING / STALLING / STALLED) × `health_signal` (GREEN / AMBER / RED). ADVANCING requires ≥1 meaningful PR (Future→Present transition or validated fix). STALLING means 2 consecutive batches with 0 meaningful PRs. STALLED means 3+. The human should never see GREEN on a stalling system. ⚠️ Inferred from honesty lens: SM health signal says GREEN but products not advancing fast enough.
- 🔲 Simulation calibration staleness visible in health signal: `sim-prediction.json` stores a `calibrated_at` timestamp but this is never surfaced to the human. SM §4f health comment must include "Sim calibrated: N days ago" and downgrade to AMBER if calibration is >14 days old. A prediction based on 14-day-old data may be systematically wrong — the human should know when the anchor is stale. Implementation: SM §4f reads `calibrated_at` from `_state:sim-prediction.json`, computes age, appends to health comment, and sets `progress_signal: AMBER` if age > 14 days. ⚠️ Inferred from honesty lens: simulation exists but its predictive authority is invisible; a stale calibration silently produces misleading divergence signals.

---

## Zone 1 — Obligations

**O1 — Divergence is a signal, not a blocker.**
The system does not stop when divergence is detected. It posts an observation and
continues. Only if autonomous recovery fails after 3 attempts does it escalate.

**O2 — Calibration must be reproducible.**
Given the same `metrics.md` and the same `simulate.py`, the calibration must produce
the same parameters. Use a fixed random seed in calibration runs. Store the seed in
`sim-prediction.json`.

**O3 — Per-project re-calibration must not overwrite fleet defaults.**
Managed projects re-calibrate into their own `.otherness/sim-prediction.json`. Fleet
defaults in `~/.otherness/scripts/sim-defaults.json` are only written by otherness SM
running on the otherness repo. Never by a managed project.

**O4 — The simulation never gates a merge.**
A divergence signal is informational. A red simulation score does not block CI or
prevent PRs from merging. The human and the autonomous recovery loop decide what to
do with the signal.

---

## Zone 2 — Implementer's judgment

- Calibration frequency: every 5 SM cycles is a reasonable default. High enough to
  catch slow drift, low enough to not dominate session time.
- Grid search bounds for calibration: `decay_rate` in [0.85, 0.99], 
  `skill_boldness_coefficient` in [0.005, 0.03]. These cover the realistic range.
- Whether to use `docs/aide/metrics.md` parse or `_state` branch history for input:
  `metrics.md` is more human-readable and already maintained. Use it as primary.
- How many batches to include in calibration: last 10 is enough for stable fit.

---

## Zone 3 — Scoped out

- Real-time streaming metrics (batch-level granularity is sufficient)
- Cross-project simulation comparison (each project calibrates independently)
- Predictive scheduling (simulation does not adjust cron)
- Public dashboards (signals go to the report issue, not an external service)
