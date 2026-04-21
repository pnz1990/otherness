# Tasks: issue-681 — test.sh recovery_action verification

## Pre-implementation
- [CMD] `cd ../otherness.issue-681 && bash scripts/validate.sh 2>&1 | tail -3` — expected: PASSED

## Implementation
- [AI] Add [5c] check to scripts/test.sh after the [5b] schema check: read sim-prediction.json from reference project _state branch, warn if absent or missing recovery_action
- [CMD] `cd ../otherness.issue-681 && grep '5c' scripts/test.sh` — expected: match found
- [CMD] `cd ../otherness.issue-681 && grep 'sim-prediction' scripts/test.sh` — expected: match found

## Post-implementation
- [CMD] `cd ../otherness.issue-681 && bash scripts/validate.sh 2>&1 | tail -3` — expected: PASSED
- [CMD] `cd ../otherness.issue-681 && bash scripts/lint.sh 2>&1 | tail -3` — expected: PASSED
