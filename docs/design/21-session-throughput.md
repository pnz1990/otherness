# 21: Session Throughput — Multiple Items Per Session, Larger Queue

> Status: Active | Created: 2026-04-20
> Applies to: all projects using otherness

---

## The problem

The autonomous loop ships approximately one item per hour. This is the throughput
ceiling that existed before this doc was written. It is not acceptable.

**Root cause 1: One item per session, hard stop.**

The `anomalyco/opencode/github` action calls `chat()` once per invocation. It runs
the agent's full prompt, waits for a response, checks if the repo is dirty, pushes
changes, creates a PR, and exits. The agent's `MANDATORY INFINITE LOOP` instruction
has no effect — the action process terminates after the first completed item.

This means: hourly cron × 1 item/session = 1 item/hour ceiling. In practice lower,
because some sessions are occupied by SM/PM phases with no implementation work.

**Root cause 2: Queue refills slowly.**

COORD generates a maximum of 5 issues per queue-gen. With 1 item/session throughput,
a 5-item queue empties in 5 hours. The next session runs COORD, finds an empty queue,
generates 5 more items, and claims 1 of them. Net work: 1 item. Two of those 5 hours
were wasted on queue-gen overhead and SM/PM busywork.

**Root cause 3: Items are too small and too safe.**

The agent optimizes for items that are fast to implement and easy to QA (size/xs,
size/s, docs-debt). High-value items (size/m, size/l, architectural changes) are
deferred because they take longer and increase QA risk. Over time the queue fills
with chores while substantive work stalls.

---

## What "fixed" looks like

A session running for 30 minutes ships 3–5 items. A session running for 2 hours
ships 10–15 items. The human checks in every few days and sees dozens of PRs merged,
not 3–4.

The throughput floor for a healthy project: **≥3 items per session**.
The throughput target for an active project: **≥8 items per session**.

---

## Fix A — Multi-item sessions

**Mechanism:** After completing one item (ENG → QA → merge), COORD does not hand off
to SM/PM. Instead, it checks the queue for the next available unclaimed item and
immediately claims it. ENG → QA → merge. Repeat. SM/PM run once at the end of the
session, not after every item.

**Implementation:** In `coord.md`, after the `BATCH COMPLETE` signal:
- Check queue for remaining todo items
- If items remain AND session has budget (< `session_item_limit` items completed):
  loop back to §1e (claim next item) without entering SM/PM
- SM/PM gate: run only when queue is empty OR `session_item_limit` reached

**`session_item_limit`:** Configurable per project via `otherness-config.yaml`.
Default: `10`. Projects with slower CI or complex items can lower it. Projects
with fast CI and small items can raise it.

```yaml
# otherness-config.yaml
maqa:
  session_item_limit: 10   # max items to complete before SM/PM gate
```

**Session budget tracking:** Each session tracks `items_completed` in memory
(not in `_state` — no write needed). When `items_completed >= session_item_limit`,
the session runs SM/PM and exits normally.

---

## Fix B — Larger queue

**Mechanism:** Increase the queue generation cap from 5 to 20 items.

**Rationale:** With multi-item sessions, the agent can consume 10+ items per session.
A 5-item queue empties in one session, causing the next session to spend its entire
budget on queue-gen overhead. A 20-item queue provides enough work for 2–4 sessions
before refill is needed.

**Source priority for queue items:**
1. `🔲 Future` items in `docs/design/` files (highest fidelity — human-authored)
2. `🔲 ⚠️ Inferred` items synthesized by the autonomous vision agent (Stage 9)
3. Roadmap items not yet tracked as design doc Future items
4. PM §5h journey gap issues (runtime failures that need fixing)

**Minimum queue depth guard:** If queue drops below 5 items AND no new design doc
items are available, COORD triggers the autonomous vision agent to synthesize new
`🔲 ⚠️ Inferred` items before the queue hits zero. Prevents the stall-then-refill
cycle that wastes sessions on overhead.

---

## Fix C — Richer queue generation (Future item, tracked in §22)

See `docs/design/22-queue-richness.md` (to be written). Short version: COORD must
generate items from roadmap gaps and vision synthesis, not only design doc `🔲`
items. Tracked separately because it requires autonomous vision to be stable first.

---

## Fix D — Proactive vision expansion (already designed)

See `docs/design/18-autonomous-vision-synthesis.md`. When design docs run dry,
the autonomous vision agent reads the vision corpus and synthesizes new Future items.
This is partially implemented. Throughput improvement from Fix A+B will expose the
need for Fix D sooner.

---

## Present (✅)

- ✅ Root cause identified: opencode github action exits after first item — one item per session hard ceiling (2026-04-20)
- ✅ Root cause identified: queue max 5 — empties in one multi-item session (2026-04-20)

## Future (🔲)

- 🔲 `coord.md`: after BATCH COMPLETE, check queue for next item before entering SM/PM — loop back to §1e if items remain and `session_item_limit` not reached
- 🔲 `coord.md`: SM/PM gate — only run after queue empty or `session_item_limit` reached, not after every item
- 🔲 `coord.md`: queue generation cap raised from 5 → 20 items
- 🔲 `coord.md`: minimum queue depth guard — trigger vision synthesis when queue drops below 5 and no design doc items remain
- 🔲 `otherness-config.yaml` + `otherness-config-template.yaml`: add `maqa.session_item_limit` field (default: 10)
- 🔲 `docs/design/22-queue-richness.md`: design doc for Fix C (richer queue sources)

---

## Zone 1 — Obligations

**O1 — `session_item_limit` must have a project-level override.**
Different projects have different CI speeds and item complexity. A hardcoded limit
breaks projects with slow CI (items time out) or complex items (QA takes longer).
Always read from `otherness-config.yaml` with a default fallback of 10.

**O2 — SM/PM must still run every session, just not between every item.**
SM/PM gate must fire at session end (queue empty OR limit reached). Skipping SM/PM
entirely would cause triage debt, stale branches, and silent metric drift.

**O3 — The multi-item loop must respect the distributed lock.**
Each claimed item still uses the branch-lock protocol (`feat/<item-id>`). Claiming
multiple items in sequence is safe — each claim is independent. The agent must not
attempt to hold multiple locks simultaneously.

**O4 — Queue gen cap increase must not flood the review queue.**
The existing CRITICAL-tier gate (skip queue-gen if ≥2 CRITICAL items in review)
still applies. The higher cap is for normal operation, not for overriding the
human review bottleneck.

---

## Zone 2 — Implementer's judgment

- `session_item_limit` default of 10 is a reasonable starting point. Adjust based
  on observed session durations on the reference project.
- Whether to track `items_completed` in memory vs `_state`: memory is simpler and
  avoids write contention. Use memory unless cross-session tracking is needed.
- Item prioritization within a session (high before medium before low) is already
  handled by the existing queue sort. No changes needed there.

---

## Zone 3 — Scoped out

- Parallel item execution within a single session (too complex, file collision risk)
- Dynamic `session_item_limit` based on remaining runner time
- Cross-session item batching (each session is still independently atomic)
