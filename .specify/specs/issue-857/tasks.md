# Tasks: issue-857

## Pre-implementation
- [CMD] `cd ../otherness.issue-857 && bash scripts/validate.sh 2>&1 | tail -3` — expected: PASSED (baseline)
- [CMD] `cd ../otherness.issue-857 && bash scripts/lint.sh 2>&1 | tail -3` — expected: PASSED (baseline)

## Implementation
- [AI] Find the §36.5 vision-backed tracking block in coord.md
- [AI] Modify the VPS_MATCH_EOF python block to also output the matched key
- [AI] Add gh issue comment call after the existing echo lines in §36.5
- [AI] Update docs/design/36-vision-pressure-in-coord.md: flip 36.3 🔲 → ✅

## Post-implementation
- [CMD] `cd ../otherness.issue-857 && grep -q 'COORD §36.3' agents/phases/coord.md && echo PASS` — expected: PASS (O1)
- [CMD] `cd ../otherness.issue-857 && grep -A3 'COORD §36.3' agents/phases/coord.md | grep -q '|| true' && echo PASS` — expected: PASS (O2)
- [CMD] `cd ../otherness.issue-857 && grep -q 'matched VPS key\|no VPS key match' agents/phases/coord.md && echo PASS` — expected: PASS (O3)
- [CMD] `cd ../otherness.issue-857 && grep -q '✅ 36.3' docs/design/36-vision-pressure-in-coord.md && echo PASS` — expected: PASS (O4)
- [CMD] `cd ../otherness.issue-857 && bash scripts/validate.sh 2>&1 | tail -3` — expected: PASSED
- [CMD] `cd ../otherness.issue-857 && bash scripts/lint.sh 2>&1 | tail -3` — expected: PASSED
