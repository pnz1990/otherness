# Tasks: issue-870 — SM §4f health AMBER when 0 meaningful PRs

## Pre-implementation
- [CMD] `cd ../otherness.issue-870 && bash scripts/validate.sh 2>&1 | tail -3` — expected: PASSED

## Implementation
- [AI] In SM §4f, after the STABLE/STALLED→AMBER block and before the sim-calibration-staleness check, add: if MEANINGFUL_PRS==0 AND HEALTH==GREEN: set HEALTH=AMBER with note.
- [CMD] `cd ../otherness.issue-870 && grep -c "MEANINGFUL_WARN\|meaningful PRs this session\|chore-only or zero-ship" agents/phases/sm.md` — expected: ≥2
- [AI] Add _MEANINGFUL_WARN to the health table (or append to the existing note column).
- [AI] In docs/design/21-session-throughput.md, move the 0 meaningful PRs AMBER item from 🔲 to ✅.
- [CMD] `cd ../otherness.issue-870 && grep -c "✅.*0 meaningful PRs.*AMBER\|✅.*Health signal.*degrade.*AMBER\|✅.*meaningful.*AMBER" docs/design/21-session-throughput.md` — expected: ≥1

## Post-implementation
- [CMD] `cd ../otherness.issue-870 && bash scripts/validate.sh 2>&1 | tail -3` — expected: PASSED
- [CMD] `cd ../otherness.issue-870 && bash scripts/lint.sh 2>&1 | tail -3` — expected: PASSED
