# Tasks: issue-909

## Pre-implementation
- [CMD] `cd ../otherness.issue-909 && bash scripts/validate.sh 2>&1 | tail -3` — PASSED (baseline)
- [CMD] `cd ../otherness.issue-909 && bash scripts/lint.sh 2>&1 | tail -3` — PASSED (baseline)

## Implementation
- [AI] Add `## 5q. Minor release trigger` section to end of `agents/phases/pm.md`
- [AI] Flip `🔲 40.2` to `✅ 40.2` in `docs/design/40-autonomous-releases.md`

## Verification
- [CMD] `grep -q '## 5q. Minor release trigger' ../otherness.issue-909/agents/phases/pm.md && echo PASS || echo FAIL`
- [CMD] `grep -q 'pm_minor_cycle' ../otherness.issue-909/agents/phases/pm.md && echo PASS || echo FAIL`
- [CMD] `grep -q 'generate-notes' ../otherness.issue-909/agents/phases/pm.md && echo PASS || echo FAIL`
- [CMD] `grep -q '✅ 40.2' ../otherness.issue-909/docs/design/40-autonomous-releases.md && echo PASS || echo FAIL`

## Post-implementation
- [CMD] `cd ../otherness.issue-909 && bash scripts/validate.sh 2>&1 | tail -3` — PASSED
- [CMD] `cd ../otherness.issue-909 && bash scripts/lint.sh 2>&1 | tail -3` — PASSED
