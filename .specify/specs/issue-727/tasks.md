# Tasks: issue-727 — PM §5o Patch Release Trigger (40.1)

## Pre-implementation
- [CMD] `cd /home/runner/work/otherness/otherness.issue-727 && bash scripts/validate.sh 2>&1 | tail -3` — expected: PASSED

## Implementation
- [AI] Add PM §5o section to `~/.otherness/agents/phases/pm.md` in the worktree copy at `agents/phases/pm.md`. The section runs every 3 PM cycles and implements the 5-condition patch release trigger.
- [CMD] `cd /home/runner/work/otherness/otherness.issue-727 && grep -n "5o\|patch release" agents/phases/pm.md | head -10` — expected: §5o heading and patch release trigger present
- [AI] Move 40.1 from 🔲 Future to ✅ Present in `docs/design/40-autonomous-releases.md`.
- [CMD] `cd /home/runner/work/otherness/otherness.issue-727 && grep "✅.*40.1" docs/design/40-autonomous-releases.md` — expected: ✅ 40.1 line present

## Post-implementation
- [CMD] `cd /home/runner/work/otherness/otherness.issue-727 && bash scripts/validate.sh 2>&1 | tail -3` — expected: PASSED
- [CMD] `cd /home/runner/work/otherness/otherness.issue-727 && bash scripts/lint.sh 2>&1 | tail -3` — expected: 0 exit or PASSED
