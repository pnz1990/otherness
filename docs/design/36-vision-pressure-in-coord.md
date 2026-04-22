# 36: Vision Pressure in COORD — Queue Prefers Design-Doc-Backed Items

> Status: Active | Created: 2026-04-20
> Applies to: otherness itself and all managed projects

---

## What this does

Today, COORD claims queue items in priority order (high → medium → low) without
considering whether the item is backed by the current vision pressure context.

The vision pressure prompt (injected into Step A of the scheduled workflow) generates
design doc Future items. But if the queue already has lower-priority items that don't
correspond to any design doc, COORD may claim those first — implementing chores and
housekeeping while the freshly-identified vision gaps wait.

This design doc makes COORD vision-pressure-aware. Items that trace to a design doc
with a `🔲 Future` item get a priority boost. Items that don't are deferred until
no design-doc-backed items remain.

---

## Present (✅)

- ✅ 36.1 — COORD §1b-vision: builds `VISION_PRESSURE_SET` at session start — reads all `🔲 Future` items from `docs/design/*.md`, takes first 40 chars lowercased as keys. Exported as newline-separated env var. Logged: "Vision pressure set: N items from M design docs." Graceful fallback if no docs/design/ exists. (PR #689, 2026-04-21)
- ✅ 36.2 — COORD §1e: vision-pressure claim priority boost — `_item_sort_key` reads `VISION_PRESSURE_SET`; items whose title+body match any VPS key (case-insensitive substring) receive -1 boost; non-matching items receive +1. Tiebreaker within same priority tier (O1: no override). Fail-open: VPS empty or unset → boost=0. (PR #820, 2026-04-22)

---

## Future (🔲)

- 🔲 36.1 — COORD §1b: read active design doc Future items at session start — before claiming any item, build an in-memory set of all `🔲 Future` items from `docs/design/*.md`. This is the "vision pressure set" for this session.
- 🔲 36.3 — COORD §1b: log vision-pressure claim decisions — when claiming an item, append to the batch report: "Claimed #N [vision-backed: yes/no] — <reason>". This makes the claim logic auditable without adding overhead.
- ✅ 36.4 — COORD §1f: queue-depth learn trigger counts vision-backed items — `VISION_BACKED_TODO_NOW` computed via `VISION_PRESSURE_SET` key match; trigger fires when vision-backed count < 3 (not raw count < 5); log: "[COORD §1e-36.4] Vision-backed todo items: N / M total."; fail-open when VPS unset (falls back to total count). (issue-891, 2026-04-22)
- 🔲 36.5 — SM §4f: report vision pressure utilisation — in the health comment, include: "Vision-backed items claimed this session: N / M total claims." This closes the feedback loop: the human can see whether the pressure prompts are actually driving what gets implemented.
- 🔲 36.6 — COORD §1b: deduplicate issue generation against ✅ Present items — before creating a new GitHub issue from a `🔲 Future` design doc item, COORD must scan all `✅ Present` items across `docs/design/*.md` and check whether the proposed issue topic is already marked as shipped. If the first 40 chars of the Future item match a ✅ Present entry (case-insensitive), COORD must skip issue creation for that item and log: "Skipped #<item> — already marked ✅ Present in <doc>." Without this guard, COORD re-queues work that has already been done, diluting the queue with ghost items and wasting session capacity on re-implementing shipped features. ⚠️ Inferred from reliability lens: COORD has no mechanism to prevent generating issues for work already marked complete in design docs.

- ✅ 36.7 — Vision pressure items that are >20 batches old and still unshipped must trigger automatic priority escalation — the current pressure system boosts items at claim time but does not track whether those boosts have been repeatedly ineffective: COORD reads the vision pressure set and boosts matching issues to `priority/high` for claim purposes (§36.2). But if a vision-backed issue has had `priority/high` for 20 consecutive batches without being claimed, the boost is being systematically overridden — either by higher-priority items always being present, or by COORD's claim sort producing a different winner each time. This is the root cause of why 39.x visibility items (all vision-backed) and 32.x onboarding items have not shipped despite being in the vision pressure set. The fix: SM §4a must check all open vision-backed issues older than 20 batches (detectable by issue `createdAt` + 20-batch timestamp). For each: escalate to `priority/critical` AND write `next_session_directive: claim_<issue_number>` to `state.json`. COORD §1b-preflight reads `next_session_directive` and claims the specified issue first in the session — before any sort key calculation. This converts a "boost within the sort" (which can still lose) into a "mandatory first claim" (which cannot lose). Without this escalation, vision-backed items can accumulate `priority/high` labels indefinitely while newer items keep outcompeting them, and the pressure system becomes decorative rather than binding. ⚠️ Inferred from all five pressure lenses: 39.x visibility items, 32.x onboarding items, 36.x vision pressure items, and 45.x honesty items have all been `✅ Future` for 20+ batches while the system reports GREEN; the root cause is that `priority/high` boosts don't prevent new higher-priority items from always winning; mandatory first-claim directives are the only mechanism that can guarantee a long-stale high-priority item ships in the next session. (PR #822)

- 🔲 36.9 — Human-comment-as-directive: the operator must be able to redirect the session's focus mid-loop via a GitHub issue comment, without editing any file: all current mechanisms for redirecting the autonomous loop require a file edit — either changing the pressure context in the scheduled workflow YAML (CRITICAL-tier risk), editing `otherness-config.yaml` (requires git commit + PR), or waiting for SCAN 5 to infer a rewrite. None of these are available to a human who has a thought right now and wants the next session to act on it immediately. COORD §1b-preflight must check the report issue for a specially-formatted operator directive comment: at session start, query `gh api repos/$REPO/issues/$REPORT_ISSUE/comments --jq '[.[] | select(.body | startswith("[DIRECTIVE]"))] | sort_by(.created_at) | last'`. If a comment exists in the format `[DIRECTIVE] <instruction>` (posted by any collaborator): (1) extract the instruction text; (2) write it as `human_directive: "<instruction>"` to `state.json`; (3) include it as a high-priority prefix in the COORD session context: "Human directive from report issue (newest): <instruction>. Treat this as a top-priority steering instruction for this session."; (4) post an acknowledgment comment: "✅ COORD acknowledged directive from <@author>: '<first 60 chars>'. Applying to this session." The directive persists for 3 sessions (tracked via `directive_sessions_remaining` in `state.json`) and then expires. Only the most recent `[DIRECTIVE]` comment is active. This mechanism requires zero file changes: the human posts a GitHub comment with `[DIRECTIVE] Focus on shipping the 39.x visibility items this session` and the next scheduled run applies it. The gap this closes: the operator currently has no low-friction, immediate way to inject a priority instruction without making a git commit or waiting for the automated pressure rewrite cycle. A comment takes 5 seconds; a PR takes 5 minutes. ⚠️ Inferred from visibility and reliability lenses: a human cannot quickly tell the system what to focus on; the existing operator steering mechanisms all require file edits; the report issue is already the human's primary interaction surface with the system — a directive posted there is the most natural steering path.

- 🔲 36.8 — Pressure context must name SPECIFIC unshipped design doc items, not just lenses: the current vision pressure context (in the scheduled workflow) names 5 concern areas ("Is otherness reliable enough?", "Is the loop honest enough?", etc.). This is lens-level pressure — it tells the agent *what category* to focus on, but not *which specific items* to ship. The result: COORD generates new queue items that address the lens but may not claim the 20+ existing unshipped items that already address it. Lens pressure is better than no pressure but weaker than item-level pressure. `vibe-vision-auto.md` SCAN 5 must, when rewriting the pressure context, include a "Top 5 unshipped items" block below the lens questions: `The following specific items are highest-priority and have been 🔲 Future for >10 batches: [list 5 oldest unshipped items with their doc-number and first 60 chars of text]`. COORD §1b must treat this list as mandatory claims for the current session, ahead of any sort key. This converts the pressure context from "here are the themes to address" into "here are the specific items to ship this session." Without this change, pressure prompts at the lens level generate new design doc items instead of shipping old ones — adding to the backlog instead of draining it. ⚠️ Inferred from visibility, reliability, self-improvement, onboarding, and honesty lenses: all five pressure areas have 10–24 unshipped 🔲 Future items in design docs; the pressure prompts correctly identify the areas but do not name the items; COORD generates new issues instead of claiming existing ones; the backlog grows.

---

## Zone 1 — Obligations

**O1 — Vision pressure boost is a tiebreaker, not an override.** If an item is `priority/critical` (e.g. a broken CI fix), it always claims first regardless of vision backing. The boost only applies within the same priority tier.

**O2 — An item with no design doc reference is not blocked.** It is deferred, not excluded. If the session exhausts all vision-backed items, it falls back to claiming non-backed items. The loop never idles waiting for vision-backed work.

**O3 — The vision pressure set is rebuilt every session.** It is not persisted to `_state`. Step A's commits land on main before Step B starts — COORD reads the current docs/design/ state as-is. This means Step A and Step B are naturally coupled: what Step A writes, Step B claims.

**O4 — Design doc number is not required — any reference counts.** An issue saying "implements accessibility WCAG 2.1 AA gaps from the donation readiness analysis" counts even if it doesn't say `docs/design/30`. The check is semantic (key phrase match), not structural (file path match). This prevents gaming via trivial doc references.

---

## Zone 2 — Implementer's judgment

- The vision pressure set build (§36.1) is a straightforward Python loop over `docs/design/*.md` — extract all `🔲 Future` lines, strip the `🔲 ` prefix, take first 40 chars of each. O(N) where N = total Future items, typically <100. Fast enough to run synchronously at session start.
- The claim boost (§36.2) does not need to be fuzzy. Exact substring match of the first 40 chars of any Future item in the issue title+body (case-insensitive) is sufficient. Fuzzy matching adds complexity with marginal benefit.
- §36.4 "vision-effective queue depth": implement as a separate count, not a replacement. Log both: `total_todo: N`, `vision_backed_todo: M`. Trigger learn/vision when `vision_backed_todo < 3` (not total_todo < 5).

---

## Zone 3 — Scoped out

- Cross-project vision pressure (kro-ui's pressure affecting kardinal-promoter's queue) — this is design doc 28 §Future cross-project propagation
- Reweighting items by how recent the corresponding design doc Future item is
- Automatic label application based on vision backing (would pollute issue labels)
