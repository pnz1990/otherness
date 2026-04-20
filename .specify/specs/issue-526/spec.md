# Spec: First persona journey: Operator

**Item**: issue-526
**Branch**: feat/issue-526

## Design reference

- **Design doc**: `docs/design/26-anchor-kro-ui.md`
- **Section**: `§ Future — First persona journey: Operator`
- **Implements**: First persona journey: Operator — deploy RGD via designer, verify instances appear, check health indicators (🔲 → ✅)

---

## Context

Journey 071 (`test/e2e/journeys/071-operator-persona-journey.spec.ts`) was already merged to `pnz1990/kro-ui` and covers the Operator persona end-to-end flow. The design doc `docs/design/26-anchor-kro-ui.md` still shows this as 🔲 Future — a documentation gap.

This item corrects the design doc to reflect the shipped implementation.

---

## Zone 1 — Obligations

**O1** — `docs/design/26-anchor-kro-ui.md` must move "First persona journey: Operator" from 🔲 Future to ✅ Present with a reference to the journey file.

Violation: Design doc still shows 🔲 after this PR.

---

## Zone 2 — Implementer's judgment

- No code changes needed. Journey 071 is already implemented and passing.
- Risk tier: LOW (docs/design only).

---

## Zone 3 — Scoped out

- Implementing the other persona journeys (Developer, SRE, Kro contributor) — separate items
- Modifying journey 071 content — it's already correct
