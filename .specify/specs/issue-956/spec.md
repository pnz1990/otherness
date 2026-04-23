# Spec: issue-956

## Design reference
- **Design doc**: `docs/design/45-distil-and-simplify.md` §45.3
- **Also**: `docs/design/43-github-project-management.md` §43.2
- **Section**: `§ Future`
- **Implements**: 43.2 — COORD §1d: when creating a GitHub issue, immediately add it to the project board with `Status: Todo` and set the `active_milestone`. Two API calls after `gh issue create`.

---

## Zone 1 — Obligations (falsifiable)

**O1** — Every `open_if_absent()` helper in `agents/phases/coord.md` must call a post-create setup
function immediately after a successful `gh issue create` (when `r2.returncode == 0`).

**O2** — The post-create setup function must attempt to add the issue to the project board with
`Status: Todo` via `gh project item-add` (or GraphQL equivalent). Non-blocking: wrap in
`try/except` and `|| true`. If `board_project_id` is empty in config: skip silently.

**O3** — The post-create setup function must attempt to assign `active_milestone` from
`otherness-config.yaml` via `gh issue edit --milestone`. Non-blocking: skip if `active_milestone`
is empty or milestone number not found.

**O4** — The `open_if_absent` function returns the issue number string. Callers already do
`if result: ... print(f"Created issue #{result}")`. The post-create calls happen inside
`open_if_absent` (not at call sites) to avoid repeating the logic in 5 places.

**O5** — The change must not break `bash scripts/validate.sh` (no hardcoded project paths,
no broken skill references, no missing required files).

**O6** — The change must not introduce any new blocking logic. Board/milestone failures
must be silent (`|| true` / `except: pass`).

## Zone 2 — Implementer's judgment

- Whether to use `gh project item-add` (simpler) or GraphQL mutation (more control) for board add.
  Given that the `Status: Todo` option ID is not known at creation time, using `gh project item-add`
  first (which adds with default status) and then a GraphQL mutation to set Status:Todo is the
  correct two-step approach — the same pattern as §43.3 (In Progress).
- Which `open_if_absent` instances to update: all 5 in the file (§1c ISSUE_GEN, §1c-guard,
  §1c-roadmap, §1f-recovery, §1f-L2, §INFERRED).

## Zone 3 — Scoped out

- Adding the item to the board in §1e (claim step) — that's already done by §43.3.
- Setting `Status: In Progress` at creation time — wrong lifecycle state.
- Backfilling existing open issues — that's issue-43.9 (separate item).
- Creating or updating `github_projects` config fields — config management is a separate concern.
