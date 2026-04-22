# Spec: issue-871 — first-run bootstrap guard

## Design reference
- **Design doc**: `docs/design/32-stage-3-onboarding-quality.md`
- **Section**: `§ Future`
- **Implements**: First-run bootstrap guard (🔲 → ✅)

---

## Zone 1 — Obligations (falsifiable)

**O1**: COORD §1a must detect zero-batch-history state by checking if
`docs/aide/metrics.md` is absent or has no data rows. Result stored as
`FIRST_RUN_SESSION=true|false`.

*Falsified by*: COORD proceeds without checking batch history on first run.

**O2**: When `FIRST_RUN_SESSION=true`, COORD must post a report comment:
`"[FIRST RUN] Zero batch history — bootstrap mode active."`

*Falsified by*: No "[FIRST RUN]" comment posted when metrics.md has no data rows.

**O3**: When `FIRST_RUN_SESSION=true`, COORD must seed `state.json` if missing
(write a minimal skeleton with `{batch_count: 0, features: {}}`).

*Falsified by*: COORD fails (KeyError/missing file error) when state.json absent on first run.

**O4**: The check must be fail-open — if metrics.md cannot be read, treat as
`FIRST_RUN_SESSION=false` (assume ongoing project, not first run).

*Falsified by*: COORD exits or errors when metrics.md is unreadable.

**O5**: When `FIRST_RUN_SESSION=true`, COORD must skip the stale-item watchdog
(no items can be stale with zero history).

*Falsified by*: Stale watchdog runs on a session with zero batch history.

---

## Zone 2 — Implementer's judgment

- Insert the bootstrap check in COORD §1a, after heartbeat and before the stop sentinel.
- `FIRST_RUN_SESSION` is a bash env var for downstream use.
- The state.json seeding only fires if `.otherness/state.json` cannot be loaded.
- The stale watchdog skip is a conditional around the existing §1d block.

---

## Zone 3 — Scoped out

- Does NOT change how SM §4f is triggered (it already runs at session end).
- Does NOT change the queue generation logic.
- Does NOT create a `docs/aide/metrics.md` file (that's SM's job).
