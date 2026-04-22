# Tasks: issue-890 Phase-role cognitive diversity

## Pre-implementation
- [CMD] `cd /home/runner/work/otherness/otherness.issue-890 && bash scripts/validate.sh 2>&1 | grep -E "PASSED|WARN.*coord"` — expected: PASSED + WARN for coord.md

## Implementation
- [AI] Add `**Cognitive stance: optimistic incrementalist — What can be shipped quickly and safely?**` after the Role identity paragraph in agents/phases/coord.md
- [CMD] `grep -n "Cognitive stance" /home/runner/.otherness/agents/phases/coord.md` — expected: match on a line
- [AI] Add `**Cognitive stance: customer advocate / strategic skeptic — Does this matter to a real user?**` after the Role identity paragraph in agents/phases/pm.md
- [CMD] `grep -n "Cognitive stance" /home/runner/.otherness/agents/phases/pm.md` — expected: match on a line

## Post-implementation
- [CMD] `cd /home/runner/work/otherness/otherness.issue-890 && bash scripts/validate.sh 2>&1 | tail -5` — expected: PASSED, no WARN for coord.md
- [CMD] `cd /home/runner/work/otherness/otherness.issue-890 && bash scripts/lint.sh 2>&1 | tail -3` — expected: PASSED
