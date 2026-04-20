# Spec: feat: PM §5m — ⚠️ Inferred ratio check executable

## Design reference
- **Design doc**: `docs/design/18-autonomous-vision-synthesis.md`
- **Section**: `§ PM §5m`
- **Implements**: PM §5m: `⚠️ Inferred` ratio check — if >80% of Future items are `⚠️ Inferred`, post vibe-vision suggestion (🔲 → ✅)

---

## Zone 1 — Obligations

**O1** — Count total `🔲 Future` items and `⚠️ Inferred` subset across all `docs/design/*.md`.
`⚠️ Inferred` items are those matching `⚠️ Inferred` or `⚠️ Observed` in the Future section.

Violation: counting wrong (e.g. counting from issue queue instead of design docs).

**O2** — If `inferred_count / total_future > 0.8` AND `total_future > 0`, post a comment
on `REPORT_ISSUE` (not a `[NEEDS HUMAN]` issue) suggesting `/otherness.vibe-vision`.
Comment must be deduplicated (one per PM cycle run, checked via `--search "Inferred items are"`).

Violation: opens a `[NEEDS HUMAN]` issue instead of commenting; or duplicate comments.

**O3** — The check is informational only. The loop continues regardless of the ratio.

Violation: check blocks or pauses the loop.

**O4** — If `total_future == 0`: skip silently (no error, no comment).

Violation: division by zero error or spurious comment when no Future items exist.

---

## Zone 2 — Implementer's judgment

- Whether to use report issue comment or separate issue: comment on REPORT_ISSUE is sufficient.
  It's a signal, not an actionable item. The design doc spec says "post vibe-vision suggestion".
- How to check for deduplication: `gh issue list --search "Inferred items are"` matches
  on open issues. But this is a comment, not an issue. Use a flag file check or just 
  always post (it's an informational signal, not a blocker).
  Actually: post unconditionally when ratio > 0.8 (it's on the report issue, not a separate issue).

---

## Zone 3 — Scoped out

- Automatically triggering `/otherness.vibe-vision` (that requires human consent)
- Filtering which design docs count (all docs/design/*.md are counted)
- Inferred ratio trending over time
