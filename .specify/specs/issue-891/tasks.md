# Tasks: issue-891 — COORD §1f queue-depth check accounts for vision pressure (36.4)

## Pre-implementation
- [CMD] `cd /home/runner/work/otherness/otherness.issue-891 && bash scripts/validate.sh 2>&1 | tail -3` — expected: PASSED
- [CMD] `grep -n "TODO_NOW\|Vision-backed\|36\.4" /home/runner/work/otherness/otherness.issue-891/agents/phases/coord.md | head -5` — expected: lines matching TODO_NOW but NOT "Vision-backed"

## Implementation
- [AI] After the TODO_NOW computation block (line ~1033), add a VISION_BACKED_TODO_NOW computation that counts only items matching VISION_PRESSURE_SET keys
- [AI] Change the learn trigger condition from `TODO_NOW < 5` to also check VISION_BACKED_TODO_NOW < 3
- [AI] Add log line: "[COORD §1e-36.4] Vision-backed todo items: N / M total."
- [CMD] `grep -n "Vision-backed todo items" /home/runner/work/otherness/otherness.issue-891/agents/phases/coord.md` — expected: match found
- [AI] Update docs/design/36-vision-pressure-in-coord.md to flip 36.4 from 🔲 to ✅

## Post-implementation
- [CMD] `cd /home/runner/work/otherness/otherness.issue-891 && bash scripts/validate.sh 2>&1 | tail -3` — expected: PASSED
- [CMD] `cd /home/runner/work/otherness/otherness.issue-891 && bash scripts/lint.sh 2>&1 | tail -3` — expected: PASSED
