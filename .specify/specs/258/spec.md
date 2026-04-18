# Spec: SM codebase hygiene scan

> Item: 258 | Created: 2026-04-18 | Status: Active

## Design reference
- **Design doc**: `docs/design/04-documentation-health.md`
- **Section**: `## Future`
- **Implements**: Codebase hygiene scan — SM phase periodic scan (🔲 → ✅)

---

## Zone 1 — Obligations

**O1 — SM phase has a §4f codebase hygiene scan sub-section.**
`agents/phases/sm.md` must include a `## 4f. Codebase hygiene scan` section with a
`[AI-STEP]` block implementing the scan.

Behavior that violates this: the scan is placed in pm.md or standalone.md.

**O2 — Scan runs every 20 SM cycles (not every cycle).**
The §4f block must be gated behind `if [ $((SM_CYCLE % 20)) -eq 0 ] && [ "$SM_CYCLE" -gt 0 ]`.
This is the same pattern as §4c-skill and §4d.

Behavior that violates this: the scan runs every cycle (too expensive/noisy).

**O3 — Scan checks coverage of non-trivial files in `agents/` and `scripts/`.**
For otherness specifically (the product is markdown+scripts): scan files in `agents/` and
`scripts/`. For general projects: extend to the project's source directory. Files checked:
- `*.md` in `agents/` (not in `agents/skills/` — those are skill library, not features)
- `*.sh` in `scripts/`
- `*.py` in `scripts/` (if any)

For each file: check whether any `docs/design/` file mentions its name in a Present or
Future item. If no coverage found: open a `kind/chore` issue.

Behavior that violates this: the scan checks only one file type.

**O4 — Nothing is deleted or modified autonomously.**
The scan opens issues only. It does not modify, delete, or deprecate any file.
The issue title must include "[NEEDS HUMAN: confirm deletion or document]" if the file
truly has no coverage — ensuring human confirms before any action.

Behavior that violates this: the scan directly removes or deprecates uncovered files.

**O5 — Duplicate-suppressed: one open issue per file.**
Before opening an issue for an uncovered file, check for an existing open issue with
the same title.

Behavior that violates this: same file generates a new issue on every 20-batch cycle.

**O6 — Graceful fallback when docs/design/ is empty or missing.**
If no design docs exist, log `[SM §4f] No design docs — codebase hygiene scan skipped.`
and exit without error.

Behavior that violates this: the scan throws an exception when docs/design/ is missing.

---

## Zone 2 — Implementer's judgment

- How to check "coverage": look for the filename (without extension) or the base name
  in any Present or Future item across all design docs. Simple string search, not AST.
- What counts as "non-trivial": files > 0 bytes. Skip empty files.
- Whether to scan recursively: no — one level only (agents/*.md, scripts/*.sh, scripts/*.py)
- Which files to always exempt from the scan:
  - PROVENANCE.md (skill learning audit, not a feature)
  - README.md (all skill READMEs)
  - Any file already listed as 🚫 Deprecated
  - Any file with "template" in the name

---

## Zone 3 — Scoped out

- Recursive directory scanning (one level only)
- Auto-detecting project source directories for non-otherness projects
- Autonomous file deletion or deprecation
- Scanning docs/ directory itself (that's §5f's job)
