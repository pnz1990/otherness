# Spec: COORD §1b — Session Pre-flight Gate

## Design reference
- **Design doc**: `docs/design/21-session-throughput.md`
- **Section**: `§ Future`
- **Implements**: Session pre-flight checks must be a blocking gate — move from 🔲 to ✅

## Zone 1 — Obligations

**O1** — `coord.md` §1b must contain a `PREFLIGHT_CHECK` bash block that reads all
of the following state.json signals in a single atomic read:
`housekeeping_streak`, `recovery_action`, `frame_lock_detected`,
`silent_session_count`, `directive`.
Violation: any signal is read from a separate file read or in a separate python call
that could produce a stale or partial view.

**O2** — The PREFLIGHT_CHECK must print a single-line summary of the form:
`Preflight: streak=N | recovery=<action|none> | frame_lock=<true|false> | silent=N | directive=<val|none>`
Violation: the summary is absent, or split across multiple lines that don't appear together.

**O3** — The PREFLIGHT_CHECK must produce exactly one of two outcomes:
- `PREFLIGHT_PASS` — session proceeds to claim work
- `PREFLIGHT_HOLD <reason>` — session posts reason to REPORT_ISSUE and exits cleanly (no claim)
Violation: the gate has any third outcome (warning but continue, etc.).

**O4** — A `PREFLIGHT_HOLD` must always post a comment to `$REPORT_ISSUE` before exiting.
Violation: the session exits cleanly without posting anything when a hold fires.

**O5** — `PREFLIGHT_PASS` must be the default when state.json is absent or unreadable.
The gate must fail-open (allow the session to proceed) if it cannot read state.
Violation: a missing or corrupt state.json causes the session to halt.

**O6** — `validate.sh` must pass after the change (no new validation failures).

## Zone 2 — Implementer's judgment

- Which conditions trigger PREFLIGHT_HOLD: the design doc names the signals but does
  not specify exact thresholds. Use: `housekeeping_streak >= 3` OR
  `frame_lock_detected == true` as HOLD conditions; `recovery_action` and
  `directive` are read and printed but not HOLD conditions (they are informational).
- Where in coord.md to insert the block: after §1a (heartbeat/CI) and before §1c
  (queue generation) — this is §1b.
- The existing scattered signal-reading code need not be removed in this PR; the
  PREFLIGHT_CHECK is additive. Removal is a follow-up chore.

## Zone 3 — Scoped out

- Standardising the `silent_session` canonical definition (separate issue)
- Autonomous `session_item_limit` tuning (separate issue)
- Item age limit auto-triage (separate issue)
