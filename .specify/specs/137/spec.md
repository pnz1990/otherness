# Spec: SM Metric Regression Auto-Open (Issue #137)

**Version**: 1.0 | **Date**: 2026-04-17 | **Risk tier**: CRITICAL (agents/phases/sm.md)

Note: Issue #137 incorrectly states "Not CRITICAL tier". agents/phases/sm.md is CRITICAL
per the AGENTS.md change risk table (agents/phases/*.md). This PR will carry needs-human
label and follow the CRITICAL tier self-review protocol.

---

## Zone 1 — Obligations (must satisfy)

1. **O1**: `agents/phases/sm.md` §4b contains a regression check that reads `docs/aide/metrics.md`
   batch log after writing the new row and parses the last 3 rows.

2. **O2**: If `needs_human` increased for 2 consecutive batches (rows N-1 and N both > row N-2,
   OR both > 0 when N-2 was 0): opens a `kind/chore` issue titled
   `[METRIC REGRESSION] needs_human increasing — investigate`. Deduped (no open issue with same title).

3. **O3**: If `todo_shipped` was 0 for 2 consecutive batches (rows N-1 and N both = 0): opens a
   `kind/chore` issue titled `[METRIC REGRESSION] no items shipped in 2 batches`. Deduped.

4. **O4**: Regression check only fires when there are at least 3 rows (compares N, N-1, N-2).
   Gracefully skips when < 3 rows.

5. **O5**: CI (`bash scripts/validate.sh && bash scripts/lint.sh`) passes after the change.

6. **O6**: The change is additive — no existing §4b behavior is removed or modified.

---

## Zone 2 — Implementer's judgment

- Location: append the regression block after the existing `git push origin main` in §4b.
- Regression definition for needs_human: last 2 batches both have needs_human > baseline
  (baseline = N-2 row value). Simple: both N-1 and N > N-2.
- Parser reuses the same approach as §5e in pm.md (copy+adapt for DRY-ness is acceptable
  since the files are separate markdown instruction files, not shared code).
- The `gh issue list --search` dedup pattern matches pm.md §5e for consistency.

---

## Zone 3 — Scoped out

- ci_red_hours regression detection (not an integer in current table — uses `~0`, `~12` etc.)
- Alerting via any channel other than GitHub issues.
- Adding new metrics columns to the table.
