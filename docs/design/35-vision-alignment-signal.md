# 35: Vision Alignment Signal — SM Detects Vision-Irrelevant Batches

> Status: Active | Created: 2026-04-20
> Applies to: otherness itself and all managed projects

---

## What this does

The SM health signal currently means "CI passed and no `[NEEDS HUMAN]` issues are open."
It says nothing about whether the batch advanced the product vision.

A batch that shipped 10 test coverage PRs with green CI is indistinguishable from a
batch that shipped 10 feature PRs — both report GREEN. This makes the health signal
useless for the human's primary question: *is the product moving forward?*

This design doc adds a **vision alignment check** to the SM health signal. After every
batch, SM checks whether at least one merged PR in the session moved a `🔲 Future` item
to `✅ Present` in a design doc. If not, health degrades to AMBER regardless of CI.
Two consecutive AMBER batches on this criterion trigger an automatic queue audit.

---

## Present (✅)

- ✅ 35.1 — SM §4f: `VISION_PR_COUNT` check — for each PR merged this session, title or body (first 500 chars) scanned for `docs/design/`, `🔲 →`, or `design doc` (case-insensitive). Excludes chore(sm)/metrics/batch/session-complete titles. If `VISION_PR_COUNT == 0`: health degrades to AMBER. `vision_aligned` boolean written to `state.json` each batch. (PR #688, 2026-04-21)
- ✅ 35.2 — SM §4f: vision-misaligned AMBER note — `THROUGHPUT_WARN` updated to include actionable guidance: "⚠️ N vision-aligned PRs. Queue may have drifted from design docs. Run /otherness.vibe-vision or check coord §1b." — shown in health comment only when `VISION_PR_COUNT == 0`; absent when vision-aligned PRs exist (PR #721, 2026-04-21)
- ✅ 35.3 — SM §4f: two-consecutive-AMBER trigger — when `consecutive_vision_misaligned >= 2` in `state.json`, SM §4f opens a `kind/chore priority/high` issue "Queue audit needed — 2 consecutive batches with no design-doc-backed PRs" (once only; skips if open issue already exists). Counter increments on each misaligned batch, resets to 0 on vision-aligned batch. (PR #762, 2026-04-21)

---

## Future (🔲)

- 🔲 35.2 — SM §4f: post AMBER note when vision-misaligned — include in health comment: "⚠️ 0 vision-aligned PRs this session. Queue may have drifted from design docs. Run vibe-vision or check coord §1b."
- 🔲 35.3 — SM §4a: two-consecutive-AMBER trigger — if `_state` shows `vision_aligned: false` for 2 consecutive batches, automatically open a `kind/chore priority/high` issue: "Queue audit needed — 2 batches with no design-doc-backed PRs."
- 🔲 35.4 — COORD §1b: vision-alignment filter — when claiming queue items, prefer items where the issue title or body references a design doc. Items with no design doc reference are labelled `size/xs priority/low` automatically and deprioritised below any item that does reference a design doc.
- 🔲 35.5 — `state.json`: add `vision_aligned` field (boolean, per-batch) — persisted to `_state` branch so the two-consecutive check in §4a can read historical values across sessions.

---

## Zone 1 — Obligations

**O1 — AMBER does not stop the loop.** Vision-misaligned AMBER is informational. The loop continues. The human is notified. Only RED (CI broken >24h) or `[NEEDS HUMAN]` stops progress.

**O2 — Design doc reference is the only criterion.** A PR counts as vision-aligned if and only if its title or body contains a string matching `docs/design/` or `design doc` or `🔲 →` or `spec \d+` (case-insensitive). No other heuristic. This is intentionally strict — if the agent is not citing design docs, it is not doing design-backed work.

**O3 — Metrics commits and session report PRs do not count.** PRs whose titles match `^chore\(sm\)|^chore\(metrics\)|batch \d+|session complete` are excluded from the count regardless of their body content.

**O4 — The two-consecutive-AMBER issue is opened once, not per-batch.** SM checks for an existing open issue with the title substring "Queue audit needed" before creating a new one.

---

## Zone 2 — Implementer's judgment

- The `VISION_PR_COUNT` check can be approximate — scanning PR titles and first 500 chars of body is sufficient. Full body scan is expensive and not needed.
- The `vision_aligned` field should be a simple boolean in `state.json`, not a ratio. The ratio is visible from the batch metrics; the signal needs to be a single bit for the two-consecutive check to be simple.
- COORD §1b deprioritisation: the simplest implementation is to sort the claim candidates so items with a `design ref:` or `docs/design/` substring in their issue body sort before items without it. No label changes needed — just claim order.

---

## Zone 3 — Scoped out

- Retroactively re-scoring past batches
- Per-phase (COORD/ENG/QA) alignment breakdown
- Weighting PRs by size or complexity
- Integration with GitHub Projects or external dashboards
