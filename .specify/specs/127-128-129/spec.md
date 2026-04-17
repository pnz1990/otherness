# Spec: Report Improvements — Daily Rotation + Agent Identity + Version (Issues #127, #128, #129)

## Zone 1 — Obligations (falsifiable)

### O1: Session ID
Every session generates a short, unique, session-scoped ID at startup.
- **Violation**: Two concurrent sessions have the same ID, or the ID changes mid-session, or no ID is generated.
- Format: `sess-<8hex>` (e.g. `sess-a3f24b1c`) derived from `os.urandom(4).hex()`.

### O2: Otherness version
Every session captures the otherness agent version at startup.
- **Violation**: A session posts a comment without the version string, or the version is not captured.
- Captured via: `git -C ~/.otherness describe --tags --always 2>/dev/null || git -C ~/.otherness rev-parse --short HEAD 2>/dev/null || echo "unknown"`.

### O3: Comment header format
Every comment posted to the report issue by standalone.md or any phase file includes the header:
`[<BADGE> | <SESSION_ID> | otherness@<VERSION>]`
- **Violation**: A comment to `$REPORT_ISSUE` is posted without session ID or version.
- Existing startup comment: `[STANDALONE | sess-a3f2 | otherness@7ebbe14] Session started.`

### O4: Daily report rotation
At session startup (COORD phase 1a), check if the current report issue (`$REPORT_ISSUE`) was created on a previous UTC calendar day.
- If it was: close it with a linking comment, create a new issue, update `$REPORT_ISSUE` in `state.json` and the running env.
- **Violation**: A session starts on a new UTC day and continues posting to the old report issue instead of rotating.
- **Violation**: The old issue is deleted or loses its history.
- The new issue title follows the pattern: `📊 Autonomous Team Reports — YYYY-MM-DD`.

### O5: State.json persists report_issue
After daily rotation, the new `report_issue` number is written to `state.json` as `report_issue`.
- **Violation**: After rotation, a second session in the same day reads state.json and creates another new issue.

### O6: Graceful fallback
If `git -C ~/.otherness ...` fails (no git, no repo): session ID still generated (random), version falls back to `"unknown"`. Report rotation is skipped on error, not crashed.
- **Violation**: Agent crashes on startup when otherness dir is missing or git is unavailable.

---

## Zone 2 — Implementer's judgment

- Exact length of session ID (recommended: 8 hex chars from 4 random bytes).
- Whether to put session ID + version in a single env var or two separate ones.
- Whether daily rotation check happens before or after the rate-limit check (before is fine, it's cheap).
- Label(s) on the newly created daily report issue (copy from old, or hardcode `otherness`).
- Whether to update `AGENTS.md` `REPORT_ISSUE:` field on rotation (do NOT — that file must not be auto-modified per AGENTS.md §Files Agents Must Not Modify).

---

## Zone 3 — Scoped out

- Updating `otherness-config.yaml` `report_issue:` field — not a source of truth at runtime; state.json + env var are enough.
- Backfilling history: old comments don't get the new header format.
- Weekly/monthly rotation granularity — daily only.
- Bounded agents: they inherit `$REPORT_ISSUE`, `$MY_SESSION_ID`, `$OTHERNESS_VERSION` from the parent env; no separate changes to bounded-standalone.md needed.
