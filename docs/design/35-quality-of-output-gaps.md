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
- ✅ `SM §4c`: skill decay tracking — every 10 SM cycles, check each skill file age (via git log) against PROVENANCE.md mentions in last 90 days; if skill not mentioned in 90 days, flag as stale; posts informational report to report issue; does NOT auto-delete skills (PR #660, 2026-04-20)
- ✅ `SM §4f` batch report two-axis signal: report format leads with `progress: ADVANCING|STABLE|STALLED` + `health: GREEN|AMBER|RED`; ADVANCING=≥1 vision PR merged; STABLE=chores only shipped; STALLED=silent session (0 merged, 0 open); STABLE/STALLED upgrades GREEN→AMBER; exported as `SESSION_PROGRESS` env var; verbose details in `<details>` block (PR #625+#615, 2026-04-21)

- ✅ `SM §4c` / `agents/otherness.learn.md`: frame-lock break protocol — when arch_convergence >= 0.65 for 3 consecutive calibrations, SM §4c opens a `learn(arch): frame-lock` issue instructing the learn agent to choose an architecturally UNLIKE target (detected via skill category distribution from PROVENANCE.md); `otherness.learn.md §1b-arch-diverse` documents the "unlike" heuristic and category-to-search-terms mapping; flag stored as `frame_lock_detected` in state.json, cleared when convergence drops below 0.55 (PR #669, 2026-04-20)
- ✅ `agents/onboard.md` STEP 7b: post-run structural validation — after generating docs/aide/, runs inline checks equivalent to `scripts/check-onboarding.sh`; auto-fixes missing section headers, empty files, missing Stage/Journey markers; warns (does not block) on missing AGENTS.md fields or otherness-config.yaml sections; applies fixes as amended commit before PR creation (PR #670, 2026-04-20)
- ✅ `onboarding-existing-project.md` + `onboarding-new-project.md`: "First-run smoke test" section — 3 observable success signals (startup comment, feat/* branch, open PR); diagnosis commands for silent failure; common failure table (PR #671, 2026-04-20)

- ✅ `agents/onboard.md` STEP 4c: vision quality gate — after writing vision.md, checks: (1) ≥100 words, (2) named user/operator present, (3) specificity ratio < 35% generic filler words; for each failing check, agent revises inline via [AI-STEP] before proceeding to STEP 5 (PR #672, 2026-04-20)

- ✅ `/otherness.status` health dashboard: Step 0 added — shows 6 sections: health trend (last 5 batches), skills count + last learn date, queue depth + next item, journey status, simulation calibration + arch_convergence, reference project health; fits in ≤40 lines; graceful fallback for missing files (PR #673, 2026-04-20)

- ✅ `SM §4f` `docs/aide/progress.md` automated update: progress.md now includes "Last 3 batch outcomes" field from metrics.md session_outcome column; SM owns progress.md the same way it owns metrics.md — updated every batch via pull-rebase-retry push to main (PR #651, 2026-04-20)

- ✅ `SM §4e-iii` / `PM §5g`: simulation-behavior coupling gate — verifies that arch_convergence AMBER (≥0.7) signals triggered a learn session and that a completed learn session decreased arch_convergence in the next calibration; posts `[⚠️ Simulation loop unclosed]` on REPORT_ISSUE if the feedback chain never closed; informational only, does not block work (PR #668, 2026-04-21)

## Future (🔲)

- ✅ `coord.md §1c`: track guard-firing frequency in session metrics — `chore_only_guard_count` incremented in `state.json` on every guard fire; SM §4b reads, writes `queue_guard_fires` column to `metrics.md`, resets counter; `docs/aide/metrics.md` header row and metric definitions updated (PR #638, 2026-04-21)
- ✅ SM §4b housekeeping PR filter: `prs_merged` now counts only PRs with ≥1 changed file outside `docs/aide/` — housekeeping-only PRs (e.g. metrics.md updates) are excluded from the count; filter implemented in SM §4b via `gh pr view --json files`; fail-open: API error → PR counted as real; a session where all merged PRs are housekeeping correctly reports `prs_merged=0`, triggering AMBER via the existing `VISION_PRS==0` defect path (PR #720, 2026-04-21)
- ✅ COORD §1b unified startup signal reader: a new `§1b-preflight` block reads `housekeeping_streak`, `next_session_directive`, `frame_lock_detected`, `silent_session_count`, and open `needs-human` count at session start; applies them in explicit priority order (needs_human > streak≥3 > directive > frame_lock > none); sets `COORD_ACTION` env var; §1c consumes `COORD_ACTION=vision-first` to run vibe-vision-auto before queue-gen when streak≥3; consolidated log line per session shows all signal values and resolved action; graceful fallback: missing/malformed state.json → action=none, session continues normally (PR #757, 2026-04-21)
- 🔲 Session type must be declared at session START, not classified post-session: SM §4b currently classifies a session as `feature-rich`, `mixed`, or `chore-only` AFTER the session completes — when it reads the merged PR list. This means the classification is a post-mortem, not a gate. A session that decides at T+0 it will claim chore items produces a predictably chore-only outcome; no mechanism fires to redirect it. COORD §1a must declare the session type at session start: before claiming any item, it must inspect the top 3 items in the queue and write `session_type_declared: feature-rich|mixed|chore-only` to `state.json`. If `session_type_declared=chore-only`: COORD must trigger the queue enrichment guard (§1c) BEFORE claiming the first item, not after it is already committed. The declared type at start is the gate; the SM-classified type at end is the accountability signal. Without the start-time declaration, the enrichment guard only fires if the queue is ALL chores — but a session that claims one chore first is now "mixed" (one chore in progress) and the guard never fires. A session that intentionally circumvents the guard by front-running a chore claim must be blocked. ⚠️ Inferred from reliability lens: a truly reliable system ships at least one meaningful PR every single run without exception — the current guard fires on queue state, not on session intent; a session that front-runs a chore claim before the guard checks can declare itself "mixed" and bypass enrichment.
- 🔲 Session minimum meaningful-PR contract — the loop must guarantee ≥1 meaningful PR per session or explicitly self-diagnose: the pressure context states "A truly reliable system ships at least one meaningful PR every single run without exception." Current design detects the failure after the fact (SM opens a defect issue, health degrades to AMBER). This is post-hoc observation, not prevention. The loop needs an IN-SESSION recovery contract with explicit steps: (1) if ENG completes an item and produces zero meaningful-file changes → COORD must immediately attempt a second item from the queue before exiting (same-session second-chance, as specified in standalone.md §1f GATE); (2) if the second-chance item also produces zero meaningful changes → COORD must synthesize a new design-doc-backed item inline (vision synthesis), claim it, and attempt it; (3) only after all three levels fail is the session permitted to exit with 0 meaningful PRs — and this exit MUST post a `[DEFECT]` comment on the report issue within the same session, not left for SM to detect. The distinction from existing items: existing specs detect the failure AFTER the session exits; this spec defines the IN-SESSION recovery sequence that must run BEFORE exit. Without this contract, every "0 meaningful PRs" session is a self-detected failure that the system accepted rather than fought. The minimum bar for "reliable" is: the system tried at least 3 different recovery paths before giving up. ⚠️ Inferred from reliability lens: a truly reliable system ships at least one meaningful PR every single run without exception — the current loop detects this failure post-session but has no in-session multi-level recovery contract that must be exhausted before zero-PR exit is permitted.
- 🔲 Meaningful-PR rate must be the primary throughput metric reported per session, replacing raw `prs_merged`: today the health comment leads with `prs_merged` (total PRs including chores and docs updates) as the primary throughput signal. A session that merges 8 chore PRs and 0 feature PRs reports a higher "prs_merged" than a session that merges 1 feature PR. This is a perverse incentive — the metric rewards volume over value. SM §4f must invert this: `meaningful_prs` (PRs with design doc references, excluding chores/metrics/session-report PRs) must be the first throughput number in the health comment. `prs_merged` (total) must appear as a secondary figure in parentheses: "Shipped: 3 meaningful PRs (8 total)". The order of numbers in the health signal determines what the operator reads first and what the agent optimizes for. A system that sees its own health signal leading with `prs_merged=8` is optimizing for volume. A system that sees `meaningful_prs=3` first is optimizing for impact. ⚠️ Inferred from reliability lens: the system produces housekeeping PRs with no real feature content and the current metric does not penalize this; meaningful_prs exists in the schema but is not the primary visibility signal.
- 🔲 Queue composition audit must run every 10 batches and post a plain-language summary: COORD §1c fires the chore-only guard reactively (when the queue is ALL chores). But the queue can be 80% chores and 20% features and the guard never fires — the session claims one feature item and leaves 19 chores unclaimed. Over time the chore backlog grows, the feature-to-chore ratio worsens, and the guard never detects the drift. SM §4a must, every 10 batches, scan all open `state=todo` issues in `state.json` and compute: `feature_items_count`, `chore_items_count`, `docs_items_count`, `ratio_feature: feature/(feature+chore+docs)`. If `ratio_feature < 0.3` (less than 30% of the queue is feature work): SM must open a `kind/chore priority/medium` issue "Queue composition: only N% feature items — chore accumulation detected. Run vibe-vision or manually close stale chore items." and post the ratio to the report issue. Without this audit, the chore-to-feature ratio can drift to 95%/5% while individual sessions remain technically "mixed" (not ALL chores), and the system never self-detects the creeping prioritisation failure. ⚠️ Inferred from reliability lens: the system produces housekeeping PRs because the queue composition drifts toward chores; no periodic audit exists to detect this drift before it becomes severe.
- 🔲 Recovery path effectiveness must be tracked — not just whether recovery was attempted: the session minimum meaningful-PR contract (above) and the existing same-session recovery path both specify that the loop must attempt multiple recovery levels before accepting a zero-PR exit. But no mechanism tracks whether those recovery attempts *work*. SM §4b must record three new fields in `state.json` per session: `recovery_attempted: bool`, `recovery_level_reached: 0|1|2|3` (0=no attempt, 1=second-chance item tried, 2=vision synthesis tried, 3=all levels exhausted), `recovery_succeeded: bool`. PM §5 stagnation check must flag when `recovery_attempted=true` AND `recovery_succeeded=false` for 2 consecutive sessions: this means the recovery paths themselves are broken, not just the primary path. A system that attempts recovery but always fails is worse than a system that never attempts it — it consumes session budget on broken recovery logic while producing the same zero-PR result. Without this tracking, the recovery contract is unverifiable: the agent can claim it attempted recovery without any observable evidence. ⚠️ Inferred from reliability lens: sessions fail silently because recovery mechanisms exist on paper but their effectiveness is untracked; the system cannot distinguish "recovery worked" from "recovery was bypassed" from "recovery was attempted but broken."
- 🔲 Claim-to-ENG-attempt rate must be tracked — COORD bail-out before ENG starts is a silent failure: there is a class of failure not yet detected by any existing mechanism: COORD claims an item (sets `state: in_progress`, creates a `feat/*` branch) but exits before ENG begins implementation — for example, when COORD reads the issue and decides the spec is ambiguous, or when the branch creation fails silently, or when COORD context-switches to SM/PM without completing the handoff to ENG. The current loop has no observable signal that distinguishes "COORD claimed, ENG attempted and produced zero-diff" (caught by zero-diff detection in doc 21) from "COORD claimed but ENG never started" (completely uncaught). The item stays `in_progress` in `state.json` and SM's stale-branch watchdog eventually reclaims it — but the session is counted as "productive" (it claimed an item). SM §4b must track `eng_attempts_per_session` — count of sessions where a `feat/*` branch was created AND at least one commit was pushed to it (proof ENG started). A session where `items_claimed > 0` but `eng_attempts == 0` means COORD claimed without ENG starting — write `eng_attempt_rate: 0` to metrics.md and flag with AMBER in next health comment. Without this metric, COORD bail-outs are invisible: the session claims items, the queue shows `in_progress`, and the health signal reports a "working" session that never implemented anything. ⚠️ Inferred from reliability lens: sessions still fail silently; the current zero-diff detection catches ENG finishing with no changes, but not ENG never starting; these are different failure modes with different root causes requiring different fixes.
- 🔲 Simulation `recovery_action` stuck-loop detection: the simulation's `recovery_action` field in `sim-prediction.json` recommends one of four actions (`escalate_oldest_needs_human`, `prioritize_ci_fix`, `trigger_learn`, `trigger_vision_synthesis`). These actions are written by SM §4e after each calibration. But if the same `recovery_action` is recommended for 5 or more consecutive calibrations (every 10 batches = 50 batches), it is strong evidence the recovery action is being recommended but never executed, or is being executed but not working. The simulation is stuck recommending the same treatment while the patient doesn't improve. SM §4e must: (1) read the last 5 `recovery_action` values from `_state:sim-prediction-prev.json` history; (2) if all 5 are identical: open a `kind/bug priority/high` issue "[SIM STUCK] recovery_action=<action> repeated for 5 consecutive calibrations without measurable improvement — the recovery mechanism may be broken or the action may not be reaching the execution path in COORD"; (3) write `recovery_action_stuck: true` to `state.json`; COORD §1b-preflight must surface this in the preflight summary. A simulation that recommends the same recovery 50 batches in a row is not calibrating — it is oscillating. The loop must detect this and escalate before the 50 batches become 100. ⚠️ Inferred from honesty lens: the simulation exists but its predictions are not visibly changing agent behavior; a recovery_action that is repeated without any observable effect is the clearest possible evidence that the feedback loop between simulation and action is broken.

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
