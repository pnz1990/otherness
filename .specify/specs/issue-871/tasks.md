# Tasks: issue-871 — first-run bootstrap guard

## Pre-implementation
- [CMD] `cd ../otherness.issue-871 && bash scripts/validate.sh 2>&1 | tail -3` — expected: PASSED

## Implementation
- [AI] In coord.md §1a, after the heartbeat write block and before stop sentinel, add a bash block that: (1) detects zero-batch-history (metrics.md missing or no data rows), (2) sets FIRST_RUN_SESSION=true/false, (3) seeds state.json if missing, (4) posts "[FIRST RUN]" comment.
- [CMD] `cd ../otherness.issue-871 && grep -c "FIRST_RUN_SESSION\|bootstrap mode\|FIRST RUN" agents/phases/coord.md` — expected: ≥3
- [AI] Wrap §1d stale-item watchdog in a FIRST_RUN_SESSION guard.
- [AI] In docs/design/32-stage-3-onboarding-quality.md, move the bootstrap guard item from 🔲 to ✅.
- [CMD] `cd ../otherness.issue-871 && grep -c "✅.*bootstrap\|✅.*First-run\|✅.*first.run" docs/design/32-stage-3-onboarding-quality.md` — expected: ≥1

## Post-implementation
- [CMD] `cd ../otherness.issue-871 && bash scripts/validate.sh 2>&1 | tail -3` — expected: PASSED
- [CMD] `cd ../otherness.issue-871 && bash scripts/lint.sh 2>&1 | tail -3` — expected: PASSED
