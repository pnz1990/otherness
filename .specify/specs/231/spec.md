# Spec: external signal injection for /otherness.learn (#231)

## Design reference
- **Design doc**: `docs/design/10-multi-agent-simulation.md`
- **Section**: `§ Future — external signal injection`
- **Implements**: 🔲 Add external signal injection event (🔲→✅)

## Zone 1 — Obligations

**O1** — `--learn-interval N` parameter: every N cycles, one random agent receives
an external signal resetting architectural divergence and injecting a foreign skill.

Falsifiable: `python3 scripts/simulate.py --learn-interval 20` runs without error.

**O2** — The injected skill has an id outside the normal range (flagged as "foreign").
This makes external vs internal skills distinguishable in the CSV output.

**O3** — The simulation summary reports total external signals fired.

**O4** — Default: `learn_interval=0` (disabled). No behavior change without the flag.

Falsifiable: existing tests pass unchanged.

## Zone 2 — Implementer's judgment
- Foreign skill IDs use a separate counter starting at 10000
- The signal fires for one agent chosen randomly each interval

## Zone 3 — Scoped out
- Modeling the quality of the external signal (it's always "genuinely different")
- Multiple agents receiving signals in the same cycle
