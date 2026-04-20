# Spec: Fix false-positive stale markers in design docs (issues 469-471)

## Design reference
- N/A — documentation fix with no user-visible behavior change (infrastructure chore)

## Context

The SM §4g hygiene scan added `⚠️ Stale — referenced file not found` markers to 23
Present items in design docs. The markers were false positives: all referenced files
exist in the repo. The scan had a bug where file path extraction was incorrect.

## Zone 1 — Obligations

**O1 — All false-positive stale markers removed from docs/design/ files.**
No Present item in any design doc should end with `⚠️ Stale — referenced file not found`
unless the file truly does not exist on disk.

**O2 — validate.sh and lint.sh pass after the change.**
The change is documentation-only and must not break any structural checks.

## Zone 2 — Implementer's judgment

- Apply the fix by removing the marker string from all design docs in one PR.
- Do not evaluate each file individually — the scan code had a systematic bug affecting all files.

## Zone 3 — Scoped out

- Fixing the hygiene scan code itself (separate issue to be filed)
- Evaluating whether any referenced files are genuinely missing (all verified to exist)
