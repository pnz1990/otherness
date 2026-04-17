# Spec: chore(docs): update progress.md — Stage 4 complete

> Item: 147 | Risk: low | Size: xs

## Design reference
- N/A — infrastructure docs update, no user-visible behavior change

---

## Zone 1 — Obligations

**O1**: `docs/aide/progress.md` Stage Completion table must show Stage 4 as ✅ Complete.
- **Falsified by**: Stage 4 shows "🔄 In Progress" after this item ships.

**O2**: The "Stage 4 remaining items" section must be removed or replaced with accurate completion notes (PRs #139 and #140 merged).
- **Falsified by**: Section still references open PRs #139/#140 as awaiting human merge.

**O3**: "Current State" section must reflect current batch (12), completed stages (0-4), and next stage (5 — pending human trigger).
- **Falsified by**: Current state still says "Batch: 10" or "Stage 4 in progress."

**O4**: Key milestones table must include the Stage 4 completion date.
- **Falsified by**: Table has no entry for Stage 4 completion.

---

## Zone 2 — Implementer's judgment

- Exact wording of completion notes is up to engineer.
- Stage 5 status line should note the human trigger condition clearly.

---

## Zone 3 — Scoped out

- Does NOT change any agent instruction files.
- Does NOT add new milestones for stages not yet started.
