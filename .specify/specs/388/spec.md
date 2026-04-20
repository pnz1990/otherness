# Spec: coord.md §1c — Roadmap Source for Queue Generation

## Design reference
- **Design doc**: `docs/design/22-queue-richness.md`
- **Section**: `§ Future` — "coord.md §1c: roadmap source"
- **Implements**: When design doc items are exhausted, ISSUE_GEN reads `docs/aide/roadmap.md` deliverables and creates issues from unimplemented stages (🔲 → ✅)

---

## Zone 1 — Obligations

**O1 — ISSUE_GEN creates roadmap issues when design items ≤ 5.**
In `coord.md §1c`, after creating issues from design doc items, if `len(new_items) <= 5`
the ISSUE_GEN block reads `docs/aide/roadmap.md` and creates issues from the earliest
incomplete stage's deliverables. Violation: roadmap deliverables never become issues even when design doc items are few.

**O2 — Roadmap items are lower priority than design doc items.**
Roadmap-sourced issues get label `area/agent-loop,priority/low` vs design items
`priority/medium`. The COORD item-claim logic (§1e) will naturally prefer higher-priority
items. Violation: roadmap items get same or higher priority than design doc items.

**O3 — Roadmap items include the source label `kind/enhancement`.**
Roadmap-sourced issues must include a `## Design reference` body that names
`docs/aide/roadmap.md` as the source doc and the stage as the section. Violation:
roadmap-derived issue body does not identify its source.

**O4 — `is_done_check` applies to roadmap items too.**
Roadmap deliverables already merged as PRs or present in design doc ✅ Present entries
are not re-created as issues. Violation: creates duplicate issues for already-shipped work.

**O5 — Cap: at most 5 roadmap issues per cycle.**
Never create more than 5 roadmap-sourced issues per queue-gen cycle. Total cap (design +
roadmap) stays at 20. Violation: more than 5 roadmap issues in one cycle.

---

## Zone 2 — Implementer's judgment

- Which stage to pull from: earliest incomplete stage (top of roadmap first).
- How to detect "incomplete stage": any deliverable line not covered by is_done_check.
- Threshold for "design items few enough to draw from roadmap": `<= 5` design items found.
  This prevents roadmap items from crowding out design doc items when both exist.
- Whether to create design doc stubs for roadmap items (O2 from design doc 22):
  Out of scope for this item — too complex for a single PR. The roadmap issue body
  will note "consider creating docs/design/ stub for this feature area" as a nudge.

---

## Zone 3 — Scoped out

- Creating design doc stubs for roadmap items (design doc 22 O2) — separate item
- Pulling from PM/SM-derived sources (source 4–6 in design doc 22) — separate items
- Cross-project roadmap reading — each project reads its own roadmap only
- Merging roadmap stages into one item — each deliverable bullet gets its own issue
