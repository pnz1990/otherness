# 12: Perpetual Autonomous Validation

> Status: Active | Created: 2026-04-18
> Applies to: all projects managed by otherness

---

## What this does

Makes `/otherness.run` perpetually self-sustaining — not by running forever,
but by always knowing what to do next and always knowing whether it is on track,
without requiring the human to define either.

The system derives its own validation criteria from its own design docs and batch
history. The simulation — calibrated to real observed behavior — predicts what
healthy progress looks like at the current stage. The PM phase measures reality
against that prediction. If the prediction holds: continue. If it doesn't: the
system knows before the human does, and surfaces the specific signal.

The human re-enters only when the system genuinely cannot determine its own health
or direction without external judgment. That is the only remaining human role in
steady-state operation.

This propagates to every project through `~/.otherness` without instruction.
A project running otherness long enough will accumulate the design docs, simulation
history, and batch metrics needed to derive its own validation criteria. At that
point it does not need the human to define "done" — it derives "done" from its own
design docs and measures its distance using its own simulation.

---

## The gap this closes

`definition-of-done.md` is a static document written at project inception. The PM
phase validates against it. But as the product evolves, "done" evolves. A system
validating against a static snapshot is not validating — it is pattern-matching
against a fixed expectation that may no longer reflect the current vision.

The simulation knows what healthy progress looks like for a project at its current
stage. That is the dynamic anchor. Static definition-of-done is one human input to
validation. Simulation-derived health score is the continuous machine input. Both
together produce a validation signal that evolves with the product.

---

## Present (✅)

- ✅ Perpetual loop trigger — standalone.md THE LOOP section now documents standby behavior explicitly: empty queue + GREEN health → standby (sleep 60 && continue), not exit; new items from vibe-vision or PM §5h restart the active loop automatically (PR #280, 2026-04-18)

## Future (🔲)

- 🔲 PM §5g: simulation health score — run simulate.py with calibrated sim-params.json,
  compare completion_rate and arch_convergence against real batch data, produce a
  three-state signal: GREEN (on track), AMBER (drift detected, self-correct),
  RED (genuine stall, needs human)
- 🔲 PM self-correction on AMBER — when health score is AMBER: automatically queue
  one `/otherness.learn` cycle targeting the area of lowest boldness; do not escalate
  to human yet
- 🔲 Dynamic definition-of-done — PM §5b reads definition-of-done.md journeys AND
  derives additional validation criteria from the current design doc Present/Future
  ratio; a project where 80%+ of Future items are unstarted is not "done" regardless
  of static journey pass/fail
- 🔲 Perpetual loop trigger — after each batch completes, standalone.md checks whether
  any Future items were generated this batch (from vibe-vision or self-generating
  vision loop); if yes, restart automatically without human intervention; if no new
  items and all journeys GREEN: enter standby mode (check daily, restart on new items)
- 🔲 Self-generating validation criteria — PM phase derives new journey-level
  acceptance tests from shipped design doc Present items; each ✅ Present item that
  doesn't have a corresponding PM journey becomes a candidate journey; surfaced to
  human for one-time confirmation, then permanent

---

## Zone 1 — Obligations

**O1 — The health score is derived, not declared.**
The PM health score is not a flag a human sets. It is computed from simulation
output compared against real batch data. The computation is deterministic and
reproducible. A human can inspect it but not override it.

**O2 — GREEN means proceed without human.**
When the health score is GREEN, the session completes, metrics are written, and
the next session starts (if perpetual mode is active) without any human action.
The human is not notified of GREEN batches unless they explicitly request it.

**O3 — AMBER means self-correct, not escalate.**
AMBER signals internal drift — the system is heading toward a local maximum or
architectural monoculture. The system corrects itself (learn cycle, boldness
adjustment) before surfacing to the human. Only if AMBER persists for 3
consecutive batches does it escalate to RED.

**O4 — RED means escalate exactly once.**
When health score reaches RED, the SM phase opens one `[NEEDS HUMAN]` issue
with the specific signal: which metric is out of range, what the simulation
predicted, what was observed, what the system tried. The human sees one clear
issue, not a stream of noise.

**O5 — Other projects inherit without instruction.**
The perpetual validation mechanism lives in `agents/phases/pm.md` and
`agents/phases/sm.md`. It propagates to every project on next `git pull`.
Projects do not need to opt in or be configured. The mechanism detects its
own prerequisites (sim-params.json, batch history) and activates when they
exist.

**O6 — Standby mode is not failure.**
A project that has completed all current Future items and all journeys pass is
in standby. This is correct behavior. The system checks daily for new Future
items (from vibe-vision sessions or self-generating proposals). When found, it
restarts. Standby is the system waiting for the next direction signal.

---

## Zone 2 — Implementer's judgment

- GREEN/AMBER/RED thresholds: GREEN = completion_rate within 20% of simulated,
  arch_convergence < 0.5. AMBER = completion_rate within 40% or arch_convergence
  0.5–0.7. RED = completion_rate < 60% of simulated or arch_convergence > 0.7
  for 3 batches.
- Perpetual loop implementation: `run-forever.sh` already exists in scripts/.
  The trigger is whether to auto-call it from standalone.md STOP CONDITION.
  Currently STOP CONDITION is "all journeys pass." Under perpetual mode it
  becomes "all journeys pass AND no unstarted Future items AND health score GREEN."
- Per-project activation: perpetual mode activates automatically when sim-params.json
  exists (calibrated against ≥10 batches). Projects without calibration data run in
  single-batch mode (current behavior).
- Self-generating validation criteria: PM derives candidates from Present items.
  Confirmation is async — opens a GitHub issue "proposed journey: X — reply 'add' to
  confirm." Human can ignore; issue auto-closes after 7 days without response and the
  journey is added anyway. This is the only place the human is asked for optional input.

---

## Zone 3 — Scoped out

- Perpetual mode on projects with no design docs — requires at least one design doc
  with Future items to be meaningful. Projects without design docs get the
  self-seeding gate (design doc 04) instead.
- Automatic code deployment or releases triggered by GREEN health score — delivery
  is still a human gate. The system ships PRs; humans decide when to release.
- Cross-project health aggregation in perpetual mode — fleet-level perpetual
  validation is a separate concern (design doc 13 if warranted).

---

## Design

### The health score computation

```python
def compute_health_score(sim_params, real_metrics, current_sim_result):
    """
    Returns: 'GREEN', 'AMBER', or 'RED'
    """
    if not sim_params or not real_metrics:
        return 'GREEN'  # not enough data — assume healthy, don't block

    target_completion = sim_params.get('observed_completion_rate', 1.0)
    real_completion = real_metrics[-1].get('prs', 0) / max(real_metrics[-1].get('items', 1), 1)
    arch_conv = current_sim_result.get('mean_arch_convergence', 0.0)

    completion_ratio = real_completion / max(target_completion, 0.01)
    
    if completion_ratio >= 0.8 and arch_conv < 0.5:
        return 'GREEN'
    elif completion_ratio >= 0.6 and arch_conv < 0.7:
        return 'AMBER'
    else:
        return 'RED'
```

### PM §5g: simulation health score (addition to pm.md)

```bash
echo "[PM §5g] Computing simulation health score..."

# Load calibrated params
SIM_PARAMS=$(cat scripts/sim-params.json 2>/dev/null || echo "{}")

# Run quick simulation with calibrated params
HEALTH=$(python3 - <<'EOF'
import json, sys, os
sys.path.insert(0, '.')

try:
    params = json.loads(os.environ.get('SIM_PARAMS', '{}'))
    from scripts.simulate import SimConfig, run_simulation
    cfg = SimConfig(
        n_agents=4, n_cycles=50, seed=42,
        decay_rate=params.get('decay_rate', 0.92),
        jump_multiplier=params.get('jump_multiplier', 1.6),
        skill_boldness_coefficient=params.get('skill_boldness_coefficient', 0.015),
    )
    m, s = run_simulation(cfg)
    arch_conv = m[-1].mean_arch_convergence
    completion = m[-1].completion_rate

    # Compare against real metrics
    import re
    rows = []
    try:
        content = open('docs/aide/metrics.md').read()
        for row in re.finditer(
            r'\|\s*\d{4}-\d{2}-\d{2}\s*\|\s*\d+\s*\|\s*(\d+)\s*\|\s*\d+\s*\|\s*\d+\s*\|\s*\d+\s*\|\s*(\d+)\s*\|',
            content):
            prs, items = int(row.group(1)), int(row.group(2))
            if items > 0:
                rows.append(prs / items)
    except: pass

    real_completion = sum(rows[-3:]) / len(rows[-3:]) if rows else 1.0
    target = params.get('observed_completion_rate', 1.0)
    ratio = real_completion / max(target, 0.01)

    if ratio >= 0.8 and arch_conv < 0.5:
        print('GREEN')
    elif ratio >= 0.6 and arch_conv < 0.7:
        print('AMBER')
    else:
        print('RED')

except Exception as e:
    print('GREEN')  # fail open — don't block on missing data
EOF
)

echo "[PM §5g] Health score: $HEALTH"

case "$HEALTH" in
  GREEN)
    echo "[PM §5g] ✅ System is on track."
    ;;
  AMBER)
    echo "[PM §5g] ⚠ Drift detected — self-correcting."
    # Queue one /otherness.learn cycle
    # (implementation: open a learn issue or trigger directly)
    ;;
  RED)
    # Escalate — but only if not already escalated this batch
    EXISTING=$(gh issue list --repo "$REPO" --state open \
      --label "needs-human" \
      --json title \
      --jq '[.[] | select(.title | contains("health score RED"))] | length' 2>/dev/null || echo "0")
    if [ "${EXISTING:-0}" -eq 0 ]; then
      gh issue create --repo "$REPO" \
        --title "[NEEDS HUMAN] System health score RED — genuine stall detected" \
        --label "needs-human,priority/high" \
        --body "## Health score: RED

The PM simulation health score has reached RED — real completion rate is
significantly below the simulated baseline, and/or architectural convergence
is above the threshold.

**What the simulation predicted:** completion_rate ≈ $(echo $SIM_PARAMS | python3 -c "import sys,json; p=json.load(sys.stdin); print(round(p.get('observed_completion_rate',1.0),2))" 2>/dev/null)
**What was observed:** see the last 3 rows of docs/aide/metrics.md

## Recommended actions

1. Review the last 3 batches: are items genuinely shipping?
2. Check if the queue has items that are blocked or mis-specified
3. Run /otherness.vibe-vision if the vision needs refreshing
4. Run /otherness.learn if the skills library needs new patterns

The system will not self-escalate again until this issue is closed." 2>/dev/null
    fi
    ;;
esac
```

### The perpetual loop (standalone.md STOP CONDITION extension)

```bash
# After all phases complete — check perpetual mode conditions
FUTURE_ITEMS=$(python3 -c "
import re, os
count = 0
if os.path.isdir('docs/design'):
    for fname in os.listdir('docs/design'):
        if fname.endswith('.md'):
            content = open(f'docs/design/{fname}').read()
            m = re.search(r'^## Future.*?\n(.*?)(?=^## |\Z)', content, re.MULTILINE|re.DOTALL)
            if m: count += len(re.findall(r'^- 🔲 (?!.*🚫)', m.group(1), re.MULTILINE))
print(count)
" 2>/dev/null || echo "0")

SIM_PARAMS_EXISTS=$([ -f scripts/sim-params.json ] && echo "true" || echo "false")

if [ "$FUTURE_ITEMS" -gt 0 ] && [ "$SIM_PARAMS_EXISTS" = "true" ] && [ "$HEALTH" != "RED" ]; then
    echo "[STANDALONE] Perpetual mode: $FUTURE_ITEMS Future items remain, health=$HEALTH — continuing."
    # Loop: the next invocation of standalone.md picks up from here
else
    echo "[STANDALONE] STOP: future_items=$FUTURE_ITEMS sim_calibrated=$SIM_PARAMS_EXISTS health=$HEALTH"
fi
```
