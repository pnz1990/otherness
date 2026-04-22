# Spec: Metrics Trend Surfacing in SM Health Comment

**Item**: issue-719

## Design reference
- **Design doc**: `docs/design/33-stage-4-self-improvement-metrics.md`
- **Section**: `§ Future`
- **Implements**: 5-batch rolling trend for `time_to_merge_avg_min` and `needs_human` in SM §4f health comment (🔲 → ✅)

---

## Zone 1 — Obligations

**O1** — SM §4f computes a 5-batch rolling trend for `time_to_merge_avg_min` using the last 5 rows in `docs/aide/metrics.md`. If fewer than 2 rows are available, the trend is skipped (not shown). Violation: trend computed from <2 rows or missing when ≥5 rows exist.

**O2** — SM §4f computes a 5-batch rolling trend for `needs_human` using the last 5 rows in `docs/aide/metrics.md`. Same ≥2 row minimum applies. Violation: as above.

**O3** — The trend is expressed as direction and pct change: `⬆️ time-to-merge up 40% over last 5 batches (trend: bad)` or `⬇️ needs-human down 60% over last 5 batches (trend: good)`. Direction: ⬆️ = increase, ⬇️ = decrease. Verdict: for `time_to_merge_avg_min`, increase = bad; for `needs_human`, increase = bad, decrease = good. A 0% change = neutral (no arrow, no verdict). Violation: wrong direction symbol or verdict.

**O4** — The trend lines are included in the `<details>` block of the SM health comment (not in the headline). Violation: trend absent from comment when ≥2 rows present.

**O5** — When a trend is unfavorable for 3 **consecutive** batches (worsening each batch): SM opens a `kind/chore priority/high` issue titled `"SM trend alert: <metric> worsening for 3 consecutive batches (slope: +N%/batch)"`. Dedup guard: if an open issue with the same metric already exists, do not open a duplicate. Violation: issue not opened after 3 consecutive worsening batches, or duplicate opened when issue already open.

**O6** — The trend computation reads `time_to_merge_avg_min` (col index 7, 0-based) and `needs_human` (col index 3) from `docs/aide/metrics.md` data rows. `—` and non-numeric values are treated as missing and excluded from average computation. Violation: wrong column read, crash on `—` or empty values.

**O7** — Fail-open: if `docs/aide/metrics.md` is missing, unreadable, or has <2 data rows, trend is silently skipped (no error, no AMBER). Violation: exception or AMBER triggered by missing metrics file.

---

## Zone 2 — Implementer's judgment

- The trend pct is computed as: `(avg(last_5) - avg(first_5_in_last_5)) / avg(first_5_in_last_5) * 100` — or more simply: `(last_val - first_val) / first_val * 100` when comparing first vs last of the last 5 rows.
- "Consecutive worsening" is detected by reading the consecutive_worsening_<metric> counter from state.json (initialized to 0 if absent).
- The consecutive counter resets to 0 when a batch shows improvement or neutral.
- Any reasonable numeric diff approach that satisfies O3 and O5 is acceptable.

---

## Zone 3 — Scoped out

- Trend for metrics other than `time_to_merge_avg_min` and `needs_human` (not in this item)
- Changing the HEALTH signal based on trends (not in this item — only opens an issue)
- Historical trend charts or graphs (out of scope)
- Removing or replacing the existing health comment format (only adding to details block)
