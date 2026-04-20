# Spec: Scenarios 19-21 — real-world complexity

## Design reference
- **Design doc**: `docs/design/25-anchor-kardinal-promoter.md`
- **Section**: `§ Future`
- **Implements**: Scenarios 19-21: real-world complexity (🔲 → ✅)

---

## Zone 1 — Obligations

**O1 — Scenarios 19, 20, 21 added to kardinal-promoter PDCA.**
- S19: 3+ concurrent bundles created, bundle list accessible after multi-create
- S20: Bundle created with invalid image (controller handles readiness)
- S21: `kardinal explain` returns pipeline state + `kardinal rollback` executes
Violation: any scenario missing from PDCA after PR #874 merge.

**O2 — Design doc 25 marks item ✅ Present.**

---

## Zone 3 — Scoped out

- Verifying exact supersession ordering across 3+ bundles (timing-dependent)
- Verifying readiness failure propagates to PromotionStep (requires cluster timing)
