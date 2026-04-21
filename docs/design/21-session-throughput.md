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
- ✅ `otherness-config.yaml` + `otherness-config-template.yaml`: `maqa.session_item_limit: 10` field added (pre-shipped in feat/session-throughput PR, doc updated PR #340, 2026-04-20)

## Future (🔲)

- ✅ `coord.md`: after BATCH COMPLETE, check queue for next item before entering SM/PM — loop back to §1e if items remain and `session_item_limit` not reached
- ✅ `coord.md`: SM/PM gate — only run after queue empty or `session_item_limit` reached, not after every item
- ✅ `coord.md`: queue generation cap raised from 5 → 20 items
- ✅ `coord.md`: minimum queue depth guard — trigger vision synthesis when queue drops below 5 and no design doc items remain
- ✅ `otherness-config.yaml` + `otherness-config-template.yaml`: add `maqa.session_item_limit` field (default: 10) — pre-shipped
- ✅ `docs/design/22-queue-richness.md`: design doc for Fix C — richer queue sources (2026-04-20)es)
- ✅ Session defect diagnosis: when a session completes with `VISION_PRS == 0`, SM §4b opens a `kind/bug priority/high` issue titled `[DEFECT] Session completed with 0 meaningful PRs — <root-cause>`; diagnoses root cause from ordered list: ci-red / vision-pressure-too-low / all-items-blocked / queue-source-exhausted / unknown; deduplicates (skips if [DEFECT] issue already open); posts report comment (PR #703, 2026-04-21)
- ✅ Meaningful-work rate tracked as a first-class metric: `docs/aide/metrics.md` adds `meaningful_prs` column; SM §4b computes and writes it each batch — count of merged PRs (last 24h, non-excluded) that reference `docs/design/`, `🔲 →`, or `design doc` in title or body (first 500 chars); same scan as VISION_PR_COUNT from §4f (PR #691, 2026-04-21)
- ✅ Same-session recovery when no PR ships in first item attempt: `standalone.md §1f GATE` — if `ITEMS_COMPLETED == 0` after first item completion (and `RECOVERY_ATTEMPTED != true`), agent scans `docs/design/*.md` for an unclaimed 🔲 Future item, creates a GitHub issue for it, claims it, and attempts implementation before falling through to SM/PM. One attempt per session; graceful fallback if no candidate found. (PR #697, 2026-04-21)
- ✅ Multi-item loop execution verified in SM health signal: SM §4b records `session_items_completed` in `metrics.md` and flags `[SINGLE-ITEM-MODE]` when the value is 1 for 3 consecutive sessions. Fail-open. (PR #736, 2026-04-21)
- ✅ Queue guard firing frequency tracked and acted on: SM §4b records `guard_enrichment_produced` (count of new enhancement issues created in last 24h when guard fires) in `metrics.md`; if guard fires but `guard_enrichment_produced == 0` for 3 consecutive sessions, a `kind/bug priority/high` issue is opened automatically; fail-open — check never blocks queue claiming (PR #772, 2026-04-21)
- ✅ Housekeeping-streak auto-escalation: SM §4b counts `housekeeping_streak` in `state.json` — incremented each chore-only session, reset on feature-rich. At streak=3: opens `kind/bug priority/high` issue, writes `housekeeping_streak: 3` to `state.json` for COORD §1b to detect, posts to REPORT_ISSUE. Fail-open. Deduplicated. (PR #784, 2026-04-21)
- ✅ COORD immediate queue refill when queue empties mid-session: `coord.md §1f` inline queue-gen now adds newly created issues to `state.json` immediately (§1f-refill python block) and re-computes `QUEUE_REMAINING` so the §1f gate can continue the session without returning to SM/PM. Fail-open. (PR #794, 2026-04-21)
- ✅ Stuck-item detection and abandonment: SM §4b increments `failed_attempts` in `state.json` when `VISION_PRS==0` and a closed-unmerged PR exists for the current item; at `failed_attempts==3` labels the issue `blocked` and posts a deprioritisation comment. COORD §1e skips `blocked` or `failed_attempts>=3` items during claim. Fail-open. (PR #799, 2026-04-21)
- ✅ ENG zero-diff detection: `eng.md §2e-zero-diff` checks ≥1 meaningful file change before committing. If 0: aborts PR creation, labels issue `blocked`, increments `failed_attempts`, deletes branch, and skips to SM/PM. Excludes `docs/aide/`, `.otherness/`, `.specify/memory`. Fail-open (defaults to 1 if diff check errors). (PR #803, 2026-04-21)
- 🔲 Session pre-flight checks must be a blocking gate, not a best-effort step: COORD §1b currently reads multiple signals from `state.json` at startup — `housekeeping_streak`, `recovery_action`, `frame_lock_detected`, `silent_session_count` — but the reading is scattered across multiple instruction blocks with no single "preflight gate" that produces a GO/NO-GO decision before any work is claimed. The result: a corrupted or unexpected state.json value causes the session to silently skip the signal and proceed as if no flag is set. COORD §1b must implement a `PREFLIGHT_CHECK` block that (1) reads all named signals atomically, (2) prints a summary: "Preflight: streak=N | recovery=<action> | frame_lock=<bool> | silent=N | directive=<val>", (3) produces a single `PREFLIGHT_PASS` or `PREFLIGHT_HOLD <reason>` decision. A PREFLIGHT_HOLD posts to the report issue and exits cleanly without claiming work. A PREFLIGHT_PASS proceeds to claim. Without this gate, signal-reading failures are invisible — the session appears to start normally while actually ignoring the safety conditions that were written into state.json. ⚠️ Inferred from reliability lens: sessions stall when queues empty and the existing signal-reading is too fragmented to reliably detect and act on compound failure states.
- 🔲 Item age limit — items that have been `todo` for >30 days without being claimed must be auto-triaged: an issue sitting in the queue for over 30 days signals one of: (1) the label/priority is wrong and it keeps being deprioritised, (2) the item is too large/ambiguous and no session can estimate it, or (3) the issue is stale and no longer reflects real work. SM §4a must check issue age for all `state: todo` items in `state.json` and flag any older than 30 days. Flagging action: add `kind/chore` label + comment "⚠️ Queue item age >30d. Re-evaluate priority, scope, or close if no longer needed." Do NOT auto-close — only flag for human review. This prevents the queue from accumulating zombie items that consume sort-key budget on every session without ever being claimed. A queue with 40 items where 20 are 30d+ stale is effectively a queue of 20 — but COORD cannot see this without the staleness signal. ⚠️ Inferred from reliability lens: a truly reliable system ships at least one meaningful PR every single run; items that cycle through the queue indefinitely without being claimed silently reduce effective queue depth.
- 🔲 Autonomous `session_item_limit` tuning based on observed throughput: `session_item_limit` defaults to 10 and is manually configured per project. But the right value depends on observed average session duration, CI speed, and item complexity — all of which vary by project and over time. SM §4e must: (1) track `session_items_completed` in metrics.md per batch; (2) every 10 batches, compute the rolling average; (3) if `avg_session_items_completed < session_item_limit * 0.5` (limit is set twice as high as what sessions actually complete), SM must propose a lower limit by opening a `kind/chore` issue: "session_item_limit may be too high — average completion is N/10. Consider reducing to N+2 in otherness-config.yaml."; (4) if `avg_session_items_completed >= session_item_limit * 0.9` (sessions consistently hit the cap), SM must propose raising the limit similarly. Manual tuning of a dynamic system property is a maintenance burden; the system should tell the operator when the value is wrong. ⚠️ Inferred from reliability lens: session throughput is not self-adjusting; a mistuned session_item_limit causes either wasted capacity or sessions that never complete their intended item set.
- 🔲 Health signal must degrade to AMBER when 0 meaningful PRs shipped — not just open an issue: the session defect diagnosis item (35.x, 21.x) opens a `kind/bug` issue when `VISION_PRS == 0`, but SM §4f still writes `health: GREEN` to `_state` and the report issue. This is dishonest. A batch that shipped zero meaningful PRs must not be reported as GREEN — regardless of whether CI was green, queue was full, or the agent ran correctly. SM §4f must: (1) check `meaningful_prs` from the current batch before computing the health signal; (2) if `meaningful_prs == 0`: set `health: AMBER` and include a one-line reason in the health comment: "⚠️ AMBER — 0 meaningful PRs this session (chore-only or zero-ship)"; (3) the AMBER condition for 0 meaningful PRs is separate from and does not override any RED condition. GREEN must mean "shipped real work, not just chores." A system that declares GREEN after shipping only housekeeping is lying to the operator. The gap: an autonomous system that "ships at least one meaningful PR every single run without exception" must first be honest when it fails to do so. ⚠️ Inferred from reliability and honesty lenses: a truly reliable system ships at least one meaningful PR every single run; when it doesn't, the health signal must reflect that failure — not open an issue while still reporting GREEN.

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
