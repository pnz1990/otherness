# 37: Self-Updating Pressure Prompts — The Agent Raises Its Own Bar

> Status: Active | Created: 2026-04-20
> Applies to: otherness itself and all managed projects

---

## What this does

The vision pressure context currently injected into Step A of the scheduled workflow
was written by a human in a single session. It captures the gaps that were visible
at that moment. But products evolve. Gaps get closed. New gaps appear. If the pressure
prompt never changes, the agent will eventually exhaust the items it names and drift
back to generating housekeeping work — the exact failure mode we fixed today.

The human wrote the first pressure context. The agent must own it from here.

This design doc specifies how `vibe-vision-auto.md` adds a fifth scan (SCAN 5) that:
1. Reads the current pressure context from the scheduled workflow file
2. Checks how many items from that context have been addressed in recent batches
3. If the addressed ratio exceeds 60%: rewrites the pressure block to raise the bar
4. If the pressure block is >30 days old: rewrites it regardless of addressed ratio

The human should never need to manually update the pressure prompts. The agent does it.

---

## Present (✅)

- ✅ Initial vision pressure context injected into all 3 project workflows by human (2026-04-20)
- ✅ `docs/design/28-dual-step-scheduled-workflow.md` §Future: self-updating pressure prompts listed as next step (2026-04-20)
- ✅ 37.1 — `agents/vibe-vision-auto.md` SCAN 5: reads the active pressure block from the `prompt:` YAML key of the Step A step in `.github/workflows/otherness-scheduled.yml` (Step A identified by containing `vibe-vision-auto.md`). Falls back to searching all workflow files if the primary source is absent. Exports `pressure_block` (full text) and `pressure_keywords` (key phrases) for use in scoring. (PR #694, 2026-04-21)

---

## Future (🔲)

- 🔲 37.2 — SCAN 5: score the current pressure — for each bullet point in the current pressure block, check recent merged PRs (last 10 batches) and open design doc Present items. If a bullet's topic has ≥2 corresponding merged PRs or Present items: mark it "addressed." Count addressed / total = addressed ratio.
- 🔲 37.3 — SCAN 5: rewrite condition — if addressed ratio > 0.6 (60% of pressure items have been acted on) OR if the last rewrite timestamp in the block is >30 days ago: trigger a rewrite.
- 🔲 37.4 — SCAN 5: synthesise new pressure block — read `docs/aide/vision.md`, current design doc Future items, recent SM health comments, and the most recent PM competitive observation (if any). Synthesise a new pressure block that: (a) removes addressed items, (b) sharpens items that are partially addressed, (c) adds new items from the gap analysis. Write the block as natural language bullets, same format as the current block. Cap at 6 bullets.
- 🔲 37.5 — SCAN 5: update the workflow file — replace the "Context for this vision scan:" block in `.github/workflows/otherness-scheduled.yml` with the new block. Add a timestamp comment: `# Pressure context last updated: YYYY-MM-DD (auto)`. Commit the change to the session branch.
- 🔲 37.6 — Cross-project pressure propagation: when otherness's own pressure scan identifies a pattern present across ≥2 managed projects (e.g. "test coverage at edge cases is weak on all projects"), update the pressure block of each affected managed project's workflow. This requires SM §4a to call SCAN 5 as a cross-project step, not just per-project.
- 🔲 37.7 — Pressure context version history must be human-readable and auditable: SCAN 5 rewrites the "Context for this vision scan:" block in the scheduled workflow — but the previous version is only recoverable via `git log` (buried in workflow YAML diffs). A human wanting to understand how the bar has been raised over time must diff workflow YAML commits manually. This is too high friction. `vibe-vision-auto.md` SCAN 5, when performing a rewrite (§37.5), must ALSO append the replaced pressure block to a dedicated file: `docs/aide/pressure-history.md` with format `## YYYY-MM-DD (auto-rewrite)` followed by the old pressure block verbatim. The file is append-only — each rewrite adds one dated entry. SM §4b must verify `docs/aide/pressure-history.md` exists and has ≥1 entry before declaring the pressure-update mechanism ✅. Without this history, the "agent raises its own bar" claim is unverifiable: the human cannot see whether the bar was raised meaningfully (harder targets) or trivially (same targets reworded). The git log is a single-commit diff; the pressure-history file is a human-readable timeline. ⚠️ Inferred from self-improvement and visibility lenses: the agents are not demonstrably smarter than they were; the pressure context rewrite mechanism exists (doc 37) but produces no artifact a human can read to confirm the bar is actually rising; the system could be rewriting the same prompt in different words every 30 days and the human would have no way to notice.
- 🔲 37.8 — Pressure rewrite quality gate: SCAN 5's synthesised pressure block (§37.4) must not simply rephrase the existing pressure topics. A rewrite that changes "Is otherness reliable enough?" to "Is the loop reliable enough?" is meaningless. Before committing the rewrite, SCAN 5 must verify: (1) at least 2 of the 6 new bullets address topics NOT in the previous pressure block (novelty check — compare first 40 chars of each new bullet to all previous bullets); (2) at least 1 new bullet references a specific recent design doc Future item that has NOT been the subject of a previous pressure context (freshness check — scan `docs/design/*.md` for the topic); (3) if novelty or freshness check fails: SCAN 5 must add a `[PRESSURE REWRITE QUALITY: LOW]` comment to the session branch commit and post to the report issue. Without this gate, SCAN 5 can declare a pressure rewrite "complete" by shuffling the same 5 themes into 6 bullets — each rewrite is cosmetically different but semantically identical. The self-updating pressure mechanism cannot break frame-lock if it only ever rewrites within the existing frame. ⚠️ Inferred from self-improvement lens: "What would genuinely break the frame-lock?" is the key question; a pressure rewrite mechanism that shuffles the same themes is not breaking any frame; the bar is not being raised if the new questions are variants of the old questions.
- 🔲 37.9 — SCAN 5 must escalate when addressed ratio is 0% for >7 days — zero-address trap: the rewrite condition (§37.3) fires when addressed ratio ≥ 60% OR age >30 days. But there is a third failure mode with no current handler: addressed ratio is 0% AND the pressure context is <30 days old. This means the loop has been running for up to 30 days while delivering zero work that matches any of the pressure topics. SCAN 5 currently sees 0/5 keywords (0%) and takes no action — it is below the 60% threshold and below the 30-day age threshold. The agent continues running sessions that ship nothing the pressure asks for, and the pressure context idles unchanged. SCAN 5 must add a zero-address trap: if `addressed_ratio == 0` AND the pressure block is >7 days old AND ≥5 sessions have run since the pressure was written (readable from `metrics.md` row count minus the row count at pressure-write time), SCAN 5 must: (1) open a `kind/bug priority/high` issue: "[Pressure Trap] 0% of pressure areas addressed in N sessions over 7 days — the loop is not executing on the current pressure context. Either COORD is not claiming vision-pressure items, or the pressure keywords do not match any queue items. Investigate COORD §1b vision-pressure claim audit." (2) add a `🔲 Future` item to doc 36: "COORD §1b vision-pressure claim audit: verify that items in the current queue actually match pressure context keywords." Without this trap, a 0% addressed ratio is silently acceptable for up to 30 days. The pressure context can be perfectly calibrated while the loop ignores it entirely — SCAN 5 never fires because neither threshold is breached. ⚠️ Inferred from reliability and honesty lenses: the loop is not honest enough; the SM health signal says GREEN while the pressure context shows 0% addressed; no mechanism connects these two signals to surface the contradiction.
- 🔲 37.10 — Current pressure context must be visible in `/otherness.status` and the health comment: the vision pressure context is the primary steering mechanism for the autonomous loop — it is what the agent is being asked to work on. But a human checking the system's health has no way to read the current pressure context without opening the scheduled workflow YAML file. `/otherness.status` must include a section "Vision pressure (current):" that prints the 4–6 bullets from the current pressure block, followed by "Addressed this week: N/M". SM §4f must include a one-line summary in the health comment: "Pressure: N/M areas addressed this session | Context age: D days". Without this, the pressure context is a hidden steering mechanism — the human cannot tell whether the system is doing what the pressure asks, and the agent cannot easily see what it is supposed to prioritise when the health comment is its primary context source at session start. The pressure context and the health signal must be co-located: the same place the operator reads about health is the place they read about current direction. ⚠️ Inferred from visibility lens: a human looking at GitHub right now cannot tell what the system is being asked to focus on; the pressure context — the primary direction signal — is hidden in a workflow YAML file that requires navigation to find; there is no zero-click visibility of what the current pressure is.

---

## Zone 1 — Obligations

**O1 — The agent may only add pressure, never remove it entirely.** SCAN 5 removes addressed items (items with ≥2 corresponding merged PRs). It never produces an empty pressure block. Minimum: 3 bullets. If fewer than 3 unaddressed items exist, generate new ones from vision/roadmap gaps before writing.

**O2 — The rewrite is human-readable.** The new pressure block must be natural language bullets, same format as what a human would write. Not JSON, not YAML, not a list of design doc numbers. The human should be able to read it and immediately understand what the agent thinks the product needs.

**O3 — The rewrite is committed on the session branch.** Like all Step A changes, the updated workflow file is committed to the `opencode/schedule-*` branch and merged at batch end by SM §4g. The change goes through the normal PR/CI cycle — it is not a direct push to main.

**O4 — Timestamp is required.** The "Pressure context last updated" comment must be present and dated. This is what the 30-day staleness check reads. Without it, SCAN 5 will always rewrite (it treats missing timestamp as infinitely old).

**O5 — The 60% threshold is hard.** Do not adjust it per-project. If a product is moving fast and addressing items quickly, more frequent pressure rewrites is the correct behaviour — not a problem to fix.

---

## Zone 2 — Implementer's judgment

- SCAN 5 runs at the end of the existing scan sequence, after SCANs 1-4. It is the most expensive scan (reads workflow file, checks PR history, synthesises new content). Running it last keeps it from blocking the cheaper scans.
- The "addressed" check (§37.2) is intentionally loose: any PR whose title contains a word from the pressure bullet (4+ chars, not a stopword) counts as addressing it. This will have false positives but false positives here are conservative — they prevent the prompt from raising the bar too early, which is the safer failure mode.
- The synthesis step (§37.4) is the core AI step — it requires genuine reasoning, not pattern matching. This is where the LLM earns its cost. The inputs (vision.md, design docs, SM comments) must be read in full, not sampled.
- §37.6 cross-project propagation: start with otherness-only (single-project scan). Cross-project is a follow-on. The value of propagation is high but the complexity of reading state across repos is non-trivial.

---

## Zone 3 — Scoped out

- Human approval gate before the rewrite lands (the point is no human needed)
- A/B testing different pressure framings
- Versioned pressure history (git log is the history)
- Per-product customisation of the 60% threshold
