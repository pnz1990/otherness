# Tasks: COORD §1b unified startup signal reader

## [CMD] Find insertion point in coord.md §1b
Find the line "## 1b. Vision check" in agents/phases/coord.md — the preflight block goes AFTER the vision check block ends (after the closing fi).

## [AI] Write the unified preflight bash+python block
Insert a new `## 1b-preflight. Startup signal reader` section after the vision check block.
The block reads state.json signals, logs them, sets COORD_ACTION, and (if housekeeping_streak >= 3) sets the vision-first flag.

## [AI] Update §1c to consume COORD_ACTION=vision-first
When COORD_ACTION=vision-first, run vibe-vision-auto before queue-gen instead of after.
This means the existing "Run vibe-vision-auto to refill queue" block in §1e moves to the top of §1c.

## [CMD] Update design doc 35 (🔲 → ✅)
Move the COORD §1b unified preflight item from Future to ✅ Present in docs/design/35-quality-of-output-gaps.md

## [CMD] Run validate/lint/test
bash scripts/validate.sh && bash scripts/lint.sh
