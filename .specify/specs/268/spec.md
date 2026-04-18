# Spec: otherness.onboard mode declaration

> Item: 268 | Created: 2026-04-18 | Status: Active

## Design reference
- **Design doc**: `docs/design/07-d4-enforcement.md`
- **Section**: `## Future`
- **Implements**: `otherness.onboard` mode: READ-ONLY for CODE zone, VISION for DOCS zone (🔲 → ✅)

---

## Zone 1 — Obligations

**O1 — `agents/onboard.md` MODE block is updated to reflect actual behavior.**
The current MODE block says READ-ONLY, but onboard.md writes to `docs/aide/` (DOCS zone)
and `.otherness/state.json` (CODE zone exception for state bootstrap). The MODE block
must be updated to accurately describe what onboard.md is permitted to do:
- Write to DOCS zone (`docs/aide/`, `docs/design/`)
- Write to `.otherness/` (state bootstrap — explicit exception)
- NOT write to general CODE zone (no scripts, no agent files, no tests)

Behavior that violates this: MODE block still says READ-ONLY after this PR merges.

**O2 — The updated MODE block specifies the one CODE zone exception.**
`.otherness/state.json` and `.otherness/state.json` seeding is an explicit exception
to DOCS-only. The MODE block must mention this exception by name.

Behavior that violates this: MODE block says VISION with no mention of .otherness/ exception.

**O3 — Design doc 07 marks this item as ✅ Present.**

Behavior that violates this: doc 07 still shows `otherness.onboard` mode as 🔲.

---

## Zone 2 — Implementer's judgment

- Whether to declare mode as VISION or a new hybrid: use VISION as the base, with
  an explicit ".otherness/ exception" note. This is the simplest accurate description.
- Whether validate.sh check 6 needs updating: validate.sh check 6 verifies that all
  agents have a MODE block. After this change, onboard.md will still have a MODE block.
  No validate.sh change needed.
- Exact wording for the exception note: "Exception: this agent may also write to
  `.otherness/` for state bootstrap (`.otherness/state.json`). This is the only
  CODE-adjacent write permitted."

---

## Zone 3 — Scoped out

- Preventing onboard.md from writing outside its declared zones (it already doesn't)
- Adding guard.sh calls to onboard.md (separate item if needed)
- Changes to onboard.md behavior (mode declaration only, not behavior change)
