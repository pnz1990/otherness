# Spec: issue-869 — metrics schema-execution drift detection

## Design reference
- **Design doc**: `docs/design/33-stage-4-self-improvement-metrics.md`
- **Section**: `§ Future`
- **Implements**: Metrics schema-execution drift detection (🔲 → ✅)

---

## Zone 1 — Obligations (falsifiable)

**O1**: SM §4a must run a schema-conformance check each batch that compares the column
count in the header row of `docs/aide/metrics.md` to the column count in the last data row.

*Falsified by*: SM §4a completes without ever reading `docs/aide/metrics.md` to compare
column counts.

**O2**: When header column count ≠ last data row column count, SM §4a must open a
`kind/bug priority/high` issue with title
`"metrics.md schema drift: N columns defined, M columns written"`.

*Falsified by*: A drift is detected and no issue is opened, OR the wrong title format is used.

**O3**: The drift check must be idempotent — if a drift issue is already open (same title
prefix), SM must not open a duplicate.

*Falsified by*: Multiple issues with the same title prefix are opened in consecutive batches.

**O4**: When no drift is detected (column counts match), SM §4a must log
`[SM §4a-schema] metrics.md OK: N columns (header matches data)` and continue.

*Falsified by*: The check fails silently without any log output.

**O5**: The check must be fail-open — if `docs/aide/metrics.md` cannot be read or has no
data rows, log a warning and continue without blocking SM.

*Falsified by*: SM fails or exits early when `metrics.md` is missing or empty.

---

## Zone 2 — Implementer's judgment

- Placement in SM §4a is after the existing stale-spec check and before §4b
  (metrics write). This ensures drift is detected before new rows are appended.
- The check can be pure Python (no shell grep required).
- The issue label `kind/bug priority/high area/tooling` is appropriate for a schema
  integrity failure.
- Dedup check uses `--search` with the title prefix (first 60 chars).

---

## Zone 3 — Scoped out

- Does NOT fix the drift (just detects and reports it).
- Does NOT validate column names — only column count is checked.
- Does NOT backfill missing columns in old rows.
- Does NOT run on every file in `docs/aide/` — only `metrics.md`.
