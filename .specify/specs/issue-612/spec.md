# Spec: SM §4b Session Outcome Classification

## Design reference
- **Design doc**: `docs/design/35-quality-of-output-gaps.md`
- **Section**: `§ Future`
- **Implements**: `SM §4b`: session outcome classification — label sessions as "chore-only", "mixed", or "feature-rich" based on item type distribution; write `vision_prs` column to metrics.md; use `vision_prs` as primary throughput metric (🔲 → ✅)

---

## Zone 1 — Obligations

**O1 — Every SM §4b metrics write includes a `vision_prs` column.**
The `vision_prs` column counts PRs merged this batch whose title matches
`^feat|^fix|^refactor` AND whose PR body or title contains `🔲 → ✅`
OR that updated a design doc moving a Future item to Present.
Chore/metrics/session-report PRs are excluded.

**O2 — Session outcome is classified in the SM §4b metrics update.**
Classification logic:
- `feature-rich`: vision_prs >= 1 and vision_prs >= 50% of total prs_merged
- `mixed`: vision_prs >= 1 but vision_prs < 50% of total prs_merged
- `chore-only`: vision_prs == 0

Classification is stored in a `session_outcome` column in metrics.md.

**O3 — The `vision_prs` metric is added to the metrics.md schema definition table.**
The Metric Definitions table in metrics.md must include `vision_prs` with
its definition and target direction.

**O4 — The SM §4f health signal uses `session_outcome` to set AMBER.**
If `session_outcome == chore-only`, health must be AMBER (not GREEN).
This enforces the meaningful-work floor from roadmap Stage 11.

**O5 — Existing metrics.md rows are NOT modified.**
Only new rows written after this PR will have the `vision_prs` and `session_outcome` columns.
Historical rows keep their existing format.

**O6 — metrics.md Batch Log table header is updated** to include the two new columns:
`vision_prs` and `session_outcome`.

---

## Zone 2 — Implementer's judgment

- Whether to detect 🔲 → ✅ transitions by scanning PR bodies vs relying purely on
  title prefix (`^feat`): scanning PR body for `🔲 → ✅` or `design doc updated`
  is more accurate but slower; title prefix is fast but may over-count.
  **Decision**: use title prefix `^feat|^fix|^refactor` AND exclude known non-vision
  patterns (chore(sm), metrics, session complete, PRs merged, batch).
  This matches the existing VISION_PRS logic in §4f.

- Whether to add `session_outcome` as a state.json field vs compute it fresh each batch:
  compute fresh each batch (simpler, correct).

---

## Zone 3 — Scoped out

- Retroactively classifying historical metrics rows
- Changing the batch report comment format (separate issue 615/625)
- Adding `guard_fires` counter to metrics (separate issue 638)
- Cross-session trend analysis on session_outcome
