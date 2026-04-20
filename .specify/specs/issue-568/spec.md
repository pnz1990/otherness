# Spec: kro-ui design docs for major feature areas

## Design reference
- **Design doc**: `docs/design/26-anchor-kro-ui.md`
- **Section**: `§ Future`
- **Implements**: docs/design/: add design docs for major feature areas (RGD display, instance management, health system, designer) to enable generic gap detection (🔲 → ✅)

---

## Zone 1 — Obligations

**O1**: kro-ui's `docs/design/` MUST have at minimum 4 new design docs covering:
1. RGD display (list, DAG, detail, diff)
2. Instance management (list, detail, health, deletion debugger)
3. Health system (rollup badges, error patterns, state machine)
4. RGD designer (authoring, generate form, YAML preview)

Each doc MUST follow the structure: ## Present (✅) / ## Future (🔲) / ## Zone 1 Obligations.

**O2**: Each design doc MUST list at least 3 ✅ Present items referencing actual merged PRs (using the same PRs from AGENTS.md spec inventory table) so the gap detection algorithm has real signal to work with.

**O3**: Each design doc MUST include at least 1 🔲 Future item so COORD can generate queue items from them going forward.

**O4**: `docs/design/26-anchor-kro-ui.md` in kro-ui MUST be updated: move the "add design docs" Future item from 🔲 to ✅ Present.

**O5**: The corresponding `docs/design/26-anchor-kro-ui.md` in otherness (this repo) MUST also be updated to reflect ✅ Present.

---

## Zone 2 — Implementer's judgment

- Number of docs: minimum 4, one per feature area. Combining areas into fewer docs is acceptable if coverage is maintained.
- Depth of Present items: 3-5 per doc is sufficient; exhaustive coverage is out of scope.
- Future items: 1-3 per doc; lean toward concrete, implementable items.
- Design doc numbering: kro-ui currently has 26 and 27 in docs/design/. New docs: 28, 29, 30, 31.

---

## Zone 3 — Scoped out

- Implementing any of the Future items in the new docs
- Creating the gap detection algorithm itself (already in SM §4g)
- Design docs for testing infrastructure or CI tooling
