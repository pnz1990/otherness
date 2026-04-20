# 24: Project Anchor Framework — Every Project Defines Its Own Evolution Metric

> Status: Active | Created: 2026-04-20
> Applies to: all projects using otherness

---

## The problem this solves

Counting PRs merged is a proxy metric. It tells you the team is active. It does not
tell you whether the product is better. A project that merges 50 PRs fixing test
flakiness has not made the product more capable. A project that merges 3 PRs covering
a previously untested integration scenario has advanced meaningfully.

The simulation (doc 23) measures team health — the abstract dynamics of boldness,
skill growth, and convergence that apply to any autonomous agent loop. That is Layer 1.

Layer 2 is missing: is the *product* getting better? That answer is different for
every project. It cannot be generic. It must be defined by the project.

---

## The two-layer model

```
Layer 1 — Universal team health (simulation, doc 23)
  Same for every project. Measures agent loop dynamics.
  Signals: items/batch, skill growth rate, Type B rate, arch convergence.
  Tells you: is the team healthy?

Layer 2 — Project anchor (this doc, per-project)
  Defined per project in AGENTS.md §Anchor and docs/design/<N>-anchor-<name>.md.
  Measures product evolution — does the product do more than it did last week?
  Tells you: is the product getting better?
```

The two layers talk. When Layer 1 shows stall (items/batch below floor), it is
possible the anchor is the cause — the team is spending cycles on anchor repair
instead of growth. When Layer 2 shows anchor stagnation (no new coverage in 3
sessions), COORD generates anchor-growth items before feature items.

---

## What an anchor is

An anchor is a **continuously growing validation suite** that exercises the actual
product from the outside — the way a real user would. Not unit tests. Not CI passing.
The real product, doing real things, measured against a growing matrix of scenarios.

An anchor has three properties:

**1. It is executable by the agent without human setup.**
The agent can trigger it via `gh workflow run`. It runs in CI. It produces a
machine-readable score. The agent reads that score after each batch.

**2. It grows automatically as features are added.**
Every new feature creates a corresponding anchor obligation. When the agent
ships a feature with no anchor coverage, COORD opens an anchor-growth issue
before the next feature item.

**3. Its growth is the primary measure of project success.**
Not PR count. Not velocity. Anchor coverage ratio: how many of the product's
defined capabilities are validated end-to-end.

---

## The feature → anchor gap

The core mechanism that makes this work:

```
feature registry (design docs ✅ Present items)
        ↓
    gap detection (SM §4g variant)
        ↓
anchor registry (AGENTS.md §Anchor coverage matrix)
        ↓
    uncovered features → anchor-growth issues
        ↓
COORD prioritizes anchor-growth above feature queue when coverage < threshold
```

**Gap detection runs in SM every 10 cycles:**
1. Read all ✅ Present items from docs/design/*.md — this is the feature registry
2. Read the anchor coverage matrix from AGENTS.md §Anchor — this is what's validated
3. For each Present feature with no corresponding anchor entry: open anchor-growth issue
4. Post coverage ratio: `[SM §4g-anchor] Feature→anchor coverage: N/M (X%)`
5. If coverage < 80%: COORD gate fires — generate anchor-growth items before feature items

---

## AGENTS.md §Anchor section

Every managed project adds a `## Anchor` section to its AGENTS.md. Structure:

```markdown
## Anchor

**Anchor type**: <demo | e2e-journey-suite | integration-scenario | benchmark>
**Coverage target**: ≥ 80% of ✅ Present features validated end-to-end
**Growth obligation**: every merged feature PR must have a corresponding anchor entry
  within 2 sessions of merge
**Run command**: gh workflow run <anchor-workflow>.yml --repo <owner/repo>
**Score field**: the workflow posts a coverage line to issue #<N> matching:
  `[ANCHOR] coverage: <N>/<M> (<X>%) scenarios passing`
**Stagnation threshold**: if anchor score does not improve in 3 consecutive sessions,
  COORD generates anchor-growth items before any feature items

### Coverage Matrix

| Feature area | Anchor entries | Status |
|---|---|---|
| <area> | <N> scenarios | ✅ covered / ⚠️ partial / ❌ none |
```

---

## otherness-config.yaml anchor fields

```yaml
anchor:
  workflow: pdca.yml          # workflow file that runs the anchor
  score_pattern: "PASS=([0-9]+) FAIL=([0-9]+)"  # regex to extract score from issue comment
  coverage_target: 80         # minimum % of features that must have anchor coverage
  stagnation_sessions: 3      # sessions without growth before COORD prioritizes anchor
  report_issue: 1             # issue where anchor scores are posted
```

---

## The bottlenecks (N+1, N+2, N+3) — acknowledged and scoped

**N+1: anchor infrastructure reliability.**
The anchor must run reliably before it can be a growth instrument. Flaky infrastructure
causes the agent to spend cycles on flakiness triage instead of coverage expansion.
Mitigation: each project's anchor design doc (docs 25, 26) includes an infrastructure
reliability section with known flakiness patterns and mitigation requirements.

**N+2: feature→anchor gap detection requires a structured feature registry.**
The gap detection algorithm reads ✅ Present items from design docs. This only works
if design docs exist and are maintained. Projects with sparse design docs (kro-ui has
1) cannot compute coverage ratios until more design docs are written. Mitigation:
COORD generates design doc stubs for feature areas with no docs, gated by the same
anchor-growth obligation that generates scenario issues.

**N+3: anchor infrastructure doesn't cover the full product surface.**
CLI can be tested in bash. UI requires a browser. Concurrent operations require
parallel runners. Each project's anchor design doc defines which surfaces are covered
and which are not, with explicit Future items for uncovered surfaces. The anchor grows
toward completeness rather than claiming completeness it doesn't have.

---

## Present (✅)

- ✅ Simulation (doc 23) — Layer 1 team health, per-project calibration designed (2026-04-20)
- ✅ SM §4g — codebase hygiene scan, surfaces undocumented files (2026-04-20, PR #347)
- ✅ kardinal-promoter PDCA workflow — 6 scenarios, weekly execution (2026-04-19)
- ✅ kro-ui E2E workflow — runs on push/PR, Playwright-based (2026-04-14)
- ✅ `otherness-config.yaml`: `anchor:` section added (commented-out, for projects with anchor workflows) — fields: workflow, score_pattern, coverage_target, stagnation_sessions (PR #357, 2026-04-20)
- ✅ `SM §4g-anchor`: feature→anchor gap detection — reads ✅ Present items from docs/design/*.md, diffs against AGENTS.md §Anchor matrix, opens anchor-growth issues for uncovered features; posts `[ANCHOR] coverage: N/M (X%)` to report issue every 10 SM cycles; graceful skip if no §Anchor section (PR #355, 2026-04-20)

## Future (🔲)

- 🔲 `otherness-config-template.yaml`: add `anchor:` section (workflow, score_pattern, coverage_target, stagnation_sessions) — HIGH tier, requires human review
- 🔲 `COORD §1c`: anchor-growth gate — when coverage < coverage_target, generate anchor-growth items before feature items
- 🔲 `docs/design/25-anchor-kardinal-promoter.md` — kardinal-promoter anchor design (PDCA expansion matrix, CLI/UI surface, infrastructure reliability, feature→scenario gap)
- 🔲 `docs/design/26-anchor-kro-ui.md` — kro-ui anchor design (E2E journey suite growth, feature→journey coverage, kro API surface, persona coverage)
- 🔲 `standalone.md` AGENTS.md template: add `## Anchor` section with standard structure

---

## Zone 1 — Obligations

**O1 — Anchor growth precedes feature growth when coverage < target.**
COORD must check anchor coverage before generating the feature queue. A project
below 80% coverage generates anchor-growth items first. Feature items are generated
only when coverage is at or above target.

**O2 — Every ✅ Present feature must have an anchor entry within 2 sessions.**
The gap between shipping a feature and validating it anchors drift. The 2-session
window prevents unbounded accumulation of unvalidated features.

**O3 — Anchor infrastructure failures are bugs, not noise.**
When the anchor workflow fails due to infrastructure (flaky cluster, network timeout),
the agent opens an infrastructure bug with priority/high and does NOT open coverage
issues. Infrastructure reliability is a precondition for anchor usefulness.

**O4 — The anchor score is posted by the workflow, not computed by the agent.**
The agent reads scores from the report issue. It does not compute coverage itself.
This means the anchor workflow is the source of truth, not the agent's interpretation
of test results.

---

## Zone 2 — Implementer's judgment

- Coverage target of 80% is a starting point. Projects with mature anchors may raise
  it. Projects bootstrapping their anchor start lower and raise as coverage grows.
- The stagnation threshold of 3 sessions is conservative. Adjust per project cadence
  — hourly sessions may use 5; 6-hour sessions may use 2.
- Whether to block the feature queue entirely or just deprioritize: start with
  deprioritize (interleave anchor and feature items) to avoid the queue running dry
  when a large surface needs coverage.

---

## Zone 3 — Scoped out

- Automated anchor writing (the agent writes scenarios from design docs automatically
  without human review — deferred; scenarios require product understanding that may
  exceed current capability)
- Cross-project anchor comparison (each project anchors independently)
- Anchor quality scoring (pass/fail ratio is sufficient; complexity scoring deferred)
