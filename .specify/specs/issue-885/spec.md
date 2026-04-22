# Spec: issue-885 — Features-per-week velocity as primary speed signal

## Design reference
- **Design doc**: `docs/design/33-stage-4-self-improvement-metrics.md`
- **Section**: `§ Future`
- **Implements**: Features-per-week velocity must be tracked as the primary speed signal (🔲 → ✅)

---

## Zone 1 — Obligations (falsifiable)

**O1** — SM §4b must compute `meaningful_prs_per_week`: count of meaningful PRs merged in the rolling 7-day window (using GitHub API `mergedAt` timestamps). A "meaningful PR" matches `^feat|^fix|^refactor` and does NOT match `^chore\(sm\)|^chore\(metrics\)|session complete|batch [0-9]`.

**O2** — SM §4b must write `meaningful_prs_per_week` as a new column in `docs/aide/metrics.md` every batch. The column header must be `meaningful_prs_week` (abbreviated for table width).

**O3** — PM §5 must flag when `meaningful_prs_per_week < 1.0` for 2 consecutive weeks. The flag must open a `kind/chore priority/medium` issue titled "Velocity stall: fewer than 1 meaningful PR/week for 14d". PM §5 must also note "Velocity: healthy (N prs/week)" when `meaningful_prs_per_week >= 3.0` for 4 consecutive batches.

**O4** — `docs/aide/metrics.md` header row must include the new `meaningful_prs_week` column between `skills_count` and `todo_shipped`.

**O5** — The compute is fail-open: if GitHub API is unavailable or returns an error, `meaningful_prs_week` must be written as `?` (not blank, not 0) and the batch row must not be skipped.

---

## Zone 2 — Implementer's judgment

- The 7-day rolling window uses the GitHub API, not state.json — direct API is authoritative.
- PM §5 velocity stall check reads the last 2 `meaningful_prs_week` data rows from metrics.md.
- The velocity stall issue dedup check: search open issues for "Velocity stall" title prefix before creating.
- The "Velocity: healthy" note is appended to the batch report comment, not a separate issue.
- `meaningful_prs_week` value should be a float (e.g., `2.0`, `0.5`) to indicate fractional prs/week.

---

## Zone 3 — Scoped out

- Per-project velocity split (only the otherness repo velocity is tracked here)
- Historical backfill of `meaningful_prs_week` for prior batch rows
- Alerting beyond what is specified in O3
- Intelligence delta computation (separate issue)
