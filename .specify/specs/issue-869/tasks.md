# Tasks: issue-869 — metrics schema-execution drift detection

## Pre-implementation
- [CMD] `cd ../otherness.issue-869 && bash scripts/validate.sh 2>&1 | tail -3` — expected: PASSED
- [CMD] `cd ../otherness.issue-869 && bash scripts/lint.sh 2>&1 | tail -3` — expected: PASSED

## Implementation
- [AI] In `agents/phases/sm.md`, find the end of the §4a section (after M7 check) and insert a new §4a-schema-conformance Python block that: (1) reads `docs/aide/metrics.md`, (2) finds the header row and last data row, (3) compares column counts, (4) if mismatch: dedup-checks open issues and creates a kind/bug issue.
- [CMD] `cd ../otherness.issue-869 && grep -c "schema-conformance\|schema drift\|§4a-schema" agents/phases/sm.md` — expected: ≥3
- [AI] In `docs/design/33-stage-4-self-improvement-metrics.md`, move the "Metrics schema-execution drift detection" item from 🔲 Future to ✅ Present.
- [CMD] `cd ../otherness.issue-869 && grep -c "✅.*schema.*drift\|✅.*schema-execution" docs/design/33-stage-4-self-improvement-metrics.md` — expected: ≥1

## Post-implementation
- [CMD] `cd ../otherness.issue-869 && bash scripts/validate.sh 2>&1 | tail -3` — expected: PASSED
- [CMD] `cd ../otherness.issue-869 && bash scripts/lint.sh 2>&1 | tail -3` — expected: PASSED
