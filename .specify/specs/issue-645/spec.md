# Spec: issue-645 — Same-session recovery when no PR ships in first item attempt

## Design reference
- **Design doc**: `docs/design/21-session-throughput.md`
- **Section**: `§ Future — Same-session recovery`
- **Implements**: `coord.md §1f`: when `ITEMS_COMPLETED == 0` after the first item attempt fails (QA rejected, CI failed, or item was a ghost/nothing to implement), COORD re-scans design docs for an unclaimed 🔲 Future item not yet in queue, creates an issue for it, and attempts that item before falling through to SM/PM. Only exits to SM/PM if the recovery attempt also produces no merged PR.

---

## Zone 1 — Obligations (falsifiable)

**O1** — After each completed item (merged or abandoned), coord.md §1f checks `ITEMS_COMPLETED`. If `ITEMS_COMPLETED == 0` (no PR has been merged yet this session), it enters the recovery path before allowing SM/PM gate to fire. Violation: session with 0 merged PRs falls through to SM/PM directly.

**O2** — The recovery path re-scans `docs/design/*.md` for unclaimed `🔲 Future` items not already in the GitHub issue queue, creates at most 1 new issue, and immediately attempts to claim and implement it. Violation: recovery path is a no-op or only logs a warning.

**O3** — Recovery is attempted at most once per session (not in a loop). If the recovery attempt also produces no merged PR, the session proceeds to SM/PM normally. Violation: recovery path loops indefinitely.

**O4** — Graceful: if `docs/design/` is absent, empty, or all items are already queued, the recovery path logs `[COORD §1f-recovery] No recovery candidate found — proceeding to SM/PM.` and exits. Violation: crash or hang when no recovery candidate exists.

---

## Zone 2 — Implementer's judgment

- The recovery check is a new conditional block in standalone.md's `§1f GATE — MULTI-ITEM CHECK` (after the existing `ITEMS_COMPLETED` counter increment). It runs before the `if ITEMS_COMPLETED < SESSION_LIMIT` check.
- The design doc scan reuses the same `docs/design/*.md` 🔲 Future item logic as `coord.md §1c` queue generation — but scoped to just 1 item (the first unclaimed candidate).
- A `RECOVERY_ATTEMPTED` flag (shell variable) prevents the recovery path from running more than once per session.
- The new item is claimed immediately (git push origin feat/issue-N) — if the claim succeeds, the session loops back to ENG phase with the new item. If the claim fails (race condition), the recovery is skipped.

---

## Zone 3 — Scoped out

- Recovery when ITEMS_COMPLETED > 0 but all PRs are chores-only — that's the meaningful_prs stagnation check (issue-644, just merged).
- Automatic CI failure diagnosis — separate item (design doc 38 §38.3).
- Recovery attempt loops (more than 1 retry per session) — out of scope per O3.
