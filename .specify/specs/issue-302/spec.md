# Spec: PM §5j Journey 2 AMBER/RED health escalation (issue-302)

## Design reference
- **Design doc**: `docs/design/16-journey-2-reference-project.md`
- **Section**: `§ Future`
- **Implements**: PM §5g: Journey 2 failure maps to AMBER after 24h, RED after 72h (🔲 → ✅)

## Context

PM §5j currently has `[AI-STEP]` comments for the full reference project health check.
This spec implements the entire §5j as executable code, including the AMBER/RED escalation
for PM §5g.

## Zone 1 — Obligations

**O1 — PM §5j runs when PM_CYCLE % N_PM_CYCLES == 0.**
Existing gate preserved.

**O2 — Reads reference project from otherness-config.yaml monitor.projects.**
First non-otherness entry. Graceful skip if not found.

**O3 — Checks _state branch age for reference project.**
Uses GitHub API. Graceful skip if no _state branch.

**O4 — Opens [NEEDS HUMAN] issue when stall > 72h.**
Duplicate-suppressed. Only one issue per stall.

**O5 — Sets JOURNEY2_HEALTH variable:**
- AGE_H <= 72: JOURNEY2_HEALTH="OK"
- AGE_H > 72 and <= 168: JOURNEY2_HEALTH="AMBER"
- AGE_H > 168: JOURNEY2_HEALTH="RED"

**O6 — PM §5g health signal respects JOURNEY2_HEALTH:**
- JOURNEY2_HEALTH="RED" forces overall HEALTH to RED
- JOURNEY2_HEALTH="AMBER" elevates GREEN to AMBER

## Zone 2 — Implementer's judgment

- Use bash for the outer flow, python3 for date math
- JOURNEY2_HEALTH is set as a bash variable before §5g reads it
- Design doc says 24h → AMBER, but the actual §5j check runs only every N_PM_CYCLES.
  Since AMBER threshold is 24h (which could be 1-2 PM cycles), use 24h boundary.

## Zone 3 — Scoped out

- Automated recovery (restart otherness on ref project) — human action required
- Multi-project journey 2 tracking
