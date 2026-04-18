# Spec: architectural convergence variable (#230)

## Design reference
- **Design doc**: `docs/design/10-multi-agent-simulation.md`
- **Section**: `§ Future — architectural convergence variable`
- **Implements**: 🔲 Add architectural convergence variable (🔲→✅)

## Zone 1 — Obligations

**O1** — `AgentState` has `arch_convergence: float` (0.0=diverse, 1.0=converged).

Falsifiable: `grep "arch_convergence" scripts/simulate.py` → match in AgentState.

**O2** — `arch_convergence` increases when agent ships items of the same structural
type as the last N proposals (same skill requirements pattern); decreases on Type B failure.

**O3** — `CycleMetrics` tracks `mean_arch_convergence` per cycle.

**O4** — `--learn-interval` injection resets the target agent's `arch_convergence` to 0.
Falsifiable: after injection, target.arch_convergence == 0.0.

**O5** — Summary output includes mean arch_convergence at final cycle.

**O6** — At N=8, mean arch_convergence is measurably higher than N=2 at same cycles.
Falsifiable: run N=8 vs N=2, arch_convergence(N=8) > arch_convergence(N=2).

## Zone 2 — Implementer's judgment
- "Same structural type" = item skill_requirements overlap > 80% with previous item
- Convergence rate: +0.05 per same-type ship, -0.20 on Type B
- Clamp to [0.0, 1.0]
- Track previous item's skill_requirements per agent

## Zone 3 — Scoped out
- Divergence signal triggering human inflection (that connects to #207 D4 intake)
- Cross-agent architectural convergence metric (mean is sufficient)
