# Spec: SM §4f Two-Axis Batch Report Signal

## Design reference
- **Design doc**: `docs/design/35-quality-of-output-gaps.md`
- **Section**: `§ Future`
- **Implements**: `SM §4f` batch report format: replace generic GREEN/AMBER/RED with a two-axis signal: `progress: <ADVANCING|STABLE|STALLED>` + `health: <GREEN|AMBER|RED>`; "advancing" requires ≥1 vision PR; "stable" means chores only; "stalled" means silent session; the human should be able to read the batch report and immediately know if the product moved (🔲 → ✅)

---

## Zone 1 — Obligations

**O1**: The SM §4f batch report comment MUST include a `progress:` field with one of three values: `ADVANCING`, `STABLE`, or `STALLED`.

**O2**: `progress: ADVANCING` if and only if `VISION_PRS ≥ 1` (at least one design-doc-backed PR merged this session).

**O3**: `progress: STABLE` if and only if `VISION_PRS == 0` AND the session merged at least one PR (chores only — something shipped but not vision work).

**O4**: `progress: STALLED` if and only if the session has `0 merged PRs AND 0 open PRs` (silent session).

**O5**: The `health:` field remains `GREEN|AMBER|RED` — it is NOT replaced by `progress:`. Both axes coexist in the same comment.

**O6**: The batch report comment format MUST be human-readable in ≤8 lines and immediately convey: (a) did the product move? (`progress:`), (b) is the system healthy? (`health:`).

**O7**: The `progress:` signal must be exported as an environment variable `SESSION_PROGRESS` for downstream use (e.g. state.json writes).

**O8**: Backward compatibility: the existing `SESSION_OUTCOME` variable (`feature-rich`/`mixed`/`chore-only`) is preserved alongside the new `progress:` field — they are computed independently.

---

## Zone 2 — Implementer's judgment

- Whether to display `progress:` before or after `health:` in the comment body: prefer `progress:` first (it's the primary user-facing signal).
- Whether to use emoji for progress states: ADVANCING=🚀, STABLE=🔄, STALLED=⚠️ — optional, use if it aids readability.
- The `MERGED` count variable may come from `§4b` or from a fresh `gh pr list` call; use whichever is already set to avoid redundant API calls.

---

## Zone 3 — Scoped out

- Changing the `health:` RED/AMBER/GREEN computation logic (that is separate work)
- Adding `progress:` to `progress.md` (may be done as a follow-up)
- Backfilling historical metrics.md rows with a `progress:` column
- Any changes to the `SESSION_OUTCOME` classification logic in §4b
