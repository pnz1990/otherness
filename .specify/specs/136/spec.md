# Spec: PM Stagnation Detection (Issue #136)

**Version**: 1.0 | **Date**: 2026-04-17 | **Risk tier**: MEDIUM (pm.md only)

---

## Zone 1 — Obligations (must satisfy)

1. **O1**: `agents/phases/pm.md` contains a stagnation check that reads `docs/aide/metrics.md` batch log and parses the last 3 rows.

2. **O2**: If the last 2 batch rows both have `todo_shipped = 0`, the agent opens a GitHub issue titled `[STALE] Queue appears blocked — investigate roadmap` with labels `kind/chore,otherness`. This issue is only opened if no issue with the same title is currently open (no spam).

3. **O3**: If the last 2 batch rows both have `needs_human > 0`, the agent posts a warning comment on `$REPORT_ISSUE` flagging the persistent escalation pattern.

4. **O4**: The check runs during Phase 5 (PM review), and its outcome is included in the PM review comment posted to `$REPORT_ISSUE`.

5. **O5**: The check is safe to skip when `docs/aide/metrics.md` has fewer than 3 batch rows (e.g., early in a project). No crash, no error.

6. **O6**: This change does NOT touch `agents/standalone.md` or `agents/bounded-standalone.md`. It is MEDIUM tier.

7. **O7**: CI (`bash scripts/validate.sh && bash scripts/lint.sh`) passes after the change.

---

## Zone 2 — Implementer's judgment

- Location within pm.md: add as new §5e before the final §5d post-review comment.
- Metrics table parsing: use python3 stdlib — no external dependencies.
- The "no spam" dedup can use `gh issue list --search` or title match; either is acceptable.
- The 2-batch lookback window is sufficient; 3-batch lookahead is not needed.

---

## Zone 3 — Scoped out

- Regression detection for metrics other than `todo_shipped` and `needs_human` (those belong to #137 which is the SM-side feature).
- Changing the metrics table format or adding new columns.
- Alerting via any channel other than GitHub issues and issue comments.

---

## Design reference
- N/A — pre-DDDD item (written before design doc system, PR #144)
