# Spec: metrics.md schema — arch_convergence and sim_floor_delta columns

## Design reference
- **Design doc**: `docs/design/35-quality-of-output-gaps.md`
- **Section**: `§ Future`
- **Implements**: `docs/aide/metrics.md` schema: add `arch_convergence` and `sim_floor_delta` columns (🔲 → ✅)

---

## Zone 1 — Obligations

**O1 — `arch_convergence` and `sim_floor_delta` are added to the Metric Definitions table.**
With correct definitions and target directions.

**O2 — The Batch Log table header is updated** to include both new columns.

**O3 — SM §4b [AI-STEP] comment is updated** to mention including these columns when writing new rows.

---

## Zone 2 — Implementer's judgment

- `arch_convergence`: from `scripts/sim-params.json` `arch_convergence_score` field, or 0.0 if missing.
- `sim_floor_delta`: `actual_prs_merged - predicted_floor`, where predicted_floor comes from `scripts/sim-params.json`.
- Historical rows are not modified.

---

## Zone 3 — Scoped out

- Actually computing arch_convergence in SM §4b (requires calibration data — separate §4d)
- Retroactively backfilling historical rows
