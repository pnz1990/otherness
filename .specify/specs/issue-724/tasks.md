# Tasks: issue-724 — 38.3 qa.md §3a CI fix loop

## Pre-implementation
- [CMD] `cd /home/runner/work/otherness/otherness.issue-724 && bash scripts/validate.sh 2>&1 | tail -5` — baseline build health
- [CMD] `cd /home/runner/work/otherness/otherness.issue-724 && bash scripts/lint.sh 2>&1 | tail -5` — baseline lint health

## Implementation
- [AI] Read `~/.otherness/agents/phases/qa.md` lines around the `[AI-STEP]` fix block in §3a (approx lines 107-120)
- [AI] Replace the `[AI-STEP]` block with a real pattern-matching fix loop (see spec.md §Known patterns)
- [AI] Update `docs/design/38-qa-ci-gate.md`: add ✅ 38.3 entry to §Present, remove 38.3 from §Future
- [CMD] `cd /home/runner/work/otherness/otherness.issue-724 && bash scripts/validate.sh 2>&1 | tail -10` — verify validate passes
- [CMD] `cd /home/runner/work/otherness/otherness.issue-724 && bash scripts/lint.sh 2>&1 | tail -10` — verify lint passes

## Commit
- [CMD] `cd /home/runner/work/otherness/otherness.issue-724 && git add agents/phases/qa.md docs/design/38-qa-ci-gate.md .specify/specs/issue-724/ && git commit -m "feat(qa): 38.3 — replace [AI-STEP] CI fix comment with real pattern-matching fix loop"`
- [CMD] `cd /home/runner/work/otherness/otherness.issue-724 && git push origin feat/issue-724`
