# 34: Stage 9 — Autonomous Vision Synthesis

> Status: Active | Created: 2026-04-20
> Mirrors: docs/design/30-stage-0-scaffolding.md pattern (one doc per completed stage)
> Applies to: otherness itself

---

## Stage goal

`/otherness.run` is perpetually self-sustaining when no human is present. When the queue empties and no human runs `/otherness.vibe-vision`, an autonomous vision agent reads the system's own knowledge corpus and synthesizes new `🔲 ⚠️ Inferred` Future items. The loop restarts itself.

The human remains the highest-fidelity source of direction — but between human sessions, the system maintains its own momentum.

From `docs/aide/roadmap.md` §Stage 9:

> **Goal**: The loop never stalls waiting for a human to bring new direction. When the queue empties and no human is present, an autonomous vision agent reads the system's own knowledge corpus and synthesizes new `🔲 ⚠️ Inferred` Future items. The loop restarts itself.

---

## Deliverables

| Deliverable | Status | PR | Date |
|---|---|---|---|
| `agents/autonomous-vision.md` — MODE: VISION, no dialogue; 4-phase batch process | ✅ Shipped | #313 | 2026-04-19 |
| SM §4h trigger — queue empty + conditions + rate limit: create vision branch, run agent | ✅ Shipped | #314 | 2026-04-19 |
| PM §5m: `⚠️ Inferred` ratio check — posts vibe-vision suggestion when >80% machine-generated | ✅ Shipped | #315, #318 | 2026-04-20 |
| COORD queue gen: strips `⚠️ Inferred/Observed:` prefix before dedup | ✅ Shipped | #316 | 2026-04-19 |
| Journey 9 in definition-of-done | ✅ Shipped | #563 | 2026-04-20 |
| State tracking: `last_auto_vision_cycle` persisted to `state.json` | ✅ Shipped | #314 | 2026-04-19 |

---

## Stage completion threshold

From `docs/aide/roadmap.md` §Stage 9:

> The queue empties. No human runs `/otherness.vibe-vision`. Within one SM cycle, the autonomous vision agent produces at least 3 `🔲 ⚠️ Inferred` items. COORD picks them up. A new batch runs. The loop never entered true standby.

**Status: ✅ VALIDATED** — Batch 87 (2026-04-20): queue emptied, SM §4h triggered, 4 ⚠️ Inferred items synthesized (PR #558), COORD queued 3 as GitHub issues (#559, #560, #561), 2 shipped in same batch (#559, #560).

---

## Present (✅)

- ✅ `agents/autonomous-vision.md` — MODE: VISION, no dialogue; corpus reading, rule-based synthesis (5 patterns), ⚠️ Inferred item writing, commit (PR #313, 2026-04-19)
- ✅ SM §4h trigger — checks 4 conditions (queue empty, no ⚠️ stubs, health GREEN/AMBER, ≥3 cycles since last run); creates `vision/auto-<date>` branch; runs autonomous-vision.md (PR #314, 2026-04-19)
- ✅ `state.json` `last_auto_vision_cycle` — persisted so rate limit tracks across sessions (PR #314, 2026-04-19)
- ✅ COORD queue gen — `is_done()` strips `⚠️ Inferred/Observed:` prefix before deduplication (PR #316, 2026-04-19)
- ✅ PM §5m — `⚠️ Inferred` ratio check: if >80% Future items are machine-generated, posts vibe-vision suggestion on report issue (PR #315, PR #318 header, 2026-04-20)
- ✅ Journey 9 in `docs/aide/definition-of-done.md` — automated check commands + pass criteria (PR #563, 2026-04-20)
- ✅ validate.sh check [7/7] — ⚠️ Inferred/Observed items must have source attribution `(source, YYYY-MM-DD)` (PR #562, 2026-04-20)

## Future (🔲)

*(No unimplemented items — Stage 9 is complete.)*


---

## Zone 1 — Obligations

**O1 — The autonomous vision agent writes only `🔲 ⚠️ Inferred` items, never plain `🔲`.**
Plain `🔲` is reserved for human-scoped intent. The marker distinction is the only signal the human has about provenance.

**O2 — The SM §4h trigger has a rate limit: at least 3 batches between autonomous runs.**
Without this, the agent floods the queue with machine-generated items.

**O3 — The `⚠️ Inferred` ratio is tracked and surfaced to the human when >80%.**
PM §5m reports the ratio. The system never silently becomes purely machine-directed.

---

## Zone 2 — Implementer's judgment

- First version: rule-based synthesis (5 patterns). LLM-assisted synthesis is a future evolution.
- Items synthesized per run: 3–5 maximum. Never flood.
- PR lifecycle for vision synthesis: open PR from `vision/auto-<date>` branch, CI passes, autonomous merge. No CRITICAL tier gatekeeping for DOCS zone changes.

---

## Zone 3 — Scoped out

- LLM-assisted synthesis in first version
- Cross-project autonomous vision (Stage 9 is otherness-self only)
- Autonomous modification of `vision.md` or `roadmap.md`
