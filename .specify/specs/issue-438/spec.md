# Spec: Anchor Score Comment Reading (issue-438)

## Design reference
- **Design doc**: `docs/design/25-anchor-kardinal-promoter.md`
- **Section**: `§ Future`
- **Implements**: Anchor score comment format: PDCA posts `[ANCHOR | kardinal-promoter | DATE] coverage: N/M (X%) | PASS=A FAIL=B` to issue #1 after every run (🔲 → ✅)

## Context

The anchor score comment format is the structured output that PDCA workflows post to their project's report issue after each run. The otherness SM agent must be able to read this pattern to:
1. Track coverage progress across sessions
2. Detect anchor stagnation (coverage not improving over N sessions)
3. Prioritize anchor-growth items when coverage is below target

The format is:
```
[ANCHOR | <project-name> | YYYY-MM-DD] coverage: N/M (X%) | PASS=A FAIL=B
```

The `score_pattern` in `otherness-config.yaml` provides a regex to extract PASS/FAIL counts. The coverage ratio `N/M (X%)` is parsed from the comment body.

---

## Zone 1 — Obligations

**O1 — SM §4g-anchor-score reads the latest anchor score from the project's report issue every SM cycle.**
The SM reads comments from `$REPORT_ISSUE` matching the `[ANCHOR | * | *] coverage:` pattern. If `anchor.score_pattern` is configured in `otherness-config.yaml`, it also extracts PASS/FAIL counts. If no anchor comments found: skip gracefully (no error, no [NEEDS HUMAN]).

**O2 — Stagnation detection: if anchor score has not improved in N consecutive sessions, SM logs a warning.**
N = `anchor.stagnation_sessions` from `otherness-config.yaml` (default: 3). Stagnation is defined as: the latest anchor score ≤ previous anchor score for ≥ N consecutive checks. When stagnation is detected, SM posts `[ANCHOR | stagnation] coverage has not improved in N sessions` to `$REPORT_ISSUE`.

**O3 — SM posts the latest anchor score to `$REPORT_ISSUE` after reading it.**
Format: `[SM §4g-anchor-score | <session>] Latest anchor: coverage N/M (X%) PASS=A FAIL=B | stagnation=0/3`

**O4 — SM stores the last anchor score in `state.json` for stagnation tracking.**
Key: `state['anchor_scores'][REPO]` = list of last N score objects `{date, coverage_pct, pass, fail}`. Oldest entries pruned to keep only last 5.

**O5 — If anchor is not configured (no `anchor:` section or `anchor.workflow` empty), skip gracefully.**
No log noise when project has no anchor.

**O6 — The score reading is additive to existing §4g-anchor gap detection; it does not replace it.**
Both run when triggered. §4g-anchor reads design doc coverage. §4g-anchor-score reads workflow run coverage. They complement each other.

---

## Zone 2 — Implementer's judgment

- Whether to run §4g-anchor-score every SM cycle or every N cycles: run every cycle (reading a comment is cheap; stagnation detection requires per-cycle data).
- The regex for extracting `N/M` from the comment: `coverage:\s*(\d+)/(\d+)\s*\((\d+)%\)`.
- Whether to open a new issue on stagnation or just post a comment: post a comment only (SM §4g-anchor can open issues if needed).
- Whether PASS/FAIL extraction failure should block the score: no — degrade gracefully, record coverage_pct only.

---

## Zone 3 — Scoped out

- Writing/modifying the PDCA workflow in kardinal-promoter (separate repo, separate item)
- Enforcing anchor score on PR merge (separate gate, future item)
- Cross-project anchor score aggregation (each project is independent)
- Automatic anchor-growth issue creation based on score (that's §4g-anchor gap detection)
