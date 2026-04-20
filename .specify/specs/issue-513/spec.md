# Spec: Infrastructure reliability — S1 reconcile wait + ArgoCD sync timeout

## Design reference
- **Design doc**: `docs/design/25-anchor-kardinal-promoter.md`
- **Section**: `§ Future`
- **Implements**: Infrastructure reliability: retry logic for S1 reconcile wait + ArgoCD sync timeout increase (🔲 → ✅)

---

## Zone 1 — Obligations

**O1 — S1 reconcile wait is increased from 3min to ≥5min.**
The S1 scenario wait loop in `.github/workflows/pdca.yml` must have at least 20 iterations
at 15s each (5 minutes total), up from 12 iterations (3 minutes).
Violation: `seq 1 12` still present in S1 wait loop after merge.

**O2 — Change is annotated with rationale.**
A comment explains WHY the wait was increased (not just what changed).
Violation: no comment explaining the reliability rationale.

**O3 — Design doc 25 marks item as ✅ Present.**
The 🔲 Future item must be moved to ✅ Present.
Violation: 🔲 marker still present after merge.

---

## Zone 2 — Implementer's judgment

- 20 iterations × 15s = 5 minutes (reasonable for a CI runner)
- ArgoCD sync timeout increase: deferred — no ArgoCD integration in current PDCA
- Retry logic implemented as longer polling loop, not re-run of the job step

---

## Zone 3 — Scoped out

- ArgoCD sync timeout (no ArgoCD in current PDCA)
- kind cluster creation retry (separate failure mode, requires different fix)
- Pre-pulling ghcr.io images (separate reliability concern)
