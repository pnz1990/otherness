# Spec: Silent-Session Detection

## Design reference
- **Design doc**: `docs/design/35-quality-of-output-gaps.md`
- **Section**: `§ Future`
- **Implements**: `standalone.md` / `coord.md §1e`: silent-session detection — when a session ends with 0 merged PRs and no open PR, write `silent_session: true` to `_state`; SM detects 2 consecutive silent sessions and opens a `[NEEDS HUMAN: silent-session-streak]` issue (🔲 → ✅)

---

## Zone 1 — Obligations

**O1 — Silent session detection runs in SM §4f (session end).**
After the batch report comment is posted, SM checks:
- Count of PRs merged this session (from VISION_PRS + MERGED context)
- Count of open PRs on main branch
If both are zero (merged=0 AND open_prs=0): write `silent_session_count` incremented by 1 to state.json.
If at least one PR was merged OR is open: reset `silent_session_count` to 0.

**O2 — SM §4b regression detection checks for silent-session streaks.**
When `silent_session_count >= 2`: open a `[NEEDS HUMAN: silent-session-streak]` issue (idempotent — skip if already open).
The issue body must include the last 2 batch health report summaries.

**O3 — `silent_session_count` is stored in state.json (not _state branch directly).**
It is written via the standard state write block at end of §4f.
It is NOT a separate field — it lives in the top-level state.json object.

**O4 — Graceful fallback when gh CLI fails.**
If the PR count check fails: assume session is NOT silent (fail-open — do not false-alarm).

---

## Zone 2 — Implementer's judgment

- Whether to check merged PRs vs checking only the MERGED variable already computed in §4b:
  use the MERGED variable (already set) + check open PRs via gh. This is cheaper than rerunning.
- What counts as "merged in this session": use MERGED variable from §4b (recent PRs in last 7 days).
  A session with 0 recent PRs is a silent session.

---

## Zone 3 — Scoped out

- Detecting silent sessions that had items assigned but not completed (stuck items)
- Per-project silent session tracking
- Emailing notifications (platform feature, not agent responsibility)
