# Design Doc 57 — Seventeenth Vision Scan Pressure Gaps

**Vision scan date**: 2026-04-23
**Scan**: 17th autonomous run
**Pressure result**: SCAN 5 scores 5/5 via domain-noun matching (100% addressed — rewrite item already queued in doc 37)
**Backlog size**: 251 `🔲 Future` items across 60 design docs

---

## The problem

16 vision scans have run. The five pressure lenses remain structurally open. The SCAN 5
pressure scoring reports 100% addressed because the domain-noun matching is over-broad —
"session", "skill", "health", "onboard", "visib" appear in hundreds of Present items and
PR titles unrelated to the specific failure modes named. This doc applies the lenses with
higher precision: the criterion is not "does any shipped PR touch these domains" but "does
any specific mechanism address the exact failure mode described in the pressure prompt."

The criterion for this doc: a gap must (a) be live today, (b) have NO existing `🔲 Future`
item covering it in any of the 60 design docs — verified by exhaustive keyword search
across all 251 items, and (c) fix directly reduces failure under one of the five lenses.
After that exhaustive search, four genuinely absent gaps were found.

---

## Present (✅)

*(No items shipped yet — doc created by this scan)*

---

## Future (🔲)

### Lens 1 — Reliability: feature-content ratio is unmeasured and the loop cannot self-correct

- 🔲 57.1 — The session minimum meaningful-PR contract (standalone.md §1f, levels 1–3)
  counts PRs as "meaningful" if they carry a `feat/` prefix. But the current batch
  demonstrates that many `feat/` PRs advance infrastructure rather than user-facing
  capability: `feat(board)`, `feat(coord)`, `feat(workflow)`, `feat(sm)` PRs are
  correctly labeled, correctly reviewed, and counted as meaningful — yet a session
  that ships 5 such PRs has not shipped a single user-visible feature. The loop says
  GREEN, the contract is satisfied, but the pressure context says "sessions still
  produce housekeeping PRs with no real feature content." These are not the same
  failure mode: the contract guards against zero-output sessions; it does not guard
  against infrastructure-only sessions that look productive while product advancement
  stalls. SM §4b must add a `feature_content_ratio` metric to `docs/aide/metrics.md`:
  (1) each batch, classify all merged PRs by prefix: `feat(board)`, `feat(coord)`,
  `feat(workflow)`, `feat(sm)`, `feat(validate)`, `feat(scheduled)`, `feat(ci)`,
  `feat(tooling)` → category `infra`; `feat(releases)`, `feat(pm)`, `feat(eng)`,
  `feat(onboard)`, `feat(learn)` + any PR that promotes a `🔲 Future` design doc item
  to `✅ Present` → category `product`; (2) compute
  `feature_content_ratio = product_prs / (product_prs + infra_prs)` for the session;
  (3) if `feature_content_ratio < 0.25` for 3 consecutive sessions: write `content_drift:
  true` to `state.json` and post to the report issue: "⚠️ Content drift: 3 consecutive
  sessions shipping <25% product PRs. Infrastructure work is crowding out product
  advancement. COORD: next session must claim a product-category item." COORD
  §1b-preflight must check `content_drift` and, if true, boost priority of items that
  promote design-doc Future items — regardless of their priority label. Without this
  metric, the loop can spend 10 sessions "successfully" advancing infrastructure while
  the roadmap stalls — the contract is satisfied but the product is not moving. The
  48.5 item covers user-visible vs docs for managed projects; this item covers the
  equivalent measurement for otherness itself. ⚠️ Inferred from reliability lens: a
  truly reliable system ships at least one meaningful PR every single run without
  exception; "meaningful" in the pressure context means product advancement, not just
  non-zero output; the contract levels 1–3 prevent zero-output sessions but do not
  prevent infrastructure-only sessions from counting as meaningful; the feature content
  ratio is the missing metric that distinguishes these two failure modes.

### Lens 2 — Honesty: the health signal is GREEN while queue items from gap docs have 0% issue coverage

- 🔲 57.2 — Item 55.3 specifies `gap_doc_queue_coverage` — a PM §5 check every 10 batches
  that measures whether items from docs 46–55 have corresponding open GitHub issues
  (threshold: <30% triggers a warning). But 55.3 has no corresponding open GitHub issue
  itself. This scan's queue coverage audit found 0% coverage: all 96 items from docs 46–56
  have no corresponding open issue. The 55.3 mechanism (PM §5 coverage check) is also
  unissued. This creates a self-referential honesty failure: the mechanism that would detect
  the coverage gap is itself not in the queue, so it never runs, so the gap is never
  detected, so the system reports GREEN while the most precisely-specified improvement items
  it has ever generated sit unread by COORD. The honesty failure is not that the metrics are
  wrong — it is that the system claims to be driven by design docs but is demonstrably NOT
  reading design docs 46–56. SM §4a must add a single-command gap-doc triage check that runs
  at session START, before any other phase: (1) count `🔲 Future` items in files matching
  `docs/design/[4-5][0-9]-*.md`; (2) query open GitHub issues for items whose title begins
  with "feat:" + the first 30 chars of each item; (3) compute
  `unissued_count = total_gap_items - items_with_open_issues`; (4) if `unissued_count > 50`
  (>50% of gap-doc items unissued): SM §4a must post an AMBER signal regardless of other
  metrics: "⚠️ Loop honesty: {unissued_count} gap-doc items have no open issues. The system
  cannot claim to be advancing the pressure lenses while ignoring the items written to advance
  them." This check runs BEFORE the normal health computation — it gates the GREEN signal.
  A GREEN signal that coexists with >50% unissued gap-doc items is a structurally dishonest
  signal. Without this gate, the loop can report GREEN indefinitely while the most important
  direction it has ever received sits in design docs that COORD never reads. The existing
  55.3 item specifies a PM §5 check every 10 batches; this item specifies an SM §4a gate
  that runs every session and affects the health signal — these are complementary gates at
  different positions in the loop. ⚠️ Inferred from honesty lens: the SM health signal says
  GREEN but the products it manages are not advancing fast enough; specifically, the gap
  analysis docs (46–56) contain 96 items written to address the five pressure lenses; 0% of
  those items have entered the queue; reporting GREEN while ignoring 96 unqueued direction
  items is structurally dishonest; this gate converts the honesty guarantee from aspirational
  to enforced.

### Lens 3 — Self-improvement: /otherness.learn is not scheduled — the "run every 30 days" intent has no enforcement

- 🔲 57.3 — `agents/standalone.md` states that `/otherness.learn` should run "approximately
  every 14 days" (referenced in Stage 2 and repeated in doc 55.2). Item 55.2 adds SM §4c
  enforcement: if 0 learn sessions and 0 new skills in 30 days, open a `priority/high`
  issue. But 55.2 itself has no corresponding open GitHub issue — the enforcement mechanism
  it specifies does not yet exist. This scan found: 14 skills in `agents/skills/`, last
  PROVENANCE.md entry date unknown (no git log was run during this scan), and no `learn`
  item in the current open issue queue. The gap is not that the enforcement logic is unclear
  (55.2 is precise) — it is that the enforcement check has never been implemented. The check
  is 5 lines of shell: `git log --since="30 days ago" -- agents/skills/ | wc -l` gives new
  skill count; `grep -c "^## " agents/skills/PROVENANCE.md` gives session count. These
  commands exist and are referenced in the skill-decay check (standalone.md §4c). What does
  NOT exist is a concrete GitHub issue representing the obligation to run a learn session.
  SM §4c must, as an immediate self-bootstrapping action on the NEXT session, perform the
  30-day check and, if it has not yet run, create the enforcement issue now. The gap that
  this item fills: no existing `🔲 Future` item covers the self-bootstrapping path — the
  path where SM recognizes that a prescribed check does not yet exist and creates the issue
  for it immediately rather than waiting for the scheduled check to trigger. 55.2 covers the
  recurring enforcement; 57.3 covers the cold-start: SM §4c must run the 30-day check on
  every session start, not just every 30 batches, and must create a learn issue immediately
  if the last learn session was >30 days ago AND no learn issue is currently open. The "every
  30 batches" cadence in 55.2 is for the full audit report; the immediate action check must
  run every session. Without a session-level learn-scheduling check, the skills library
  growth depends on a 30-batch periodic audit that has itself not been implemented. This is
  a different gap from 55.2 (periodic audit) — it is the zero-cost session-level check that
  ensures the learn cadence is never more than one session behind schedule. ⚠️ Inferred from
  self-improvement lens: the skills library grows slowly; `/otherness.learn` runs rarely; the
  stated intention "run every 14 days" has never been implemented as a session-level
  enforcement check; 57.3 is the minimum-complexity path: SM checks at session start, creates
  issue if needed, exits; the issue enters the queue; COORD claims it; the cycle restarts.

### Lens 5 — Visibility: the pressure context itself is invisible to a human arriving at the repo

- 🔲 57.4 — A human arriving at the GitHub repo to understand "what is the system currently
  working toward improving?" has no direct answer. The five pressure lenses are defined in
  `.github/workflows/otherness-scheduled.yml` — a workflow file, not a human-readable doc.
  `docs/aide/vision.md` describes the product vision but not the current operational focus.
  `docs/aide/progress.md` shows stage completion but not which pressure lens is blocking
  Stage 11 from completing. Item 37.10 specifies that the pressure context must be visible
  in `/otherness.status` and the health comment — but 37.10 itself has no open GitHub issue.
  The result: a human stakeholder reading `docs/aide/` today sees GREEN health and 55.4%
  design items shipped, but has no answer to "what is the agent actively trying to fix right
  now?" This is a different gap from 48.15 (HEALTH.md with three questions) and from 39.2
  (health table in report issue body). Both of those answer "is it working?" — not "what
  problem is it focused on solving?" The pressure context is the answer to the second
  question. `docs/aide/progress.md` must include a "Current Focus" section (3 lines maximum)
  that is updated by SM §4f on every batch, summarizing the active pressure lenses in plain
  language: "Stage 11 focus: (1) Feature content ratio — sessions are shipping infrastructure
  instead of product; (2) Gap doc queue coverage — 96 improvement items not in queue;
  (3) Skills cadence — no learn session in 30+ days." SM §4f generates this by reading the
  pressure block from the scheduled workflow (same parse used in SCAN 5) and condensing each
  bullet to a one-line plain-language summary. A human opens `docs/aide/progress.md`, reads
  the 3-line "Current Focus" section, and immediately understands what the system is actively
  trying to fix — without opening the workflow file, without reading the report issue, without
  knowing what "SCAN 5" means. Without this section, the visibility gap persists at the
  semantic level: the system's operational intention is invisible to anyone not already
  familiar with the vibe-vision-auto workflow. The health dashboard (when 48.15 ships)
  answers "is it healthy?" — this item answers "what is it trying to fix?" Both questions
  matter; only the first has a shipping path. ⚠️ Inferred from visibility lens: a human
  looking at GitHub right now cannot quickly tell if the system is moving toward the vision
  or spinning in circles; the pressure context — the operational definition of "toward the
  vision" — is buried in a workflow file; surfacing it in `docs/aide/progress.md` as a
  "Current Focus" section is the minimum change that makes the system's intent readable to
  any human in 30 seconds.

---

## Zone 1 — Obligations

| # | Obligation |
|---|---|
| 57.1 | SM §4b must add `feature_content_ratio` metric: classify merged PRs as `infra` vs `product` by prefix. If ratio <25% for 3 consecutive sessions, write `content_drift: true` to `state.json` and post warning. COORD §1b-preflight must check `content_drift` and boost priority of design-doc-backed items. |
| 57.2 | SM §4a must add a gap-doc triage check at session START: count unissued items in `docs/design/[4-5][0-9]-*.md`; if unissued >50%, post AMBER signal immediately, before normal health computation. This gates GREEN on gap-doc queue coverage. |
| 57.3 | SM §4c must run a learn-scheduling check every session (not just every 30 batches): if last learn session >30 days ago AND no open learn issue exists, create one immediately. The session-level check is distinct from the 55.2 periodic audit — it ensures the cadence is never more than one session behind. |
| 57.4 | SM §4f must add a "Current Focus" section (≤3 lines) to `docs/aide/progress.md` every batch, condensing the active pressure bullets into plain-language summaries. Source: parse the scheduled workflow pressure block (same as SCAN 5). |

## Zone 2 — Implementer's judgment

- 57.1: the infra/product classification by prefix is a heuristic. The definitive signal is
  "does this PR promote a design doc `🔲 Future` item to `✅ Present`?" Any PR that does that
  is `product` regardless of prefix. The prefix heuristic handles PRs that don't follow the
  design-doc pattern. The two checks are complementary.
- 57.2: the "50%" threshold is conservative. With 96 items and 0 issued, the threshold fires
  immediately on the next session. The intent is to prevent GREEN from coexisting with a near-
  total gap-doc coverage gap. Once COORD begins issuing gap-doc items, the ratio will naturally
  improve and the AMBER trigger will clear.
- 57.3: the session-level check must NOT open duplicate learn issues. Before creating, SM §4c
  must search open issues for any issue with title containing "learn" and label "area/agent-loop"
  — if one exists, skip creation. The cadence enforcement is "at least one open learn issue at
  all times when last session >30 days ago," not "create a new issue every session."
- 57.4: the "Current Focus" section must be ≤3 bullets, each ≤20 words. SM §4f generates it
  by iterating over the pressure bullets and extracting the first sentence of each. The section
  replaces itself on every batch — it is not accumulated. The section heading is:
  `## Current Focus (auto-updated by SM §4f)` to signal its machine-generated origin.

## Zone 3 — Scoped out

- 57.1 does NOT change the definition of "meaningful PR" in the contract levels 1–3. The
  contract levels prevent zero-output sessions. The feature content ratio is a separate, slower
  signal that detects strategic drift over multiple sessions — not session-by-session output.
- 57.2 does NOT block the session if SM §4a cannot access the gap docs (file read error, etc.).
  The check is fail-open: if it cannot compute the count, it logs a warning and continues.
  The AMBER signal only fires when the count is definitively >50%.
- 57.3 does NOT run `/otherness.learn` inline. It creates a GitHub issue that enters the queue.
  COORD claims the issue; ENG runs the learn agent. Human oversight of the learn session target
  is preserved via the issue creation step.
- 57.4 does NOT redesign `docs/aide/progress.md`. It adds a new section before the existing
  "Stage Completion" table. The existing content is unchanged. If the workflow file cannot be
  parsed, the "Current Focus" section is omitted for that batch — fail-open.
