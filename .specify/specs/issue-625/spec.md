# Spec: SM §4f batch report condensed format

## Design reference
- **Design doc**: `docs/design/35-quality-of-output-gaps.md`
- **Section**: `§ Future`
- **Implements**: `SM §4f` batch report condensed format — report issue comment must fit in 8 lines; adopt structured terse format with `<details>` block for verbose content (🔲 → ✅)

---

## Zone 1 — Obligations (falsifiable)

**O1 — Condensed headline fits in ≤8 lines.**
The `gh issue comment` body posted by SM §4f must have a summary line followed by at most 7 additional lines of structured data before any `<details>` block. A human can scan 10 such comments in 30 seconds.

**O2 — Structured terse format is used.**
The headline line must match the pattern:
`Batch {N} | Health: {GREEN/AMBER/RED} | Progress: {ADVANCING/STEADY/STALLED} | Vision PRs: {N} | Chores: {N} | Queue: {N} remaining | Journeys: {N}✅ {N}❌ | Next: [{item title}]`

**O3 — Verbose details move to `<details>` block.**
All diagnostic text (session ID, otherness version, silent-session count, skill decay, etc.) that existed in the old comment must be preserved inside a `<details><summary>Details</summary>...</details>` HTML block appended after the headline.

**O4 — `Progress` classification is defined.**
- `ADVANCING`: `vision_prs > 0`
- `STEADY`: `vision_prs == 0` but `merged > 0` (chore-only progress)
- `STALLED`: `merged == 0`

**O5 — `Journeys` counts come from `definition-of-done.md`.**
The Journeys column shows how many journeys are ✅ validated (passing `gh run` or known working) vs ❌ blocked. If not computed, show `?✅ ?❌`.

**O6 — `Next` shows the next todo item title.**
Read the first `state=todo` item from `state.json` (same sort order as COORD claim). Truncate to 40 chars.

**O7 — `Chores` is distinct from `Vision PRs`.**
Chores = merged PRs in the last batch with `kind/chore` label or titles matching `chore|metrics|session`. Vision PRs = the existing `VISION_PRS` variable.

---

## Zone 2 — Implementer's judgment

- How to count Journeys: use a simple count from `definition-of-done.md` headers vs a live test run. Preference: count `##` sections in `definition-of-done.md` as total journeys; count those with `✅` in a recent PM §5b validation result stored in state. If no validation data: show `?✅ ?❌`.
- Whether to compute `Chores` inline or from an existing variable: compute inline from `MERGED` minus `VISION_PRS`.
- Format of `<details>` block: one `<summary>Details</summary>` with existing verbose content.

---

## Zone 3 — Scoped out

- Changing the `progress.md` update logic (separate issue #627)
- Adding a machine-readable JSON summary (separate item)
- Changing when §4f fires (already every batch)
- Modifying the silent-session detection logic itself
