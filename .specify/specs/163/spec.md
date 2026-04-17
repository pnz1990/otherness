# Spec: feat(onboard): generate design doc stubs

> Item: 163 | Risk: high | Size: l | Tier: HIGH (onboard.md)

## Design reference
- **Design doc**: `docs/design/01-declarative-design-driven-development.md`
- **Section**: `§ Future (🔲)`
- **Implements**: `/otherness.onboard` generates design doc drafts inferred from codebase (🔲 → ✅)

---

## Zone 1 — Obligations

**O1**: `/otherness.onboard` must create draft `docs/design/` files for 2-4 major feature areas inferred from the codebase.
- **Falsified by**: Onboarding completes without creating any `docs/design/` files.

**O2**: Each generated design doc must include `⚠️ Inferred — review before treating as authoritative` in the status line.
- **Falsified by**: Generated design doc has no inferred warning.

**O3**: Each generated design doc must have `## Present (✅)` and `## Future (🔲)` sections, populated with inferred content.
- **Falsified by**: Generated design doc has neither section.

**O4**: The step must be graceful when the codebase has no identifiable feature areas (new empty project). In that case, create a single `docs/design/01-overview.md` stub.
- **Falsified by**: Onboarding crashes or creates 0 docs for an empty project.

**O5**: `docs/design/01-DDDD.md` `## Future` must be updated: `/otherness.onboard generates design doc drafts` → `✅ Present`.
- **Falsified by**: Item still in Future after merge.

---

## Zone 2 — Implementer's judgment

- How to infer feature areas: look at directory structure, package.json/pom.xml/go.mod, and README.md headings
- Number of design docs to generate: 2-4 (too many overwhelms; too few is useless)
- Depth of generated content: stubs are acceptable — Present section can say "inferred from code" and Future can say "TODO: review and add items"

---

## Zone 3 — Scoped out

- Does NOT enforce the inferred design docs are accurate
- Does NOT update them after initial onboarding
- Does NOT run validate.sh on the generated docs (they're marked as drafts)
