# Spec: Journey depth — error state coverage for journeys 063-070

## Design reference
- **Design doc**: `docs/design/26-anchor-kro-ui.md`
- **Section**: `§ Future`
- **Implements**: Journey depth: add error state coverage to journeys 063-070 (kro v0.9.1 features) (🔲 → ✅)

---

## Zone 1 — Obligations

**O1 — Error state test added to journeys 063, 064, 065, 066.**
Each of these 4 journey files must have an "Error resilience" describe block that:
(a) mocks the primary API to return 503, (b) navigates to the page, (c) asserts no raw error strings,
(d) asserts layout renders.
Violation: any of these 4 journeys missing the error block after merge.

**O2 — Design doc 26 marks item as ✅ Present.**
The 🔲 Future item for journey depth coverage must be moved to ✅ Present.
Violation: 🔲 marker still present in design doc 26 after merge.

**O3 — No test anti-patterns introduced.**
Tests must follow kro-ui §XIV E2E discipline: no waitForTimeout, no HTTP status assertions for SPA routes.
page.route() mocking is explicitly permitted.
Violation: test uses waitForTimeout or HTTP status check for page existence.

---

## Zone 2 — Implementer's judgment

- Journeys 067, 068 do not exist in the current test suite — skip them
- Journeys 069, 070 already have error-aware tests — skip them
- Pattern: page.route() 503 mock + layout chrome assertion

---

## Zone 3 — Scoped out

- PR to kro-ui is tracked by reference (pnz1990/kro-ui#504)
- Adding error tests to journeys 069, 070 (already error-aware)
- Running E2E tests locally (they run in kro-ui CI)
