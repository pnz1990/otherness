# Tasks: issue-947

## Pre-implementation
- [CMD] `cd ../otherness.issue-947 && bash scripts/validate.sh 2>&1 | tail -3` — PASSED
- [CMD] `cd ../otherness.issue-947 && bash scripts/lint.sh 2>&1 | tail -3` — PASSED

## Implementation
- [AI] Add `## 5r. Periodic ✅ Present audit` section to end of `agents/phases/pm.md`
- [AI] Flip `🔲 41.5` to `✅ 41.5` in `docs/design/41-design-doc-integrity.md`

## Verification
- [CMD] `grep -q '## 5r. Periodic' ../otherness.issue-947/agents/phases/pm.md && echo PASS || echo FAIL`
- [CMD] `grep -q 'pm_audit_cycle' ../otherness.issue-947/agents/phases/pm.md && echo PASS || echo FAIL`
- [CMD] `grep -q '✅ 41.5' ../otherness.issue-947/docs/design/41-design-doc-integrity.md && echo PASS || echo FAIL`

## Post-implementation
- [CMD] `cd ../otherness.issue-947 && bash scripts/validate.sh 2>&1 | tail -3` — PASSED
- [CMD] `cd ../otherness.issue-947 && bash scripts/lint.sh 2>&1 | tail -3` — PASSED
