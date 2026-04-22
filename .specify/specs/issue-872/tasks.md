# Tasks: issue-872 — SM health comment skills_count and last-learn date

## Pre-implementation
- [CMD] `cd ../otherness.issue-872 && bash scripts/validate.sh 2>&1 | tail -3` — expected: PASSED
- [CMD] `cd ../otherness.issue-872 && bash scripts/lint.sh 2>&1 | tail -3` — expected: PASSED

## Implementation
- [AI] In SM §4f, find where the health comment body is assembled (REPORT_BODY or similar). Add a Python block before it that computes: (1) skills_count from agents/skills/*.md, (2) last learn date from PROVENANCE.md. Expose as shell vars SKILLS_COUNT and LAST_LEARN.
- [AI] Modify the health comment body to include "Skills: $SKILLS_COUNT (last learn: $LAST_LEARN)" with color-coded date prefix.
- [CMD] `cd ../otherness.issue-872 && grep -c "SKILLS_COUNT\|last learn\|PROVENANCE" agents/phases/sm.md` — expected: ≥3
- [AI] In docs/design/31-stage-2-skills-expansion.md, move the skills_count/last-learn item from 🔲 to ✅.
- [CMD] `cd ../otherness.issue-872 && grep -c "✅.*skills_count.*PROVENANCE\|✅.*PROVENANCE.*skills_count\|✅.*last.learn.*health" docs/design/31-stage-2-skills-expansion.md` — expected: ≥1

## Post-implementation
- [CMD] `cd ../otherness.issue-872 && bash scripts/validate.sh 2>&1 | tail -3` — expected: PASSED
- [CMD] `cd ../otherness.issue-872 && bash scripts/lint.sh 2>&1 | tail -3` — expected: PASSED
