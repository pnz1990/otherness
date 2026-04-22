# Spec: issue-896 — PM §5j: comparison doc accuracy check (design doc 41.4)

## Design reference
- **Design doc**: `docs/design/41-published-docs-freshness.md`
- **Section**: `§ Future`
- **Implements**: 41.4 — PM §5j: comparison doc accuracy check (🔲 → ✅)

---

## Zone 1 — Obligations

**O1 — PM must scan `docs/comparison.md` for ❌ rows and check if corresponding design doc items have moved to ✅ Present.**
If `docs/comparison.md` does not exist, the check is skipped gracefully.

**O2 — When a ❌ row's corresponding feature has moved to ✅ Present, PM opens a `kind/docs priority/medium` issue.**
Issue title: `docs: comparison.md row for '<feature>' should be ✅ — design doc marks it Present`.

**O3 — Deduplication: at most one open issue per ❌ row.**
Before opening, PM checks for an existing open issue with the same title prefix.

**O4 — The check runs every N_PM_CYCLES.**
It does not run on every cycle.

---

## Zone 2 — Implementer's judgment

- The matching between comparison.md rows and design doc items is fuzzy (keyword matching on feature name). False positives are OK — human will review and close.
- `docs/comparison.md` format: typically a Markdown table with `Feature | otherness | Competitor | Notes` columns with ✅/❌ markers.
- This check is informational only — it opens issues, does not auto-update comparison.md.

---

## Zone 3 — Scoped out

- 41.1-41.3, 41.5, 41.6 (separate items)
- Auto-updating comparison.md (human should review first)
- The comparison.md file itself (does not exist in otherness yet)
