# 51: Eleventh Vision Scan — Pressure Gap Analysis (2026-04-23)

> Status: Active | Created: 2026-04-23
> Source: Eleventh autonomous vision scan — SCAN 5 scored 0/5 pressure bullets (0%), all five lenses still open
> Applies to: otherness itself and all managed projects

---

## The problem

Ten prior vision scans (docs 45–50 + 35–39) have produced 392 `🔲 Future` items.
SCAN 5 still scores 0/5 pressure bullets addressed. The corpus is now so large that
no existing mechanism guides COORD to the 5 items that would most immediately address
each pressure lens. Accumulation is outpacing delivery.

This doc captures the genuinely new gaps not covered by any prior design doc item —
specific to the failure modes still live as of batch 6 / 2026-04-23. Items 51.1–51.10
are novel; they do not restate items from docs 46–50.

---

## Present (✅)

*(Nothing shipped yet — this doc was created by the eleventh vision scan.)*

---

## Future (🔲)

### Lens 1 — Reliability: every run ships at least one meaningful PR

- 🔲 51.1 — The 392-item Future backlog has no designated "critical path" — COORD cannot distinguish which 5 items, if shipped, would most directly close the five pressure lenses: docs 46–50 collectively have 392 `🔲 Future` items. COORD's claim selection is driven by `priority/high`, `kind/enhancement`, and vision-backing — but not by "which item directly addresses an open pressure bullet." A pressure bullet that has been open for 11 scans (like "is the loop honest enough?") may have 40 design doc Future items that address it, but COORD has no mechanism to identify the smallest claimable item from each pressure area and cluster them as a "pressure-closing sprint." PM §5 must, every 10 batches, compute a `pressure_critical_path`: for each of the 5 pressure bullets, identify the single smallest (shortest item text, fewest obligations) unissued `🔲 Future` item that contains a keyword from that bullet's text. Write this 5-item list to `state.json` as `pressure_critical_path: [{bullet_idx: 1, doc: "48-...", item_text: "..."}, ...]`. COORD §1b must, when `pressure_critical_path` exists and is fewer than 5 sessions old: boost those 5 items to `priority/critical` in claim sorting. The pressure-closing sprint is the minimum necessary mechanism to make 11 scan runs of 0/5 impossible after another 11 runs. Without it, COORD selects from 392 items without any guidance on which items directly move the pressure needle. ⚠️ Inferred from reliability lens: a truly reliable system ships at least one meaningful PR every single run; the 392-item backlog contains the solution but COORD cannot navigate to the highest-leverage items without a critical-path signal.

- 🔲 51.2 — The `VISION_PRESSURE_SET` block (PR #941, coord.md §1b-vision) was merged but is not yet in `~/.otherness/agents/phases/coord.md` — the self-update gap means this feature is shipping to the agents repo but not reaching the running agent: PR #941 merged on 2026-04-22T23:50Z. The self-update at session startup (`git -C ~/.otherness pull`) ran before this merge. The current session's coord.md does not contain the `VISION_PRESSURE_SET` block. This is the "agents self-update is one session behind" problem: any PR merged between the scheduled run's startup pull and the next scheduled run is invisible to the current session. The practical impact: coord.md §1b-vision was designed to build a `VISION_PRESSURE_SET` that biases claim selection toward pressure-closing items — but this mechanism is missing from the running agent. SM §4a must, after the self-update pull, verify that `~/.otherness/agents/phases/coord.md` contains the expected sections by sha-checking against the latest `main` commit: `git -C ~/.otherness rev-parse HEAD` must match `gh api repos/pnz1990/otherness/commits/main --jq .sha`. If they diverge: log "⚠️ Agents repo is behind main — coord.md may be missing recent features. Manual pull may be needed if cron gap exceeds session duration." Without this check, features that merged between sessions are silently absent from the running agent — the operator assumes the feature is active when it is not. ⚠️ Inferred from reliability lens: sessions fail silently; one failure mode is a self-update gap between PR merge and next session start; no mechanism detects this gap or warns the operator that recent features are not yet active.

### Lens 2 — Honesty: loop says GREEN but not advancing fast enough

- 🔲 51.3 — The gap stagnation ratio (doc 42.2) exists as a Future item but has no enforcement at the scan level — each vision scan adds items without checking whether the scan is making the backlog better or worse: doc 42.2 specifies a `gap_stagnation_ratio` = `gaps_aged_30d / (new_gaps + gaps_shipped)`. But no scan currently computes this ratio before deciding whether to add more items. SCAN 3 (infer from code TODOs) and SCAN 5 (add pressure rewrite items) add new Future items every run — potentially increasing the stagnation ratio while it is already above 2.0. `vibe-vision-auto.md` must add a SCAN 0 pre-check that runs before ALL other scans: (1) compute the current stagnation ratio: count `⚠️ Inferred` items with `(date:` annotations older than 30 days, count `🔲 Future` items added in the last scan (via `git diff HEAD~1 HEAD -- docs/design/` for `+.*🔲`), count items promoted to ✅ in the last scan; (2) if `ratio > 3.0` AND `gaps_aged_30d > 20`: skip SCAN 3 and SCAN 5 entirely for this run with log: "[SCAN 0] Stagnation ratio {ratio:.1f} — suppressing new item generation until backlog shrinks." The suppression is temporary: it lifts automatically when the stagnation ratio drops below 2.5 on a subsequent scan. Without this gate, vision scans are unconditionally additive — they make the backlog larger every run regardless of whether the system is shipping. An honest system must not knowingly increase technical debt when debt is already at a critical level. ⚠️ Inferred from honesty lens: the metrics are collected (stagnation ratio is specified in 42.2) but the scan that generates new items never reads this metric before adding more; the loop is not honest enough because it produces Future items that it knows (by the stagnation ratio) are unlikely to be shipped.

- 🔲 51.4 — The `loop_honesty_score` (doc 45.1) is specified but has a flawed `doc_honesty` component that can be self-inflated without detection: 45.1 defines `doc_honesty` as "ratio of ✅ Present items verifiable against agent files." But `vibe-vision-auto.md` SCAN 1 promotes items to ✅ Present when a merged PR title matches the first 20 chars of the item text. This is a title-match promotion, not a behavioral verification. A PR titled "feat: improve eng session startup" can promote a `🔲 Future` item about "improve eng session" even if the implementation only adds a print statement. The ✅ Present mark is then counted as "verifiable" by `doc_honesty`. The result: `doc_honesty` is inflated by title-match promotions that were never behaviorally verified. SCAN 1 must add a promotion confidence flag: items promoted by title match are marked `✅ Present (title-match, unverified)`. The `doc_honesty` component in 45.1 must treat these as 0.5 confidence (partial credit) rather than 1.0 (full credit). Items manually marked ✅ by an ENG session with a "Implements: §N.M" declaration in the PR body are 1.0 confidence. The honesty score must reflect the difference between "PR title matched" and "implementation verified." Without this distinction, SCAN 1 title-match promotions inflate `doc_honesty` by 10–20 points per scan run — the honesty score becomes a measure of PR title quality, not implementation quality. ⚠️ Inferred from honesty lens: the SM health signal says GREEN; the doc_honesty component is a key input; SCAN 1 title-match promotion inflates this component without behavioral verification; this is precisely the "metrics collected but not acted on honestly" failure mode.

### Lens 3 — Self-improvement: agents not smarter, monoculture unaddressed

- 🔲 51.5 — The `agents/skills/` directory has grown to 14 files but no session has ever measured whether loading a skill changed ENG's output in a verifiable way — skills may be loaded but not applied: PR #936 added skill-load verification: ENG must cite the skill in the PR. This confirms skills are loaded. But "cited in PR" and "changed the implementation" are different claims. ENG can write "Loaded skill: agent-coding-discipline.md" in the PR body without the skill's guidance having influenced a single line of the implementation. The skill citation is a logging step, not a behavioral gate. To verify skills actually change behavior: QA §3a must add a `skill_application_check`: when a PR cites a loaded skill, QA must identify ≥1 specific line in the diff that directly reflects guidance from the cited skill file. For example: if `agent-coding-discipline.md` says "changes must be scoped to the minimum necessary surface" and the PR diff changes 3 files when 1 would suffice, QA must note: "Skill cited but not applied: agent-coding-discipline.md §scoped-changes — diff modifies 3 files, spec obligation requires 1." This is not a QA rejection condition (too slow) — it is a QA observation that appears in the review comment. SM §4b must track `skill_application_rate` (PRs where QA observed direct skill application / total PRs with skill citations) over 20 batches. When `skill_application_rate < 30%` for 3 consecutive windows: SM §4b must open a `kind/chore priority/high` issue: "Skills loaded but not applied — citation rate is N% but application rate is M%. Skills may be cosmetic compliance rather than behavioral guidance." Without this check, skill citations are a checkbox step that confirms loading without confirming application — the self-improvement mechanism becomes a logging exercise. ⚠️ Inferred from self-improvement lens: skills are extracted (PR #919) and loading is verified (PR #936) but application is not; a skill that is loaded and cited but not applied is an improvement theater, not an improvement.

- 🔲 51.6 — The competitive rubric (doc 47, `docs/aide/competitive-standing.md`) exists but no mechanism connects a worsening competitive delta to COORD claim selection — competitive regressions are documented but not acted on: PM §5c generates `competitive-standing.md` with rubric scores. Item 47.x specifies that when delta worsens for 3 consecutive comparisons, a `[NEEDS HUMAN: competitive-stall]` issue is opened. But between "delta worsens" and "human intervention," there is no automated COORD behavior change. If the competitive audit shows otherness is losing on "self-improvement (skill growth/mo)" for 3 batches: COORD should be preferentially claiming issues tagged `area/skills` or referencing docs 31/48/49/50 — the self-improvement design docs. COORD §1b must, after reading `competitive-standing.md`, extract the dimension with the largest negative delta and add items from the corresponding design doc area to `VISION_PRESSURE_SET` for the current session. The mapping: "self-improvement" → docs 31, 48, 49; "onboarding" → docs 32, 48.10, 50.5; "visibility" → docs 39, 49.10, 49.11; "reliability" → docs 35, 48.1, 50.1. Without this mapping, competitive audit results are observational — the human reads them but the agent never changes behavior based on them. The competitive audit becomes a passive report rather than an active steering signal. ⚠️ Inferred from self-improvement and honesty lenses: the simulation exists but predictions are not visibly changing agent behavior; the same applies to the competitive audit; both are signals that inform but do not steer; connecting competitive delta to COORD claim priority is the missing wire.

### Lens 4 — Onboarding: new projects require human intervention

- 🔲 51.7 — `/otherness.onboard` generates `docs/aide/` files but does not verify the target project's GitHub Actions runner has the required permissions — projects with restrictive `GITHUB_TOKEN` permissions silently fail after setup: `onboard.md` STEP 7 enables the scheduled workflow and STEP 8 verifies the first run appears. But if the target repo has `GITHUB_TOKEN` permissions set to `contents: read` in the workflow file (a common security-hardening practice), all `git push` operations in the agent loop fail with "403 Permission denied." The first scheduled run will start, produce zero PRs, and SM §4f will report GREEN (0 PRs = housekeeping session). No error message points to the permission gap — it looks like an empty queue. `/otherness.onboard` STEP 7 must add a `permissions_check`: after enabling the workflow but before verifying the first run, run `gh api repos/<OWNER>/<REPO>/actions/permissions --jq .default_workflow_permissions` and verify the result is `"write"` not `"read"`. If `"read"`: warn "⚠️ Target repo has `default_workflow_permissions: read` — the otherness workflow requires `contents: write` to push `_state` branch updates. Update repo settings: Settings → Actions → General → Workflow permissions → Allow write." Block the onboarding completion message until the operator confirms. Without this check, every new project with security-hardened GitHub Actions settings will appear to run successfully but produce no state updates — the operator diagnoses a silent loop failure 48 hours later. ⚠️ Inferred from onboarding lens: a new project added today would still require significant human intervention; the most common security-hardening practice in modern GitHub repos (restrictive GITHUB_TOKEN) creates a silent failure mode in the otherness loop that onboarding never detects.

- 🔲 51.8 — The `otherness-config.yaml` `monitor.projects` field accepts arbitrary strings — no schema validation catches typos that cause silent PM monitoring failures: PM §5 Scenario 1 queries each project in `monitor.projects`. If a project is listed as `"owner/my-project "` (trailing space), `"owner//my-project"` (double slash), or `"my-project"` (missing owner), the `gh api repos/<value>/branches/_state` call returns 404. PM §5 silently skips it (fail-open). The operator added the project expecting it to be monitored; PM §5 counts it as "unreachable" but never reports why. The config validation step in `/otherness.setup` STEP 5 (`otherness-config.yaml` field completeness check per 48.12) checks for empty fields — but not for format validity. STEP 5 must add a `monitor.projects` format check: each entry must match `^[a-zA-Z0-9._-]+/[a-zA-Z0-9._-]+$` (owner slash repo, no spaces, no double slashes). For each entry that fails: print "⚠️ Invalid `monitor.projects` entry: `[value]` — must be in `owner/repo` format. Common typos: trailing space, missing owner, double slash." The fix is a one-line regex check. Without it, monitor list typos silently break PM monitoring for the affected project indefinitely — the operator has no signal until they notice the project never appears in health comments. ⚠️ Inferred from onboarding lens: the setup guide is incomplete; a missing format validation for a required config field is a category of human error that a 1-line validation eliminates entirely; currently the system silently accepts invalid monitor.projects entries.

### Lens 5 — Visibility: human cannot answer 3 questions in 30 seconds

- 🔲 51.9 — The `docs/aide/progress.md` file shows a single snapshot but the Stage Completion table has been static for multiple batches — stages that are marked `✅ Complete` with no progress since Stage 4 give a false impression of advancement: `docs/aide/progress.md` shows Stages 0–4 complete and Stage 5 pending. The file has not updated the Stage Completion table since Stage 4 shipped. But the system has shipped 100+ PRs since Stage 4 — PRs that implement design doc items from docs 35–50. These PRs advance the capability of the system but the Stage Completion table doesn't move. A human reading `progress.md` sees "last shipped 2026-04-22" but the Stage Completion table looks identical to how it looked a week ago. The disconnect signals either (a) the system is not making progress (wrong) or (b) the progress metric doesn't capture what's actually being built (correct, and the problem). SM §4f must, when updating `progress.md`, add a `Key capabilities added this session` table below the Stage Completion section: one row per PR merged in the current batch with columns `PR`, `capability`, `design doc`. This table answers "what was actually built?" without requiring the Stage Completion model to move. It makes every batch's contribution visible regardless of whether a stage threshold was crossed. The capability table also makes it easier for a human to answer "is it moving toward the vision or spinning in circles?" — each row should name a concrete capability, not a process improvement. ⚠️ Inferred from visibility lens: a human looking at GitHub right now cannot quickly tell if the system is moving toward the vision; the Stage Completion model is coarse-grained and doesn't move frequently enough to show weekly progress; a per-session capability table shows what specifically changed without redesigning the stage model.

- 🔲 51.10 — The report issue (issue #741) has no pinned comment or description that tells a first-time visitor what they are looking at — a new team member opening this issue sees 30+ comments with no orientation: the report issue is the primary health-monitoring artifact for otherness. But its title is "otherness: autonomous team reports — batch N" and its body describes the format of comments — it does not describe what otherness IS, what the comments mean, or how to read them. A first-time visitor to the report issue must read multiple comments to understand the system. The issue body must be updated (by SM §4g, every 20 batches or when the body is more than 30 days old) to include: (1) a 3-sentence description of what otherness is; (2) a 5-row "reading guide" explaining each comment type (health table, vision scan, session outcome, etc.); (3) a link to `docs/aide/progress.md` for historical trend; (4) a link to `docs/aide/metrics.md` for raw data. The update must use `gh issue edit $REPORT_ISSUE --body "..."` — not a new comment. This is a zero-infrastructure change that makes the report issue self-explanatory to any GitHub user who opens it. Without it, the report issue is an impenetrable stream of technical output that communicates nothing to anyone who hasn't read the architecture docs. ⚠️ Inferred from visibility lens: the report issue comments are too verbose and technical; the root cause is not just comment verbosity but the complete absence of orientation material in the issue itself; a self-describing issue body is the first-touch visibility fix that costs one write per 20 batches.

---

## Zone 1 — Obligations

**O1 — All items are fail-open.**
None of these items may block the main loop. Detection failures are logged and
the loop continues.

**O2 — Items 51.1–51.10 must enter the queue via COORD §1d.**
This doc is the source. COORD reads `🔲 Future` items and creates GitHub issues.
No human intervention needed to queue them.

**O3 — Priority ordering within this doc:**
1. 51.2 (self-update gap detection) — detectable today, 2-line check
2. 51.3 (SCAN 0 stagnation gate) — stops backlog inflation, needed before more scans add items
3. 51.1 (pressure critical path) — highest-leverage for breaking the 0/5 score
4. 51.9 (progress.md capability table) — lowest-friction visibility improvement
5. 51.10 (report issue body orientation) — one-time write, immediate first-touch improvement
6. 51.7, 51.8 (onboarding checks) — next new-project protection
7. 51.4, 51.5, 51.6 (honesty and self-improvement depth)

**O4 — 51.3 (SCAN 0 stagnation gate) must not suppress SCAN 6 (this doc's gap analysis).**
The stagnation gate applies to automated inference scans (SCAN 3, SCAN 5).
Human-context pressure scans (this doc) are always permitted.

---

## Zone 2 — Implementer's judgment

- 51.1: the `pressure_critical_path` computation must handle the case where a pressure bullet
  has NO corresponding Future item text that matches — in this case, the system must
  synthesize a `size/xs` item from the bullet text itself as a fallback.
- 51.2: the sha comparison must be soft — log-only, not a HOLD condition — because the
  agents repo legitimately lags main by one pull cadence; the goal is detection, not blocking.
- 51.4: the `(title-match, unverified)` annotation must be applied retroactively to all
  existing ✅ Present items promoted by SCAN 1 in the last 5 scans; use `git log --oneline
  -- docs/design/` to identify scan commits.
- 51.8: the regex for `monitor.projects` must accept hyphens and dots in repo names
  (e.g. `owner/my.project-v2`); the pattern `^[a-zA-Z0-9._-]+/[a-zA-Z0-9._-]+$` covers this.

---

## Zone 3 — Scoped out

- Replacing the scheduled workflow infrastructure
- Changes to the GitHub Actions runner or model configuration
- Items already covered in docs 46–50 (not restated here)
