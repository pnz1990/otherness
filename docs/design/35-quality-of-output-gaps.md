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
- ✅ `SM §4f` batch report two-axis signal: report format leads with `progress: ADVANCING|STABLE|STALLED` + `health: GREEN|AMBER|RED`; ADVANCING=≥1 vision PR merged; STABLE=chores only shipped; STALLED=silent session (0 merged, 0 open); STABLE/STALLED upgrades GREEN→AMBER; exported as `SESSION_PROGRESS` env var; verbose details in `<details>` block (PR #625+#615, 2026-04-21)

- ✅ `SM §4c` / `agents/otherness.learn.md`: frame-lock break protocol — when arch_convergence >= 0.65 for 3 consecutive calibrations, SM §4c opens a `learn(arch): frame-lock` issue instructing the learn agent to choose an architecturally UNLIKE target (detected via skill category distribution from PROVENANCE.md); `otherness.learn.md §1b-arch-diverse` documents the "unlike" heuristic and category-to-search-terms mapping; flag stored as `frame_lock_detected` in state.json, cleared when convergence drops below 0.55 (PR #669, 2026-04-20)
- ✅ `agents/onboard.md` STEP 7b: post-run structural validation — after generating docs/aide/, runs inline checks equivalent to `scripts/check-onboarding.sh`; auto-fixes missing section headers, empty files, missing Stage/Journey markers; warns (does not block) on missing AGENTS.md fields or otherness-config.yaml sections; applies fixes as amended commit before PR creation (PR #TBD, 2026-04-20)
- ✅ `onboarding-existing-project.md` + `onboarding-new-project.md`: "First-run smoke test" section — 3 observable success signals (startup comment, feat/* branch, open PR); diagnosis commands for silent failure; common failure table (PR #TBD, 2026-04-20)

- ✅ `agents/onboard.md` STEP 4c: vision quality gate — after writing vision.md, checks: (1) ≥100 words, (2) named user/operator present, (3) specificity ratio < 35% generic filler words; for each failing check, agent revises inline via [AI-STEP] before proceeding to STEP 5 (PR #TBD, 2026-04-20)

- ✅ `/otherness.status` health dashboard: Step 0 added — shows 6 sections: health trend (last 5 batches), skills count + last learn date, queue depth + next item, journey status, simulation calibration + arch_convergence, reference project health; fits in ≤40 lines; graceful fallback for missing files (PR #TBD, 2026-04-20)

- ✅ `SM §4f` `docs/aide/progress.md` automated update: progress.md now includes "Last 3 batch outcomes" field from metrics.md session_outcome column; SM owns progress.md the same way it owns metrics.md — updated every batch via pull-rebase-retry push to main (PR #TBD, 2026-04-20)

## Future (🔲)

- ✅ `coord.md §1c`: track guard-firing frequency in session metrics — `chore_only_guard_count` incremented in `state.json` on every guard fire; SM §4b reads, writes `queue_guard_fires` column to `metrics.md`, resets counter; `docs/aide/metrics.md` header row and metric definitions updated (PR #638, 2026-04-21)
- ✅ SM §4b housekeeping PR filter: `prs_merged` now counts only PRs with ≥1 changed file outside `docs/aide/` — housekeeping-only PRs (e.g. metrics.md updates) are excluded from the count; filter implemented in SM §4b via `gh pr view --json files`; fail-open: API error → PR counted as real; a session where all merged PRs are housekeeping correctly reports `prs_merged=0`, triggering AMBER via the existing `VISION_PRS==0` defect path (PR #720, 2026-04-21)
- 🔲 COORD §1b must check `housekeeping_streak` and `next_session_directive` at session start as a single unified preflight: `state.json` now accumulates multiple behavioral signals that COORD must act on at startup — `housekeeping_streak`, `next_session_directive`, `frame_lock_detected`, `silent_session_count`, and `recovery_action` (from sim-prediction.json). These signals are defined across docs 21, 23, 33, 35 but there is no unified spec for how COORD reads and prioritises them. If all signals fire simultaneously (streak + directive + frame-lock), COORD has no precedence rule. COORD §1b must implement a unified startup signal reader with explicit priority order: (1) `[NEEDS HUMAN]` open → log and proceed with caution; (2) `housekeeping_streak ≥ 3` → trigger vision synthesis first, skip chore claims; (3) `recovery_action` from sim-prediction → apply as sort-key adjustment; (4) `next_session_directive` → reorder claim priority; (5) `frame_lock_detected` → prefer learn-type items. Without a precedence rule, conflicting signals produce unpredictable behavior — or some signals are silently ignored because COORD reads them in the wrong order. ⚠️ Inferred from reliability lens: multiple behavioral signals accumulate in state.json but their interactions and precedence are unspecified; COORD may silently ignore signals when multiple are active.
- 🔲 Session minimum meaningful-PR contract — the loop must guarantee ≥1 meaningful PR per session or explicitly self-diagnose: the pressure context states "A truly reliable system ships at least one meaningful PR every single run without exception." Current design detects the failure after the fact (SM opens a defect issue, health degrades to AMBER). This is post-hoc observation, not prevention. The loop needs an IN-SESSION recovery contract with explicit steps: (1) if ENG completes an item and produces zero meaningful-file changes → COORD must immediately attempt a second item from the queue before exiting (same-session second-chance, as specified in standalone.md §1f GATE); (2) if the second-chance item also produces zero meaningful changes → COORD must synthesize a new design-doc-backed item inline (vision synthesis), claim it, and attempt it; (3) only after all three levels fail is the session permitted to exit with 0 meaningful PRs — and this exit MUST post a `[DEFECT]` comment on the report issue within the same session, not left for SM to detect. The distinction from existing items: existing specs detect the failure AFTER the session exits; this spec defines the IN-SESSION recovery sequence that must run BEFORE exit. Without this contract, every "0 meaningful PRs" session is a self-detected failure that the system accepted rather than fought. The minimum bar for "reliable" is: the system tried at least 3 different recovery paths before giving up. ⚠️ Inferred from reliability lens: a truly reliable system ships at least one meaningful PR every single run without exception — the current loop detects this failure post-session but has no in-session multi-level recovery contract that must be exhausted before zero-PR exit is permitted.

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
