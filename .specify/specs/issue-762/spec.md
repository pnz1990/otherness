# Spec: SM §4a two-consecutive-AMBER trigger (35.3)

## Design reference
- **Design doc**: `docs/design/35-vision-alignment-signal.md`
- **Section**: `§ Future`
- **Implements**: 35.3 — SM §4a: two-consecutive-AMBER trigger — if `_state` shows `vision_aligned: false` for 2 consecutive batches, automatically open a `kind/chore priority/high` issue: "Queue audit needed — 2 batches with no design-doc-backed PRs." (🔲 → ✅)

---

## Zone 1 — Obligations

**O1** — When SM §4a reads `_state` and finds `vision_aligned: false` for 2 or more consecutive batches (tracked via `consecutive_vision_misaligned` counter in `state.json`), it must open a GitHub issue with title containing "Queue audit needed" and body explaining the trigger.
- Violation: issue not opened after 2 consecutive `vision_aligned: false` batches.

**O2** — The issue must have labels `kind/chore,priority/high,area/agent-loop,otherness`.
- Violation: labels missing or wrong.

**O3** — The issue must NOT be opened if an open issue already exists with title matching "Queue audit needed" (per design doc O4 — open once, not per-batch).
- Violation: duplicate issues created on consecutive batches.

**O4** — The `consecutive_vision_misaligned` counter must be reset to 0 when `vision_aligned: true`.
- Violation: counter not reset, causing false triggers after recovery.

**O5** — The counter must be persisted in `state.json` via the standard STATE MANAGEMENT write block so it survives across sessions.
- Violation: counter resets every session (not persisted).

---

## Zone 2 — Implementer's judgment

- Read `vision_aligned` from `state.json` after SM §4f writes it (§4a runs before §4f, but we use the value from the _state branch which was written by the previous session's §4f).
- Actually: §4a runs at the START of a batch. The current session's `vision_aligned` is written at the END by §4f. So the two-consecutive check must read `consecutive_vision_misaligned` from state.json (a counter SM §4f increments when `vision_aligned: false` and resets when `vision_aligned: true`).
- Simplest implementation: SM §4f increments `consecutive_vision_misaligned` in state.json when it sets `vision_aligned = False`, resets to 0 when `vision_aligned = True`. SM §4a reads this counter from `_state` at batch start and opens the issue if counter >= 2.
- The check can be placed in SM §4a (triage section) or §4f right after writing vision_aligned.
- To keep the logic co-located with the vision_aligned write: place in §4f right after the existing vision_aligned block.

---

## Zone 3 — Scoped out

- Retroactive calculation from metrics.md
- Auto-closing the queue audit issue when alignment recovers
- Per-session vs per-batch granularity (use per-batch via state.json)
