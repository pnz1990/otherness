# Design Doc 55 — Fifteenth Vision Scan Pressure Gaps

**Vision scan date**: 2026-04-23
**Scan**: 15th autonomous run
**Pressure result**: SCAN 5 scores 5/5 via domain-noun matching (over-broad, per 50.3/53) — all five lenses remain genuinely open
**Backlog size**: 255 `🔲 Future` items across all design docs

---

## The problem

14 vision scans have run. Each produced 4–10 new `🔲 Future` items. The shipped `✅ Present`
count is 424 across 58 design docs — which is real progress. But the five pressure lenses
named in the scheduled workflow's `Context for this vision scan:` block remain structurally
open: sessions still produce housekeeping PRs, the loop-honesty gap persists, the skills
library is not measurably growing, onboarding requires human intervention, and no single-page
health view has shipped.

The criterion: a gap must (a) be live today, (b) have NO existing `🔲 Future` item covering
it in any of the 58 design docs, and (c) fix directly reduces failure under one of the five
lenses. After exhaustive search across all 255 existing `🔲 Future` items, three genuinely
absent gaps were found.

---

## Present (✅)

*(No items shipped yet — doc created by this scan)*

---

## Future (🔲)

### Lens 1 — Reliability: stage advancement is undetected when it stalls for 30+ batches

- 🔲 55.1 — The roadmap has Stages 11 and 12 with named deliverables. Stage 11 has been the
  active stage since at least 2026-04-20. No mechanism detects when the active roadmap stage
  has made zero progress for 30 consecutive batches — meaning no Stage 11 deliverable has
  transitioned from `🔲 Future` to `✅ Present` in that window. `docs/aide/progress.md` shows
  "Stage: 11" but does not show how many batches have elapsed since any Stage 11 deliverable
  shipped. The health signal is GREEN. A human reading progress.md has no indication whether
  Stage 11 has been advancing for the past 30 batches or frozen for all 30. PM §5 must add a
  `stage_stall_detector` check every 10 batches: (1) identify the active roadmap stage
  (first stage in `docs/aide/roadmap.md` without "COMPLETE" status); (2) read its deliverables
  list; (3) scan design doc `✅ Present` items for deliverables that shipped in the last 30
  batches (proxy: `git log --since="<30-batches-ago-date>" -- docs/design/` for lines changing
  from `🔲` to `✅`); (4) if zero deliverables shipped in the last 30 batches: open a
  `kind/chore priority/high` issue: "Stage stall: Stage N has had 0 deliverables ship in 30
  batches. Review roadmap for blocked deliverables, missing issues, or priority displacement."
  and write `stage_stall_detected: true` to `state.json`; COORD §1b-preflight must surface
  `stage_stall_detected` in its startup summary and set a `COORD_ACTION=stage-unblock` directive
  that gives deliverable issues `priority/critical`. Without this detector, the system can run
  100 batches "advancing" Stage 11 while every batch ships chores and CI improvements — the
  stage never moves and no automated signal surfaces it. The 30-batch threshold is chosen to be
  strict enough to catch a genuine stall (30 batches = approximately 30 hours at the current
  hourly schedule) while allowing for brief periods where Stage 11 items are being specced or
  waiting for dependencies. ⚠️ Inferred from reliability lens: a truly reliable system ships at
  least one meaningful PR every single run without exception; "meaningful" must include progress
  toward the active roadmap stage; sessions that ship housekeeping while Stage 11 sits idle are
  structurally broken even if their `meaningful_prs > 0` count looks healthy.

### Lens 3 — Self-improvement: skills library minimum growth rate is untracked and unenforced

- 🔲 55.2 — `docs/aide/metrics.md` and `agents/skills/PROVENANCE.md` record skill additions
  but no mechanism enforces a minimum rate of addition. Stage 2 (complete as of 2026-04-14)
  set a target of ≥10 skills. The current count is 11. That target was for stage completion,
  not ongoing growth. There is no ongoing floor: "the skills library grows slowly" is a stated
  failure mode in the pressure context, but there is no design doc item that defines what
  "slowly" means quantitatively OR that triggers an action when the defined rate is violated.
  `agents/skills/PROVENANCE.md` must be checked by SM §4c (already responsible for skill decay
  tracking) every 30 batches: (1) count PROVENANCE.md entries in the last 30 days; (2) count
  skills added to `agents/skills/` in the last 30 days (via `git log --since="30 days ago" --
  agents/skills/`); (3) if both counts are 0: SM §4c must open a `kind/chore priority/high`
  issue: "Skills library growth stalled: 0 learn sessions and 0 new skills in 30 days. Run
  /otherness.learn on a high-signal open-source project to add at least 1 new skill." and write
  `skills_growth_stalled: true` to `state.json`; COORD §1b-preflight surfaces this flag and
  opens a `learn(arch)` issue if one is not already open. The threshold of 30 days is the same
  cadence used in `agents/standalone.md` for learn-session scheduling — it is already the
  stated target interval, just not enforced. This item makes "at least 1 learn session per 30
  days" a verifiable, acted-on constraint rather than a stated aspiration. Without it, the
  skills library can go 90 days without growth while all other health metrics are GREEN, and no
  signal surfaces. ⚠️ Inferred from self-improvement lens: the skills library grows slowly;
  `/otherness.learn` runs rarely; the cadence exists in standalone.md as an intention but is
  not tracked in any metric and has no enforcement path; the missing item is the measurement
  and gate that converts the intention into a verifiable system property.

### Lens 5 — Visibility: gap-doc items (docs 46–55) are not entering the queue

- 🔲 55.3 — Docs 46–55 contain 90+ `🔲 Future` items, each naming a specific SM, PM, COORD,
  or ENG change. These items were written specifically to advance the five pressure lenses.
  But there is no mechanism that verifies whether items from the gap analysis series (docs
  46–55) are entering COORD's queue as GitHub issues. The items may exist in the design docs
  without any corresponding GitHub issue, which means COORD never sees them. A gap analysis doc
  is useless if its items are never issued. PM §5 must add a `gap_doc_queue_coverage` check
  every 10 batches: (1) read all `🔲 Future` items from docs 46–55 (by scanning filenames
  matching `4[6-9]-*.md` and `5[0-9]-*.md`); (2) for each item, search open GitHub issues for
  a title containing the first 40 chars of the item text (same heuristic used in SCAN 3 §42.1);
  (3) compute `gap_doc_coverage_pct = issues_found / total_gap_doc_items * 100`; (4) if
  `gap_doc_coverage_pct < 30%` (fewer than 30% of gap doc items have a corresponding open
  issue): post to the report issue: "⚠️ Gap-doc queue coverage: only N% of gap analysis items
  (docs 46–55) have corresponding GitHub issues. COORD is not seeing these items. Run queue
  generation to convert gap doc items to issues." and write `gap_doc_coverage_pct` to
  `state.json`. COORD §1c queue-gen must, when `gap_doc_coverage_pct < 30%`, prioritize
  creating issues from docs 46–55 before processing any other design doc. The gap analysis docs
  exist specifically to advance the pressure lenses — they represent the human analyst's
  highest-signal direction. If COORD is not processing them, the entire gap-analysis mechanism
  (14 scans, 10 docs, 90+ items) is producing documentation rather than queue items. The
  visibility failure is: a human looking at GitHub cannot tell whether the gap docs are
  influencing the queue or just accumulating. ⚠️ Inferred from visibility lens: a human looking
  at GitHub right now cannot quickly tell if the system is moving toward the vision; the gap
  analysis docs 46–55 are the most direct link between the pressure lenses and the queue; if
  their items are not in the issue queue, the pressure lenses cannot be addressed; no existing
  mechanism verifies this link.

---

## Zone 1 — Obligations

| # | Obligation |
|---|---|
| 55.1 | PM §5 must add `stage_stall_detector` every 10 batches: if active stage shows 0 deliverable `🔲→✅` transitions in last 30 batches, open `kind/chore priority/high` issue and write `stage_stall_detected: true`. COORD §1b-preflight must surface flag and apply `COORD_ACTION=stage-unblock`. |
| 55.2 | SM §4c must check PROVENANCE.md entries and new skill files every 30 batches: if both counts are 0 in 30 days, open `kind/chore priority/high` issue and write `skills_growth_stalled: true`. COORD §1b-preflight must surface flag and ensure a learn issue is open. |
| 55.3 | PM §5 must add `gap_doc_queue_coverage` check every 10 batches: compute pct of docs 46–55 items with open GitHub issues; if <30%, post warning and write `gap_doc_coverage_pct` to `state.json`; COORD §1c must prioritize creating gap-doc issues when coverage is <30%. |

## Zone 2 — Implementer's judgment

- 55.1: the "30 batches" count is an approximation using `git log --since=` with a wall-clock
  cutoff rather than an exact batch counter. This is acceptable given the hourly schedule.
  The detector must NOT fire on Stage 0–4 (already complete). It fires only when the current
  stage (`progress.md` "Stage: N") has been active for 30+ batches.
- 55.2: "30 days" is the same cadence as the learn-session scheduler in `standalone.md`.
  The SM §4c implementation already has the PROVENANCE.md git-log plumbing from the skill
  decay check (PR #660). Reuse that git log call — add a "new skills since 30 days" count.
- 55.3: the 30% coverage threshold is intentionally low — it requires only that some fraction
  of gap doc items are being tracked. A strict 80% threshold would fire on every run (gap docs
  are large). The goal is to detect the failure mode where NONE of the gap analysis items
  have entered the queue, not to require complete coverage.

## Zone 3 — Scoped out

- 55.1 does NOT rewrite `docs/aide/roadmap.md`. It only reads deliverables from the active
  stage and checks whether corresponding `✅ Present` items exist. If the roadmap stage
  deliverables are not written in a parseable format, the detector fails open (no issue opened).
- 55.2 does NOT auto-run `/otherness.learn`. It opens an issue. COORD claims the issue and
  runs the learn agent. Human oversight is preserved.
- 55.3 does NOT auto-create issues for all gap doc items. It flags the coverage gap and
  directs COORD to process gap docs first. Issue creation follows COORD's normal queue-gen
  flow, maintaining the de-duplication and label logic that already exists.
