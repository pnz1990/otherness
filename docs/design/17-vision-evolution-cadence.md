# 17: Vision Evolution Cadence

> Status: Active | Created: 2026-04-19
> Applies to: otherness itself and all managed projects

---

## The goal

"An ever-evolving vision" is not a metaphor. It is a design requirement. The system
must have a mechanism that ensures the vision does not freeze — that new intent is
regularly introduced, that design docs grow, that the queue never permanently empties
because the vision keeps expanding.

The system is currently designed well for executing against a vision. It is not yet
designed to evolve the vision autonomously when the human is absent.

---

## Three sources of new vision

The system has three mechanisms for introducing new Future items into the queue.
Each operates at a different level of autonomy.

### Source 1: Human-initiated (vibe-vision)

The human runs `/otherness.vibe-vision`. This is the highest-fidelity source — it
encodes human intent directly into design doc stubs. Nothing replaces this.

The gap: there is no mechanism to detect when the human should run vibe-vision.
The system sits in standby but does not ask "has the vision evolved recently?"

**Fix**: PM §5 checks the age of the last vibe-vision session (last `docs/design/`
file with `⚠️ Inferred` or a human-authored commit to a design doc). If >30 days
with no new design doc activity AND the queue is empty: PM posts a prompt on the
report issue: `"[📋 PM] The vision has not been updated in 30 days and the queue
is empty. Consider running /otherness.vibe-vision to expand the roadmap."`

This is a suggestion, not a [NEEDS HUMAN]. The system does not stop. It proposes.

### Source 2: Competitive observation (PM §5c)

Every 10 PM cycles, the PM checks competitor releases (Kargo, GitOps Promoter, etc.)
and notes capabilities the managed project doesn't have. Each gap opens a kind/enhancement
issue as a candidate Future item for the next vibe-vision session.

This is already designed but not yet connected to the vibe-vision trigger. The fix:
PM §5c findings are written to `docs/design/` as a `⚠️ Inferred` stub, making them
automatically visible to COORD queue generation without requiring a vibe-vision session
for low-risk, clearly-scoped items.

### Source 3: Self-generating (PM §5h)

PM §5h scans ✅ Present items and checks definition-of-done.md for coverage gaps.
Already designed. The further extension: PM §5h also checks the shipped Present items
for *emergent patterns* — capabilities that exist in the code but were never explicitly
designed. These become `⚠️ Observed` design doc entries, which the human can confirm
as canonical or deprecate.

---

## The vision evolution cycle

```
Human intent (vibe-vision)
         ↓
   docs/design/*.md  ←── PM §5c competitive observations (⚠️ Inferred)
         ↓                PM §5h self-generating criteria (⚠️ Observed)
   COORD queue gen
         ↓
   Implementation (otherness.run)
         ↓
   ✅ Present markers + PM health signal
         ↓
   PM §5: vision age check → prompt human if >30d empty queue
         ↓
         └──────────── back to Human intent
```

The cycle is never-ending. The vision evolves at the human's pace when the human is
active. When the human is absent, the system adds inferred and observed items from
competitive observation and self-scanning. The human can confirm or reject these on
their next vibe-vision session.

---

## The "ever-evolving" invariant

At no point should the system be in a state where:
- The queue is permanently empty AND
- No new items will ever arrive AND
- The health is GREEN

If all three are true simultaneously, the system is frozen — it has reached the end
of the vision. That is not the goal. The goal is that the vision always expands
faster than the implementation catches up.

The PM §5 vision age check is the guard: when the queue has been empty for >30 days
with no new design doc activity, propose a vibe-vision session. This ensures the
system never freezes.

---

## Present (✅)

- ✅ PM §5k: vision age check — posts vibe-vision suggestion when queue empty AND no design doc activity >30 days; one post per period; not a blocker (PR #307-310, 2026-04-19)
- ✅ PM §5c: competitive gap findings written as `⚠️ Inferred` design doc stubs — visible to COORD queue gen immediately (PR #307-310, 2026-04-19)
- ✅ PM §5h extension: emergent pattern detection — PRs merged with no design doc coverage flagged as `⚠️ Observed` stubs (PR #307-310, 2026-04-19)
- ✅ Marker conventions: `docs/design/00-marker-conventions.md` defines ✅/🔲/⚠️ Inferred/⚠️ Observed/🚫 (PR #307-310, 2026-04-19)

## Future (🔲)

*(All planned vision evolution items shipped.)*

---

## Zone 1 — Obligations

**O1 — The system never declares the vision complete.**
Standby means "nothing to do right now," not "vision achieved."

**O2 — When queue is empty >30 days, PM suggests vibe-vision.**
One post on the report issue. Not a [NEEDS HUMAN] block. The loop continues in standby.

**O3 — Competitive observations produce design doc stubs, not just issues.**
PM §5c findings go to `docs/design/<area>-competitive-gaps.md` as `⚠️ Inferred` items,
making them visible to COORD queue gen without requiring explicit human vibe-vision
sessions for well-scoped gaps.

**O4 — The human is never required to restart the vision.**
The system adds candidate future items autonomously from observation and competitive
scanning. The human validates and shapes them at their own cadence via vibe-vision.
