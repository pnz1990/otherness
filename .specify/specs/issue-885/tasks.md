# Tasks: issue-885 — Features-per-week velocity as primary speed signal

## Pre-implementation
- [CMD] `cd ../otherness.issue-885 && bash scripts/validate.sh 2>&1 | tail -5` — expected: PASSED
- [CMD] `cd ../otherness.issue-885 && bash scripts/lint.sh 2>&1 | tail -3` — expected: PASSED or no critical errors

## Implementation
- [AI] Add `meaningful_prs_week` column to `docs/aide/metrics.md` header row (O4)
- [CMD] `cd ../otherness.issue-885 && grep "meaningful_prs_week" docs/aide/metrics.md | head -3` — expected: at least 1 match (header row)
- [AI] Add `meaningful_prs_per_week` compute block to SM §4b in `agents/phases/sm.md` — query GitHub API for merged PRs in last 7 days, filter for meaningful ones (O1)
- [AI] Update the metrics row write in SM §4b to include the new `meaningful_prs_week` value (O2)
- [AI] Update the schema column comment in SM §4a-schema-conformance to reflect the new column count
- [AI] Add PM §5 velocity stall check: read last 2 `meaningful_prs_week` values from metrics.md, flag if both < 1.0 (O3)
- [AI] Add PM §5 healthy velocity note: note "Velocity: healthy" when >= 3.0 for 4 consecutive batches (O3)
- [AI] Update `docs/design/33-stage-4-self-improvement-metrics.md` to move the 🔲 item to ✅ Present

## Post-implementation
- [CMD] `cd ../otherness.issue-885 && bash scripts/validate.sh 2>&1 | tail -5` — expected: PASSED
- [CMD] `cd ../otherness.issue-885 && bash scripts/lint.sh 2>&1 | tail -3` — expected: PASSED or no critical errors
- [CMD] `cd ../otherness.issue-885 && bash scripts/test.sh 2>&1 | tail -5` — expected: PASSED or informational (no failures)
