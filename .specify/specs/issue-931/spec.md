# Spec: Onboarding generates docs/design/ stubs with real Future items

## Design reference
- **Design doc**: `docs/design/32-stage-3-onboarding-quality.md`
- **Section**: `§ Future`
- **Implements**: Onboarding generates `docs/design/` stubs from real codebase analysis (🔲 → ✅)

---

## Zone 1 — Obligations (falsifiable)

**O1** — STEP 4b in `agents/onboard.md` must explicitly require that each `docs/design/` stub
contains at least 3 `🔲 Future` items derived from codebase analysis
(not left empty or with placeholder text).

_Violation_: STEP 4b instruction says "leave empty" or allows empty Future sections in generated stubs.

**O2** — STEP 4b must include a post-generation quality gate that verifies at least 3 design
doc stubs exist in `docs/design/` AND each stub has at least 1 `🔲 Future` item.
If the gate fails: the agent must retry the stub generation before proceeding to STEP 5.

_Violation_: Onboarding proceeds to STEP 5 when `docs/design/` has fewer than 3 stubs,
or when stubs exist but all have empty Future sections.

**O3** — The instruction must state that Future items are derived from real codebase gaps:
missing tests, missing error handling, incomplete features, known TODOs in code, or
areas clearly not implemented yet. Future items must not be invented without codebase evidence.

_Violation_: Future items are generic placeholders ("Add more features", "Improve performance")
with no codebase evidence cited.

---

## Zone 2 — Implementer's judgment

- How many Future items per stub (minimum 3 total across all stubs, or minimum 1 per stub with ≥3 stubs) is implementer's choice; minimum 1 per stub with ≥3 stubs is preferred.
- Whether the quality gate uses bash counting or a [AI-STEP] check is implementer's choice.
- The retry instruction may be "re-read the codebase and add specific gaps" — exact wording is implementer's choice.

---

## Zone 3 — Scoped out

- Automatically generating GitHub issues from the stub Future items at onboard time (separate design doc item already shipped — PR #709)
- Validating Future item quality (whether items are truly specific) — too hard to automate
- Generating more than 5 stubs (scope limit: 3-5 stubs is enough for first batch)
