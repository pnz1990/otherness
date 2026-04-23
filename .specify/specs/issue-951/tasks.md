# Tasks: issue-951

## Pre-implementation
- [CMD] `cd ../otherness.issue-951 && bash scripts/validate.sh 2>&1 | tail -3` — expected: PASSED (baseline)
- [CMD] `cd ../otherness.issue-951 && bash scripts/lint.sh 2>&1 | tail -3` — expected: PASSED (baseline)

## Implementation
- [AI] Add `§43.4 Board Status: In Review` block to `agents/phases/eng.md` after the `gh pr create` command
- [AI] Flip `🔲 43.4` to `✅ 43.4` in `docs/design/43-github-project-management.md`

## Verification
- [CMD] `grep -q '§43.4 Board Status: In Review' ../otherness.issue-951/agents/phases/eng.md && echo PASS || echo FAIL`
- [CMD] `grep -q 'if \[ -n.*_BOARD_PID' ../otherness.issue-951/agents/phases/eng.md && echo PASS || echo FAIL`
- [CMD] `grep -q '✅ 43.4' ../otherness.issue-951/docs/design/43-github-project-management.md && echo PASS || echo FAIL`

## Post-implementation
- [CMD] `cd ../otherness.issue-951 && bash scripts/validate.sh 2>&1 | tail -3` — expected: PASSED
- [CMD] `cd ../otherness.issue-951 && bash scripts/test.sh 2>&1 | tail -3` — expected: PASSED
- [CMD] `cd ../otherness.issue-951 && bash scripts/lint.sh 2>&1 | tail -3` — expected: PASSED
