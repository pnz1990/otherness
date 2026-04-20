# Spec: Feature→scenario gap detection in SM §4g-anchor

**Item**: issue-523
**Branch**: feat/issue-523

## Design reference

- **Design doc**: `docs/design/25-anchor-kardinal-promoter.md`
- **Section**: `§ Future`
- **Implements**: Feature→scenario gap detection: SM §4g-anchor reads ✅ Present items from docs/design/*.md, diffs against coverage matrix, opens anchor-growth issues for uncovered features (🔲 → ✅)

---

## Context

The existing SM §4g-anchor checks features against `AGENTS.md §Anchor` section. The design doc item asks for a complementary check: reading ✅ Present items from design docs and diffing them against a PDCA-style coverage matrix (the scenario table within `docs/design/25-anchor-kardinal-promoter.md` and similar anchor design docs).

This adds a new sub-section `§4g-anchor-design-gap` to `agents/phases/sm.md` that:
1. Reads ✅ Present items from all `docs/design/*.md` files
2. Reads the coverage matrix from anchor design docs (docs named `*-anchor-*`)
3. For each ✅ Present item not covered in any scenario: opens an anchor-growth issue

---

## Zone 1 — Obligations

**O1** — `agents/phases/sm.md` must contain a new sub-section `§4g-anchor-design-gap` that reads ✅ Present items from `docs/design/*.md` files.

Violation: The section is absent or reads from a source other than docs/design/*.md.

**O2** — The new section must diff ✅ Present feature names against the `## Present` section of anchor design docs (files named `*anchor*` in `docs/design/`). It must identify features not mentioned in any anchor doc's Present section.

Violation: The diff compares against AGENTS.md or a fixed list instead of docs/design/*anchor*.md.

**O3** — For each uncovered feature (cap at 5 per cycle), the agent must call `gh issue create` with label `anchor: cover` and include the source design doc and feature name.

Violation: Issues are created without the `anchor: cover` label, or more than 5 issues per cycle.

**O4** — The section must run every SM cycle (not gated on SM_CYCLE count) but include deduplication so existing `anchor: cover` issues are not re-opened.

Violation: Section is gated on `SM_CYCLE % N` and skips most cycles.

**O5** — The section must exit gracefully (no crash) when: docs/design/ doesn't exist, no anchor design docs exist, or no ✅ Present items exist.

Violation: Section crashes with unhandled exception when any of these conditions are true.

---

## Zone 2 — Implementer's judgment

- Whether to add the section before or after existing §4g-anchor: add after §4g-anchor-parity, before §4g-anchor-score. Logical grouping with other anchor checks.
- Fuzzy matching for feature names: use substring match (first 40 chars of feature name appears anywhere in the anchor doc's Present/Scenarios section). False positives are acceptable; false negatives (missing real gaps) are not.
- The cap of 5 issues per cycle prevents flooding. The deduplication check is by issue title prefix (first 50 chars).

---

## Zone 3 — Scoped out

- Diffing against AGENTS.md §Anchor section (already done by existing §4g-anchor)
- Cross-repo gap detection (only checks docs/design/ in current repo)
- Automatic scenario generation (opens issues only — ENG writes the scenarios)
