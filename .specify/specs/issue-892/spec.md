# Spec: issue-892 — SM §4b: QA rejection pattern tracker (38.6)

## Design reference
- **Design doc**: `docs/design/38-qa-ci-gate.md`
- **Section**: `§ Future`
- **Implements**: 38.6 — SM §4b QA rejection pattern tracker (🔲 → ✅)

## Zone 1 — Obligations (falsifiable)

O1. SM §4b MUST detect when a `feat/*` branch was closed without merging (QA rejection
    proxy: branch deleted after >1h with no merged PR on that branch).
    Violation: `§4b-qa-rejection` block does not scan for unmerged closed branches.

O2. When a rejection is detected, SM MUST record `qa_rejection_reason` (one of:
    ci_failure / spec_violation / scope_creep / test_missing / other) in `state.json`.
    Violation: no `qa_rejections` field in state.json after detecting a closed branch.

O3. If the same rejection reason appears 3+ consecutive times across sessions, SM MUST
    open a `kind/chore priority/high` issue: "QA rejection pattern: <type> in last 3
    sessions — ENG may need a targeted skill."
    Violation: no issue opened after 3 consecutive same-type rejections.

O4. Fail-open: if gh CLI call fails or branch detection errors, log warning and continue.
    Violation: SM exits or stalls when gh CLI returns non-zero.

O5. `scripts/validate.sh` MUST PASS.
    Violation: any validate check fails.

O6. `scripts/lint.sh` MUST PASS.
    Violation: lint fails.

## Zone 2 — Implementer's judgment

- Whether to detect rejection type via PR body keywords or use 'other' for unclassified
- Whether to store rejections in state.json as a list or a counter per type
- Threshold for "consecutive" (can be approximate — 3 of last 5 instead of 3 in a row)

## Zone 3 — Scoped out

- Skill file creation for the repeated failure type (that's a follow-up)
- Changes to QA phase
- Modifying metrics.md format
