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
