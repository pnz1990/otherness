# Spec: SM §4d simulation calibration (#239)

## Design reference
- **Design doc**: `docs/design/11-simulation-feedback-loop.md`
- **Section**: Phase 1b + Phase 2b
- **Implements**: 🔲 Phase 1b: SM §4d (🔲→✅)

## Zone 1 — Obligations

**O1** — `sm.md` contains a `## 4d. Simulation calibration` section that runs
`scripts/calibrate.py` every 10 batches.

Falsifiable: `grep "4d.*[Ss]imulation\|calibrate" agents/phases/sm.md` → match.

**O2** — The section reads `sm_cycle_count` from state.json to determine frequency.

**O3** — If `scripts/sim-params.json` arch_convergence signal > 0.7 (when present),
SM opens a `[NEEDS HUMAN]` issue with label `needs-human`.

**O4** — sm.md is CRITICAL tier — PR labeled needs-human, AUTONOMOUS_MODE=true
self-review must pass all 5 checks.

**O5** — Design doc 11 Present section updated.

## Zone 2 — Implementer's judgment
- calibrate.py takes ~60s with default settings — sm.md calls it with
  `--runs 3 --cycles 50` for speed (acceptable precision for periodic calibration)
- arch_convergence threshold read from sim-params.json if present, else default 0.7

## Zone 3 — Scoped out
- Per-project calibration (Phase 2a) — deferred; this item covers Phase 1b only
- Automatic trigger of /otherness.learn on arch_convergence signal — O4 says
  needs-human only; no autonomous action
