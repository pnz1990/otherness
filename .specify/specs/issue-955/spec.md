# Spec: [AI-STEP] Elimination in coord.md and eng.md

## Design reference
- **Design doc**: `docs/design/45-distil-and-simplify.md`
- **Section**: `§ Future`
- **Implements**: 45.2 — replace every [AI-STEP] in coord.md and eng.md with executable code or delete

---

## Zone 1 — Obligations (falsifiable)

1. **O1**: `grep -c '\[AI-STEP\]' agents/phases/coord.md` returns `0` after this PR merges.
2. **O2**: `grep -c '\[AI-STEP\]' agents/phases/eng.md` returns `0` after this PR merges.
3. **O3**: Every removed `[AI-STEP]` comment is either:
   - Replaced with executable bash/python that a shell can run without human guidance, OR
   - Deleted with an inline comment explaining why it was deleted (aspirational/non-implementable).
4. **O4**: `bash scripts/validate.sh` passes (no broken skill refs or hardcoded paths introduced).
5. **O5**: `bash scripts/lint.sh` passes.

## Zone 2 — Implementer's judgment

- The replacement code for the needs-human resolution loop (coord.md §1e) may be partial: the agent cannot truly judge all human issues, so the replacement may read issues and post a structured response comment.
- For eng.md §2b step 3, §2c, and §2f: these describe AI reasoning steps inherent to the loop. Where the step is genuinely an AI decision, it may be replaced with a concrete bash read + explicit instructions that make the agent's reasoning explicit rather than leaving it as an opaque comment.
- The design doc update step (§2f) is intrinsically AI work — replace with explicit templated instructions.

## Zone 3 — Scoped out

- This spec does NOT cover `[AI-STEP]` stubs in `qa.md`, `sm.md`, or `pm.md` (tracked separately in issue-958).
- This spec does NOT change functional behavior — stubs that already have surrounding executable code just need the comment removed or replaced.
