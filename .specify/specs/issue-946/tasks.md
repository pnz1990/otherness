# Tasks: issue-946

## Pre-implementation
- [CMD] `cd ../otherness.issue-946 && bash scripts/validate.sh 2>&1 | tail -3` — PASSED
- [CMD] `cd ../otherness.issue-946 && bash scripts/lint.sh 2>&1 | tail -3` — PASSED

## Implementation
- [AI] Update §5q in `agents/phases/pm.md` to add Upgrading section from AGENTS.md
- [AI] Flip `🔲 40.4` to `✅ 40.4` in `docs/design/40-autonomous-releases.md`

## Verification
- [CMD] `grep -q 'Upgrading' ../otherness.issue-946/agents/phases/pm.md && echo PASS || echo FAIL`
- [CMD] `grep -q '✅ 40.4' ../otherness.issue-946/docs/design/40-autonomous-releases.md && echo PASS || echo FAIL`

## Post-implementation
- [CMD] `cd ../otherness.issue-946 && bash scripts/validate.sh 2>&1 | tail -3` — PASSED
- [CMD] `cd ../otherness.issue-946 && bash scripts/lint.sh 2>&1 | tail -3` — PASSED
