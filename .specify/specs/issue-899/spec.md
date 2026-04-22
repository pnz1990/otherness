# Spec: issue-899 — ENG §2a: set board Status: In Progress at claim time (43.3)

## Design reference
- **Design doc**: `docs/design/43-github-project-management.md`
- **Section**: `§ Future`
- **Implements**: 43.3 — ENG §2a: when claiming an item (writing heartbeat), set board `Status: In Progress` for the issue. One GraphQL mutation. (🔲 → ✅)

## §41.4 Verification note

This item adds an [AI-STEP] comment to `agents/phases/coord.md` §1e (the claim step).
Verification: `grep -q "Status: In Progress" agents/phases/coord.md` — will be verified after implementation.

---

## Zone 1 — Obligations (falsifiable)

**O1** — `agents/phases/coord.md` §1e (item claim section) must contain a new block that reads `board_project_id` from `otherness-config.yaml` and, if non-empty, executes a GraphQL mutation to set the board item's Status field to `In Progress`.

**O2** — The board update must be non-blocking: failure (no board configured, network error, GraphQL error) must not stop the claim or the loop. The block must use `2>/dev/null || true` or equivalent.

**O3** — The block must be a `[AI-STEP]` comment or a bash block with graceful fallback — not a hard requirement.

**O4** — `scripts/validate.sh` must pass after the change.

**O5** — `scripts/lint.sh` must pass after the change.

**O6** — `docs/design/43-github-project-management.md` must be updated: move 43.3 from 🔲 Future to ✅ Present.

---

## Zone 2 — Implementer's judgment

- Placement: add the board update block immediately after the `gh issue comment` (claim posted) in coord.md §1e, before proceeding to ENG.
- The GraphQL mutation pattern is already used in qa.md §3e (Done status) — follow the same pattern.
- Use `in_progress_option_id` if configured in `otherness-config.yaml github_projects`; otherwise try to find the "In Progress" option by name from the board fields API.
- Since `board_project_id` and `github_projects.project_id` serve the same purpose, check both (prefer `project.board_project_id` as it is the simpler field).

---

## Zone 3 — Scoped out

- Setting `In Review` at PR open time (43.4) — separate item
- `Done` status (43.5 — already in qa.md §3e)
- Blocked status for stale items (43.6) — separate item
- Creating epic issues for new design docs (43.7) — separate item
