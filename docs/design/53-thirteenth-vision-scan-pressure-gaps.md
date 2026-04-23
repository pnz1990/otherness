# Design Doc 53 — Thirteenth Vision Scan Pressure Gaps

**Vision scan date**: 2026-04-23
**Scan**: 13th autonomous run
**Pressure result**: 5/5 bullets scored as "addressed" by SCAN 5 domain-noun matching — but all five lenses remain genuinely open (see 50.3: over-broad domain nouns inflate the score)
**Backlog size**: 409 `🔲 Future` items across all design docs

---

## The problem

12 vision scans have run. The SCAN 5 domain-noun problem (doc 50.3) means the pressure score
is no longer a reliable signal — it fires the rewrite item every single run. Meanwhile, the
five pressure lenses remain structurally open. This doc applies the pressure lenses as a
human analyst would — not as a pattern-matcher — and identifies four gaps that are genuinely
absent from the 409-item corpus.

The criterion for inclusion: the gap must name a specific failure mode that (a) is live
today, (b) has no existing `🔲 Future` item that addresses it, and (c) would, if fixed,
directly reduce the failure rate under one of the five pressure lenses.

---

## Present (✅)

*(No items shipped yet — doc created this scan)*

---

## Future (🔲)

- 🔲 53.1 — The 409-item Future backlog is itself the primary obstacle to shipping meaningful PRs: every batch COORD must navigate 409 items to find the 1–3 it can actually complete, and the navigation cost grows with the backlog — no existing item addresses the backlog as the primary reliability bottleneck. Docs 51.3, 52.4, and 45 each describe backlog growth as a problem and propose: SCAN 3 stagnation gate (51.3), supersession check (52.4), simplification cycle (45.5). But none of these address the core issue: the 409 items exist NOW and COORD is navigating them NOW without relief. A backlog of 409 items where COORD must re-score every item on every claim is O(N) selection work that grows as N grows. The minimum viable fix — not a new mechanism, but a surgical removal — is: SM §4a must, once every 5 batches, run a `backlog_triage_gate`: (1) extract all `🔲 Future` items whose full item text is a subset of a newer item in the same lens area (detect by: newer item in the same doc explicitly references the older item, OR the older item text appears verbatim as a sub-clause of the newer one); (2) mark those older items `🔲 [superseded — see item X.Y]` and exclude them from COORD's issue-creation pipeline; (3) cap at 10 supersessions per run to avoid mass-invalidation. This differs from 52.4 (which uses Jaccard similarity and 20-batch cadence): 53.1 targets explicit subsumption (item A is wholly contained in item B) at 5-batch cadence, making the retirement mechanism responsive rather than passive. Without this triage, every scan adds items and no scan removes items — the backlog is a one-way accumulator that degrades COORD's claim quality over time. ⚠️ Inferred from reliability lens: a truly reliable system ships at least one meaningful PR every single run; the 409-item backlog imposes O(N) claim-selection cost; the path to reliable shipping requires active backlog reduction, not just addition suppression.

- 🔲 53.2 — The pressure scan itself has become a source of backlog inflation with no termination condition: 12 consecutive vision scans have each added 4–10 new `🔲 Future` items to the corpus. The total backlog grew from ~50 items (batch 1) to 409 items (batch 15) — a 700% increase over 15 batches while the shipped ✅ Present count has grown by approximately 80 items. The net backlog growth rate is ~24 items per batch (add rate) minus ~5 items per batch (ship rate) = +19 items/batch. At this rate the backlog reaches 800 items within 20 more batches. No existing `🔲 Future` item specifies a TERMINATION CONDITION for the vision scan process itself — when to stop adding items and spend all available session budget on shipping existing ones. The pressure scan has no self-limiting rule. `vibe-vision-auto.md` must add a SCAN 0 pre-check (complementary to 51.3 stagnation gate, which targets SCAN 3 specifically): if `total_future_items > 400` AND `net_backlog_change_last_5_batches > 0` (more items added than shipped): suppress ALL item-generation scans (SCAN 3, SCAN 5 rewrite item, this human-context scan) for this run, with log: "[SCAN 0] Backlog ceiling: {N} items and growing — suspending item generation until net_backlog_change_last_5_batches ≤ 0. Running SCAN 1 and SCAN 2 only." The ceiling is 400 items — a threshold where the backlog has demonstrably exceeded COORD's effective navigation capacity (evidenced by 12 consecutive 0/5 pressure scores despite 409 items covering all five lenses). The termination condition is not permanent: it lifts when shipping outpaces addition for 5 consecutive batches. Without a ceiling, the vision scan process is structurally incapable of improvement — every run adds items that are never shipped, the honesty gap widens, and COORD's effective queue depth keeps growing. ⚠️ Inferred from all five lenses: every pressure lens has been documented for 12 scans without resolution; the common factor is not missing items but excess items; the vision scan process must have a self-limiting rule that prioritizes shipping over specifying when the backlog ceiling is breached.

- 🔲 53.3 — The 12 gap analysis docs (46–53) have never been read as a system — each was written independently, but no session has asked "across all 12 docs, what is the single highest-ROI unshipped item?" and acted on the answer. The individual docs contain priority orderings (doc 48 §O3, doc 49 §O3, doc 51 §O3) but no cross-doc ordering exists. COORD navigates these docs as independent issue queues, claiming from each based on individual priority labels. But the cross-doc ordering would show, for example, that 52.2 (health comment two-tier restructure) requires zero new infrastructure and directly addresses the visibility lens, while 48.10 (onboarding regression test) requires a test fixture setup that depends on infrastructure not yet built. A cross-doc priority synthesis has been absent from every batch. PM §5 must add a `gap_doc_synthesis` step every 10 batches: (1) read docs 46–53 (the gap analysis series); (2) from each doc's priority ordering section (§O3), extract the first two items per lens; (3) build a cross-doc "top 10" list: the 2 highest-priority items from each of the 5 lenses across all 8 docs; (4) write this list to `docs/aide/progress.md` as a "Priority shipping targets" section; (5) COORD must, when the priority targets list exists and is fewer than 3 batches old, claim from this list before any other item. This is the minimum coordination mechanism that makes 12 independent gap docs behave as a single prioritized backlog. Without it, COORD navigates 409 items without the cross-doc synthesis that would make the highest-ROI items visible. ⚠️ Inferred from all five lenses: 12 gap analysis docs exist with internal priority orderings; no cross-doc synthesis has been produced in 12 batches; the cross-doc top-10 is a PM artifact that costs one read and one write per 10 batches and directly guides COORD's claim sequence.

- 🔲 53.4 — The self-improvement lens specifically asks "what would genuinely break the frame-lock?" — and the corpus has 40+ items about monoculture but none propose injecting structurally DIFFERENT reasoning into the loop, only softer DIVERSITY_MODE nudges that use the same LLM with the same prompt structure. The monoculture is not just about which repos are learned from — it is about the reasoning architecture: every agent (COORD, ENG, QA, SM, PM) is the same model (claude-sonnet-4-6) given a markdown instruction file. The diversity mechanism (arch_convergence + DIVERSITY_MODE) changes WHAT items are claimed but not HOW reasoning proceeds. A genuinely different reasoning structure requires: (a) a second-opinion step that uses a DIFFERENT prompt architecture (not just a different instruction file), or (b) an adversarial injection where one agent explicitly argues AGAINST the current session's reasoning before it is finalized. The minimum viable implementation: `agents/phases/qa.md` §3a must add an ADVERSARIAL STANCE section: before reviewing the PR, QA must explicitly write a 3-bullet "strongest case for REJECTING this PR" (even if QA ultimately approves it). The adversarial reasoning forces the model to generate a structurally different perspective within the same session. SM §4b must track: "QA adversarial coverage: N sessions in last 20 where QA wrote ≥3 rejection arguments before approving." When `adversarial_coverage < 50%`: flag in health comment: "⚠️ QA adversarial stance missing in >50% of sessions — frame-lock mitigation may be inactive." This is not a new field in any existing design doc — docs 31, 46, 47, 48, 49, 50, 51, 52 all address monoculture via diversity of INPUT (which repos to learn from, which items to claim) but none specify diversity of REASONING PROCESS within a single session. ⚠️ Inferred from self-improvement lens: the agents are not meaningfully smarter than they were two weeks ago; the monoculture problem has not been addressed; the existing DIVERSITY_MODE changes claim selection but not reasoning process; an adversarial QA stance is the minimum structural change that forces a different reasoning architecture within the existing toolchain.

---

## Zone 1 — Obligations

| # | Obligation |
|---|---|
| 53.1 | SM §4a must run `backlog_triage_gate` every 5 batches: detect explicit superseded items (item A is wholly contained in item B), mark `[superseded]`, cap 10/run |
| 53.2 | `vibe-vision-auto.md` must add SCAN 0: if `total_future_items > 400` AND net backlog growing: suppress all item-generation scans; log ceiling message; lift when net backlog negative for 5 batches |
| 53.3 | PM §5 must add `gap_doc_synthesis` every 10 batches: read docs 46–53, extract top-2 per lens per doc, write cross-doc top-10 to progress.md; COORD must claim from this list before all others |
| 53.4 | QA §3a §ADVERSARIAL STANCE: before reviewing any PR, QA must write ≥3 rejection arguments; SM §4b must track adversarial coverage and flag AMBER when < 50% of sessions in last 20 include it |

## Zone 2 — Implementer's judgment

- 53.1: "wholly contained" supersession detection must use text inclusion (substring match), not Jaccard similarity (that's 52.4's mechanism). The two mechanisms are complementary and should both run.
- 53.2: the 400-item ceiling is empirical — it is the observed point at which 12 scan runs produced 0/5 pressure scores despite comprehensive coverage. The implementer may tune this based on observed COORD navigation quality.
- 53.3: the cross-doc top-10 list in progress.md must be a separate section with a `last_updated` timestamp. It must not replace the existing Stage Completion table.
- 53.4: the adversarial stance does NOT change QA's final approval/rejection decision — it is a reasoning artifact written before the decision. A QA that writes 3 rejection arguments and then approves has done its job. The measurement is whether the arguments were written, not whether they led to rejection.

## Zone 3 — Scoped out

- 53.2 does NOT suppress SCAN 1 (promote shipped items) or SCAN 2 (flag stale items) — those are maintenance operations, not new-item generation.
- 53.3 does NOT require rewriting the 409-item backlog. It only requires reading the 8 gap analysis docs and synthesizing a 10-item claim priority list.
- 53.4 does NOT require a different AI model or a second-agent architecture. The adversarial stance is a reasoning step added to QA's existing prompt structure.
- 53.1 explicitly does NOT auto-delete items. Items are marked `[superseded]` and excluded from COORD's issue-creation pipeline. Humans can still read and act on them.
