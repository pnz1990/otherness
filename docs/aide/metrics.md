# otherness Self-Improvement Metrics

> Updated by the SM phase every batch. One row per batch appended at the bottom.
> Metrics measure whether otherness is improving itself — not the projects it manages.

---

## Metric Definitions

| Metric | What it measures | Target direction |
|---|---|---|
| `prs_merged` | PRs merged to otherness main in this batch | ↑ (throughput) |
| `needs_human` | [NEEDS HUMAN] issues opened this batch | ↓ (autonomy) |
| `ci_red_hours` | Hours main CI was red this batch | ↓ (stability) |
| `skills_count` | Total skill files in agents/skills/ (excl. PROVENANCE, README) | ↑ (knowledge) |
| `todo_shipped` | Backlog items moved to done this batch | ↑ (velocity) |
| `time_to_merge_avg_min` | Average minutes from PR open to merge (excl. CRITICAL tier wait) | ↓ (efficiency) |

---

## Batch Log

| Date | Batch | prs_merged | needs_human | ci_red_hours | skills_count | todo_shipped | time_to_merge_avg_min | Notes |
|---|---|---|---|---|---|---|---|---|
| 2026-04-14 | 1 | 1 | 1 | ~0.5 | 4 | 0 | — | Bootstrap: CI fix PR; CRITICAL tier PRs awaiting review |
| 2026-04-14 | 2 | 4 | 2 | 0 | 5 | 4 | ~12 | Shipped #11 #12 #14 #15; CRITICAL #13 #16 pending human |
| 2026-04-14 | 3 | 5 | 0 | 0 | 5 | 6 | ~8 | Merged all CRITICAL PRs; shipped #17 #18; Stage 1 complete |
| 2026-04-14 | 4 | 4 | 0 | 0 | 6 | 3 | ~10 | Shipped #25 #29 #31; autonomous learn scheduling live; 6 skills |
| 2026-04-14 | 5 | 4 | 1 | 0 | 10 | 3 | ~7 | Simplify pass (-12 lines, 3 bugs fixed PR#36 CRITICAL); 4 learn sessions; Stage 2 complete |
| 2026-04-15 | 6 | 1 | 0 | 0 | 11 | 1 | ~8 | Batch 6: docs vision rewrite merged (#64); state write reliability bug found and queued (#62); onboarding audit queued (#61) |
| 2026-04-16 | 7 | 6 | 0 | ~12 | 11 | 7 | ~8 | Arch-audit session + fix-all sprint: CI fix (#85), loop bug (#86), git prune (#87), learn clarify (#88), onboard gaps (#89 — metrics.md + config template), fleet status (#90). All open PRs merged. All open issues closed except #27 (epic) and #48 (design gate). |
| 2026-04-16 | 8 | 6 | 0 | 0 | 11 | 6 | ~8 | Stage 3 complete: #92 README, #95 labels+report, #96 REPORT_ISSUE→AGENTS.md, #97 doc fix, #91 README table |
| 2026-04-16 | 9 | 4 | 0 | 0 | 11 | 5 | ~10 | External-user readiness sprint: #103 cmd deploy, #104 autonomous_mode default, #105 queue generator, #106 RECOVERY.md |
| 2026-04-17 | 10 | 1 | 0 | 0 | 11 | 1 | ~5 | Batch 10: Stage 4 queue generated; #138 docs update merged (#141); PRs #139 #140 CRITICAL awaiting human |
| 2026-04-17 | 11 | 1 | 0 | 0 | 11 | 1 | ~6 | Batch 11: Stale issues #136 #137 #138 closed; DoD Journey 2 fixed (alibi stall documented, [NEEDS HUMAN] posted); new queue #147 #148 generated |
| 2026-04-17 | 12 | 2 | 0 | 0 | 11 | 2 | ~4 | Batch 12: #147 progress.md Stage 4 complete, #148 design docs Future items (7 items parseable by COORD) |
| 2026-04-17 | 13 | 3 | 0 | 0 | 11 | 3 | ~3 | Batch 13: #152 Stage 5 design doc, #153 validate.sh check 5 (Design ref lint), #154 D4 translation artifact (CRITICAL self-review) |
| 2026-04-17 | 14 | 2 | 0 | 0 | 11 | 2 | ~4 | Batch 14: #158 Stage 5 guard, #159 QA customer doc MISS check (both CRITICAL tier self-review) |
| 2026-04-17 | 15 | 2 | 0 | 0 | 11 | 2 | ~5 | Batch 15: #162 is_done filter fix (CRITICAL, self-review found WRONG/fixed), #163 onboard design doc stubs — DDDD doc now 0 Future items |
| 2026-04-17 | 16 | 2 | 0 | 0 | 11 | 2 | ~4 | Batch 16: #166 progress.md, #167 D4 for issue comments (CRITICAL) — D4 doc 1 deferred item |
| 2026-04-17 | 17 | 2 | 0 | 0 | 12 | 2 | ~4 | Batch 17: #170 difficulty-ledger + SM trigger, #171 cross-project mining (self-review fixed WRONG) |
| 2026-04-17 | 18 | 2 | 0 | 0 | 12 | 2 | ~3 | Batch 18: #174 skills README, #175 PM cross-project proposals (CRITICAL self-review) |
| 2026-04-17 | 19 | 2 | 0 | 0 | 12 | 2 | ~3 | Batch 19: #178 fix test.sh __file__ bug (integration check works), #179 skill confidence (CRITICAL) |
| 2026-04-17 | 20 | 2 | 0 | 0 | 12 | 2 | ~3 | Batch 20: #182 validate.sh counter fix, #183 metrics trend notes batches 6-19 |
| 2026-04-17 | 21 | 2 | 0 | 0 | 12 | 2 | ~3 | Batch 21: PROVENANCE 6 patterns, future-ideas 4 done — 31 total |
| 2026-04-17 | 22 | 1 | 0 | 0 | 12 | 1 | ~3 | Batch 22: #190 progress.md batch 22 + Ideas 1&2 covered — 6/9 future ideas done |
| 2026-04-17 | 23 | 1 | 0 | 0 | 12 | 1 | ~3 | Batch 23: #192 metrics.md restructure (all 22 rows in sequential order) |
| 2026-04-17 | 24 | 1 | 0 | 0 | 12 | 1 | ~2 | Batch 24: #194 future-ideas.md implementation order updated (6/9 done) |
| 2026-04-17 | 25 | 1 | 0 | 0 | 12 | 1 | ~2 | Batch 25: #196 D4 speculative item removed from COORD queue — 0 non-deferred Future items |


| 2026-04-17 | 26 | 6 | 0 | 0 | 12 | 6 | ~4 | Batch 26: arch-audit fixes #210 #211 #212 #213 #206 + design docs 04 D4 intake |

| 2026-04-17 | 27 | 20 | 0 | 0 | 12 | 5 | ~3 | Batch 27: D4 enforcement Layer 0+2, simulate.py, deprecated marker, README taxonomy |

| 2026-04-18 | 28 | 7 | 0 | 0 | 12 | 4 | ~3 | Batch 28: sim improvements #230 #231 #232 + vision.md empirical grounding |

| 2026-04-18 | 29 | 2 | 0 | 0 | 12 | 2 | ~3 | Batch 29: calibrate.py + SM §4d — Stage 6 Phase 1 operational |

| 2026-04-18 | 30 | 0 | 1 | 0 | 12 | 1 | ~3 | Batch 30: #245 D4 at issue intake (coord §1e) — CRITICAL tier, needs-human, awaiting human review |

| 2026-04-18 | 31 | 0 | 1 | 0 | 12 | 1 | ~3 | Batch 31: #246 PM §5f doc health scan (CRITICAL tier, needs-human, awaiting human review) |
---

## Trend Notes

**Batch 1→2**: Velocity increased (0→4 items). CRITICAL tier queue building up — both backlog items #10 and #6-9 required standalone.md changes. Efficiency limited by human-review gate on CRITICAL tier.

**Batch 2→3**: All CRITICAL PRs merged by human. needs_human dropped to 0. time_to_merge improved as items are smaller (xs/s). Stage 1 complete.

**Batch 3→4**: Autonomous learn scheduling trigger shipped (CRITICAL — standalone.md). Learn session execution is AI-level delegation (the agent reads and follows otherness.learn.md), not pure shell automation. Two learn sessions completed (CrewAI + LangChain). Skills grew 5→6. Onboard.md schema bug fixed. needs_human=0 — CRITICAL tier PRs merged promptly. Strong velocity maintained.

**Batch 4→5**: Human direction: "invent but also simplify." Both honored simultaneously. Simplification audit found 3 real bugs in standalone.md (-12 lines). Four learn sessions ran: OpenHands (ephemeral-pr-artifacts), LiteLLM (explicit-anti-patterns), AutoGen (triage-discipline), Pydantic AI (agent-responsibility). Skills 6→10. Stage 2 complete. PR #36 (CRITICAL simplification) awaits human review.

**Batch 5→6**: Stage 3 started. Docs vision rewrite. State write reliability bug queued. Onboarding audit queued.

**Batch 6→7**: Largest batch yet. 6 PRs merged, 7 items shipped. Full autonomous arch-audit found 8 findings — all fixed in a single session including CI-breaking validate.sh false positive (3 consecutive failures unblocked). Loop continuation bug fixed. Onboarding gaps closed (metrics.md missing, config template incomplete). Fleet health added to /otherness.status. needs_human=0 — AUTONOMOUS_MODE=true enabled agent to self-review and merge CRITICAL PRs (#87, #88) without human gate.

**Batch 7→9**: Stage 3 complete. README, labels, report issue, config template, RECOVERY.md all shipped. External-user readiness sprint completed. Project now usable by external users without manual setup.

**Batch 9→10**: Stage 4 metrics deliverables queued. PRs #139 #140 for regression detection await human review (CRITICAL tier).

**Batch 10→12**: Design-driven development system (DDDD) built. Design docs created with Present/Future markers. COORD queue now reads design docs as primary source (not just roadmap). validate.sh gained 5th check for Design reference in specs.

**Batch 12→15**: DDDD design system fully shipped — all 9 obligations complete. Stage 5 design doc and guard added. D4 translation improvements: artifact persistence, GitHub issue comment interception. is_done filter bug found and fixed. onboard.md Step 4b generates design doc stubs.

**Batch 15→19**: Learning infrastructure expanded: difficulty-ledger.md (hard case tracking), SM cross-project mining, PM cross-project improvement proposals, skill confidence checking. Bug fixes: test.sh __file__ bug (integration check was always skipped), validate.sh step counters. skills 11→12.

**Batch 19→22**: Documentation quality pass. PROVENANCE updated (6 patterns). future-ideas.md updated (6/9 ideas done). metrics.md restructured (rows in sequential order). validate.sh, test.sh both clean.

**Overall session (batches 11-22)**: 27 items shipped. 0 needs_human. All CRITICAL tier PRs passed autonomous self-review (multiple WRONG findings caught and fixed). Journey 2 (alibi) ❌ Failing throughout — awaiting human restart. Journey 1 fully operational.

**Next target**: Idea 4 (internal portfolio learn) triggers at sm_cycle_count=30 (currently 13). Journey 2 fix requires human to restart otherness on alibi.

| 2026-04-18 | 32 | 1 | 0 | 0 | 12 | 1 | ~3 | Batch 32: #247 /otherness.vibe-vision validate+wire (Journey 6, design doc 05 complete) |

| 2026-04-18 | 33 | 1 | 0 | 0 | 12 | 1 | ~3 | Batch 33: #249 scripts/guard-ci.sh + CI step — Layer 3 D4 enforcement complete |

| 2026-04-18 | 34 | 0 | 1 | 0 | 12 | 1 | ~3 | Batch 34: #255 coord §1c design ref template (CRITICAL, needs-human). Queue: 3 todo items generated. |

| 2026-04-18 | 35 | 0 | 1 | 0 | 12 | 1 | ~3 | Batch 35: #256 PM §5f doc health scan + freshness metric (CRITICAL, needs-human) |

| 2026-04-18 | 36 | 0 | 1 | 0 | 12 | 1 | ~3 | Batch 36: #257 PM §5g README/AGENTS.md claims cross-check (CRITICAL, needs-human). Queue empty. |

| 2026-04-18 | 37 | 0 | 1 | 0 | 12 | 1 | ~3 | Batch 37: #263 SM §4g codebase hygiene scan (CRITICAL). 2 stale queue items closed. 6 CRITICAL PRs queued. |

| 2026-04-18 | 38 | 2 | 0 | 0 | 12 | 2 | ~2 | Batch 38: #264 doc 06 drift fix, #265 Layer 1 D4 + config template. Queue empty. |

| 2026-04-18 | 39 | 1 | 0 | 0 | 12 | 0 | ~2 | Batch 39: #266 doc 10+11 drift cleanup (sim items marked shipped). Queue empty — generating new queue. |

| 2026-04-18 | 40 | 3 | 0 | 0 | 12 | 2 | ~2 | Batch 40: #272 vibe-vision hard rule, #273 onboard mode. Design doc 07 complete — all D4 layers shipped. |

| 2026-04-18 | 41 | 0 | 1 | 0 | 12 | 1 | ~3 | Batch 41: #274 SM §4d-learn auto-learn trigger (CRITICAL). 7 CRITICAL PRs awaiting human. |

| 2026-04-18 | 42 | 0 | 2 | 0 | 12 | 2 | ~3 | Batch 42: #275 Phase 2a per-project cal, #276 Phase 2c sim-results. Design doc 11 complete. 9 CRITICAL queued. |
