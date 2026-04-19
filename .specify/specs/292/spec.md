# Spec: Health Signal Framing — items 292, 293, 294

> Items: 292, 293, 294 | Created: 2026-04-19 | Status: Active

## Design reference
- **Design doc**: `docs/design/14-eternal-loop-stop-condition.md`
- **Section**: `§ Future`
- **Implements**: standalone.md health signal framing + SM batch completion format (🔲 → ✅)

---

## Zone 1 — Obligations

**O1 — standalone.md removes all "final run" / "complete" language from the LOOP and HARD RULES sections.**
The LOOP description and HARD RULES must contain no language implying the session
ends or the system reaches completion. The phrase "final run" and "system is complete"
are explicitly banned.

Behavior that violates this: standalone.md still contains "final" or "complete" as
a descriptor of system state (not as a technical term like "git cherry-pick --continue").

**O2 — standalone.md HARD RULES gains an explicit rule: "Never report finality."**
New rule: "**Never report finality.** Do not say 'final run', 'system complete', or
'done'. At batch end: post health signal (GREEN/AMBER/RED), journey counts, and queue
state. Enter standby — not stop."

**O3 — sm.md Phase 4 batch completion post uses health signal format.**
The SDM batch completion comment (posted on REPORT_ISSUE after every batch) must
include: `Health: <GREEN|AMBER|RED> | Journeys: N✅ M❌ | Queue: N todo | Action: <Standby|Active|Self-correcting>`

Behavior that violates this: SDM posts "Batch complete." without the health signal.

**O4 — Health is GREEN when: CI green + 0 open needs-human + Journey 1 passing.**
GREEN does not require Journey 2 to pass (external dependency). It requires the
system to be locally healthy and able to do work.

---

## Zone 2 — Implementer's judgment

- Whether to add health computation to a function: no — [AI-STEP] in sm.md is sufficient.
- Where in standalone.md to add the "Never report finality" rule: at the end of HARD RULES, as the last bullet.
- Whether LOOP description needs rewording: yes — remove "completing one batch does NOT end the session" framing and replace with perpetual health language.

---

## Zone 3 — Scoped out

- Actual GREEN/AMBER/RED computation (that's PM §5g — doc 12, already designed)
- Journey 2 counting toward GREEN (external dependency)
- Retroactive fixing of past batch posts
