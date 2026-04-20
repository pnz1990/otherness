# Spec: Automated `docs/aide/progress.md` update in SM §4f

## Design reference
- **Design doc**: `docs/design/06-command-surface.md`
- **Section**: `§ Future`
- **Implements**: Automated `docs/aide/progress.md` update in SM §4f (🔲 → ✅)

---

## Zone 1 — Obligations (falsifiable)

**O1 — SM §4f must update `docs/aide/progress.md` every batch.**
After each SM cycle, `docs/aide/progress.md` is overwritten with current data.
Violation: `progress.md` still contains content from a previous batch after SM §4f completes.

**O2 — `progress.md` must include: current stage, last-shipped PR title and date, queue depth, health signal.**
The file must contain all four fields visible to a human reading it.
Violation: any of these four fields is absent or shows stale data (older than the current batch).

**O3 — The update is committed to main directly by SM (not as a PR).**
SM commits `docs/aide/progress.md` to `main` via a direct low-risk commit (same pattern as existing SM §4e metrics.md commit).
Violation: `progress.md` update requires a PR review step, or SM skips it if no PR was shipped this batch.

**O4 — The update always runs, even if no PR was shipped this session.**
SM §4f updates `progress.md` regardless of whether `VISION_PRS > 0`.
Violation: `progress.md` is only updated when work was shipped.

**O5 — The health signal in `progress.md` matches the health signal posted to the report issue.**
Both outputs are computed from the same source data in the same SM §4f pass.
Violation: health signal in `progress.md` differs from the signal posted in the issue comment.

---

## Zone 2 — Implementer's judgment

- Whether to commit directly to `main` or open a PR: commit directly to `main` (low-risk doc commit, same as metrics.md in §4e).
- Format of `progress.md`: keep existing structure but overwrite the dynamic fields. Do not remove stage completion table or milestone history — only update the header fields.
- How to determine "last-shipped PR": use `gh pr list --state merged --limit 1` filtered to non-chore/non-session PRs; fall back to most recent merged PR if none.
- How to determine "current stage": read from existing `progress.md` header (do not auto-detect from code — that is out of scope for this item). SM can only update what it knows: queue depth and health. Stage advancement requires human or PM intervention.
- Retry behavior on commit failure: up to 2 retries with `git pull --rebase` then `git push`. Log failure but do not block session.

---

## Zone 3 — Scoped out

- Auto-detecting stage advancement from code state — stage progression is human-driven per the roadmap.
- Reformatting or restructuring `progress.md` beyond updating dynamic fields.
- Updating `progress.md` from phases other than SM §4f.
- Adding metrics graphs or visualizations to `progress.md`.
