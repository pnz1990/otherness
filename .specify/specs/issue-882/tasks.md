# Tasks: issue-882 — COORD §1e chore-claim gate

## Pre-implementation
- [CMD] `cd ../otherness.issue-882 && bash scripts/validate.sh 2>&1 | tail -3` — expected: PASSED

## Implementation
- [AI] Add `MEANINGFUL_PRS_THIS_SESSION=0` initialization to COORD §1a startup section in coord.md
- [AI] Add §1e-chore-gate python block after ITEM_ID selection but before the branch-push claim
- [CMD] `cd ../otherness.issue-882 && grep -n "MEANINGFUL_PRS_THIS_SESSION\|1e-chore-gate" agents/phases/coord.md | head -10` — expected: at least 2 matching lines
- [AI] Update docs/design/21-session-throughput.md: move 🔲 item to ✅ Present

## Post-implementation
- [CMD] `cd ../otherness.issue-882 && bash scripts/validate.sh 2>&1 | tail -3` — expected: PASSED
- [CMD] `cd ../otherness.issue-882 && bash scripts/lint.sh 2>&1 | tail -3` — expected: PASSED
