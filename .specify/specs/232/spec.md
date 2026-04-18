# Spec: diminishing returns on skill growth (#232)

## Design reference
- **Design doc**: `docs/design/10-multi-agent-simulation.md`
- **Section**: `§ Model gaps — ceiling artifact` + `§ Future`
- **Implements**: 🔲 Fix skill growth ceiling (🔲→✅)

## Zone 1 — Obligations

**O1** — Skill growth uses `log(1 + skill_count)` not linear `skill_count`.

Falsifiable: `grep "log(1 + " scripts/simulate.py` → match.

**O2** — Without Force 3, the system no longer trivially reaches 0.99 boldness.
A system with diminishing returns should plateau below 0.9 without Type B events.

Falsifiable: `python3 scripts/simulate.py --falsify force3 --cycles 100 --runs 5`
final boldness < 0.85 (down from 0.9985 with linear growth).

**O3** — Baseline (all forces) consistently outperforms no-Force-3 scenario —
confirming Type B events now meaningfully drive boldness, not just accelerate it.

Falsifiable: `baseline_final > no_force3_final` in same seed/cycles configuration.

**O4** — Design doc 10 Present section updated.

## Zone 2 — Implementer's judgment
- `import math` already available in stdlib
- Apply to Force 2 lift calculation only; Force 3 jump is unchanged

## Zone 3 — Scoped out
- Re-running all prior experiments (design doc has the results with linear model labeled as such)
