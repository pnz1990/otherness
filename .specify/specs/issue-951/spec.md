# Spec: issue-951

## Design reference
- **Design doc**: `docs/design/43-github-project-management.md`
- **Section**: `§ Future`
- **Implements**: 43.4 — ENG §2f: when opening the PR, set board `Status: In Review`. One GraphQL mutation.

---

## Zone 1 — Obligations (falsifiable)

**O1**: `agents/phases/eng.md` contains a `§43.4 Board Status: In Review` block that fires immediately after `gh pr create` succeeds.
- Verify: `grep -q '§43.4 Board Status: In Review' agents/phases/eng.md`

**O2**: The block reads `board_project_id` from `otherness-config.yaml` project section. When the field is empty or absent, the block is silently skipped.
- Verify: block contains `if [ -n "$_BOARD_PID" ]` guard

**O3**: The block sets board `Status` to `In Review` (case-insensitive match on `review` in option name).
- Verify: `grep -q 'review' agents/phases/eng.md` (in the new block)

**O4**: The block uses `2>/dev/null || true` — failure never stops the loop (design doc 43 §O5).
- Verify: `grep -q '2>/dev/null || true' agents/phases/eng.md` (in the block)

**O5**: `docs/design/43-github-project-management.md` has `43.4` moved from `🔲 Future` to `✅ Present`.
- Verify: `grep -q '✅ 43.4' docs/design/43-github-project-management.md`

---

## Zone 2 — Implementer's judgment

- The `_BOARD_PID` read pattern mirrors the existing `§43.3` block in `coord.md` for consistency.
- The GraphQL queries are identical structure to `§43.3` — copy the pattern, change `In Progress` to `In Review`.
- `_ISSUE_NUM` is already set in `§2f` from `$(echo "$ITEM_ID" | grep -oE '[0-9]+$')`.
- The block goes right after the `gh pr create` command and before the `Update state` line.

---

## Zone 3 — Scoped out

- Adding the issue to the board if it is not already there (that's `§43.2` — COORD's job)
- Setting any status other than `In Review` in this block
- `§43.5` (Done), `§43.6` (Blocked), `§43.7` (epics) — separate issues
