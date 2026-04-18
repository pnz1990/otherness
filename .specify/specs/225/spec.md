# Spec: scripts/simulate.py — multi-agent boldness simulation (#225)

## Design reference
- **Design doc**: `docs/design/10-multi-agent-simulation.md`
- **Section**: Implementation spec O1–O6
- **Implements**: 🔲 Implement scripts/simulate.py (🔲→✅)

## Zone 1 — Obligations

**O1** — Pure Python 3.8+ stdlib. No external dependencies.
Falsifiable: `python3 scripts/simulate.py` runs on a clean Python 3.8 install.

**O2** — Single file. `python3 scripts/simulate.py` runs with defaults and prints summary.
Falsifiable: running with no args produces the summary output format from the design doc.

**O3** — Outputs CSV to stdout or file, plus ASCII summary.
Falsifiable: output contains `cycle,n_agents,vision_boldness,...` header line.

**O4** — `--falsify force1/force2/force3` mode removes each force independently.
Falsifiable: `--falsify force3` produces lower final boldness than baseline.

**O5** — Optimal N search runs N=1,2,4,8,16 and reports best N.
Falsifiable: summary contains "Optimal N search" section with 5 rows.

**O6** — Deterministic given same seed.
Falsifiable: two runs with `--seed 42` produce identical CSV output.

## Zone 2 — Implementer's judgment
- Use dataclasses for state (Python 3.7+)
- ASCII chart via simple character plotting (no matplotlib required)
- Default: 4 agents, 200 cycles, 50 runs

## Zone 3 — Scoped out
- matplotlib visualization (optional enhancement, not required for O1)
- Calibration against real metrics.md data (that is a separate Future item)
