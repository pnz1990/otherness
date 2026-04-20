# Spec: PM §5g Simulation Health Score + Self-correction

## Design reference
- **Design doc**: `docs/design/12-perpetual-validation.md`
- **Section**: `§ Present — PM §5g simulation health score; PM self-correction on AMBER`
- **Implements**: Replace [AI-STEP] stubs with executable code (design doc already ✅ Present but code was missing)

---

## Zone 1 — Obligations (falsifiable)

**O1** — `pm.md §5g` must contain executable python3 (not `[AI-STEP]` comments) that: reads sim-results.json from _state, reads metrics.md, computes GREEN/AMBER/RED signal. Violation: §5g contains only comments.

**O2** — Graceful fallback: if sim-results.json absent from _state OR metrics_rows < 3: print skip message and sys.exit(0). Violation: exception propagates.

**O3** — GREEN path: no action taken. AMBER path: posts comment to REPORT_ISSUE with reason. RED path: opens [NEEDS HUMAN] issue (duplicate-suppressed). Violation: wrong action for given health.

**O4** — AMBER path checks if learn branch already exists before creating (idempotent). Violation: tries to create existing branch.

**O5** — validate.sh and lint.sh pass. Violation: non-zero exit.

---

## Zone 2 — Implementer's judgment

- arch_convergence read from sim-results.json params dict or top-level (flexible schema).
- AMBER path defers actual learn cycle to SM §4d-learn (already implemented); PM §5g only signals.

---

## Zone 3 — Scoped out

- Running the learn cycle inline from PM (SM §4d-learn handles this)
- Storing health signal history in _state
