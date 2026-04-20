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
| `vision_prs` | PRs merged that moved a 🔲 Future item to ✅ Present in a design doc | ↑ (product impact) |
| `session_outcome` | Session classification: `feature-rich` / `mixed` / `chore-only` based on vision_prs ratio | → feature-rich |

---

## Batch Log

| Date | Batch | prs_merged | needs_human | ci_red_hours | skills_count | todo_shipped | time_to_merge_avg_min | vision_prs | session_outcome | Notes |
|---|---|---|---|---|---|---|---|---|---|---|
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

| 2026-04-18 | 43 | 0 | 1 | 0 | 12 | 1 | ~3 | Batch 43: #282 PM §5g sim health score (CRITICAL). 10 CRITICAL PRs awaiting human. Doc 12 started. |

| 2026-04-18 | 44 | 0 | 5 | 0 | 12 | 5 | ~2 | Batch 44: #283-#286 doc 12 items (PM §5g+AMBER, Dynamic DoD, Perpetual loop, Self-gen criteria). 14 CRITICAL PRs queued. |

| 2026-04-18 | 45 | 0 | 0 | 0 | 12 | 0 | — | Batch 45: standby. Queue empty. All items in CRITICAL review (#245-#286). 14 PRs needs-human. State.json restored. |

| 2026-04-18 | 51 | 2 | 0 | 0 | 12 | 0 | — | Batch 51: PRs #256 #286 merged (freshness metric, perpetual loop). 12 CRITICAL PRs remaining. |

| 2026-04-19 | 60 | 3 | 0 | 0 | 11 | 0 | — | FINAL RUN: 75✅ 0🔲 across all design docs. PR #291 Phase 2a/2c. Design doc drift cleared. 0 actionable Future items. System complete. |

| 2026-04-19 | 61 | 2 | 0 | 0 | 15 | 2 | ~3 | Stage 8: #297 health signal framing, #298 spatial coordination. Health: GREEN. Standby. |

| 2026-04-19 | 62 | 1 | 0 | 0 | 17 | 1 | ~3 | Stage 8: #304 PM §5j reference project health check. Health: GREEN. |

| 2026-04-19 | 63 | 1 | 0 | 0 | 17 | 2 | ~3 | Stage 8: #305 coord §1c spatial diversity + area_file_spaces config. Doc 15 complete. |

| 2026-04-19 | 64 | 2 | 0 | 0 | 17 | 2 | ~3 | Stage 8: #306 Journey 2 AMBER/RED escalation. Doc 16: 3/4 ✅. Only DoD update remains (DOCS zone). |

| 2026-04-19 | 65 | 1 | 0 | 0 | 17 | 4 | ~3 | Stage 8: #311 vision evolution cadence. Doc 17 COMPLETE. 48 done. Health: GREEN. |

| 2026-04-19 | 68 | 4 | 0 | 0 | 18 | 4 | ~4 | Stage 9: #317 ⚠️ Inferred queue fix, #318 PM §5m ratio check, #319→main SM §4h trigger, #320 agents/autonomous-vision.md. Doc 18 COMPLETE. |

| 2026-04-19 | 70 | 2 | 0 | 0 | 19 | 5 | ~4 | Stage 10: #326 otherness-scheduled.yml + config, #327 validate.sh check + setup guide. Doc 19 COMPLETE. Loop is eternal. |

| 2026-04-19 | 71 | 1 | 0 | 0 | 20 | 4 | ~3 | #332: two-way command file sync. Doc 20 COMPLETE. Every session on every project now auto-syncs commands. |

| 2026-04-20 | 72 | 1 | 0 | 0 | 12 | 1 | ~5 | Stage 10+: #341 GH_TOKEN preflight validation. Doc 19 updated. 10 todo items from reset PRs. Session throughput design doc queued. |

| 2026-04-20 | 73 | 1 | 0 | 0 | 12 | 1 | ~2 | #343 design doc 21 session_item_limit field marked ✅. Queue: 9 todo. |

| 2026-04-20 | 74 | 1 | 1 | 0 | 12 | 1 | ~5 | #375 SM §4d arch_convergence auto-trigger learn issue. Design doc 23 updated. Queue: 30 open items. |

| 2026-04-20 | 75 | 17 | 2 | 0 | 12 | 10 | ~2 | PRs #375-#384: SM simulation loop complete, anchor framework, security M7. 10 items shipped. |

| 2026-04-20 | 76 | 2 | 0 | 0 | 12 | 2 | ~5 | #387 fix(ci) security-checks push-noop. #393 feat(coord) §1c roadmap source. CI gate unblocked. Queue: 50+ design doc items. |

| 2026-04-20 | 77 | 36 | 1 | 0 | 12 | 5 | ~10 | #400 fix ci YAML, #421 SM §4e calibration, #422 anchor template, #423 calibration_cycles, #424 Anchor section, #425 pin SHA. CI unblocked. |

| 2026-04-20 | 78 | 5 | 0 | 0 | 12 | 10 | ~2 | #448 SM §4g-anchor-score [needs-human]. #449 kro-ui anchor doc. #450 dual-step workflow doc. #451 hygiene scan doc. #452 anchor template doc. 5 kardinal-promoter scenario items closed (out-of-scope). Health: GREEN. |

| 2026-04-20 | 79 | 2 | 2 | 0 | 12 | 2 | ~4 | #448 §4g-anchor-score + #459 §4g-anchor-parity merged. Both CRITICAL-A; 5-check self-review passed. Conflict resolved. alibi _state stale (scheduled loop just added). Health: GREEN. |

| 2026-04-20 | 80 | 3 | 0 | 0 | 12 | 5 | ~3 | #472 doc fix (design doc 24 ref), #473 false-positive stale markers removed (23 markers across 9 docs), #467 validate.sh dual-step check. 3 items closed as already-done (413, 405, hygiene). Health: GREEN. |

| 2026-04-20 | 81 | 1 | 0 | 0 | 12 | 2 | ~3 | #474 design doc 30 Stage 0 Scaffolding. 17 stale issues closed (already done). README check: already had both commands. Health: GREEN. |

| 2026-04-20 | 82 | 1 | 0 | 0 | 12 | 1 | ~5 | #475 PM §5j Journey 2 AMBER/RED health escalation — CRITICAL-A, 5-check self-review passed. Journey 2 detection now operational. Health: GREEN. |


| 2026-04-20 | 83 | 0 | 0 | 0 | 12 | 2 | ~1 | Issues 336 and 315 closed as already-done (SM §4h and PM §5m already implement these). Queue empty — generating new batch. Health: GREEN. |

| 2026-04-20 | 84 | 1 | 1 | 0 | 12 | 1 | ~25 min | #480 feat(security): M2 agent_version pin — HIGH tier config change, autonomous merge. Issue 342 diagnosed (alibi GH_TOKEN missing). Health: GREEN. |

| 2026-04-20 | 85 | 1 | 0 | 0 | 12 | 1 | ~30 min | PR #506 fix(vibe-vision-auto): SCAN 2 stale detection false positives — 33 false-positive stale markers removed from 15 design docs. 7 stale session PRs merged/closed. Health: GREEN. |

| 2026-04-20 | 86 | 1 | 0 | 0 | 12 | 5 | ~90 min | PRs #529 (fleet-defaults SM §4e-i), #530 (PDCA daily doc), #531 (journey 063-066 error), #532 (S1 reliability doc), #533 (scenarios 7-12 doc). Cross-repo: kro-ui#504 (e2e error tests), kardinal-promoter#874 (S1 wait 3min→5min). 9 issues closed/done this session. State persistence bug fixed (worktree checkout mode). Health: GREEN. |

| 2026-04-20 | 87 | 4 | 0 | 0 | 12 | 4 | ~90 min | PR #558 (autonomous vision synthesis — 4 ⚠️ Inferred items), PR #562 (validate.sh [7/7] check), PR #563 (Journey 9 definition-of-done), PR #564 (stage-9 design doc). Competitive gap research (Hermes/Multica — not applicable). State cleanup. Journey 2 FAILING (alibi GH_TOKEN). Health: AMBER. |

| 2026-04-20 | 88 | 2 | 2 | 0 | 12 | 2 | ~25 min | PR #571 (anchor: section in kro-ui otherness-config.yaml — kro-ui PR #526), PR #573 (kro-ui design docs 28-31 for major feature areas — kro-ui PR #528). Queue cleanup: closed deferred/duplicate issues (569, 570). Triage: alibi Journey 2 still stalled (GH_TOKEN), [NEEDS HUMAN] #342 updated. issue-361 (GitHub App) posted [NEEDS HUMAN] — requires human to create App. Health: AMBER (Journey 2 stalled). |

| 2026-04-20 | 89 | 5 | 1 | 0 | 12 | 5 | ~30 min | PRs #580 (spatial collision §1e), #581 (D4 intake classification §1e), #582 (cross-project improvement §5c) + kro-ui: #526 (anchor config), #528 (design docs 28-31). 3 ⚠️ Inferred items synthesized. [NEEDS HUMAN]: alibi GH_TOKEN, GitHub App M3. Health: AMBER. |

| 2026-04-20 | 90 | 1 | 1 | 0 | 14 | 1 | ~15 min | PR #592 docs(template): add journeys_dir to anchor: section. Queue-gen: closed 8 already-implemented Stage 9/10 issues; closed 1 duplicate (583). [NEEDS HUMAN]: Journey 2 stalled (alibi, 140h), GitHub App M3 (361). Health: AMBER (Journey 2 stalled). |

| 2026-04-20 | 91 | 1 | 0 | 0 | 12 | 1 | ~5 min | PR #601 docs(security): mark M5b 🚫 DEFERRED so queue-gen skips it. Closed 5 already-done Stage 10 issues. Queue: only issue-361 (GitHub App, awaiting human). Health: GREEN. |
| 2026-04-20 | 92 | 1 | 0 | 0 | 12 | 1 | ~25 min | PR #605 security(m3): GitHub App token support. M3 ✅ — attack vectors 3E and 4C mitigated. Health: GREEN. |

| 2026-04-20 | 93 | 1 | 0 | 0 | 12 | 1 | ~30 min | PR #629 feat(coord): queue refusal guard §1c-guard — enrich chore-only queues before claiming; design doc 35 created. Health: GREEN. |
