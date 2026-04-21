# Tasks: issue-633 — Graceful partial handoff on GitHub Actions job timeout

## Pre-implementation
- [CMD] `cd ../otherness.issue-633 && bash scripts/validate.sh 2>&1 | tail -3` — expected: PASSED or similar pass output
- [CMD] `cd ../otherness.issue-633 && grep "timeout-minutes" .github/workflows/otherness-scheduled.yml` — expected: line with timeout-minutes: 120

## Implementation
- [AI] Change `timeout-minutes: 120` to `timeout-minutes: 330` in the `otherness` job
- [CMD] `cd ../otherness.issue-633 && grep "timeout-minutes" .github/workflows/otherness-scheduled.yml` — expected: timeout-minutes: 330
- [AI] Add cleanup step "Graceful timeout cleanup" after Step 8 (Run otherness) with `if: always()`, correct token env, and Python script that reads _state, resets in-progress items, posts comment
- [CMD] `cd ../otherness.issue-633 && python3 -c "import yaml; yaml.safe_load(open('.github/workflows/otherness-scheduled.yml'))" && echo "YAML valid"` — expected: YAML valid
- [CMD] `cd ../otherness.issue-633 && grep -c "Graceful timeout cleanup" .github/workflows/otherness-scheduled.yml` — expected: 1

## Post-implementation
- [CMD] `cd ../otherness.issue-633 && bash scripts/validate.sh 2>&1 | tail -5` — expected: PASSED
- [CMD] `cd ../otherness.issue-633 && bash scripts/lint.sh 2>&1 | tail -3` — expected: PASSED or OK
