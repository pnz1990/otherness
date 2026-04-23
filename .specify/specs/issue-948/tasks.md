# Tasks: issue-948

## Pre-implementation
- [CMD] `cd ../otherness.issue-948 && bash scripts/validate.sh 2>&1 | tail -3` — PASSED (baseline)
- [CMD] `cd ../otherness.issue-948 && bash scripts/lint.sh 2>&1 | tail -3` — PASSED (baseline)

## Implementation
- [AI] Add `§41.5 docs gate` block to `agents/phases/qa.md` inside §3b, after §41.4 closes
- [AI] Flip `🔲 41.5` to `✅ 41.5` in `docs/design/41-published-docs-freshness.md`

## Verification
- [CMD] `grep -q '§41.5 docs gate' ../otherness.issue-948/agents/phases/qa.md && echo PASS || echo FAIL`
- [CMD] `grep -q '✅ 41.5' ../otherness.issue-948/docs/design/41-published-docs-freshness.md && echo PASS || echo FAIL`

## Post-implementation
- [CMD] `cd ../otherness.issue-948 && bash scripts/validate.sh 2>&1 | tail -3` — PASSED
- [CMD] `cd ../otherness.issue-948 && bash scripts/lint.sh 2>&1 | tail -3` — PASSED
