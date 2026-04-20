# 31: Stage 2 — Skills Expansion

> Status: Complete | Created: 2026-04-20

---

## What this does

Grows the skills library from 4 foundational skills to ≥10 through `/otherness.learn`
sessions on high-signal open-source repos. Skills are reusable agent checklists that
improve decision quality across all projects.

---

## Present (✅)

- ✅ `/otherness.learn` command deployed — `agents/otherness.learn.md` + `.opencode/command/otherness.learn.md` (2026-04-14) ⚠️ Stale — referenced file not found
- ✅ Skills library reached ≥10: currently 12 skills in `agents/skills/` (2026-04-20)
- ✅ `PROVENANCE.md` — audit trail for each learning session: what was learned, what was rejected, why (2026-04-14) ⚠️ Stale — referenced file not found
- ✅ `agents/skills/README.md` — skill index listing all skills and when to load them (2026-04-14)
- ✅ SM §4c: autonomous learn scheduling — SM runs `/otherness.learn` when Type B rate drops; monitors skill quality (2026-04-14) ⚠️ Stale — referenced file not found
- ✅ Quality gate enforced: skills are specific, falsifiable, novel, transferable — PROVENANCE.md records rejections (2026-04-14)

## Future (🔲)

- 🔲 Autonomous `/otherness.learn` cadence enforcement with measurable trigger: SM §4c must check PROVENANCE.md date of last learn session every batch. If last entry is >14 days ago, SM queues a learn session immediately — not as a suggestion but as a `priority/high` issue claiming the next session. The monoculture risk identified in `docs/aide/vision.md §What the simulation proved` requires active countermeasures, not passive availability of the command. Target: learn session runs at least once every 14 days, measured in PROVENANCE.md. ⚠️ Inferred from self-improvement lens: /otherness.learn runs rarely, agents not meaningfully smarter than two weeks ago.
- 🔲 Architectural monoculture breakout mechanism: the simulation identified that all agents share `standalone.md` — the same reasoning framework — regardless of how diverse their skill sets are. Skill diversity ≠ conceptual diversity. The only current break is `/otherness.learn` importing foreign patterns. This must be made systematic: every learn session must explicitly target a repo from a different paradigm (functional, event-sourced, actor-model, etc.) than the last session. SM §4c must record the `paradigm_category` of each PROVENANCE.md entry and reject back-to-back sessions in the same category. This is the highest-priority investment for breaking frame-lock. ⚠️ Inferred from self-improvement lens: monoculture problem has not been addressed architecturally.
- 🔲 Learn session completion must be verified, not just queued: the current flow is "SM detects low Type B rate → opens `learn(arch):` issue → session claims it → the NEXT session runs `/otherness.learn`." This means PROVENANCE.md may show the last learn completed weeks ago even though an issue to do a new one has been open for days. SM §4c must distinguish between (a) `learn issue open, not yet worked` and (b) `PROVENANCE.md updated in last 14 days`. The cadence clock must be based on PROVENANCE.md date, not issue creation date. If PROVENANCE.md has not been updated in 14 days AND no active `feat/*` branch is attempting a learn session, SM §4c should re-open (or escalate priority of) the learn issue. This is the difference between "we scheduled learning" and "learning happened." ⚠️ Inferred from self-improvement lens: agents are not meaningfully smarter than two weeks ago; queuing a learn issue is not the same as learning.
- 🔲 Skill impact measurement — skills grow but there is no mechanism to verify they are working: every learn session adds new patterns to `agents/skills/`, but neither SM nor any other phase ever measures whether loading those skills has actually reduced `needs_human` rate, shortened `time_to_merge`, or decreased QA rejection rate over the subsequent 10 batches. Without this measurement, skill accumulation is faith-based — we assume they help but have no evidence. SM §4b must add a `skill_impact_score` metric: after each learn session, compare the 10-batch rolling average of `needs_human` and `time_to_merge_avg_min` before vs. after the session. If no improvement is detected after 10 batches, SM must open a `kind/chore` issue flagging the specific skill as "unverified impact" and suggesting either: (a) the skill is too generic to apply, (b) the agent is not loading it at the right moment, or (c) the PROVENANCE.md entry needs more specific applicability criteria. The question is not "do we have skills?" but "are the agents actually smarter?" ⚠️ Inferred from self-improvement lens: agents not measurably smarter than two weeks ago; skills grow but impact is not tracked.

---

## Zone 1 — Obligations

**O1 — Skills library has ≥10 skills at all times.**
If a skill is deprecated, a replacement must be added in the same batch.
Current count: 12.

**O2 — Every new skill has a PROVENANCE.md entry.**
The entry records: what pattern was observed, what skill was created or extended,
and what was rejected.

**O3 — Skills are generic — no project names.**
Skills must be transferable to any project. PROVENANCE.md records project-specific
rejections to keep skills portable.

---

## Zone 2 — Implementer's judgment

- Skills are grown through `/otherness.learn` sessions, not through direct file editing.
- The SM §4c cycle ensures automatic growth when needed.

---

## Zone 3 — Scoped out

- Automated skill quality scoring
- Cross-project skill effectiveness tracking
