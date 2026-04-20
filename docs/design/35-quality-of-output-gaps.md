# 35: Quality of Output Gaps — Ensuring Sessions Ship Meaningful Work

> Status: Active | Created: 2026-04-20
> Applies to: all projects using otherness

---

## The problem

An autonomous session that processes only `kind/chore` or `kind/docs` items ships
no user-visible improvements. The queue can drift toward chore-only composition when:

- Design doc `🔲 Future` items are exhausted mid-session
- PM/SM-derived hygiene items accumulate faster than vision items are written
- A session inherits a queue that was already chore-heavy

A session that starts on a chore-only queue is executing in low-value mode. The
agent should recognize this and inject vision-derived items before claiming work.

---

## The queue refusal guard

**Trigger condition**: when all `state=todo` items in the queue have labels in
`{kind/chore, kind/docs}` — and none have `kind/enhancement` or `kind/bug` —
the session must enrich the queue before claiming the next item.

**Enrichment sequence** (from `docs/design/22-queue-richness.md`):
1. Re-scan `docs/design/` for unclaimed `🔲 Future` items
2. If none: pull from earliest incomplete roadmap stage
3. If none: trigger autonomous vision synthesis inline
4. If none after synthesis: log warning, allow chore claim to avoid stalling

The guard fires at `coord.md §1c` (queue generation), not at `§1e` (item claim).
This keeps the claim logic clean and ensures enrichment happens before the session
commits to a specific item.

---

## Present (✅)

- ✅ `coord.md §1c`: queue refusal guard — when all todo items are `kind/chore` or `kind/docs`, trigger enrichment before claiming; enrichment follows design doc → roadmap → vision sequence; posts report comment when triggered (PR #629, 2026-04-20)
- ✅ `SM §4b`: session outcome classification — classify sessions as `feature-rich` / `mixed` / `chore-only` based on vision_prs ratio; write `vision_prs` and `session_outcome` columns to metrics.md; `session_outcome=chore-only` triggers AMBER health signal in §4f (PR #655, 2026-04-20)
- ✅ `SM §4f`: silent-session detection — when session ends with 0 merged PRs AND 0 open PRs, increment `silent_session_count` in state.json; when streak ≥ 2 consecutive sessions, open `[NEEDS HUMAN: silent-session-streak]` issue with diagnosis guide; resets to 0 when any PR ships (PR #657, 2026-04-20)
- ✅ `docs/aide/metrics.md` schema: added `arch_convergence` and `sim_floor_delta` columns to batch log — tells the human whether the simulation is tracking reality; SM §4b [AI-STEP] updated to include these values (from sim-params.json) in new rows (PR #659, 2026-04-20)
- ✅ `SM §4c`: skill decay tracking — every 10 SM cycles, check each skill file age (via git log) against PROVENANCE.md mentions in last 90 days; if skill not mentioned in 90 days, flag as stale; posts informational report to report issue; does NOT auto-delete skills (PR #TBD, 2026-04-20)
- ✅ `SM §4f` batch report condensed format: report issue comment fits in ≤8 lines; structured terse format `Batch N | Health: X | Progress: X | Vision PRs: N | Chores: N | Queue: N remaining | Journeys: N✅ N❌ | Next: [title]`; verbose details in `<details>` block; Progress classifies as ADVANCING/STEADY/STALLED; Chores = MERGED − VISION_PRS; Next = first todo item title (PR #625, 2026-04-20)

- ✅ `SM §4c` / `agents/otherness.learn.md`: frame-lock break protocol — when arch_convergence >= 0.65 for 3 consecutive calibrations, SM §4c opens a `learn(arch): frame-lock` issue instructing the learn agent to choose an architecturally UNLIKE target (detected via skill category distribution from PROVENANCE.md); `otherness.learn.md §1b-arch-diverse` documents the "unlike" heuristic and category-to-search-terms mapping; flag stored as `frame_lock_detected` in state.json, cleared when convergence drops below 0.55 (PR #669, 2026-04-20)
- ✅ `agents/onboard.md` STEP 7b: post-run structural validation — after generating docs/aide/, runs inline checks equivalent to `scripts/check-onboarding.sh`; auto-fixes missing section headers, empty files, missing Stage/Journey markers; warns (does not block) on missing AGENTS.md fields or otherness-config.yaml sections; applies fixes as amended commit before PR creation (PR #TBD, 2026-04-20)
- ✅ `onboarding-existing-project.md` + `onboarding-new-project.md`: "First-run smoke test" section — 3 observable success signals (startup comment, feat/* branch, open PR); diagnosis commands for silent failure; common failure table (PR #TBD, 2026-04-20)

- ✅ `agents/onboard.md` STEP 4c: vision quality gate — after writing vision.md, checks: (1) ≥100 words, (2) named user/operator present, (3) specificity ratio < 35% generic filler words; for each failing check, agent revises inline via [AI-STEP] before proceeding to STEP 5 (PR #TBD, 2026-04-20)

- ✅ `/otherness.status` health dashboard: Step 0 added — shows 6 sections: health trend (last 5 batches), skills count + last learn date, queue depth + next item, journey status, simulation calibration + arch_convergence, reference project health; fits in ≤40 lines; graceful fallback for missing files (PR #TBD, 2026-04-20)

- ✅ `SM §4f` `docs/aide/progress.md` automated update: progress.md now includes "Last 3 batch outcomes" field from metrics.md session_outcome column; SM owns progress.md the same way it owns metrics.md — updated every batch via pull-rebase-retry push to main (PR #TBD, 2026-04-20)

## Future (🔲)

- 🔲 `coord.md §1c`: track guard-firing frequency in session metrics (metrics.md schema — see docs/design/33-stage-4-self-improvement-metrics.md)

---

## Zone 1 — Obligations

**O1 — Guard fires on chore-only queues, never on mixed queues.**
If ≥1 `kind/enhancement` or `kind/bug` item exists in the queue, no guard action
is taken. The guard is a quality floor, not a priority gate.

**O2 — Guard does not block sessions.**
If enrichment produces no new items, the guard logs and allows claiming the next
chore item. An indefinitely stalled session is worse than a chore-only session.

**O3 — Guard-triggered enrichment posts a comment on the report issue.**
The operator must be able to observe that the guard fired and what was injected.

---

## Zone 2 — Implementer's judgment

- Whether to re-use the existing `§1c` queue-gen Python block or add a separate
  guard check: preference is a separate, clearly-labeled guard block for readability.
- How to detect chore-only: check `labels` array in state.json features; items
  without labels are treated as `kind/enhancement` (unknown = not chore).

---

## Zone 3 — Scoped out

- Changing chore item priority relative to feature items (handled in §1e sort key)
- Auto-labeling issues that lack labels — separate hygiene concern
- Cross-session queue contamination analysis
