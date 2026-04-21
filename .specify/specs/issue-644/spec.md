# Spec: issue-644 — PM §5 meaningful_prs stagnation check

## Design reference
- **Design doc**: `docs/design/21-session-throughput.md`
- **Section**: `§ Future — Meaningful-work rate tracked as a first-class metric`
- **Implements**: PM §5 stagnation check: trigger AMBER (open issue) when `meaningful_prs = 0` for 2 consecutive batches. The SM §4b `meaningful_prs` column is already implemented (already ✅ Present); this completes the PM-side detection.

---

## Zone 1 — Obligations (falsifiable)

**O1** — PM §5 reads the last 2 rows of `docs/aide/metrics.md` and checks the `meaningful_prs` column (column 14, 0-indexed). If both rows have `meaningful_prs == 0`, it triggers a stagnation action. Violation: PM §5 doesn't read `meaningful_prs` at all.

**O2** — When 2 consecutive batches have `meaningful_prs == 0`, PM §5 opens a GitHub issue titled `[STALE] No meaningful PRs in last 2 batches — pipeline may be running on chores only` if no such issue is already open. Violation: PM §5 detects the condition but posts no issue.

**O3** — The stagnation check for `meaningful_prs` is separate from (and in addition to) the existing `todo_shipped = 0` check. Both checks run independently. Violation: one check suppresses the other.

**O4** — Graceful fallback: if the `meaningful_prs` column is absent from metrics.md rows (schema migration case), PM §5 skips the check and logs a warning. Violation: PM §5 crashes when `meaningful_prs` column is missing.

---

## Zone 2 — Implementer's judgment

- The `meaningful_prs` column is at index 13 (14th column, 0-indexed) in the current metrics.md schema: `Date | Batch | prs_merged | needs_human | ci_red_hours | skills_count | todo_shipped | time_to_merge_avg_min | vision_prs | session_outcome | arch_convergence | sim_floor_delta | queue_guard_fires | meaningful_prs | Notes`.
- The check runs in PM §5 immediately after the existing `todo_shipped` stagnation check (not in SM §4b — the issue spec says PM §5).
- The issue body is concise: shows the last 2 batch rows with meaningful_prs values, directs to `docs/aide/metrics.md` for context.
- Duplicate check: use `--search "[STALE] No meaningful"` to prevent opening the same issue twice.

---

## Zone 3 — Scoped out

- SM §4b changes — already done in a prior PR.
- Auto-remediation (triggering vision synthesis when meaningful_prs=0) — separate feature.
- Historical metrics.md back-fill — schema was added in PR #TBD; historical rows may lack the column.
