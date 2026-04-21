# Spec: SM §4b must distinguish metrics-only PRs from real work PRs

## Design reference
- **Design doc**: `docs/design/35-quality-of-output-gaps.md`
- **Section**: `§ Future`
- **Implements**: SM §4b: `prs_merged` and `meaningful_prs` must exclude PRs where all changed files are in `docs/aide/` or `_state` (🔲 → ✅)

---

## Zone 1 — Obligations

**O1** — `SM §4b` must filter `prs_merged` to exclude PRs where ALL changed files are under `docs/aide/` or correspond to `_state`-branch state files. A PR that only touches `docs/aide/metrics.md` must not increment `prs_merged`.
- Violation: `prs_merged` counts a docs/aide/-only PR as meaningful.

**O2** — When `meaningful_prs == 0` but `prs_merged > 0` (all housekeeping), the AMBER health signal must fire in `SM §4b` (same as when vision_prs == 0).
- Violation: a session with only housekeeping PRs is reported as GREEN.

**O3** — The filter must be implemented server-side (via `gh pr view --json files`) for each PR in the recent merged list, not guessed from title alone.
- Violation: filter relies only on PR title pattern matching.

**O4** — Graceful fallback: if the `gh pr view` files call fails for a PR (API error, timeout), count that PR as meaningful (fail-open).
- Violation: API failure causes `prs_merged` to under-count.

---

## Zone 2 — Implementer's judgment

- The filter is applied to the `MERGED` variable used in metrics. A new variable `REAL_PRS` (or reuse `MEANINGFUL_PRS`) can be used.
- Focus on excluding PRs where 100% of files are in `docs/aide/`. PRs that change docs/aide/ AND code are still meaningful.
- The health signal AMBER trigger is the same pattern as `VISION_PRS == 0` in the defect diagnosis block.

---

## Zone 3 — Scoped out

- Filtering the `prs_merged` column for historical rows already written — only affects future rows.
- Detecting `_state`-branch-only PRs (these don't appear as regular PRs).
- N/A — infrastructure change with no user-visible behavior.
