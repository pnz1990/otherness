# 25: Anchor — kardinal-promoter

> Status: Active | Created: 2026-04-20
> Applies to: pnz1990/kardinal-promoter
> Framework: docs/design/24-project-anchor-framework.md

---

## What kardinal-promoter's anchor is

The anchor is the **PDCA validation suite** — a live end-to-end test that exercises
kardinal-promoter the way a real platform engineer would use it: real cluster, real
ArgoCD, real application images, real CLI commands, real policy evaluation.

Not unit tests. Not CI. The actual product, doing actual work, measured against a
growing matrix of real-world scenarios.

**The anchor must grow in two dimensions simultaneously:**
1. **Coverage width** — more of the product surface is exercised each week
2. **Scenario depth** — each area is exercised at higher complexity (basic → edge case → adversarial)

A project where anchor width grows but depth stays shallow has coverage theater.
A project where depth grows but width stagnates has gaps. Both dimensions must advance.

---

## Current state (as of 2026-04-20)

**Anchor workflow:** `.github/workflows/pdca.yml` — runs weekly (Sundays 04:00 UTC) + manual dispatch
**Also:** `.github/workflows/demo-validate.yml` — runs nightly, broader demo surface

**Current PDCA coverage (6 scenarios):**

| Scenario | Surface | Depth | Status |
|---|---|---|---|
| S1: Happy path promotion | CLI + controller | basic | ✅ passing |
| S2: Pause blocks promotion | CLI + controller | basic | ✅ passing |
| S3: Weekend gate blocks prod | policy evaluation | basic | ✅ passing |
| S4: Explain shows gate details | CLI output | basic | ✅ passing |
| S5: Rollback opens PR | CLI + GitHub | basic | ✅ passing |
| S6: Concurrent bundles | CLI + controller | intermediate | ✅ passing |

**Coverage score:** 6/? scenarios — denominator is undefined because the full feature
surface has not been mapped to the anchor matrix. That is the first gap to close.

---

## The feature surface — what needs to be covered

Derived from kardinal-promoter's 10 design docs + CLI surface:

### Surface 1: Promotion mechanics (docs 01, 02, 03, 08)
| Feature | Current anchor | Gap |
|---|---|---|
| Basic bundle create + promote | S1 | ✅ covered |
| Pause/resume in-flight promotion | S2 | ✅ covered |
| Rollback | S5 | ✅ covered |
| Config-only promotions (no image change) | none | ❌ |
| Multi-stage promotion (test→uat→prod) | S1 partial | ⚠️ partial |
| Promotion with failing health check | none | ❌ |
| Bundle supersession when newer image arrives | S6 partial | ⚠️ partial |
| Promotion with ArgoCD sync timeout | none | ❌ |
| Distributed architecture (separate control/agent) | none | ❌ |

### Surface 2: Policy gates (doc 04)
| Feature | Current anchor | Gap |
|---|---|---|
| Time-based gate (weekend block) | S3 | ✅ covered |
| Time-based gate (business hours allow) | S3 partial | ⚠️ partial |
| Explain shows gate details | S4 | ✅ covered |
| Policy simulate CLI | S3 | ✅ covered |
| Multiple gates on same pipeline | none | ❌ |
| Gate with custom expression | none | ❌ |
| Gate override (emergency deploy) | none | ❌ |

### Surface 3: Health adapters (doc 05)
| Feature | Current anchor | Gap |
|---|---|---|
| HTTP healthcheck adapter | none | ❌ |
| Prometheus metrics adapter | none | ❌ |
| ArgoCD sync status adapter | S1 implicit | ⚠️ implicit |
| Health check failure blocks promotion | none | ❌ |
| Health check recovery unblocks promotion | none | ❌ |
| Custom health adapter configuration | none | ❌ |

### Surface 4: CLI completeness (all docs)
| Command | Current anchor | Gap |
|---|---|---|
| `kardinal create bundle` | S1 | ✅ covered |
| `kardinal get pipelines` | S1 | ✅ covered |
| `kardinal pause` / `kardinal resume` | S2 | ✅ covered |
| `kardinal rollback` | S5 | ✅ covered |
| `kardinal explain` | S4 | ✅ covered |
| `kardinal policy simulate` | S3 | ✅ covered |
| `kardinal get bundles` | none | ❌ |
| `kardinal delete bundle` | none | ❌ |
| `kardinal get steps` | none | ❌ |
| `kardinal describe pipeline` | none | ❌ |
| `kardinal apply` (config-only) | none | ❌ |

### Surface 5: Real-world complexity (no doc — scenario-driven)
| Scenario | Current anchor | Gap |
|---|---|---|
| 2 concurrent bundles, correct supersession | S6 | ✅ covered |
| 3+ concurrent bundles | none | ❌ |
| Promotion during ArgoCD outage | none | ❌ |
| Clock skew between clusters | none | ❌ |
| Network partition between control and agent | none | ❌ |
| App that fails readiness probe | none | ❌ |
| App with database migration | none | ❌ |
| SRE persona: full incident response (rollback + policy + explain) | none | ❌ |
| Developer persona: full feature deploy lifecycle | none | ❌ |
| Platform engineer persona: multi-env pipeline setup | none | ❌ |

### Surface 6: UI/UX (doc 06)
| Feature | Current anchor | Gap |
|---|---|---|
| Bundle status visible in UI | none | ❌ |
| Policy gate status in UI | none | ❌ |
| Rollback button in UI | none | ❌ |
| Pipeline graph visualization | none | ❌ |
| All CLI functionality accessible via UI | none | ❌ |

**Note on UI surface:** current PDCA is bash-only. UI coverage requires Playwright
or a similar browser automation tool. This is an infrastructure gap, not just a
scenario gap. See Infrastructure section below.

---

## Coverage score formula

```
coverage_score = (scenarios_passing / total_defined_scenarios) * 100

Current: 6 / ~35 defined = ~17%
Target: ≥ 80% within 1 quarter
```

The denominator grows as new scenarios are defined. The score should grow faster
than the denominator — each session should add more passing scenarios than new
scenario definitions.

---

## Infrastructure reliability requirements (N+1 bottleneck)

Before the anchor can grow, the infrastructure must be reliable. Observed failure
modes from PDCA run history:

| Failure mode | Frequency | Mitigation required |
|---|---|---|
| kind cluster creation timeout | occasional | Retry logic + timeout increase |
| ArgoCD sync timeout (app not synced in time) | occasional | Increase wait timeout, add retry |
| krocodile not ready after helm install | rare | Wait-for-ready probe before tests |
| `ghcr.io` image pull rate limit | rare | Pre-pull image in setup step |
| Flaky S1 (controller not reconciling fast enough) | occasional | Increase reconcile wait, add polling |

**Obligation:** before adding scenario N+1, ensure the existing N scenarios pass
in ≥ 3 consecutive runs without infrastructure failures. Anchor growth on a flaky
base produces false signals.

**Infrastructure health gate (SM §4g-anchor sub-check):**
If the last 3 PDCA runs show infrastructure failures (not scenario failures), COORD
generates infrastructure-fix items before anchor-growth items.

---

## Growth roadmap

### Week 1 (now → +7 days): foundation reliability + coverage to 30%
- Scenario 7: config-only promotion (no image change)
- Scenario 8: multi-stage full path (test→uat→prod, all three assertions)
- Scenario 9: health check failure blocks promotion
- Scenario 10: `kardinal get bundles` + `kardinal delete bundle` CLI coverage
- Infrastructure: make PDCA run daily (not weekly), add retry logic to S1

### Month 1 (+30 days): coverage to 60%, depth increase
- Scenarios 11-15: policy gate completeness (multiple gates, custom expr, override)
- Scenarios 16-18: health adapter coverage (HTTP, Prometheus, custom)
- Scenarios 19-21: real-world complexity (3+ concurrent, app readiness failure)
- Scenarios 22-24: persona journeys (SRE incident, developer feature deploy)
- Infrastructure: add Playwright to PDCA for UI surface (first 3 UI scenarios)

### Quarter 1 (+90 days): coverage ≥ 80%, full product surface
- UI coverage complete (all CLI commands accessible via UI)
- Edge cases: distributed architecture, ArgoCD outage, clock skew
- All 3 persona journeys: SRE, developer, platform engineer — full lifecycle
- PDCA runs on every PR that touches controller, CLI, or ArgoCD integration (not just daily)

---

## The anchor score comment format

PDCA posts to issue #1 after every run:
```
[ANCHOR | kardinal-promoter | YYYY-MM-DD] coverage: N/M (X%) | PASS=A FAIL=B
```

The agent reads this pattern to track coverage ratio across sessions.

---

## Present (✅)

- ✅ PDCA workflow — 6 scenarios, weekly execution, posts results to issue #1 (2026-04-19)
- ✅ Demo-validate workflow — nightly, broader demo surface (2026-04-19)
- ✅ test infrastructure: kind + krocodile + ArgoCD + kardinal-test-app (2026-04-09)
- ✅ Anchor score comment format: SM §4g-anchor-score reads `[ANCHOR | kardinal-promoter | DATE] coverage: N/M (X%) | PASS=A FAIL=B` from report issue, tracks stagnation across sessions (PR #438, 2026-04-20)

## Future (🔲)

- 🔲 PDCA runs daily (not weekly) — change cron to `0 2 * * *` matching demo-validate cadence
- 🔲 Infrastructure reliability: retry logic for S1 reconcile wait + ArgoCD sync timeout increase
- 🔲 Scenario 7: config-only promotion — `kardinal apply` with no image change, verify PromotionStep created
- 🔲 Scenario 8: full multi-stage assertion — verify each stage independently (test health ✅, uat health ✅, prod gate ✅)
- 🔲 Scenario 9: health check failure blocks promotion — deploy app with failing readiness probe, verify promotion pauses
- 🔲 Scenarios 10-12: CLI completeness — `kardinal get bundles`, `kardinal delete bundle`, `kardinal get steps`
- 🔲 Scenarios 13-15: policy gate completeness — multiple gates, custom expression, emergency override
- 🔲 Scenarios 16-18: health adapter coverage — explicit HTTP, Prometheus, and custom adapter scenarios
- 🔲 Scenarios 19-21: real-world complexity — 3+ concurrent bundles, app readiness failure, SRE rollback+explain flow
- 🔲 Scenarios 22-24: persona journeys — developer full lifecycle, platform engineer pipeline setup, SRE incident response
- 🔲 Playwright integration in PDCA — first 3 UI scenarios (bundle status, pipeline graph, rollback button)
- 🔲 Feature→scenario gap detection: SM §4g-anchor reads ✅ Present items from docs/design/*.md, diffs against this coverage matrix, opens anchor-growth issues for uncovered features
- 🔲 otherness-config.yaml: `anchor:` section — workflow, score_pattern, coverage_target: 80, stagnation_sessions: 3

---

## Zone 1 — Obligations

**O1 — Infrastructure reliability before growth.**
Before adding scenario N+1, the existing N scenarios must pass in ≥ 3 consecutive runs
without infrastructure failures. Never grow a flaky anchor.

**O2 — UI surface requires its own infrastructure investment.**
Playwright must be added to PDCA before any UI scenario can be validated. Do not
create UI scenarios without the infrastructure to run them.

**O3 — The anchor score comment format is the source of truth.**
The agent reads coverage from the structured comment, not from parsing workflow logs.
The PDCA workflow is responsible for posting this comment. Never let the comment
format drift from the pattern the agent reads.

**O4 — Persona journeys are the highest-value scenarios.**
A passing S1 (happy path) proves the product works. A passing persona journey
(SRE incident response end-to-end) proves the product is useful. Persona journeys
are prioritized over narrow CLI command coverage in the growth roadmap.

---

## Zone 2 — Implementer's judgment

- Whether to add retries inside the PDCA bash script or at the workflow level:
  retry at the step level (GitHub Actions `continue-on-error` + explicit re-run)
  is simpler and more observable than bash retry loops.
- Whether the UI tests use Playwright embedded in PDCA or a separate workflow:
  separate is cleaner for isolation but requires two workflows to stay in sync.
  Start with embedded Playwright in PDCA; split only if test time exceeds 30 minutes.
- Coverage target of 80% by end of quarter is ambitious given current 17%.
  Achievable if each session adds 2-3 new passing scenarios.

---

## Zone 3 — Scoped out

- Automated scenario generation from design docs (agent writes scenarios without human review)
- Performance/load testing scenarios (separate concern)
- Multi-cluster cross-region scenarios (requires infrastructure not yet available)
- External integrations (PagerDuty, Slack alerts) — future extension point
