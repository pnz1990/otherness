# Spec: SM §4b — skill_impact_score: measure whether learn sessions improve metrics

**Item**: issue-717
**Design doc**: `docs/design/31-stage-2-skills-expansion.md`
**Section**: `§ Future` (🔲 → ✅)

## Design reference

- **Design doc**: `docs/design/31-stage-2-skills-expansion.md`
- **Section**: `§ Future`
- **Implements**: "Skill impact measurement" (🔲 → ✅)

---

## Zone 1 — Obligations (falsifiable)

**O1**: SM §4b includes a new block that runs once per 5 SM cycles. It reads `~/.otherness/agents/skills/PROVENANCE.md` for learn session dates (headers matching `^## YYYY-MM-DD`), then reads `docs/aide/metrics.md` for batch rows. For each learn session date, it computes a 10-batch rolling average of `needs_human` before the session date and after it.

**O2**: If the `after` average of `needs_human` is ≥ the `before` average (no improvement), AND ≥10 batches exist after the learn session date (not enough data → skip), AND no `[SKILL-IMPACT]` issue for that session date is already open, SM §4b opens a `kind/chore priority/low` issue titled `[SKILL-IMPACT] Learn session YYYY-MM-DD: no measurable reduction in needs_human after 10 batches`.

**O3**: The check is fully fail-open: if PROVENANCE.md is unreadable, metrics.md has <10 rows total, or comparison fails for any session, that session is skipped silently. No crash, no error. Missing data → skip, not error.

**O4**: Deduplication: before opening any `[SKILL-IMPACT]` issue, the check queries open issues with title containing `[SKILL-IMPACT]` and the session date — if one exists, it is skipped.

**O5**: The implementation is entirely within `agents/phases/sm.md` §4b bash block (after the MEANINGFUL_PRS block and before the metrics row append). No other file is modified except `docs/design/31-stage-2-skills-expansion.md` (design doc update: 🔲 → ✅).

**O6**: The log line `[SM §4b] Skill impact check: session YYYY-MM-DD before_avg=N.N after_avg=N.N improved=yes|no` appears for each session evaluated.

---

## Zone 2 — Implementer's judgment

- Where in §4b to insert: after the MEANINGFUL_PRS block, before the metrics row append. Runs once per 5 cycles.
- The `before` window: last 10 batch rows strictly before the session date. If <5 rows before: skip (not enough baseline).
- The `after` window: first 10 batch rows with dates >= session date. If <10 rows after: skip (not enough post-learn data).
- Use `needs_human` column (index 3, 0-indexed) as the primary impact metric. It's the most direct measure of agent quality.
- The `time_to_merge` column has mixed formats (~Xmin, —) making it harder to parse; keep it as future enhancement.

---

## Zone 3 — Scoped out

- `time_to_merge_avg_min` comparison (format is inconsistent across historical rows — future item).
- Tracking impact at individual skill file granularity (PROVENANCE.md maps sessions to skills, but the date-level check is sufficient for now).
- Retroactive analysis of historical sessions with <10 post-session batches (skip criterion covers this).
