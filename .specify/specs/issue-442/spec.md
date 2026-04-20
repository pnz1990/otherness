# Spec: AGENTS.md template Anchor section in standalone.md (issue-442)

## Design reference
- **Design doc**: `docs/design/24-project-anchor-framework.md`
- **Section**: `§ Future`
- **Implements**: `standalone.md` AGENTS.md template: add `## Anchor` section with standard structure (🔲 → ✅)

## Context

The `## Anchor` template for AGENTS.md is already present in `onboarding-new-project.md`
(PR #413). The SM §4g-anchor reads `## Anchor` from AGENTS.md directly. The template
for this section doesn't need to be in standalone.md separately — onboarding-new-project.md
is the canonical source for AGENTS.md templates.

This item is resolved by design doc update: the Future item is moved to Present with
clarification that onboarding-new-project.md is the canonical template source.

---

## Zone 1 — Obligations

**O1 — Design doc 24 updated: standalone.md anchor template item moved from 🔲 Future to ✅ Present.**
Clarifies that `onboarding-new-project.md` is the canonical AGENTS.md template source
and `standalone.md` reads the anchor section via SM §4g-anchor.

**O2 — N/A — no standalone.md code changes required (design doc update only).**

---

## Zone 2 — Implementer's judgment
- N/A

## Zone 3 — Scoped out
- Adding anchor template to standalone.md body text (covered by onboarding-new-project.md)
