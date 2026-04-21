# 42: Vision Scan → Shipped Gap — Closing the Loop Between Identified and Implemented

> Status: Active | Created: 2026-04-21
> Applies to: otherness itself and all managed projects

---

## The problem

`vibe-vision-auto.md` (SCAN 3) infers `🔲 Future` items from code gaps. SCAN 4
flags stale `🔲 Future` items that have accumulated for 90+ days with no issue.
SCAN 5 detects when pressure prompts are stale. These scans run correctly.

But none of them have a downstream verification loop. The scan writes a `🔲 Future`
item to `docs/design/`. COORD creates a GitHub issue. The issue sits in the queue.
The session claims it. Or it doesn't. Either way, the vision scan has no feedback
mechanism that tells it "the item you identified 90 batches ago still hasn't shipped."

The result: the vision scan produces an accurate inventory of gaps, but the gap
inventory grows without any automatic pressure to close it. The scan becomes a
documentation exercise, not a forcing function.

---

## What "fixed" looks like

The vision scan is connected to the delivery loop. When a `🔲 Future` item written
by vibe-vision-auto has been open as a GitHub issue for >14 days without being
claimed, the scan re-surfaces it with elevated priority in the next scan cycle.
When an item has been `in_progress` for >7 days without a merged PR, the scan flags
it as likely-stuck and adds it to the weekly priority report.

The human sees, in the report issue, a clear separation:
1. New gaps identified this scan
2. Gaps from previous scans that have not moved
3. Gaps that shipped (promoted to ✅ Present)

Category 2 must never grow silently. When it exceeds 10 items, the scan triggers
automatic escalation rather than just adding more items to category 1.

---

## Present (✅)

*(Nothing shipped yet.)*

---

## Future (🔲)

- 🔲 42.1 — SCAN 3 inferred-item age tracking: when `vibe-vision-auto.md` SCAN 3 writes a `🔲 ⚠️ Inferred` item to a design doc, it must also record the item's creation date as a comment in the line: `- 🔲 item text ⚠️ Inferred from \`file:line\` (date: YYYY-MM-DD)`. On subsequent scan runs, SCAN 3 must check all `⚠️ Inferred` items that include a `(date:...)` annotation. If the item's age exceeds 30 days AND there is no open GitHub issue with a title matching the item text (first 40 chars): SCAN 3 must re-open a GitHub issue for it directly (not just annotate the design doc). The item was identified as a real gap 30 days ago. If no one created an issue for it, the scan must create one now. Without age tracking and re-issue logic, SCAN 3 is an accurate gap detector that produces results no one acts on.

- 🔲 42.2 — Vision scan must report "gap stagnation ratio" in its output: each SCAN run must compute: (a) `new_gaps` = items written this run, (b) `gaps_aged_30d` = `⚠️ Inferred` items older than 30 days with no corresponding closed issue, (c) `gaps_shipped` = items promoted to ✅ this run. The ratio `gaps_aged_30d / (new_gaps + gaps_shipped)` is the "gap stagnation ratio". If the ratio exceeds 2.0 (more than twice as many stale gaps as new+shipped): the scan must include a prominent `[⚠️ GAP STAGNATION: N old gaps are not shipping]` message in the report issue comment. This converts the vision scan from a silent background process into a visible accountability signal. A human who sees this message knows the loop is identifying problems faster than it is solving them.

- 🔲 42.3 — COORD §1c must treat vision-scan-generated issues with elevated priority when stagnation ratio is high: when `state.json` contains `gap_stagnation_ratio > 2.0` (written by the vision scan): COORD §1c must sort all issues tagged `area/docs area/agent-loop` that reference `design doc` in their body above all other queue items except `priority/critical`. The normal priority/size sort still applies within that elevated group. This converts the gap-stagnation signal from "observation" to "action" — the session that reads a high stagnation ratio preferentially works on closing the accumulated gaps rather than claiming new chore items. Without this coupling, COORD sees the stagnation ratio in `state.json` and ignores it during claim sorting. ⚠️ Inferred from the meta-problem: vision scans and COORD operate independently; no mechanism couples a stagnation signal to claim priority adjustment.

- 🔲 42.4 — `vibe-vision-auto.md` SCAN 5 (pressure context rewrite) must trigger on time-based staleness independently of keyword match rate: SCAN 5 currently only rewrites the pressure context when ≥60% of pressure keywords appear in recent merged PR titles. But a pressure context can become stale not because the keywords were shipped, but because the system has shifted focus entirely (e.g. the project moved from agent loop hardening to onboarding quality — the old pressure questions about "loop honest enough" are still relevant but no PR title will match them). SCAN 5 must add a time-based trigger: if the pressure block has not been rewritten in >30 days regardless of keyword match rate, add a `🔲 Future` item: "Pressure context is >30 days old — review and rewrite even if keyword match rate is below 60%. Stale pressure is better than absent pressure, but human review of the bar is overdue." This is a different failure mode than the keyword-match staleness: it is the system failing to raise its own bar simply because time has passed. ⚠️ Inferred from self-improvement lens: the system cannot genuinely break its own frame-lock if the pressure prompt — the primary mechanism for injecting new direction — is allowed to remain unchanged for months.

- 🔲 42.5 — Design doc `🔲 Future` item count must be a tracked metric: `docs/aide/metrics.md` currently tracks `prs_merged`, `needs_human`, `vision_prs`, and others — but not the total count of `🔲 Future` items across all design docs. A growing future-item count with flat `vision_prs` is the clearest possible signal that the system is identifying work faster than it ships work. SM §4b must add a `future_items_count` column: count all lines matching `^- 🔲` across all `docs/design/*.md` files (excluding `🚫` and `[stale` items). PM §5 must flag when `future_items_count` has grown for 5 consecutive batches with no corresponding growth in ✅ Present items. Without this metric, the design doc backlog can balloon invisibly — the human has no signal that the system is accumulating debt faster than it is paying it down. ⚠️ Inferred from visibility and honesty lens: the system produces Future items prolifically but has no metric capturing the ratio of Future items written vs. Future items shipped over time.

- 🔲 42.6 — Human-authored `🔲 Future` items that have been open for >30 batches with no corresponding GitHub issue must be auto-escalated to `priority/critical`: doc 42.1 specifies age-tracking for SCAN 3 inferred items. But human-authored `🔲 Future` items — the highest-quality design intent the system has — can also sit for 90+ batches with no issue created and no session ever claiming them. The pressure context explicitly calls this out: "The human should never need to manually add direction that the system could have identified itself." SM §4b must: (1) every 10 batches, scan all `docs/design/*.md` for `🔲 Future` items (not inferred, not stale-flagged) that do not appear in any open or closed GitHub issue title (first 40 chars match); (2) for items with no issue found AND whose parent design doc was first committed >30 batches ago (using `git log --follow` on the file): open a `kind/enhancement priority/critical` issue titled "[Age Escalation] Design doc <N> Future item has been unissued for >30 batches: <item text[:60]>"; (3) deduplicate: skip if an issue with `[Age Escalation]` for this item text already exists open. The 30-batch threshold distinguishes new design docs (expected to have unissued items) from stale backlog. Without this escalation, a human who writes design doc Future items expecting the system to eventually ship them will discover months later that the system never created GitHub issues for them — the design intent was never injected into the queue. ⚠️ Inferred from reliability lens: the system has 244 open `🔲 Future` items across design docs; the pressure context identifies that items identified 90+ batches ago have not shipped; no mechanism automatically converts aging human-authored Future items into escalated queue entries when COORD's normal queue-gen cycle hasn't picked them up.

---

## Zone 1 — Obligations

**O1 — Vision scans produce actionable outputs, not just documentation.**
A `🔲 Future` item that has been in a design doc for >30 days with no corresponding
GitHub issue is a scan output that failed to produce action. SCAN 3 must ensure every
inferred item eventually becomes an issue, not just a design doc annotation.

**O2 — Gap stagnation is surfaced to the human without manual investigation.**
The human should never need to count stale items in design docs to know the system
is backlogged. The scan's report issue comment must contain the stagnation count
as a first-line signal.

**O3 — Vision scan modifications stay in the docs zone.**
SCAN additions under this doc (42.1–42.5) modify `vibe-vision-auto.md` scan logic
and `docs/design/` files only. COORD and SM instruction changes require separate PRs
via their normal change tier.

---

## Zone 2 — Implementer's judgment

- `(date: YYYY-MM-DD)` annotation format: lightweight, parseable with `re.search`. Does not break SCAN 2 stale detection (not a file ref).
- Gap stagnation ratio threshold of 2.0 is conservative. Adjust based on observed ratios after 5 batches.
- `future_items_count` metric: count at the file level (glob `docs/design/*.md`, count matching lines). Fast enough for every batch.

---

## Zone 3 — Scoped out

- Retroactive dating of existing `⚠️ Inferred` items (too expensive; start fresh from this doc's merge date)
- Cross-project gap stagnation aggregation (fleet-level; future stage)
- Automatic deletion of stale Future items (human decision only; the scan flags but never removes)
