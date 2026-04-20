# Spec: feat(sm): §4g-anchor — feature→anchor gap detection, coverage ratio comment

## Design reference
- **Design doc**: `docs/design/24-project-anchor-framework.md`
- **Section**: `§ The feature → anchor gap`
- **Implements**: SM §4g-anchor feature→anchor gap detection + coverage ratio comment (🔲 → ✅)

---

## Zone 1 — Obligations

**O1** — SM §4g-anchor runs every 10 SM cycles (same cadence as calibration).
It checks for an `## Anchor` section in `AGENTS.md`. If absent, logs
`[SM §4g-anchor] No §Anchor section in AGENTS.md — skipping.` and exits.

Violation: runs on every cycle; crashes when §Anchor absent.

**O2** — If §Anchor section present: count ✅ Present features from `docs/design/*.md`
(same regex as queue-gen). Count anchor-covered features from §Anchor section
(lines matching `- ✅` or `- [x]`). Post coverage ratio comment on REPORT_ISSUE:
`[ANCHOR] coverage: N/M (X%)` where N=covered, M=total features.

Violation: ratio not posted; wrong denominator (e.g. using open issues not design doc items).

**O3** — For each ✅ Present feature with no matching entry in §Anchor: open a
`kind/chore,area/tooling` issue titled `anchor: cover '<feature-name>'`.
Deduplication: `gh issue list --search "anchor: cover"` before opening.

Violation: duplicate anchor-growth issues; wrong labels.

**O4** — If `docs/design/` is absent or empty: skip gracefully.

Violation: crashes or false report when no design docs exist.

---

## Zone 2 — Implementer's judgment

- Matching features to anchor entries: use a fuzzy substring match (50 chars of
  feature description). Exact match would be too strict; full sentence is too loose.
- Whether to post the ratio even when 0 features: yes, post 0/0 = 100% (vacuous truth).
  This is the correct behavior for projects with no features yet.
- Deduplication granularity: per feature name, not per batch. One open issue per
  uncovered feature at a time.

---

## Zone 3 — Scoped out

- COORD anchor-growth gate (issue 356) — separate item
- Computing coverage from anchor workflow run results (O4 from design doc says agent reads scores; this spec is about gap detection from design docs, not workflow scores)
- Cross-project anchor comparison
