# Spec: issue-882 — COORD §1e chore-claim gate with proactive queue enrichment

## Design reference
- **Design doc**: `docs/design/21-session-throughput.md`
- **Section**: `§ Future`
- **Implements**: COORD §1e must refuse to claim a `kind/chore` item when no `kind/enhancement` or `kind/bug` item has shipped this session (🔲 → ✅)

---

## Zone 1 — Obligations (falsifiable)

**O1**: Before COORD §1e selects any item for claiming, if `MEANINGFUL_PRS_THIS_SESSION == 0` AND the top-sorted candidate item is `kind/chore`, COORD must NOT claim that chore item.

**O2**: When O1 fires, COORD must scan `docs/design/*.md` for a `🔲 Future` item in a `## Future` section whose title has no matching open GitHub issue (first 40 chars). If a candidate is found: create a GitHub issue for it, claim that issue, and proceed to ENG.

**O3**: If O2 finds no candidate (no unissued Future items), COORD must write `meaningful_pr_guarantee_failed: true` to `state.json` and claim the chore normally (fail-open).

**O4**: The gate must be fail-open: if reading `state.json`, GitHub API, or `docs/design/` fails for any reason, COORD must claim the top-sorted item as normal.

**O5**: `MEANINGFUL_PRS_THIS_SESSION` is a session-scoped shell variable initialized to 0 at startup and incremented by ENG/QA after each merged feature PR.

**O6**: The gate must log its decision: `[COORD §1e-chore-gate] <action taken>`.

## Zone 2 — Implementer's judgment

- The scan for unissued Future items can reuse the existing `is_done_check` logic from §1c.
- `MEANINGFUL_PRS_THIS_SESSION` can be a simple shell variable — no persistent state needed.
- The gate should integrate into the existing `ITEM_ID=$(python3 ...)` block or wrap it.

## Zone 3 — Scoped out

- Does not retroactively cancel already-claimed chore items.
- Does not affect sessions where `MEANINGFUL_PRS_THIS_SESSION > 0`.
- Does not change the priority sort — gate fires after sort, before claim push.
