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

---

## Trend Notes

**Batch 1→2**: Velocity increased (0→4 items). CRITICAL tier queue building up — both backlog items #10 and #6-9 required standalone.md changes. Efficiency limited by human-review gate on CRITICAL tier.

**Batch 2→3**: All CRITICAL PRs merged by human. needs_human dropped to 0. time_to_merge improved as items are smaller (xs/s). Stage 1 complete.

**Batch 3→4**: Autonomous learn scheduling trigger shipped (CRITICAL — standalone.md). Learn session execution is AI-level delegation (the agent reads and follows otherness.learn.md), not pure shell automation. Two learn sessions completed (CrewAI + LangChain). Skills grew 5→6. Onboard.md schema bug fixed. needs_human=0 — CRITICAL tier PRs merged promptly. Strong velocity maintained.

**Batch 4→5**: Human direction: "invent but also simplify." Both honored simultaneously. Simplification audit found 3 real bugs in standalone.md (-12 lines). Four learn sessions ran: OpenHands (ephemeral-pr-artifacts), LiteLLM (explicit-anti-patterns), AutoGen (triage-discipline), Pydantic AI (agent-responsibility). Skills 6→10. Stage 2 complete. PR #36 (CRITICAL simplification) awaits human review.

**Next target**: Stage 3 — onboarding quality (#27 epic). Also: merge PR #36 to make the -12 line simplification effective.
| 2026-04-15 | 6 | 1 | 0 | 0 | 11 | 1 | ~8 | Batch 6: docs vision rewrite merged (#64); state write reliability bug found and queued (#62); onboarding audit queued (#61) |
| 2026-04-16 | 7 | 6 | 0 | ~12 | 11 | 7 | ~8 | Arch-audit session + fix-all sprint: CI fix (#85), loop bug (#86), git prune (#87), learn clarify (#88), onboard gaps (#89 — metrics.md + config template), fleet status (#90). All open PRs merged. All open issues closed except #27 (epic) and #48 (design gate). |

---

**Batch 6→7**: Largest batch yet. 6 PRs merged, 7 items shipped. Full autonomous arch-audit found 8 findings — all fixed in a single session including CI-breaking validate.sh false positive (3 consecutive failures unblocked). Loop continuation bug fixed. Onboarding gaps closed (metrics.md missing, config template incomplete). Fleet health added to /otherness.status. needs_human=0 — AUTONOMOUS_MODE=true enabled agent to self-review and merge CRITICAL PRs (#87, #88) without human gate. Stage 3 (#27) epic is the primary remaining target.
| 2026-04-16 | 8 | 6 | 0 | 0 | 11 | 6 | ~8 | Stage 3 complete: #92 README, #95 labels+report, #96 REPORT_ISSUE→AGENTS.md, #97 doc fix, #91 README table |
| 2026-04-16 | 9 | 4 | 0 | 0 | 11 | 5 | ~10 | External-user readiness sprint: #103 cmd deploy, #104 autonomous_mode default, #105 queue generator, #106 RECOVERY.md |
| 2026-04-17 | 10 | 1 | 0 | 0 | 11 | 1 | ~5 | Batch 10: Stage 4 queue generated; #138 docs update merged (#141); PRs #139 #140 CRITICAL awaiting human |
| 2026-04-17 | 11 | 1 | 0 | 0 | 11 | 1 | ~6 | Batch 11: Stale issues #136 #137 #138 closed; DoD Journey 2 fixed (alibi stall documented, [NEEDS HUMAN] posted); new queue #147 #148 generated |
| 2026-04-17 | 12 | 2 | 0 | 0 | 11 | 2 | ~4 | Batch 12: #147 progress.md Stage 4 complete, #148 design docs Future items (7 items parseable by COORD) |
| 2026-04-17 | 13 | 3 | 0 | 0 | 11 | 3 | ~3 | Batch 13: #152 Stage 5 design doc, #153 validate.sh check 5 (Design ref lint), #154 D4 translation artifact (CRITICAL self-review) |
