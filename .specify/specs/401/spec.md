# Spec: SM §4e — per-5-cycle calibration update + sim-prediction.json write

## Design reference
- **Design doc**: `docs/design/23-simulation-as-anchor.md`
- **Section**: `§ Future`
- **Implements**: `SM §4e`: read `metrics.md`, calibrate `simulate.py` parameters against real data, write `.otherness/sim-prediction.json` — runs every 5 SM cycles (🔲 → ✅)

## Zone 1 — Obligations

**O1** — Every 5 SM cycles, §4e reads `docs/aide/metrics.md`, runs calibration via `scripts/calibrate.py`, and writes `.otherness/sim-prediction.json` to the `_state` branch.

Violation: §4e only checks divergence and does NOT run calibration every 5 cycles.

**O2** — The calibration in §4e uses the same `calibrate.py` invocation as §4d, but with a `--quick` or similar flag (or with the same full calibration). The result updates `scripts/sim-params.json` (local file, committed separately or used in-memory) and writes `sim-prediction.json` to `_state`.

Violation: §4e runs calibration but does not update `sim-prediction.json` on `_state`.

**O3** — If `scripts/calibrate.py` is not available or metrics has fewer than 5 rows, §4e skips gracefully with a log message. It does NOT block SM execution.

Violation: §4e exits with an error when calibrate.py is missing.

**O4** — Calibration frequency is configurable via `otherness-config.yaml` `simulation.calibration_cycles` field (default: 5). If the field is absent, default to 5.

Violation: hardcoded cycle count with no config lookup.

**O5** — §4e calibration is an addition to, not a replacement for, the existing divergence detection logic. Both the calibration (every 5 cycles) and the divergence check (every cycle) run in §4e.

Violation: existing divergence check is removed.

## Zone 2 — Implementer's judgment

- Whether to call `calibrate.py` as a subprocess or import it: subprocess is safer (no side-effects on current process).
- Whether §4e writes its own `sim-prediction.json` or defers to §4d: §4e writes it if sm_cycle % 5 == 0. §4d still writes it at sm_cycle % 10 == 0 (redundant at cycle 10, but idempotent).
- Seed: use same fixed seed as calibrate.py default (O2 in design doc).
- If sm_cycle is not available (env var missing): skip calibration, run divergence check only.

## Zone 3 — Scoped out

- Changing §4d calibration frequency (stays at every 10 cycles)
- Real-time streaming calibration
- Cross-project parameter sharing in §4e (handled separately by sim-defaults.json)
- otherness-config.yaml `simulation.calibration_cycles` field (that is issue #408 — a separate item)
