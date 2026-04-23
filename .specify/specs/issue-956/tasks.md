# Tasks: issue-956

## Pre-implementation
- [CMD] `cd ../otherness.issue-956 && bash scripts/validate.sh 2>&1 | tail -3` — expected: PASSED (baseline)
- [CMD] `cd ../otherness.issue-956 && bash scripts/lint.sh 2>&1 | tail -3` — expected: PASSED (baseline)

## Implementation
- [AI] Add `_coord_post_create_setup(num)` helper inside each `open_if_absent`-containing Python block in `agents/phases/coord.md`
- [AI] Helper reads `board_project_id` from config; if set: `gh project item-add` then GraphQL to set Status:Todo
- [AI] Helper reads `active_milestone` from config; if set: lookup milestone number, `gh issue edit --milestone`
- [AI] Both calls non-blocking (`except: pass`, `|| true`)
- [AI] Call `_coord_post_create_setup(result)` at each `open_if_absent` return site

## Post-implementation
- [CMD] `cd ../otherness.issue-956 && bash scripts/validate.sh 2>&1 | tail -3` — expected: PASSED
- [CMD] `cd ../otherness.issue-956 && bash scripts/test.sh 2>&1 | tail -3` — expected: PASSED
- [CMD] `cd ../otherness.issue-956 && bash scripts/lint.sh 2>&1 | tail -3` — expected: PASSED
