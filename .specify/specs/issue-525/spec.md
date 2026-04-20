# Spec: Journey depth — error + empty state for Tier 1 journeys (001-007)

**Item**: issue-525
**Branch**: feat/issue-525

## Design reference

- **Design doc**: `docs/design/26-anchor-kro-ui.md`
- **Section**: `§ Future — Journey depth`
- **Implements**: Journey depth: add error + empty state to all Tier 1 journeys (001-007) (🔲 → ✅)

---

## Zone 1 — Obligations

**O1** — Journeys 006 and 007 (the two Tier 1 journeys with 0 error/empty state coverage) must each gain at least one error state test and one empty state test.

Violation: Either journey 006 or 007 has 0 new error/empty state steps after this PR.

**O2** — New error state steps must assert: page does not show `[object Object]`, `undefined`, or a blank screen. They must NOT require inducing real cluster failures.

Violation: A new step tries to kill the server or apply a broken YAML to test error states.

**O3** — New empty state steps must assert correct rendering when the relevant feature input is absent (no CEL expressions, no secondary context). They must use `test.skip` when prerequisite fixtures aren't ready.

Violation: Empty state step crashes when fixture is not present instead of skipping.

---

## Zone 2 — Implementer's judgment

- Whether to add steps to existing files or create new journey files: add to existing files (same file = same test context, no new infrastructure).
- Which journeys to prioritize: 006 and 007 (0 coverage). 001-005 have ≥4 refs already.
- Step numbering: continue from last existing step (010/011 for 006, 008/009 for 007).

---

## Zone 3 — Scoped out

- Adding error/empty state to journeys 008-070 (scope creep — the item says 001-007)
- Inducing real server failures for error testing
- Accessibility axe assertions (separate issue-527)
