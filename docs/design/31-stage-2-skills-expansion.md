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

- ✅ Autonomous `/otherness.learn` cadence enforcement: SM §4c now checks `PROVENANCE.md` last entry date every batch; if >14 days AND no open learn issue AND no active learn branch: opens a `priority/high` learn issue; cadence clock is based on PROVENANCE.md date (proof of completion), not issue creation date (PR #TBD, 2026-04-20)
- 🔲 Architectural monoculture breakout mechanism: the simulation identified that all agents share `standalone.md` — the same reasoning framework — regardless of how diverse their skill sets are. Skill diversity ≠ conceptual diversity. The only current break is `/otherness.learn` importing foreign patterns. This must be made systematic: every learn session must explicitly target a repo from a different paradigm (functional, event-sourced, actor-model, etc.) than the last session. SM §4c must record the `paradigm_category` of each PROVENANCE.md entry and reject back-to-back sessions in the same category. This is the highest-priority investment for breaking frame-lock. ⚠️ Inferred from self-improvement lens: monoculture problem has not been addressed architecturally.
- 🔲 Learn session completion must be verified, not just queued: the current flow is "SM detects low Type B rate → opens `learn(arch):` issue → session claims it → the NEXT session runs `/otherness.learn`." This means PROVENANCE.md may show the last learn completed weeks ago even though an issue to do a new one has been open for days. SM §4c must distinguish between (a) `learn issue open, not yet worked` and (b) `PROVENANCE.md updated in last 14 days`. The cadence clock must be based on PROVENANCE.md date, not issue creation date. If PROVENANCE.md has not been updated in 14 days AND no active `feat/*` branch is attempting a learn session, SM §4c should re-open (or escalate priority of) the learn issue. This is the difference between "we scheduled learning" and "learning happened." ⚠️ Inferred from self-improvement lens: agents are not meaningfully smarter than two weeks ago; queuing a learn issue is not the same as learning.
- 🔲 Skill impact measurement — skills grow but there is no mechanism to verify they are working: every learn session adds new patterns to `agents/skills/`, but neither SM nor any other phase ever measures whether loading those skills has actually reduced `needs_human` rate, shortened `time_to_merge`, or decreased QA rejection rate over the subsequent 10 batches. Without this measurement, skill accumulation is faith-based — we assume they help but have no evidence. SM §4b must add a `skill_impact_score` metric: after each learn session, compare the 10-batch rolling average of `needs_human` and `time_to_merge_avg_min` before vs. after the session. If no improvement is detected after 10 batches, SM must open a `kind/chore` issue flagging the specific skill as "unverified impact" and suggesting either: (a) the skill is too generic to apply, (b) the agent is not loading it at the right moment, or (c) the PROVENANCE.md entry needs more specific applicability criteria. The question is not "do we have skills?" but "are the agents actually smarter?" ⚠️ Inferred from self-improvement lens: agents not measurably smarter than two weeks ago; skills grow but impact is not tracked.
- 🔲 Frame-lock break protocol as a scheduled mechanism, not a human-triggered event: the current pattern for frame-lock is: simulation detects arch_convergence > 0.7 → opens `[NEEDS HUMAN]` issue → human runs `/otherness.learn`. The human is the executor. But the point of frame-lock detection is to break the loop autonomously. SM §4c must implement an auto-escalation path: if arch_convergence > 0.7 AND the last autonomous learn session is >14 days ago AND no human has responded to the `[NEEDS HUMAN]` issue in >48 hours: SM §4c automatically triggers a learn session (same as the normal learn trigger, but with `paradigm_diversity_required: true` flag). The human issue stays open as a notification. This converts frame-lock from "human must notice and act" to "system detects and heals, human informed." ⚠️ Inferred from self-improvement lens: monoculture break currently requires human initiation; the system cannot break its own frame-lock without human intervention.
- 🔲 Phase-role cognitive diversity — COORD, ENG, QA, SM must each frame problems from a genuinely different perspective: all four phases run through `standalone.md` and therefore share the same reasoning framework. When COORD generates work, ENG implements it, and QA reviews it, all three use the same frame — so QA cannot truly challenge what ENG built because they start from the same mental model. This is a deeper problem than skill monoculture: it is structural. Each phase must be given an explicit cognitive stance that is designed to conflict with the others. COORD: optimistic incrementalist (what can be shipped quickly?). ENG: pragmatic builder (what is the minimal change that is correct?). QA: adversarial skeptic (what assumption is wrong here?). SM: historian (what pattern do we keep repeating?). These stances should be injected as phase-header preambles in each `phases/*.md` file. A QA phase that has been explicitly told "your job is to find the assumption this PR got wrong" will reject PRs that a same-framed QA would approve. ⚠️ Inferred from self-improvement lens: monoculture — all phases share the same reasoning framework; the QA adversarial review is nominal because QA is not structurally opposed to ENG.
- 🔲 Skill load verification: ENG must confirm which skills were loaded before implementation — skills accumulate in `agents/skills/` but there is no mechanism verifying the ENG phase actually loaded the relevant one before starting work. A skill that exists but is never loaded has zero impact. ENG `§2c` must: (a) list the skill files checked at session start, (b) select the most applicable skill file for the current item type, (c) log "Loaded skill: `<filename>`" in the PR description. SM §4b must check that the last 5 ENG PRs each include a "Loaded skill" line — if fewer than 3 of 5 do, SM opens a `kind/chore` issue: "Skill loading discipline has drifted — ENG is not citing skill files." Without this check, skill accumulation is fiction. ⚠️ Inferred from self-improvement lens: skills grow but agents may not be loading them; no verification loop confirms skills are applied.
- 🔲 `/otherness.learn` triggerable by COORD mid-session without waiting for SM detection: the current learn trigger path is: SM §4c detects stale PROVENANCE.md → opens learn issue → next session claims it → next-next session runs the learn. Two session delays before learning happens. When COORD §1b detects at session start that PROVENANCE.md is >14 days stale AND no open learn issue exists AND no active learn branch exists: COORD must immediately create the learn issue and claim it in the same session — the current session becomes a learn session. The human never needed to initiate it. The SM detection path should remain as a fallback for when COORD misses the condition, but COORD acting first collapses two session delays to zero. ⚠️ Inferred from self-improvement lens: /otherness.learn runs rarely because it waits for SM to detect the condition, which waits for COORD to observe the issue, which waits for a session to claim it — three separate sessions before learning occurs.
- 🔲 Paradigm diversity enforcement must be observable in PROVENANCE.md: `SM §4c` is specified to record `paradigm_category` of each PROVENANCE.md entry and reject back-to-back sessions in the same category — but PROVENANCE.md entries currently contain no `paradigm_category` field. The spec is defined but the artifact does not conform to it. Two changes required: (1) `agents/otherness.learn.md` must add a PROVENANCE.md entry format requirement: each entry must include a `paradigm_category:` field (one of: `functional`, `event-sourced`, `actor-model`, `imperative-oop`, `declarative-config`, `reactive`, `domain-driven`, `protocol-oriented`); (2) SM §4c paradigm-diversity check must parse this field from the last 3 PROVENANCE.md entries and refuse to open a learn issue targeting the same category as the most recent. Without the field in PROVENANCE.md, SM §4c cannot implement the diversity check regardless of how the instruction is written — it is a spec without an artifact. The monoculture breakout mechanism cannot work until PROVENANCE.md carries the paradigm metadata SM needs to enforce diversity. ⚠️ Inferred from self-improvement lens: the monoculture problem has not been addressed; the paradigm_category tracking mechanism is specified but the PROVENANCE.md format does not include the required field, making the diversity enforcement unimplementable in practice.

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
