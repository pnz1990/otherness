# Spec: Perpetual loop trigger

> Item: 280 | Created: 2026-04-18 | Status: Active

## Design reference
- **Design doc**: `docs/design/12-perpetual-validation.md`
- **Section**: `## Future`
- **Implements**: Perpetual loop trigger (🔲 → ✅)

---

## Zone 1 — Obligations

**O1 — standalone.md LOOP contains a perpetual trigger check at the start of each cycle.**
At the top of the LOOP (before Phase 1), standalone.md must check whether there are
any new queue items (state has todo items, or design docs have unqueued Future items).
This is already implicit in the loop structure — the explicit addition is a comment
block that documents the standby mode behavior.

Behavior that violates this: the loop exits on empty queue rather than entering standby.

**O2 — The STOP CONDITION remains unchanged.**
The only valid exit is still: all journeys ✅ validated AND human says "stop" or
"confirmed complete". Empty queue is NOT a stop condition (this is already stated).
This PR adds documentation clarity but does not change the existing stop condition logic.

**O3 — A "standby mode" comment is added for when queue is empty and no new items.**
When the queue is empty (COORD finds no todo items and no new Future items in design docs),
standalone.md documents the expected behavior: "No new items. Re-checking in 60s."
This is the existing `sleep 60 && continue` path in coord.md — just made explicit.

**O4 — Design doc 12 marks Perpetual loop trigger as ✅ Present.**

---

## Zone 2 — Implementer's judgment

- Whether to change the loop behavior: NO. The loop already does this correctly —
  COORD already sleeps 60s on empty queue. This PR adds documentation clarity only.
- Where to add in standalone.md: a comment block at the start of THE LOOP section,
  explaining the perpetual behavior.
- Whether to add an explicit "standby mode" state: no new state needed.

---

## Zone 3 — Scoped out

- Actual code changes to the loop behavior (already correct)
- "Check daily" interval (loop already checks every ~60s on empty queue)
- Automatic restart on vibe-vision artifacts (handled by queue-gen reading design docs)
