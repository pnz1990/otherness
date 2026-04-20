# 35: Quality-of-Output Gaps — Five Lenses the System Must Answer

> Status: Active | Created: 2026-04-20
> Applies to: otherness itself
> Source: vibe-vision pressure scan — system not good enough yet

---

## Purpose

This doc captures five structural gaps identified by applying the pressure lens
from the scheduled vision scan. For each gap: the problem, why it matters, and
the `🔲 Future` items that must close it. No existing design doc had `🔲` coverage
for these areas.

---

## Lens 1 — Reliability: sessions that ship nothing meaningful

**The problem:**
Batches regularly ship only housekeeping: a metrics commit, a docs fix, a
🚫-deferred marker. The system counts these as "shipped PRs" and reports GREEN.
But from the product's perspective, nothing advanced. The vision principle says
every run must ship ≥1 vision-advancing PR. Today there is no mechanism that
distinguishes housekeeping from meaningful work or that escalates when a session
ships zero meaningful PRs.

**The gap:** No design doc has a `🔲 Future` item for "meaningful work gate" —
a check that blocks GREEN from being reported when all PRs in a batch are
`kind/chore`, `kind/docs`, or metrics commits with no `🔲 → ✅` transition.

**Related doc:** `docs/design/21-session-throughput.md` (throughput framing), but
throughput counts PRs not quality.

## Present (✅)

*(None for this doc — all items are Future)*

## Future (🔲)

### Lens 1 — Reliability

- 🔲 `SM §4b` / `PM §5`: meaningful-work gate — after each batch, check if any merged PR moved a `🔲 Future` item to `✅ Present` in a design doc; if none, downgrade health signal to AMBER and log `[⚠️ Housekeeping-only batch]` on the report issue; do NOT allow GREEN if zero design-doc transitions occurred in the batch
- 🔲 `SM §4b`: session outcome classification — classify each merged PR as "vision-advancing" (`🔲 → ✅` in a design doc) vs "housekeeping" (metrics, docs fix, CI, deferred marker); write classification to `metrics.md` as a new column `vision_prs`; use `vision_prs` as the primary throughput metric, not raw `prs_merged`
- 🔲 `standalone.md` / `coord.md §1e`: silent-session detection — when a session ends with 0 merged PRs and no open PR, write `silent_session: true` to `_state`; SM detects 2 consecutive silent sessions and opens a `[NEEDS HUMAN: silent-session-streak]` issue with the last 2 batch health reports; this is the primary signal for "the loop is spinning without shipping"
- 🔲 `coord.md §1c`: queue refusal guard — when all items in the queue are `kind/chore` or `kind/docs` (no `kind/enhancement` or `kind/bug`), trigger a minimum queue depth refresh from roadmap or autonomous vision before claiming the next item; a session that starts on a chore-only queue should inject ≥1 vision item first

### Lens 2 — Loop Honesty: GREEN signal does not mean product is advancing

- 🔲 `SM §4f` batch report format: replace generic GREEN/AMBER/RED with a two-axis signal: `progress: <ADVANCING|STABLE|STALLED>` + `health: <GREEN|AMBER|RED>`; "advancing" requires ≥1 vision PR; "stable" means chores only; "stalled" means silent session; the human should be able to read the batch report and immediately know if the product moved
- 🔲 `SM §4e` / `PM §5g`: simulation-behavior coupling gate — verify that the simulation's `arch_convergence` score actually changed the agent's behavior in the last 10 batches (did an AMBER from high arch_convergence trigger a `/otherness.learn`? did the learn run? did the arch_convergence score decrease in the subsequent calibration?); if the chain never closed, post `[⚠️ Simulation loop unclosed — signals exist but behavior unchanged]` on the report issue; the simulation is an instrument, not wallpaper
- 🔲 `docs/aide/metrics.md` schema: add `arch_convergence` and `sim_floor_delta` columns to batch log rows — `arch_convergence` from last calibration run, `sim_floor_delta` = actual_prs - predicted_floor; these are the two numbers that tell the human whether the simulation is tracking reality; currently not persisted in the batch log

### Lens 3 — Self-Improvement: skills grow slowly, frame-lock not broken

- 🔲 `SM §4c` learn-cadence enforcement: add an explicit check — if `PROVENANCE.md` last entry is >14 days old AND queue is non-empty AND health is GREEN, trigger `/otherness.learn` regardless of Type B rate; the "Type B rate triggers learn" rule is necessary but not sufficient; the 14-day cadence is a floor, not a ceiling
- 🔲 `agents/otherness.learn.md` / `SM §4c`: frame-lock break protocol — when the simulation detects `arch_convergence > 0.65` for 3 consecutive calibrations, the learn target must be chosen from a repo that is architecturally UNLIKE the current skills library (e.g. if skills are all agent-loop patterns, learn from a data pipeline repo); document the "unlike" heuristic in `otherness.learn.md` and implement the arch-diversity targeting in SM §4c; the monoculture problem cannot be solved by learning more of the same
- 🔲 `agents/skills/README.md` + `SM §4c`: skill decay tracking — skills added >90 days ago without a PROVENANCE.md "reinforced" entry are candidates for revision; SM §4c checks skill age against last use signal (appearance in session comments or PR bodies) and flags stale skills for refresh via the next learn session; a growing skill count is not the same as a useful skill count
- 🔲 `agents/otherness.learn.md`: diversity-first learn target selection — when choosing a repo to learn from, score candidates by structural distance from existing skills (different language, different paradigm, different domain); document the scoring heuristic; currently the agent picks repos by quality/stars without considering architectural diversity; this is the root of the monoculture problem

### Lens 4 — Onboarding: human intervention still required

- 🔲 `agents/onboard.md` post-run validation: after generating `docs/aide/`, run a structural self-check that matches `scripts/check-onboarding.sh` criteria inline; if the check finds gaps (missing sections, placeholder text still present, empty vision.md), fix them before exiting the onboard session; the agent should not require a human to run the check script
- 🔲 `onboarding-existing-project.md` + `onboarding-new-project.md`: add a "first-run smoke test" section — after `/otherness.setup` completes, the human runs `/otherness.run` once and the system self-validates: queue generated, first item claimed, PR opened; if any step fails, the system writes a `[NEEDS HUMAN: first-run-failure]` issue with the specific failure; today a new project can be "set up" but silently broken until the human notices no PRs
- 🔲 `agents/onboard.md` vision inference quality: after writing `vision.md`, run the vision doc through a self-check: does the vision describe what the codebase actually does? does it name the specific user/operator, the specific value delivered, the specific differentiator? generic vision docs ("this project manages X efficiently") are useless to the agent loop; add a quality gate that rejects vision statements under 100 words or without a named user

### Lens 5 — Visibility: no clean human-readable health status

- 🔲 `SM §4f` batch report condensed format: the report issue comment must fit in 8 lines; current format is verbose and technical; adopt a structured terse format: `Batch N | Health: GREEN | Progress: ADVANCING | Vision PRs: 2 | Chores: 1 | Queue: 4 remaining | Journeys: 9✅ 0❌ | Next: [item title]`; everything else goes into a collapsible `<details>` block; the human should be able to scan 10 batch comments in 30 seconds
- 🔲 New command `/otherness.status` enhanced output: the command currently exists but its output is not structured as a health dashboard; add a "one-page view" to `.opencode/command/otherness.status.md` that shows: (1) current health signal with trend (last 5 batches), (2) skills count + last learn date, (3) queue depth + next item, (4) journey status table, (5) simulation status (calibrated? arch_convergence?), (6) reference project health; this is the single page a human checks to know if otherness is working
- 🔲 `docs/aide/progress.md` automated update: SM §4f must update `progress.md` after every batch with current stage, current queue state, and last 3 batch outcomes; currently `progress.md` is stale (shows Batch 22 state); a human reading `progress.md` should get current state, not week-old state; SM must own this file the same way it owns `metrics.md`

---

## Zone 1 — Obligations

**O1 — Meaningful work gate must never suppress a genuine GREEN.**
The gate is only additive: a session that shipped 2 vision PRs and 1 chore gets
`progress: ADVANCING, health: GREEN`. The gate only downgrades when ALL merged
PRs are chores with no design-doc transitions.

**O2 — Frame-lock break requires a different repo type, not just a different repo.**
The learn target must be structurally diverse. Choosing a different agent-loop
project does not break architectural monoculture.

**O3 — Onboarding self-check must not block on edge cases.**
If the structural self-check finds issues it cannot fix autonomously (e.g. vision
requires real knowledge of the project domain), it records them as `[NEEDS HUMAN:
onboard-gap]` issues and exits cleanly. It never silently skips the check.

**O4 — The condensed batch report format must be backward-compatible.**
Existing report issue parsing (test.sh check 5b) must still work. The terse format
goes in the comment body; the test checks for specific strings that remain present.

---

## Zone 2 — Implementer's judgment

- "Vision-advancing PR" definition: a PR that moves ≥1 `🔲 Future` item to `✅ Present`
  in any design doc AND is labeled `kind/enhancement` or `kind/bug`. Docs-only PRs that
  move items to ✅ in the same docs-only PR are borderline — treat as housekeeping.
- `arch_convergence > 0.65` as the frame-lock trigger threshold: this is lower than
  the 0.7 alarm threshold in doc 23. Use 0.65 as a proactive trigger (learn before
  alarm fires).
- progress.md update frequency: every batch. It's a small file and SM already commits
  to _state. Adding a progress.md update to SM §4f is low-risk.

---

## Zone 3 — Scoped out

- Replacing the report issue with an external dashboard (GitHub-only principle)
- Per-PR quality scoring (binary vision/chore classification is sufficient)
- Cross-project progress.md (each project maintains its own)
