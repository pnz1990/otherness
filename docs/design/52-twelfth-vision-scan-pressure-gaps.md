# Design Doc 52 — Twelfth Vision Scan Pressure Gaps

**Vision scan date**: 2026-04-23
**Scan**: 12th autonomous run
**Pressure result**: 0/5 bullets addressed (all five lenses still open)
**Backlog size**: 238 `🔲 Future` items across all design docs

---

## The problem

11 vision scans have run. 0 of 5 pressure bullets are scored as addressed. The backlog is 238 items. Sessions are shipping work — but not work that visibly closes the pressure lenses. This doc captures four gaps that were not present in any prior design doc, identified by applying the pressure lens directly against the current system state.

---

## Present (✅)

*(No items shipped yet — doc created this scan)*

---

## Future (🔲)

- 🔲 52.1 — The system has no mechanism to detect "spinning in circles" — recurring queue items that are claimed, fail, re-open, and cycle indefinitely while health stays GREEN: at least one failure mode exists where the same item is claimed, ENG opens a PR, QA rejects or CI fails, the PR is closed, the issue re-enters `todo`, and the next session claims it again. This cycle can repeat 5–10 times over multiple batches while SM §4b reports GREEN because `prs_merged` is non-zero and `needs_human` count is below threshold. The "circular item" failure mode is not detected by any current mechanism. COORD §1b must track a `claim_history` annotation per issue: each time an issue is claimed, increment a `claim_count` field in `state.json` (keyed by issue number). SM §4a must check: for any issue with `claim_count >= 3` that is still open (not closed, not `needs-human`): post a diagnostic comment to the issue: "⚠️ This item has been claimed 3 times without resolution. Adding label `blocked`. Root cause must be identified before this item can be re-claimed." Apply label `blocked` to prevent COORD from claiming it again without human review. Without this check, the system can spend 30 batches re-claiming the same unresolvable item while health signals remain GREEN. The circular item pattern is a reliability sink that disguises itself as normal delivery activity. ⚠️ Inferred from reliability lens: sessions fail silently; one silent failure mode is circular item cycling — the same issue claimed repeatedly without resolution; this is not captured by any existing silent-session or stale-watchdog mechanism.

- 🔲 52.2 — The health comment is so verbose and technical that a human cannot extract the three key signals in under 30 seconds — the format optimizes for completeness, not actionability: the SM §4f health comment currently includes: health signal, metric table with 8+ columns, simulation trace, vision pressure score, batch count, skill count, CI status, and fleet status. Each item is formatted as `§4f-label: value` using internal section references. A human opening the report issue to check health must decode abbreviations like `arch_convergence`, `vision_prs`, `session_item_limit`, `qa_rejection_rate`. The comment is complete but not actionable in 30 seconds. SM §4f must restructure the health comment into two tiers: **Tier 1 (always visible, ≤5 lines)**: "Status: GREEN/AMBER/RED | Last PR: #N — [title] | Queue: N items | Action needed: [none / see below]." This is the human-readable dashboard line. **Tier 2 (in a `<details>` block, collapsed by default)**: the full technical table for operators. The Tier 1 line must be the first 5 lines of every health comment, always. The Tier 2 block is collapsible and defaults to closed. A human who opened the report issue a year ago and never read the docs sees Tier 1 and immediately knows if the system needs attention. An operator who needs detail opens the `<details>` block. Without this restructuring, the health comment is operator-complete and human-opaque — the visibility gap is not in the data, it is in the presentation layer. ⚠️ Inferred from visibility lens: a human looking at GitHub right now cannot quickly tell if the system is healthy; the report issue comments are too verbose and technical; the fix is a presentation change, not a data change.

- 🔲 52.3 — No mechanism detects "the system is active but moving away from the vision" — a session that ships 5 PRs on peripheral tooling is indistinguishable from one that advances a roadmap milestone: SM §4f computes `vision_aligned: true/false` per batch (doc 35). But `vision_aligned=true` only requires ≥1 PR with design-doc backing — it does not require the PR to advance a roadmap milestone. A session that ships `feat(scripts): improve validate.sh error message` (design-backed) counts as `vision_aligned=true` even if the roadmap milestone it is supposed to advance ("Stage 11 — onboarding completeness") has had zero progress for 20 batches. The system can be permanently `vision_aligned=true` while the roadmap is frozen. PM §5 must add a `roadmap_velocity_check` every 10 batches: (1) read `docs/aide/roadmap.md`; (2) identify the current active milestone (first non-completed milestone); (3) count PRs in the last 10 batches whose title or body mentions a design doc from that milestone's area; (4) if count < 2 for 10 batches: health must not be GREEN — set to AMBER with "⚠️ Roadmap velocity: active milestone [name] has had no contributing PRs in 10 batches. System may be shipping peripheral work." Without this check, the system looks active and vision-aligned while the actual roadmap milestone it should be advancing is frozen. The human cannot tell from the health signal alone whether the system is advancing toward the stated vision or spinning on adjacent work. ⚠️ Inferred from reliability lens and visibility lens: the SM health signal says GREEN but the products it manages are not advancing fast enough; vision_aligned=true does not mean roadmap-advancing; this item adds the per-milestone velocity signal that distinguishes "active" from "progressing."

- 🔲 52.4 — The 238-item Future backlog has no shrink mechanism — vision scans add items every run but no process systematically retires items that are superseded, out-of-scope, or permanently blocked: docs 46–51 have added 80+ items in the last 6 vision scans. Items are shipped (SCAN 1 promotions) but at a much lower rate than new items are added. The result: the backlog grows every scan. A growing backlog is only healthy if the growth reflects expanding product scope — but most additions are refinements of existing items (new angles on the same gaps). Items 49.1, 50.1, 51.1 are all variations on "COORD needs a priority signal for the reliability items." The backlog has 238 items not because there are 238 independent gaps, but because the vision scan process adds a new variation of the same gap each run without retiring the older, partially-superseded version. `vibe-vision-auto.md` SCAN 4 (deprecate 90+ day items) is the only retirement mechanism — but it only fires when an item is 90+ days old AND has no open issue. Most items don't qualify because they are recent (<90 days old) or already have an open issue. A complementary mechanism is needed: SCAN 1 must check not only "was this item shipped?" but also "is this item a subset of a newer, more specific item?" When a newer item in the same doc covers the same obligation with more precision, the older item must be marked `🔲 [superseded by 52.X]` and excluded from COORD's queue. SM §4a must, every 20 batches, run a supersession check: for each pair of `🔲 Future` items in the same doc with ≥60% word overlap (Jaccard similarity on the item text): flag the older item as a supersession candidate and post to the report issue: "⚠️ Possible superseded items: [doc A item X] and [doc B item Y] overlap significantly — review and retire the older one." Without a supersession mechanism, the backlog grows indefinitely as each scan adds a refined variant of the same gap, and COORD must sift through 300+ items to find the 5 that actually matter. ⚠️ Inferred from all five lenses: the backlog growth rate is the meta-failure that makes all five pressure bullets harder to close; a system that generates more gaps than it closes is reliable only in the sense that it reliably produces work — not in the sense that the work converges toward a resolved state.

---

## Zone 1 — Obligations

| # | Obligation |
|---|---|
| 52.1 | SM §4a must track `claim_count` per issue and post diagnostic + `blocked` label after 3 claims without closure |
| 52.2 | SM §4f must restructure health comment: Tier 1 (≤5 lines, plain-English) always visible; Tier 2 (full table) in collapsed `<details>` |
| 52.3 | PM §5 must add `roadmap_velocity_check` every 10 batches; AMBER when active milestone has < 2 contributing PRs in 10 batches |
| 52.4 | SCAN 1 must check for superseded items; SM §4a must run supersession check every 20 batches; flag overlapping items as candidates |

## Zone 2 — Implementer's judgment

- 52.1: `claim_count` threshold of 3 is a reasonable default; implementer may tune based on observed false-positive rate.
- 52.2: The 5-line Tier 1 target is a cap, not a minimum. Implementation may use fewer lines if all three signals are covered.
- 52.3: "Design doc from that milestone's area" requires a mapping table in `docs/aide/roadmap.md` or inline in the check — implementer defines the mapping.
- 52.4: Jaccard similarity threshold of 60% may produce false positives on short items; implementer may adjust to 70%.

## Zone 3 — Scoped out

- 52.4 does NOT specify automatic retirement — only flagging. Actual retirement decisions require human judgment.
- 52.2 does NOT change the data in the health comment — only the presentation. The Tier 2 block must preserve all existing fields.
- 52.1 does NOT close items automatically — only blocks re-claiming. Humans must review `blocked` items.
