# Tasks: issue-892 — SM §4b QA rejection pattern tracker

## Pre-implementation
- [CMD] `cd /home/runner/work/otherness/otherness.issue-892 && bash scripts/validate.sh 2>&1 | tail -3` — expected: PASSED
- [CMD] `grep -n "qa_rejection\|§4b-qa" /home/runner/work/otherness/otherness.issue-892/agents/phases/sm.md | head -3` — expected: no matches

## Implementation
- [AI] Add §4b-qa-rejection block after §4b batch report posted line in sm.md
- [CMD] `grep -n "§4b-qa-rejection\|qa_rejection" /home/runner/work/otherness/otherness.issue-892/agents/phases/sm.md | head -5` — expected: matches found
- [AI] Update docs/design/38-qa-ci-gate.md to flip 38.6 from 🔲 to ✅

## Post-implementation
- [CMD] `cd /home/runner/work/otherness/otherness.issue-892 && bash scripts/validate.sh 2>&1 | tail -3` — expected: PASSED
- [CMD] `cd /home/runner/work/otherness/otherness.issue-892 && bash scripts/lint.sh 2>&1 | tail -3` — expected: PASSED
