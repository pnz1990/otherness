# Spec: SCAN 5 — Self-Updating Pressure Prompts

## Design reference
- **Design doc**: `docs/design/28-dual-step-scheduled-workflow.md`
- **Section**: `§ Future`
- **Implements**: Self-updating pressure prompts: Step A reads its own current pressure context, evaluates whether it is still the right thing to push given what shipped, and rewrites the pressure block if it has grown stale or too easy (🔲 → ✅)

---

## Zone 1 — Obligations

**O1 — SCAN 5 runs in `agents/vibe-vision-auto.md` as a new SCAN block.**
It executes after SCAN 4 and before the COMMIT section.

**O2 — SCAN 5 reads the workflow file's pressure context block.**
The pressure block is delimited by `# OTHERNESS_PRESSURE_START` and `# OTHERNESS_PRESSURE_END`
comments in the workflow file. If no pressure block is found, SCAN 5 is a no-op.

**O3 — SCAN 5 checks staleness: how many items from the pressure areas shipped.**
Staleness is determined by counting merged PRs (limit 20) whose titles mention
keywords from the current pressure context. If ≥60% of pressure keywords have
corresponding merged PRs, the block is considered addressed.

**O4 — SCAN 5 rewrites the pressure block when staleness threshold is reached.**
When addressed ratio ≥60%: add a new inferred Future item to the relevant design doc:
`⚠️ Inferred: pressure prompt stale — N/M pressure areas addressed; rewrite needed`
This creates a work item for a human or the PM phase to update the actual workflow prompt.
SCAN 5 does NOT directly modify workflow files (which may be in .github/workflows/ — out of docs zone).

**O5 — SCAN 5 is a no-op when the workflow file is not found or has no pressure block.**
Graceful fallback: print `[SCAN 5] No pressure block found — skipping.` and continue.

**O6 — SCAN 5 caps injected items at 1 per run** to avoid queue flooding.

---

## Zone 2 — Implementer's judgment

- Where to look for the workflow file: scan `.github/workflows/` for any file containing
  `OTHERNESS_PRESSURE_START`. Use glob to find it — do not hardcode the filename.
- What counts as "addressed": a pressure keyword appearing as a substring in any merged PR title
  in the last 20 PRs. This is approximate but fast.
- Whether to rewrite the workflow file directly or inject a design doc Future item:
  **Decision**: inject a design doc Future item only (docs zone). Do not touch .github/ files.

---

## Zone 3 — Scoped out

- Actually rewriting the workflow pressure block (requires .github/ writes — out of docs zone)
- Cross-project pressure propagation (separate issue 611)
- Measuring vision alignment score numerically (separate issue 647)
