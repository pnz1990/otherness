# Spec: Spatial Collision Detection — coord.md §1e executable

## Design reference
- **Design doc**: `docs/design/15-multi-session-spatial-coordination.md`
- **Section**: `§ Future`
- **Implements**: spatial collision detection — coord.md §1e [AI-STEP] comment block → executable Python (🔲 → ✅)

---

## Zone 1 — Obligations

**O1**: The candidate selection loop in coord.md §1e MUST execute the spatial overlap check (not just comment it). When a candidate item's computed file_spaces overlap with any active item's file_spaces, the candidate MUST be skipped.

**O2**: The file_spaces declaration in the claim block MUST be computed from item labels (not left as empty `[]`). The AREA_TO_SPACES map MUST be used to populate file_spaces at claim time.

**O3**: The AREA_TO_SPACES map MUST cover the label areas used in otherness: `area/agent-loop`, `area/docs`, `area/tooling`, `area/onboarding`, `area/skills`. Project-specific areas (area/ui, area/controller) are included as examples but are not required to match any specific project structure.

**O4**: Collision detection MUST be fail-open: if file_spaces is empty for the candidate OR for all active items, no collision is detected and the item proceeds. This ensures projects without file_spaces declarations are not blocked.

**O5**: Validate.sh MUST pass after the change (CRITICAL-A self-review requirement).

---

## Zone 2 — Implementer's judgment

- The AREA_TO_SPACES map: start with the areas already present as comments. Use generic paths applicable to any project.
- Overlap logic: prefix-based (`startswith`) is sufficient — exact match would be too restrictive.
- Whether to add `area/agent-loop` pointing to `agents/` and `scripts/` — yes, this is the main otherness-specific area.

---

## Zone 3 — Scoped out

- Learning area→path mappings from project structure (would require codebase scanning)
- Per-project custom area→path overrides in config
- Retroactively populating file_spaces for existing in-flight items
