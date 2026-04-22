# Tasks: issue-702 — fix SESSION_PROGRESS false STALLED

## Pre-implementation
- [CMD] `cd /home/runner/work/otherness/otherness.issue-702 && bash scripts/validate.sh 2>&1 | tail -3` — expected: PASSED

## Implementation
- [AI] Add MERGED/VISION_PRS recompute guard before PROGRESS_CLASS in sm.md §4f.
- [CMD] `cd /home/runner/work/otherness/otherness.issue-702 && grep -n "MERGED unset\|recomputing" agents/phases/sm.md` — expected: guard comment present

## Post-implementation
- [CMD] `cd /home/runner/work/otherness/otherness.issue-702 && bash scripts/validate.sh 2>&1 | tail -3` — expected: PASSED
- [CMD] `cd /home/runner/work/otherness/otherness.issue-702 && bash scripts/lint.sh 2>&1 | tail -3` — expected: PASSED
