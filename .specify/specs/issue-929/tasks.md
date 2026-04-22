# Tasks: issue-929

## Implementation tasks

- [CMD] Read current `agents/phases/pm.md` §5j (already done)
- [AI] Identify exact location in §5j to inject workflow-disabled detection (after stale detection, before generic stall issue)
- [AI] Write the disabled-workflow detection block in Python (inline in §5j bash)
- [CMD] Read `docs/design/19-scheduled-execution.md` to identify the 🔲 Future item to flip
- [AI] Edit `agents/phases/pm.md` §5j to add detection block
- [AI] Edit `docs/design/19-scheduled-execution.md` to move item from 🔲 Future to ✅ Present
- [CMD] Run validate.sh, test.sh, lint.sh in worktree
- [CMD] Commit and push
- [CMD] Open PR
