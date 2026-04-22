# Spec: issue-702 — fix(sm) §4f SESSION_PROGRESS false STALLED when MERGED unset

## Design reference
- N/A — infrastructure bug fix with no user-visible behavior change in normal loop execution.

---

## Zone 1 — Obligations

**O1 — When `MERGED` env var is unset and `§4f` is called, do NOT default to STALLED.**
Add a guard before the PROGRESS_CLASS computation: if `MERGED` is unset or empty,
recompute it from `gh pr list` (same query as §4b uses). Use the result for the
PROGRESS_CLASS and downstream computations.

**O2 — The guard is non-blocking.**
If the `gh pr list` recompute fails (no network, API error), default `MERGED=0`.
This means worst-case is the same as before (STALLED on failure), but normal
standalone calls will now get correct values.

**O3 — VISION_PRS is also guarded similarly.**
If `VISION_PRS` is unset, recompute it with the same vision-aligned filter used in §4b.

---

## Zone 2 — Implementer's judgment

- The recompute uses the same query as §4b (last 30 PRs, filter feat/fix/refactor,
  exclude metrics-only chores). Consistent with the normal flow.
- Log the recompute: `[SM §4f] MERGED unset — recomputing from gh pr list`.

---

## Zone 3 — Scoped out

- Fixing the root cause of §4f being called standalone without §4b first
  (design issue — caller's responsibility)
- Fixing the VISION_PRS ratio display in standalone calls
