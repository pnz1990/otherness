# Design Doc 56 — Sixteenth Vision Scan Pressure Gaps

**Vision scan date**: 2026-04-23
**Scan**: 16th autonomous run
**Pressure result**: SCAN 5 scores 5/5 via domain-noun matching (over-broad, per 50.3/53) — all five lenses remain genuinely open
**Backlog size**: 251 `🔲 Future` items across 59 design docs

---

## The problem

15 vision scans have run. Each produced 3–10 new `🔲 Future` items. The
`✅ Present` count is 423 across 59 design docs — real progress. But the five
pressure lenses named in the scheduled workflow's `Context for this vision scan:`
block remain structurally open: sessions still produce housekeeping PRs, the
loop-honesty gap persists, the skills library is not measurably growing, onboarding
requires human intervention, and no single-page health view has shipped.

The criterion for this doc: a gap must (a) be live today, (b) have NO existing
`🔲 Future` item covering it in any of the 59 design docs, and (c) fix directly
reduces failure under one of the five lenses. After exhaustive search across all
251 existing `🔲 Future` items, four genuinely absent gaps were found.

---

## Present (✅)

*(No items shipped yet — doc created by this scan)*

---

## Future (🔲)

### Lens 1 — Reliability: duplicate issue generation inflates the queue silently

- 🔲 56.1 — COORD §1c queue-gen creates duplicate GitHub issues when the same
  design doc `🔲 Future` item has no closed corresponding issue — causing queue
  inflation and COORD navigation degradation. The current deduplication heuristic
  in COORD §1c uses the first 40 characters of a design doc item's text to search
  for an existing open issue. But when COORD runs in two consecutive sessions and
  neither session has yet claimed the item (it sits in `state=todo` with no
  `in_progress` lock), BOTH sessions' queue-gen pass can find "no open issue with
  this text" — because the issue created by session 1 was created AFTER session 2's
  deduplication check ran. The result: two GitHub issues with near-identical titles
  for the same design doc item. COORD then sees two `todo` items for the same work,
  may claim one and leave the other as dead weight, and the queue depth count is
  inflated by duplicates that SM never prunes. No existing item addresses this
  race-condition-free deduplication path. COORD §1c queue-gen must use GitHub's
  search API with a broader search window — not just "open" issues but also
  "closed in last 14 days" issues: `gh issue list --state all --search "<title>"
  --json state,closedAt` — to avoid creating a new issue for work that was just
  completed. Additionally, COORD §1c must write a `queue_gen_lock` to `state.json`
  at the START of queue-gen (not just at claim time) — the same atomic push pattern
  used for item claims — to prevent two concurrent sessions from both entering
  queue-gen in the same minute. Without this dual guard (closed-14d search + gen
  lock), the queue grows by 1–3 duplicate issues every time two sessions overlap,
  producing phantom work items that COORD cannot distinguish from real ones. After
  50 batches, the queue may contain 20+ duplicates — inflating queue depth metrics,
  triggering false "queue full" signals, and degrading COORD's ability to prioritise
  real work. ⚠️ Inferred from reliability lens: a truly reliable system ships at
  least one meaningful PR every run; duplicate queue inflation is a compounding
  failure that makes COORD progressively less effective over time, since it must
  navigate a queue that grows with phantom items; no existing item covers the
  queue-gen race condition itself (doc 35 covers claim-time deduplication, not
  gen-time).

### Lens 2 — Honesty: metrics.md column definitions drift out of sync with data rows

- 🔲 56.2 — `docs/aide/metrics.md` accumulates columns as new metrics are added
  (e.g. `recovery_attempted`, `chore_cause`, `eng_attempt_rate`) but the column
  DEFINITIONS block at the top of the file is never updated to match. The definitions
  block — which tells a human what each column means — was written once during
  Stage 4 and has not been regenerated since. New columns added in PRs #638, #720,
  #775, #796, #800 added headers but not definitions. A human reading
  `docs/aide/metrics.md` to diagnose a health regression reads column definitions
  that describe 8 columns while the actual data rows have 15+ columns, with no
  explanation of what columns 9–15 mean. Doc 46.5 covers schema drift detection
  (column count mismatch between header and data rows). But no existing item covers
  the definitions block staleness: the human-readable column glossary that explains
  what each metric means and how to interpret it. SM §4b must: (1) maintain a
  `METRICS_COLUMNS` constant in its Python block — a list of `(name, description)`
  tuples for every column the SM writes; (2) after writing each new data row,
  regenerate the definitions block at the top of `metrics.md` from this constant;
  (3) if a column is added to `METRICS_COLUMNS` without a description: SM §4b must
  refuse to write the new column and post "⚠️ metrics.md: column '<name>' added
  without a definition — add a description to METRICS_COLUMNS before deploying."
  The definitions block regeneration converts the column glossary from a
  manually-maintained artifact (that drifts) into an auto-generated one (that is
  always current). Without this, `docs/aide/metrics.md` is an honest record of
  numbers but a dishonest record of what those numbers mean — the human can see
  the data but cannot interpret it without reading the PR that introduced each
  column. ⚠️ Inferred from honesty lens: metrics are being collected but not acted
  on; the definitions block drift means the collected metrics become opaque over
  time as the human cannot decode what the columns mean; the system cannot claim
  its metrics are honest when the glossary that makes them interpretable is frozen
  at Stage 4.

### Lens 3 — Self-improvement: learn target repo selection is not diverse by construction

- 🔲 56.3 — `/otherness.learn` selects learn targets using a trending-repo heuristic
  (`gh api /repos/trending` or `gh search repos`) filtered by paradigm keywords.
  The diversity enforcement is reactive: SM §4c checks PROVENANCE.md after a session
  and flags when two consecutive sessions share the same `paradigm_category`. Item
  46.7 adds a pre-scan paradigm assessment. But neither item covers the source of
  the diversity problem: the CANDIDATE POOL from which learn targets are drawn is
  biased toward recently-trending GitHub repositories, which are disproportionately
  TypeScript/React/Next.js projects. A trending-repo pool in April 2026 contains
  50–70% JavaScript/TypeScript projects. Even with paradigm pre-assessment (46.7),
  an agent selecting "the first non-TypeScript entry" from a 70% TypeScript pool is
  selecting the 2nd or 3rd result — still from a biased sample. The monoculture
  problem is not fixed by per-session diversity checks on a monoculture pool.
  `agents/otherness.learn.md` must define a CANDIDATE POOL construction protocol
  that is diverse by design: rather than drawing from trending repos, the learn
  agent must construct its candidate pool from multiple source categories: (1) a
  language-diverse list — one candidate per major language family (Rust, Go, Python,
  Java/Kotlin, Elixir/Erlang, Haskell/OCaml, C/C++); (2) an architectural-style
  list — one candidate per architectural pattern (actor-model, event-sourced,
  functional-pure, reactive-streams, constraint-based); (3) an age-diverse list —
  one candidate from repos with initial commit >5 years ago (mature engineering
  patterns) and one from repos created in the last 6 months (emerging patterns).
  The learn agent selects from this multi-category pool, not from a single trending
  list. This is a different gap from 46.7 (which ensures the CHOSEN repo is not a
  repeat paradigm) and from frame-lock detection (35.8, which detects when
  arch_convergence is already high). This item prevents monoculture at the pool
  construction level — before any session budget is spent. ⚠️ Inferred from
  self-improvement lens: the skills library grows slowly because `/otherness.learn`
  sessions draw from a biased candidate pool; the existing diversity enforcement
  (post-hoc duplicate detection, pre-scan paradigm assessment) operates on a pool
  that is already biased; pool-level diversity is the missing structural fix that
  makes paradigm diversity reliable rather than incidental.

### Lens 5 — Visibility: single-page health file has no self-reporting staleness indicator

- 🔲 56.4 — Doc 48.15 specifies `docs/aide/HEALTH.md` as a committed markdown file
  updated every batch, answering all three human questions in one URL. When this
  ships, humans will bookmark `docs/aide/HEALTH.md` as their go-to health view.
  But `docs/aide/HEALTH.md` has the same staleness failure mode as `progress.md`
  today: if SM §4g fails to commit the file in a batch (network error, context
  budget exhausted, partial session exit), the human who opens the bookmarked URL
  sees a file that appears current but is N batches stale, with no visible indicator
  of its staleness. The "last_updated" date in the file body is the only staleness
  signal — and it is buried in the content, not visible from the GitHub file listing.
  No existing item covers this specific failure mode for HEALTH.md. `docs/aide/
  HEALTH.md` must be structured so staleness is self-evident at a glance, without
  requiring the human to read the file body: (1) the file's first line (the H1
  header) must include the batch number and date: `# otherness health — batch 152
  (2026-04-23)`; a human who sees this header on GitHub's file listing page
  immediately knows whether it is current or stale; (2) SM §4g must add a staleness
  self-test: after committing HEALTH.md, immediately re-read it via `git show
  HEAD:docs/aide/HEALTH.md | head -1` and verify the batch number matches the
  current session's batch number; if it does not match (write or commit failed
  silently), SM §4g must post to the report issue: "⚠️ HEALTH.md write verification
  failed — the file may be stale. Batch: N. Check git log for the last commit to
  docs/aide/HEALTH.md."; (3) SM §4a must include HEALTH.md in the docs-freshness
  check (doc 39.23) — specifically check whether the batch number in HEALTH.md's
  first line matches the current batch count; if HEALTH.md is >2 batches stale,
  flag it as stale alongside `progress.md` and `metrics.md`. Without this
  self-verification loop, HEALTH.md becomes the new `progress.md` — the primary
  human-facing health surface that drifts silently when SM fails to write it.
  The pressure context says "there is no clean single-page health dashboard" — when
  48.15 ships, HEALTH.md IS that dashboard; if it goes stale without detection, the
  visibility gap reappears in a different file. ⚠️ Inferred from visibility lens: a
  human looking at GitHub right now cannot quickly tell if the system is healthy;
  48.15 ships the single-page dashboard; 56.4 ensures it stays honest by detecting
  and surfacing its own staleness; without 56.4, 48.15 solves the problem for one
  day and then reintroduces the exact same failure mode in a new file.

---

## Zone 1 — Obligations

| # | Obligation |
|---|---|
| 56.1 | COORD §1c queue-gen must: (1) search closed-in-last-14d issues before creating new ones (not just open issues); (2) write a `queue_gen_lock` to `state.json` at queue-gen START using the same atomic push pattern as item claims. Both guards required together. |
| 56.2 | SM §4b must maintain `METRICS_COLUMNS` as a Python constant with `(name, description)` tuples for every column written. After each new data row, regenerate the definitions block at the top of `metrics.md`. Refuse to add a column without a description. |
| 56.3 | `agents/otherness.learn.md` must define a CANDIDATE POOL construction protocol with three categories: language-diverse, architectural-style-diverse, age-diverse. The pool is constructed before paradigm pre-assessment (46.7). The learn agent selects its target from this multi-category pool. |
| 56.4 | `docs/aide/HEALTH.md` first line must be `# otherness health — batch N (YYYY-MM-DD)` (batch number in H1). SM §4g must verify the file after commit by re-reading and checking the batch number. SM §4a must include HEALTH.md in the docs-freshness check with a 2-batch staleness threshold. |

## Zone 2 — Implementer's judgment

- 56.1: the `queue_gen_lock` write must be a separate `_state` push from the item-claim
  write. These are distinct operations — one prevents parallel gen, one prevents parallel
  claim. The gen lock must auto-expire after 10 minutes (same TTL as the stale watchdog
  for claims) to prevent a crashed gen session from permanently blocking queue generation.
- 56.2: the `METRICS_COLUMNS` constant must be a Python list at the TOP of SM §4b's Python
  block, easily readable by an engineer. The regenerated definitions block must be formatted
  as a markdown table with columns `| Column | Description |`. Backfill of old rows with
  empty values for new columns is covered by 46.5; 56.2 is specifically about the
  definitions glossary, not the data rows.
- 56.3: the three candidate categories do not require exactly one repo each — the goal is a
  pool that is not dominated by any single category. A pool of 9 candidates (3 per category)
  gives the paradigm pre-assessment (46.7) a diverse input. The construction can use static
  curated lists (updated by PM §5 competitive scan) supplemented by GitHub search.
- 56.4: the H1 staleness indicator (batch N in the header) is the minimal-change approach —
  it requires only one additional piece of information in the file title. The self-test
  (`git show HEAD:docs/aide/HEALTH.md | head -1`) is one additional command in SM §4g.
  These are zero-risk additions that protect the highest-value visibility artifact once it
  ships.

## Zone 3 — Scoped out

- 56.1 does NOT redesign the queue-gen flow entirely. It adds two guards to the existing
  gen flow. The item-creation logic, labeling, and issue body format are unchanged.
- 56.2 does NOT backfill descriptions for all 15 existing columns at once. SM §4b must
  add descriptions for the columns it controls; columns owned by other phases (PM §5,
  COORD §1b) must have their descriptions added in the PR that introduces each column.
  A missing description for a legacy column must log a warning, not block the write.
- 56.3 does NOT require a live GitHub API call to construct the pool at session time.
  A curated static list in `agents/otherness.learn.md` (updated periodically by PM §5)
  is sufficient and more reliable than real-time trending API calls.
- 56.4 does NOT change the content of HEALTH.md — only the H1 header format and the
  post-commit verification step. The three-question content (health, latest delivery,
  direction) is defined by 48.15 and unchanged here.
