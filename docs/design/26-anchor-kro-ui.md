# 26: Anchor — kro-ui

> Status: Active | Created: 2026-04-20
> Applies to: pnz1990/kro-ui
> Framework: docs/design/24-project-anchor-framework.md

---

## What kro-ui's anchor is

The anchor is the **E2E journey suite** — Playwright tests running against a real
kro cluster, exercising every shipped feature through a real browser, measuring
whether the UI correctly represents what kro is actually doing.

Unlike kardinal-promoter's bash-based PDCA, kro-ui's anchor is already a browser
automation suite with 71 journey files. The infrastructure exists. The problem is
not absence — it is that the suite is **reactive**: journeys are added after features
ship, not as a mandatory growth obligation. There is no coverage ratio tracked. There
is no mechanism that generates journey-growth issues when a feature has no corresponding
journey. The anchor exists but is not being treated as one.

**The anchor must grow in three dimensions:**
1. **Feature→journey parity** — every spec has a corresponding journey file
2. **Scenario depth** — each journey tests not just "the feature exists" but edge
   cases, error states, loading states, empty states, accessibility
3. **kro upstream tracking** — as kro adds new API surface, kro-ui adds coverage

---

## Current state (as of 2026-04-20)

**Anchor workflow:** `.github/workflows/e2e.yml` — runs on every push to main
and every PR
**Test framework:** Playwright + Chromium, via `test/e2e/journeys/*.spec.ts`
**Journey count:** 71 spec files
**Spec count:** 67 shipped specs

**Coverage score:** 71 journeys / 67 specs = **106%** — but this is misleading.
Several specs have no journey (gaps), and several journeys cover features not in the
spec list. The real metric is: of the 67 shipped specs, how many have journeys that
test edge cases, error states, and not just happy paths?

**Honest assessment:** most journeys test the happy path. Error states, loading
states, empty states, accessibility, and concurrent operations are sparsely covered.
Journey count ≠ journey depth.

---

## The two coverage metrics

**Metric 1: Feature→journey parity**
```
parity = journeys_with_matching_spec / total_merged_specs * 100
Current: ~67/67 (apparent parity — actual gaps exist in newer specs 063-070)
Target: 100% within 1 session of spec merge
```

**Metric 2: Journey depth score**
Each journey earns points for:
- Happy path: 1 point (baseline)
- Error state (API failure, network error): +1 point
- Empty state (no resources): +1 point
- Loading/skeleton state: +1 point
- Accessibility check (axe, aria): +1 point
- Edge case (large dataset, long names, special characters): +1 point

```
depth_score = total_points / (total_journeys * 6) * 100
Current estimate: ~20-30% (most journeys are happy-path-only)
Target: ≥ 60% within 1 quarter
```

The anchor score posted to issue #439 tracks both:
```
[ANCHOR | kro-ui | DATE] parity: N/M (X%) | depth: P/Q (Y%) | journeys: J | pass: A fail: B
```

---

## Feature surface — what needs depth coverage

### Tier 1: Core data display (specs 001-007)
| Feature | Happy path | Error state | Empty state | Loading | A11y | Edge case |
|---|---|---|---|---|---|---|
| RGD list | ✅ | ⚠️ partial | ⚠️ partial | ⚠️ partial | ⚠️ partial | ❌ |
| RGD DAG | ✅ | ❌ | ❌ | ⚠️ partial | ❌ | ❌ |
| Instance list | ✅ | ⚠️ partial | ✅ | ⚠️ partial | ⚠️ partial | ❌ |
| Instance detail (live) | ✅ | ❌ | ❌ | ✅ | ❌ | ❌ |
| Context switcher | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Feature flags | ✅ | ❌ | — | — | — | ❌ |

### Tier 2: Advanced features (specs 008-040)
| Feature | Happy path | Error state | Empty state | Edge case |
|---|---|---|---|---|
| Graph diff | ✅ | ❌ | ❌ | ❌ |
| Collection explorer | ✅ | ❌ | ✅ | ❌ |
| Multi-cluster overview | ✅ | ❌ | ❌ | ❌ |
| RGD Designer | ✅ | ⚠️ partial | ❌ | ❌ |
| RBAC visualizer | ✅ | ❌ | ❌ | ❌ |
| Smart event stream | ✅ | ❌ | ✅ | ❌ |
| Per-context metrics | ✅ | ❌ | ❌ | ❌ |
| Global instance search | ✅ | ❌ | ✅ | ❌ |
| Cache invalidation on context switch | ✅ | ❌ | — | ❌ |

### Tier 3: kro upstream tracking (specs 046, 063+)
| kro feature | UI coverage | Journey depth |
|---|---|---|
| GraphRevision API (kro v0.9.0) | ✅ journey 063 | shallow |
| kro v0.9.1 upgrade | ✅ journey 063 | shallow |
| CEL extensions | ⚠️ partial | shallow |
| readyWhen conditions | ⚠️ partial | shallow |
| includeWhen | ✅ | shallow |
| Fleet reconciling count | ✅ journey 064 | shallow |

### Tier 4: Persona journeys (none exist yet)
| Persona | Scenario | Status |
|---|---|---|
| Operator | Deploy new RGD, verify instances appear, check health | ❌ no journey |
| Developer | Author RGD in designer, validate, apply to cluster | ❌ no journey |
| SRE | Cluster degraded — diagnose which RGDs/instances affected | ❌ no journey |
| Kro contributor | Review upstream fixture alignment, identify drift | ❌ no journey |

---

## The N+1 and N+2 bottlenecks for kro-ui specifically

**N+1: feature→journey gap detection requires structured mapping.**
The gap detection algorithm (doc 24) reads ✅ Present items from docs/design/*.md.
kro-ui has 1 design doc. The feature registry lives in AGENTS.md's spec inventory
table, not in design docs with Present/Future markers. Before gap detection works,
either: (a) the spec inventory becomes the source of truth for the gap algorithm,
or (b) design docs are created for major feature areas.

Mitigation: extend the gap detection to also read AGENTS.md spec inventory rows
where `Merged (PR #N)` — these are the ✅ Present items for kro-ui specifically.

**N+2: depth scoring requires journey analysis.**
The depth score cannot be computed by reading file names. The algorithm must read
journey file contents and count which of the 6 depth dimensions are present
(look for `axe`, `toHaveCount(0)`, error response mocking, etc.).
This is more complex than the parity check but tractable.

Mitigation: start with parity-only scoring in the anchor comment. Add depth scoring
in a second pass once parity is near 100%.

---

## Growth roadmap

### Week 1: parity for specs 063-070
- Journey depth audit: identify which of the last 10 journeys are happy-path-only
- Add error state to journeys 063, 064, 065, 066 (kro v0.9.1 features)
- Anchor score comment: post `[ANCHOR | kro-ui]` to issue #439 after each E2E run

### Month 1: depth to 50% + first persona journeys
- Error states for Tier 1 core features (RGD list, DAG, instance detail)
- Empty states for context switcher, RGD designer, graph diff
- First persona journey: Operator — deploy RGD, verify instances, check health
- Accessibility audit: run axe on all Tier 1 pages, fix violations, add axe assertions
  to existing journeys

### Quarter 1: depth ≥ 60% + full persona coverage + kro upstream tracking
- All Tier 1 and Tier 2 features have error + empty state coverage
- All 4 persona journeys: operator, developer, SRE, kro contributor
- kro upstream tracking: when a new kro version lands, a journey exists within 2 sessions
- kro API surface coverage metric: what % of kro CRD fields are exercised in journeys

---

## The anchor score comment format

After each E2E run, post to issue #439:
```
[ANCHOR | kro-ui | YYYY-MM-DD] parity: N/M (X%) | depth: P/Q (Y%) | journeys: J | pass: A fail: B
```

Until depth scoring is implemented, use:
```
[ANCHOR | kro-ui | YYYY-MM-DD] journeys: J | pass: A fail: B
```

---

## Present (✅)

- ✅ E2E workflow: `.github/workflows/e2e.yml` — Playwright, runs on push/PR (2026-04-14)
- ✅ 71 journey files covering 67 merged specs — high parity (2026-04-20)
- ✅ Journey infrastructure: kind-less (uses mock fixtures), fast, reliable (2026-04-14)
- ✅ Constitution §XIV E2E standards — anti-patterns documented (PR #311, 2026-04-15)

## Future (🔲)

- 🔲 Anchor score comment: E2E workflow posts `[ANCHOR | kro-ui | DATE] journeys: J | pass: A fail: B` to issue #439
- 🔲 Feature→journey parity check: SM §4g-anchor reads AGENTS.md spec inventory (Merged rows), diffs against journey file names, opens anchor-growth issues for specs with no journey
- 🔲 Journey depth: add error state coverage to journeys 063-070 (kro v0.9.1 features)
- 🔲 Journey depth: add error + empty state to all Tier 1 journeys (001-007)
- 🔲 First persona journey: Operator — deploy RGD via designer, verify instances appear, check health indicators
- 🔲 Accessibility: run axe assertions on Tier 1 pages (RGD list, DAG, instance list, context switcher)
- 🔲 kro upstream tracking: when kro version bumps, SM opens anchor-growth issue for new API surface
- 🔲 otherness-config.yaml: `anchor:` section — score_pattern for `[ANCHOR | kro-ui]`, coverage_target: 60, stagnation_sessions: 5
- 🔲 docs/design/: add design docs for major feature areas (RGD display, instance management, health system, designer) to enable generic gap detection

---

## Zone 1 — Obligations

**O1 — Every merged spec has a journey within 2 sessions.**
Parity must be maintained. A spec with no journey is an untested feature.

**O2 — Happy-path-only journeys count as half-coverage.**
A journey that only tests success is better than no journey but does not count as
full coverage. Depth is part of the anchor obligation, not optional polish.

**O3 — kro upstream changes trigger anchor obligations.**
Every kro version upgrade opens an anchor-growth issue for new API surface. The
journey suite must track the upstream, not lag behind it.

**O4 — The journey infrastructure must stay reliable.**
Constitution §XIV anti-patterns are obligations. Violations must be fixed before
new journeys are added — a flaky existing journey degrades the whole anchor.

---

## Zone 2 — Implementer's judgment

- Journey depth scoring algorithm: start simple (grep for `axe`, error mock patterns,
  `toHaveCount(0)`) rather than AST parsing. Refine if false positives are significant.
- Whether to use axe-playwright or custom aria checks: axe-playwright is standard
  and already referenced in Constitution §XIV. Use it.
- Persona journey complexity: start with the simplest persona (Operator happy path)
  before adding complex multi-step SRE scenarios.

---

## Zone 3 — Scoped out

- Visual regression testing (screenshot diffing) — deferred, high maintenance cost
- Performance journey tests (LCP, FCP metrics) — future extension point
- Multi-cluster E2E with real clusters (current fixtures simulate multiple clusters)
- Cross-browser testing beyond Chromium — out of scope for kro-ui donation readiness
