# Spec: Meaningful-PR rate as primary throughput metric in SM §4f

**Item**: issue-800  
**Branch**: feat/issue-800  
**Date**: 2026-04-21

## Design reference
- **Design doc**: `docs/design/35-quality-of-output-gaps.md`
- **Section**: `§ Future`
- **Implements**: Meaningful-PR rate as primary throughput metric (🔲 → ✅)

---

## Zone 1 — Obligations (falsifiable)

**O1 — SM §4f REPORT_BODY headline shows `meaningful_prs` first, `prs_merged` as secondary.**  
Format: `Shipped: N meaningful (N total)`.  
Violation: headline still leads with `Vision PRs: N` or `prs_merged` without `meaningful_prs` first.

**O2 — `Vision PRs` and `Chores` counts are still accessible (in the Details section).**  
Violation: `Vision PRs` and `Chores` counts are completely removed and not visible anywhere.

---

## Zone 2 — Implementer's judgment

- Whether `meaningful_prs` and `prs_merged` (MERGED) use the same variable names already computed.
- Exact wording of the format string (current: `Shipped: N meaningful (N total)`).

---

## Zone 3 — Scoped out

- Changing how `meaningful_prs` is computed (that is a separate item).
- Removing `Vision PRs` from progress.md updates.
