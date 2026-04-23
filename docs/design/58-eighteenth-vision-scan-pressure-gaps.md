# Design Doc 58 — Eighteenth Vision Scan Pressure Gaps

**Vision scan date**: 2026-04-23
**Scan**: 18th autonomous run
**Pressure result**: SCAN 5 scores 5/5 via domain-noun matching (over-broad, per 50.3/53) — all five lenses remain genuinely open
**Backlog size**: 251 `🔲 Future` items across 61 design docs

---

## The problem

17 vision scans have run. Doc 57 added four precisely-scoped items (57.1–57.4). This
doc applies the same high-precision criterion: a gap must (a) be live today, (b) have NO
existing `🔲 Future` item covering it in any of the 61 design docs — verified by exhaustive
keyword search across all 251 items, and (c) fix directly reduces failure under one of the
five pressure lenses.

After that exhaustive search, two genuinely absent gaps were found. The remaining pressure
failures are already covered by items in docs 46–57; those items have not yet shipped.
This doc does NOT re-describe covered gaps. It adds only what is demonstrably absent.

---

## Present (✅)

*(No items shipped yet — doc created by this scan)*

---

## Future (🔲)

### Lens 2 — Honesty: simulation predictions have no accuracy tracking — they are stated but never verified

- 🔲 58.1 — The simulation (`docs/design/10-multi-agent-simulation.md`,
  `docs/design/11-simulation-feedback-loop.md`) generates predictions: `arch_convergence`
  score, `recovery_action` recommendations, `stagnation_risk` signals. These predictions
  appear in SM health comments. But no existing item specifies that predictions must be
  verified against actual outcomes. The honesty failure is specific: the simulation says
  "recovery_action: trigger_vision_synthesis" — does triggering vision synthesis actually
  reduce stagnation? The simulation says `arch_convergence` is rising — does skills
  diversity actually improve after a learn session? Today, these predictions are stated and
  then forgotten. The next session reads the new state but never compares predicted outcomes
  against actual outcomes. The pressure context states: "simulation exists but its predictions
  are not visibly changing agent behavior." The reason they are not visibly changing behavior
  is that there is no outcome record: COORD cannot learn from "simulation said X → actual
  result was Y" because Y is never recorded against X. SM §4b must maintain a
  `simulation_accuracy` ledger in `state.json`: after each batch, for every
  `recovery_action` that was recommended in the previous batch, record whether the
  recommended action was taken AND whether the metric it was supposed to improve
  (stagnation_risk, arch_convergence, etc.) actually improved in the next batch. After 5
  completed ledger entries, SM §4b must compute `prediction_accuracy_rate =
  correct_outcomes / total_outcomes` and include it in the health comment alongside the
  simulation score: "Simulation: arch_convergence=0.72, accuracy=3/5 (60%)". A simulation
  that is correct 60% of the time should be weighted at 60% confidence in COORD's claiming
  decisions — not at 100%. Without the ledger, the simulation is always treated as
  authoritative regardless of its actual predictive quality; the "simulation exists but
  predictions not visibly changing agent behavior" failure persists because there is no
  feedback loop connecting prediction → outcome → adjusted confidence. Doc 23 covers
  `recovery_action` verification end-to-end (23.x). Doc 48.6 covers making recovery_action
  human-readable. Neither covers the accuracy tracking ledger that would prove the simulation
  is or is not a reliable guide. This item covers the missing feedback loop.

### Lens 4 — Onboarding: `/otherness.onboard` has no post-run output quality gate

- 🔲 58.2 — The pressure context states: "/otherness.onboard produces docs that need manual
  editing." Doc 32 covers many onboarding quality improvements (32.x items). But no existing
  item specifies a post-run output quality gate — a check that runs AFTER `/otherness.onboard`
  completes and verifies its outputs meet a minimum correctness standard before the human is
  told "onboarding complete." Today the onboarding agent runs, writes `docs/aide/*.md` files,
  and exits — with no verification that what was written is correct, current, and complete.
  The human receives "onboarding complete" but still needs to manually edit the docs to fix
  placeholder values, stale descriptions, and generic boilerplate. The quality gate must
  verify the four most common failure modes in onboarding outputs: (1) placeholder detection
  — scan `docs/aide/*.md` for patterns like `<project-name>`, `TBD`, `TODO`, `FIXME`,
  `[insert`, `your-repo` that were not replaced by real values; (2) BUILD_COMMAND
  reachability — verify the `BUILD_COMMAND` in `otherness-config.yaml` points to a file
  that exists (`scripts/validate.sh` or equivalent); (3) docs/aide completeness — verify
  all five required files exist: `vision.md`, `roadmap.md`, `definition-of-done.md`,
  `progress.md`, `metrics.md`; (4) cross-reference sanity — verify the `REPO` field in
  `otherness-config.yaml` matches the actual git remote URL (catches copy-paste from
  another project). If any check fails, the onboarding agent must post the failures to the
  terminal output AND to the report issue before exiting, labeling the status as
  "⚠️ ONBOARDING INCOMPLETE — manual fixes required" rather than "onboarding complete."
  This converts the current silent-failure mode (human discovers problems days later) into
  an explicit-failure mode (human sees exactly what needs fixing immediately). Doc 32.x
  items improve what the onboarding agent writes; this item verifies what was written.
  These are complementary: writing better content (32.x) reduces the gate failure rate;
  the gate (58.2) ensures failures are surfaced regardless of how good the writing is.
  Without 58.2, the "onboard produces docs needing manual editing" pressure failure persists
  even after all 32.x items ship — because there is no check that the improvements actually
  produce correct output for the specific project being onboarded.

---

## Zone 1 — Obligations

| # | Obligation |
|---|---|
| 58.1 | SM §4b must maintain a `simulation_accuracy` ledger in `state.json`. After each batch, record `{recommended_action, metric_targeted, metric_before, metric_after}` for each `recovery_action` recommendation. After 5 entries, compute `prediction_accuracy_rate` and include it in the health comment. COORD must weight simulation recommendations by `prediction_accuracy_rate` (not always at 100% confidence). |
| 58.2 | `/otherness.onboard` must run a post-completion quality gate checking: (1) placeholder strings in `docs/aide/*.md`, (2) BUILD_COMMAND file existence, (3) all five required `docs/aide/` files present, (4) `otherness-config.yaml` REPO field matches actual git remote. On any failure: post "⚠️ ONBOARDING INCOMPLETE" with explicit failure list. Never report "onboarding complete" when gate checks fail. |

## Zone 2 — Implementer's judgment

- 58.1: the `simulation_accuracy` ledger does not need to be exhaustive. Track only
  `recovery_action` recommendations — these are the simulation's most consequential
  outputs. The `arch_convergence` score is an input to recommendations; the
  `prediction_accuracy_rate` measures whether those recommendations, when followed,
  produced the expected improvement. A "correct outcome" is defined as: the metric
  targeted by the recommendation improved by ≥5% in the batch following the action.
  If the recommended action was NOT taken (e.g. COORD did not claim the suggested item
  type), the ledger entry is `{skipped: true}` and does not count toward the accuracy
  rate — only acted-upon recommendations are scored.
- 58.2: the quality gate must run at the END of the onboarding agent, not as a
  separate step. The check is pure file inspection — no GitHub API calls, no network.
  Total runtime: <1 second. The gate result must be printed to stdout (visible in the
  terminal) AND posted to the report issue comment. The four checks are minimum viable;
  implementers may add checks for `otherness-config.yaml` schema completeness (all
  required keys present) but must not expand the gate to >10 checks total (keep it fast
  and readable).

## Zone 3 — Scoped out

- 58.1 does NOT redesign the simulation model itself. It adds a measurement layer on top
  of existing simulation outputs. The simulation continues to run exactly as specified in
  docs 10 and 11; the accuracy ledger simply records whether its recommendations proved
  correct in hindsight.
- 58.1 does NOT change COORD's claiming logic in this PR. The `prediction_accuracy_rate`
  must first appear in the health comment (SM §4b change) before being wired into COORD's
  claiming weight. This is a two-PR implementation: first SM writes the rate, then COORD
  reads it. The obligation in this doc covers only the SM §4b change (the ledger + rate
  computation). The COORD weighting is a dependent follow-up.
- 58.2 does NOT validate the CONTENT of `vision.md`, `roadmap.md`, etc. It only checks
  that the files exist, are non-empty, and do not contain placeholder strings. Content
  quality is the domain of docs 32.x items.
- 58.2 does NOT block the human from continuing if the gate fails. It reports and exits
  with a non-zero hint in the output, but does not prevent the human from proceeding. The
  "⚠️ ONBOARDING INCOMPLETE" label is informational, not a hard lock.
