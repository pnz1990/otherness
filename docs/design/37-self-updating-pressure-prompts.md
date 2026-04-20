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

---

## Future (🔲)

- 🔲 37.1 — `agents/vibe-vision-auto.md` SCAN 5: read current pressure block — parse the `prompt:` section of the Step A workflow step from `.github/workflows/otherness-scheduled.yml` to extract the current "Context for this vision scan:" block. This is the active pressure context.
- 🔲 37.2 — SCAN 5: score the current pressure — for each bullet point in the current pressure block, check recent merged PRs (last 10 batches) and open design doc Present items. If a bullet's topic has ≥2 corresponding merged PRs or Present items: mark it "addressed." Count addressed / total = addressed ratio.
- 🔲 37.3 — SCAN 5: rewrite condition — if addressed ratio > 0.6 (60% of pressure items have been acted on) OR if the last rewrite timestamp in the block is >30 days ago: trigger a rewrite.
- 🔲 37.4 — SCAN 5: synthesise new pressure block — read `docs/aide/vision.md`, current design doc Future items, recent SM health comments, and the most recent PM competitive observation (if any). Synthesise a new pressure block that: (a) removes addressed items, (b) sharpens items that are partially addressed, (c) adds new items from the gap analysis. Write the block as natural language bullets, same format as the current block. Cap at 6 bullets.
- 🔲 37.5 — SCAN 5: update the workflow file — replace the "Context for this vision scan:" block in `.github/workflows/otherness-scheduled.yml` with the new block. Add a timestamp comment: `# Pressure context last updated: YYYY-MM-DD (auto)`. Commit the change to the session branch.
- 🔲 37.6 — Cross-project pressure propagation: when otherness's own pressure scan identifies a pattern present across ≥2 managed projects (e.g. "test coverage at edge cases is weak on all projects"), update the pressure block of each affected managed project's workflow. This requires SM §4a to call SCAN 5 as a cross-project step, not just per-project.

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
