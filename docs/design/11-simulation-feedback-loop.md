# 11: Simulation Feedback Loop — Empirical Anchoring of Agent Behavior

> Status: Active | Created: 2026-04-18
> Applies to: otherness self-improvement + all projects using otherness

---

## What this does

Connects `scripts/simulate.py` to the agent loop so simulation findings
influence real agent behavior, not just design docs.

Today the simulation is a file. It produces numbers. Nothing reads them.
This design doc defines the mechanism that closes that gap — making the
simulation a living instrument that calibrates how otherness behaves, and
propagating that calibration to every project that uses otherness.

**The two-phase architecture:**

**Phase 1 — Calibrate against otherness itself.**
Run the simulation against otherness's own batch history (`docs/aide/metrics.md`).
Find the parameter set where simulated curves match observed reality. Ship those
parameters as the default in `~/.otherness`. Every new project inherits them.

**Phase 2 — Per-project re-calibration.**
After a project accumulates sufficient local batch history, the SM phase re-runs
the simulation calibrated to that project's data. Parameters drift from the
otherness defaults toward project-specific reality. The simulation becomes a
mirror for that team, not a generic benchmark.

Phase 1 makes the simulation useful immediately.
Phase 2 makes it precise over time.
You don't need Phase 2 to start. Phase 2 emerges from Phase 1 running long enough.

---

## Present (✅)

- ✅ Phase 1a: `scripts/calibrate.py` — grid search, writes `scripts/sim-params.json` (PR #240, 2026-04-18)
- ✅ Phase 1b: SM §4d — calibration every 10 batches, arch-convergence alarm at >0.7, sim-params.json updated (PR #239, 2026-04-18)
- ✅ Phase 2b: arch-convergence signal in SM — SM §4d reads mean_arch_convergence; opens [NEEDS HUMAN] if >0.7 for 2 consecutive batches (PR #239, 2026-04-18)
- ✅ Phase 1c: SM §4d-learn — auto-trigger /otherness.learn when Type B rate < sim floor for 3 consecutive batches, gated by 0 escalations (PR #269, 2026-04-18)
- ✅ Phase 2a: per-project calibration — SM §4d checks metrics.md row count; if ≥10 rows: runs calibrate.py with local metrics (`--metrics docs/aide/metrics.md`); sim-params.json persisted to _state branch (PR #270, 2026-04-18)

## Future (🔲)

- 🔲 Phase 2c: simulation results in `_state` — each SM calibration run commits
  results to `_state` as `.otherness/sim-results.json`; PM phase reads it for
  the product validation scenario

---

## Zone 1 — Obligations

**O1 — Simulation parameters are data, not code.**
The parameters that govern agent behavior (decay_rate, jump_multiplier, etc.)
must live in `scripts/sim-params.json`, not hardcoded in `simulate.py`. This
makes calibration possible without code changes.

**O2 — Phase 1 runs before Phase 2.**
Per-project calibration requires a baseline. The baseline is otherness's own
calibrated parameters. A project cannot calibrate from nothing.

**O3 — Calibration is non-destructive.**
The SM calibration run never modifies agent instruction files. It only updates
`sim-params.json`. Agent behavior changes through parameter drift, not
instruction rewrites.

**O4 — The arch-convergence signal escalates to human, never auto-acts.**
When architectural monoculture is detected, the system opens a needs-human issue.
It does not autonomously run `/otherness.learn` or `/otherness.vibe-vision`.
Those are human-initiated. The simulation surfaces the signal. The human decides.

**O5 — Calibration results are reproducible.**
Given the same `metrics.md` input and the same random seed, `calibrate.py`
produces the same `sim-params.json`. Calibration is deterministic.

---

## Zone 2 — Implementer's judgment

- How many parameter combinations to search in Phase 1a: grid search over
  decay_rate (0.88–0.96), jump_multiplier (1.3–2.0), skill_boldness_coefficient
  (0.01–0.02). ~50 combinations × 10 runs = ~500 simulation runs. Acceptable
  runtime on a modern machine (~30s).
- What "best fit" means: minimize RMSE between simulated completion_rate and
  observed PRs/batch normalized by queue depth. Completion rate is the most
  directly observable real metric.
- How frequently to re-calibrate in Phase 1b: every 10 batches. Enough signal
  to update; not so frequent that noise dominates.
- Minimum batch history for Phase 2a: 10 batches. Below that, simulated defaults
  are more reliable than project-specific noise.
- Whether to expose sim-params.json to the human: yes, as a read artifact in
  `/otherness.status` output ("current simulation parameters: ..."). Transparent.

---

## Zone 3 — Scoped out

- Multi-project simulation (modeling the fleet, not individual projects) —
  this is a separate research question deferred to design doc 12 if warranted
- Automatic parameter tuning without human visibility — all calibration outputs
  are committed to `_state` and visible. No silent parameter changes.
- Replacing agent instructions with simulation-derived rules — the simulation
  informs thresholds and trigger frequencies; it does not rewrite instructions

---

## Design

### Phase 1a: calibrate.py

```python
# scripts/calibrate.py
# Reads docs/aide/metrics.md → runs grid search → writes scripts/sim-params.json

import json, math, itertools
from simulate import SimConfig, run_simulation, average_metrics

# Parse real metrics
real_metrics = parse_metrics_md('docs/aide/metrics.md')
# real_metrics = [{'batch': N, 'prs': N, 'items': N, 'needs_human': N}, ...]

# Target: completion_rate per cycle ≈ real prs / (batches * cycles_per_batch)
target_completion = mean(r['prs'] / r['items'] for r in real_metrics if r['items'] > 0)

best_params = None
best_rmse = float('inf')

grid = list(itertools.product(
    [0.88, 0.90, 0.92, 0.94],           # decay_rate
    [1.3, 1.5, 1.6, 1.8, 2.0],          # jump_multiplier
    [0.010, 0.013, 0.015, 0.018],        # skill_boldness_coefficient
))

for decay, jump, coef in grid:
    cfg = SimConfig(decay_rate=decay, jump_multiplier=jump,
                    skill_boldness_coefficient=coef, n_cycles=100, n_runs=10)
    runs = [run_simulation(SimConfig(**{**cfg.__dict__, 'seed': 42+i}))[0]
            for i in range(cfg.n_runs)]
    avg = average_metrics(runs)
    sim_completion = mean(m.completion_rate for m in avg)
    rmse = math.sqrt((sim_completion - target_completion) ** 2)
    if rmse < best_rmse:
        best_rmse = rmse
        best_params = {'decay_rate': decay, 'jump_multiplier': jump,
                       'skill_boldness_coefficient': coef,
                       'calibrated_at': now(), 'source': 'otherness-metrics',
                       'n_batches': len(real_metrics), 'rmse': best_rmse}

json.dump(best_params, open('scripts/sim-params.json', 'w'), indent=2)
print(f"Calibrated: RMSE={best_rmse:.4f} params={best_params}")
```

### Phase 1b: SM integration

```markdown
## 4d. Simulation calibration (every 10 batches)

```bash
BATCH_COUNT=$(python3 -c "
import re
with open('docs/aide/metrics.md') as f:
    rows = re.findall(r'^\|\s*\d{4}-\d{2}-\d{2}', f.read(), re.MULTILINE)
    print(len(rows))
")

if [ $((BATCH_COUNT % 10)) -eq 0 ] && [ "$BATCH_COUNT" -gt 0 ]; then
    echo "[SM] Running simulation calibration (batch $BATCH_COUNT)..."
    python3 scripts/calibrate.py
    # Commit sim-params.json to _state
    # Check arch_convergence signal
    ARCH_CONV=$(python3 -c "
import json
try:
    r = json.load(open('scripts/sim-params.json'))
    print(r.get('mean_arch_convergence', 0))
except: print(0)
")
    if python3 -c "exit(0 if float('$ARCH_CONV') < 0.7 else 1)"; then
        echo "[SM] Arch convergence normal: $ARCH_CONV"
    else
        gh issue create --repo $REPO \
          --title "[NEEDS HUMAN] Architectural monoculture detected (arch_convergence=$ARCH_CONV)" \
          --label "needs-human,area/agent-loop" \
          --body "Simulation calibration detected mean_arch_convergence > 0.7 for this project.
The agent loop is showing signs of architectural monoculture — agents are proposing
items of the same structural type repeatedly.

Consider: run /otherness.learn to inject novel patterns, or run /otherness.vibe-vision
to introduce new architectural direction.

Simulation params: \$(cat scripts/sim-params.json)"
    fi
fi
```
```

### What calibrated parameters mean in practice

The calibrated `sim-params.json` does not directly change agent behavior today.
It changes two things:

1. **Trigger thresholds**: the frequency of `/otherness.learn` triggers, the
   `boldness_floor` for human inflection points, the `anomaly_threshold` — all
   read from `sim-params.json` rather than hardcoded defaults.

2. **The arch-convergence alarm**: when mean_arch_convergence exceeds the
   calibrated threshold, the SM raises a needs-human issue. The calibrated
   threshold is project-specific — a project with naturally high boldness
   needs a different alarm level than one with consistently low boldness.

### The propagation chain

```
otherness batch history (metrics.md)
    ↓ calibrate.py
scripts/sim-params.json (calibrated parameters)
    ↓ committed to _state branch
    ↓ git -C ~/.otherness pull on every project startup
Every project inherits calibrated parameters
    ↓ SM reads sim-params.json for trigger thresholds
    ↓ after ≥10 project batches: re-calibrate against project-specific data
Project-specific sim-params.json (in _state)
    ↓ overrides global defaults
Project loop calibrated to its own reality
```
