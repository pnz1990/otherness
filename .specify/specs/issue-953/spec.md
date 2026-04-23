# Spec: Audit and reduce sm.md (issue-953)

## Design reference
- **Design doc**: `docs/design/45-distil-and-simplify.md`
- **Section**: `§ Future`
- **Implements**: 45.1 — Audit and reduce sm.md to under 2,000 lines

## Zone 1 — Obligations

**O1 — sm.md must be under 2,000 lines after this PR.**
Verification: `wc -l agents/phases/sm.md` returns < 2000.

**O2 — No currently-executing section may be removed.**
A section "executes" if it runs on every SM cycle (unconditionally).
Sections gated on SM_CYCLE % N that have never produced evidence of execution
(sim-params.json never updated, AI-STEP not replaced) are safe to remove.

**O3 — The core loop (4a triage, 4b batch report, 4e handoff, 4f report, 4g merge) remains intact.**
Verification: those section headers still exist in sm.md.

**O4 — scripts/validate.sh must still pass.**
Verification: `bash scripts/validate.sh` exits 0.

**O5 — scripts/lint.sh must still pass.**
Verification: `bash scripts/lint.sh` exits 0.

## Zone 2 — Implementer's judgment

Sections to remove (never demonstrably executed):
- §4d simulation calibration (279 lines): calibrate.py only committed once, never run
- §Recovery action inside 4d (62 lines): dead code block
- §4e calibration update + divergence detection (666 lines): SM_CYCLE never set in state
- §4f simulation calibration staleness check (52 lines): references §4e which is removed

Sections to compress (large, conditional, AI-STEP heavy, no evidence of execution):
- §4c cross-project learning (685 → ~60 lines): one [AI-STEP], fires every 5 cycles
- §4c-skill confidence check (105 → ~20 lines): one [AI-STEP], fires every 10 cycles
- §4g-anchor* 5 sections (653 → ~50 lines): otherness has no anchor workflow
- §4a-speckit speckit release check (136 → ~30 lines)
- §4f-integrity design doc integrity (174 → ~30 lines)

## Zone 3 — Scoped out

- Rewriting §4a triage, §4b batch report, §4f health report, §4g merge
- Removing PM phase calls or SM→PM handoff
- Changing state.json schema
- Any change to scripts/validate.sh, scripts/test.sh, scripts/lint.sh
