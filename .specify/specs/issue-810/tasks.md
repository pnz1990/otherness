# Tasks: issue-810 — Workflow-level silent failure detection

## Pre-implementation
- [CMD] `cd ../otherness.issue-810 && bash scripts/validate.sh 2>&1 | tail -5` — expected: PASSED

## Implementation
- [AI] Add a new step to `.github/workflows/otherness-scheduled.yml` between Step 6 (auth) and Step 7 (vision scan):
  - Name: "Workflow heartbeat — session started"
  - continue-on-error: true
  - Uses GITHUB_TOKEN (not GH_TOKEN) to post "🔄 Session started — TIMESTAMP" to REPORT_ISSUE
  - Reads REPORT_ISSUE from otherness-config.yaml with python3
  - Skips silently if REPORT_ISSUE is 0 or unreadable
- [AI] Update docs/design/19-scheduled-execution.md: move item from 🔲 to ✅ Present

## Post-implementation
- [CMD] `cd ../otherness.issue-810 && bash scripts/validate.sh 2>&1 | tail -5` — expected: PASSED
- [CMD] `cd ../otherness.issue-810 && bash scripts/lint.sh 2>&1 | tail -5` — expected: PASSED
- [CMD] `cd ../otherness.issue-810 && grep -n "session.*started\|🔄 Session" .github/workflows/otherness-scheduled.yml` — expected: at least 1 match
