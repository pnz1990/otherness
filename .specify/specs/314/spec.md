# Spec: SM phase trigger for autonomous vision synthesis

> Item: 314 | Created: 2026-04-19 | Status: Active

## Design reference
- **Design doc**: `docs/design/18-autonomous-vision-synthesis.md`
- **Section**: `§ Future`
- **Implements**: SM phase trigger — when queue empty + conditions met, run autonomous-vision agent (🔲 → ✅)

---

## Zone 1 — Obligations

**O1 — SM phase has a §4h autonomous vision trigger.**
A new SM §4h section checks conditions and, when all are met, creates a
`vision/auto-<date>` branch and reads/follows `agents/autonomous-vision.md`.
The check runs every SM cycle (not rate-limited to 10).

**O2 — The trigger fires only when all four conditions are true:**
1. Queue is empty (0 todo, 0 in_review in state.json)
2. No pending ⚠️ Inferred or ⚠️ Observed stubs awaiting conversion (in design docs)
3. PM §5g health is GREEN or AMBER (not RED)
4. At least 3 SM cycles since last autonomous vision run (stored in state.json as `last_auto_vision_cycle`)

**O3 — After the agent runs, SM records the cycle number in state.json.**
`state.json.last_auto_vision_cycle = SM_CYCLE`

**O4 — Design doc 18 marks this ✅ Present.**

---

## Zone 2 — Implementer's judgment

- CRITICAL-B: all new content is [AI-STEP] comments in sm.md.
- `agents/autonomous-vision.md` does not exist yet (item 313). The [AI-STEP]
  references it — when 313 ships, the trigger becomes executable.
- The 3-cycle rate limit prevents flood synthesis.

---

## Zone 3 — Scoped out

- Counting pending ⚠️ stubs (complex; condition 2 is advisory in first version)
- Configurable rate limit (3 cycles is hardcoded in first version)
