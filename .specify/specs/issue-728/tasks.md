# Tasks: issue-728 — SM §4f design doc integrity spot-check (41.1)

## Pre-implementation
- [CMD] `cd /home/runner/work/otherness/otherness.issue-728 && bash scripts/validate.sh 2>&1 | tail -3` — expected: PASSED

## Implementation
- [AI] Find the SM §4f section in `agents/phases/sm.md` and append the spot-check block after the existing §4f content.
- [CMD] `cd /home/runner/work/otherness/otherness.issue-728 && grep -n "4f-integrity\|SM §4f" agents/phases/sm.md | tail -10` — expected: §4f-integrity block present
- [AI] Move 41.1 from 🔲 Future to ✅ Present in `docs/design/41-design-doc-integrity.md`.
- [CMD] `cd /home/runner/work/otherness/otherness.issue-728 && grep "✅.*41.1" docs/design/41-design-doc-integrity.md` — expected: ✅ 41.1 line present

## Post-implementation
- [CMD] `cd /home/runner/work/otherness/otherness.issue-728 && bash scripts/validate.sh 2>&1 | tail -3` — expected: PASSED
- [CMD] `cd /home/runner/work/otherness/otherness.issue-728 && bash scripts/lint.sh 2>&1 | tail -3` — expected: PASSED
