# 14: Eternal Loop — Stop Condition and "Final Run" Clarity

> Status: Active | Created: 2026-04-19
> Applies to: otherness itself and all managed projects

---

## The problem this solves

The agent said "this is the final run" three times in three consecutive sessions.
Each time it was wrong. The loop kept running because the STOP CONDITION was not met.

The failure was communication: the agent used "final" to mean "the queue is clean and
the architecture is correct." The STOP CONDITION means something precise: all journeys
✅ validated live AND a human says "stop." These are different things. The agent must
never say "final run" or "ready" unless it has checked the STOP CONDITION literally.

There is a second, deeper issue. The STOP CONDITION in the current codebase is a
**termination condition** — a moment when the loop exits. But the system's intended
behavior is not to terminate. It is to run perpetually, entering standby when there
is nothing to do, restarting when new intent arrives. A termination-framed stop
condition is the wrong model for an eternal system.

This design doc replaces the termination framing with a **health signal framing**.

---

## The new model: READY ≠ DONE

| State | What it means | Agent says |
|---|---|---|
| **READY** | Queue clean, architecture correct, all design docs ✅ | "System is ready. Entering standby." |
| **HEALTHY** | PM §5g GREEN, journeys passing, no open needs-human | "Health: GREEN. No action required." |
| **STANDBY** | READY + HEALTHY + no new Future items | "Standby. Watching for new vision." |
| **DONE** (human-only) | Human explicitly says "stop" | Never said by the agent |
| **COMPLETE** (incorrect framing) | Agent believes it has finished | Never said — this framing is wrong |

The agent never says "final run." The agent never says "the system is complete."
The agent reports its health signal and enters standby. That is all.

---

## What triggers exit from standby

Standby is not dormancy. The agent checks every 60s:

1. **New Future items in any design doc** — triggers queue generation and a new batch
2. **PM §5g AMBER** — triggers automatic `/otherness.learn`
3. **PM §5g RED** — triggers `[NEEDS HUMAN]` issue
4. **New vibe-vision output** — new `docs/design/` stubs with 🔲 items → triggers queue
5. **Journey regression** — a previously ✅ journey starts failing → opens bug issue

None of these require human action to restart the loop. The loop restarts itself.
The human's role is to add new vision (via `/otherness.vibe-vision`) or confirm a RED
signal requires their judgment. Everything else is autonomous.

---

## What the agent reports at the end of each batch

Instead of "final run complete," the agent posts:

```
[STANDALONE | session | version] Batch N complete.
Health: GREEN | AMBER | RED
Journeys: 1✅ 2❌ 3✅ 4✅ 5✅ 6✅
Queue: N todo | N in_review | N done
Action: Standby (watching for new vision) | Active (N items in queue) | Self-correcting (AMBER)
```

This is objective. It does not imply termination. It does not create false expectations.

---

## Present (✅)

- ✅ standalone.md: "final run" framing removed from LOOP section; loop description updated to perpetual language (PR #292-294 batch, 2026-04-19)
- ✅ standalone.md HARD RULES: "Never report finality" rule added — explicit ban on "final run", "system complete", "the system is ready" (PR #292-294 batch, 2026-04-19)
- ✅ SM §4f: batch completion post now uses health signal format — Health: GREEN/AMBER/RED | Queue: N todo | Action: Standby/Active (PR #292-294 batch, 2026-04-19)

## Future (🔲)

- ✅ definition-of-done.md: Journey Status table has Health column (GREEN/AMBER/RED) + Journey 8 (commands always current) added (2026-04-19)

---

## Zone 1 — Obligations

**O1 — The agent never uses the words "final run," "complete," or "done" to describe the system state.**
These words imply the loop ends. The loop does not end. Any agent output containing
"final run" or "system complete" is a communication failure.

**O2 — At the end of every batch, the agent posts a health signal in the standard format.**
The format: `Health: <GREEN|AMBER|RED> | Journeys: <N>✅ <M>❌ | Queue: N todo | Action: <Standby|Active|Self-correcting>`

**O3 — "Standby" is the correct terminal state when there is nothing to do.**
Standby is not stop. The agent wakes from standby when new items appear. This behavior
is implemented in the perpetual loop trigger (doc 12).

**O4 — The STOP CONDITION check is literal before any session-end language.**
If the agent is about to say anything that implies the session is ending, it must first
run: `all journeys ✅ AND human said stop?` If no: report health signal and continue.
