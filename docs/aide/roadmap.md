# otherness: Development Roadmap

> Based on: docs/aide/vision.md

The build order is: tooling first, then agent loop improvements, then the self-improvement flywheel.

---

## Stage 0: Scaffolding — self-onboarding infrastructure

**Goal:** otherness has the minimum files to run on itself. `BUILD_COMMAND`, `TEST_COMMAND`, and `LINT_COMMAND` all exit 0.

### Deliverables
- `scripts/validate.sh` — markdown structure checks (no hardcoded project paths in agents/, all skill refs exist on disk)
- `scripts/test.sh` — full test suite including integration check against alibi _state branch
- `scripts/lint.sh` — markdownlint on all files in `agents/`
- `AGENTS.md` — project context for the agent reading this repo
- `otherness-config.yaml` — project config
- `docs/aide/` — vision, roadmap, definition-of-done, progress
- `.specify/memory/constitution.md` — behavioral rules
- `.opencode/command/otherness.*.md` — all command files deployed
- `_state` branch with seeded `state.json`
- GitHub report issue #1 and all labels
- CI: `.github/workflows/ci.yml` running validate + lint on every PR

### Dependencies
None — this is the bootstrap stage.

---

## Stage 1: Agent Loop Hardening

**Goal:** The standalone agent loop has no known failure modes on standard projects. Every edge case is documented and handled.

### Deliverables
- Document and fix: what happens when `docs/aide/vision.md` is missing (graceful fallback, not crash)
- Document and fix: what happens when CI is broken for >24 hours (escalation path)
- Document and fix: what happens when all issues are in `needs-human` state (agent behavior)
- Document and fix: what happens when a worktree directory already exists (cleanup + retry)
- Document and fix: the state write race condition when two sessions commit to `_state` simultaneously (retry with backoff)
- `scripts/test.sh` integration test verifies all 5 scenarios above pass on alibi

### Dependencies
Stage 0

---

## Stage 2: Skills Expansion

**Goal:** The skills library grows from 4 skills to ≥10 through `/otherness.learn` sessions on high-signal repos.

### Deliverables
- Run `/otherness.learn` autonomously every 14 days (cron-like: check PROVENANCE.md, if last entry >14 days ago, run a session)
- At least 6 new skills added from open-source research
- Each skill meets the quality gate: specific, falsifiable, novel, transferable
- `PROVENANCE.md` has entries for each learning session
- Skill index in `agents/skills/README.md` listing all skills and when to load them

### Dependencies
Stage 0

---

## Stage 3: Onboarding Quality

**Goal:** `/otherness.onboard` produces a complete, accurate `docs/aide/` set that needs zero manual editing for standard projects.

### Deliverables
- Test `/otherness.onboard` against a real codebase that was not pre-configured for otherness
- Identify gaps in the generated `vision.md`, `roadmap.md`, `definition-of-done.md`
- Fix the `onboard.md` agent to close each gap found
- Acceptance: after running `/otherness.onboard` on a fresh repo, `/otherness.run` starts working without any human edits to the generated files

### Dependencies
Stage 0

---

## Stage 4: Self-Improvement Metrics

**Goal:** The system generates quantitative evidence of its own improvement over time.

### Deliverables
- `docs/aide/metrics.md` — tracked metrics: time-to-merge per item (by stage/size), `[NEEDS HUMAN]` rate per batch, skill count over time, alibi/kardinal throughput
- Agent produces a metrics update in Phase 4 (SM) every batch
- PM validation Scenario 5 uses metrics to detect stagnation and open issues proactively
- A `kind/chore` issue is auto-opened when any metric regresses for 2 consecutive batches

### Dependencies
Stage 1

---

## Stage 5: Versioned Release Model (Option B)

**Goal:** Projects can pin to a stable otherness version, upgrading explicitly rather than auto-updating.

This stage is only entered when triggered by: >10 repos using otherness, OR a CRITICAL tier regression causing real damage, OR community request.

### Deliverables
- Git tags as releases (`v1.0.0`, `v1.1.0`, etc.)
- `otherness-config.yaml` gains a `version:` field (semver, defaults to `main`)
- Self-update mechanism respects pinned version: `git -C ~/.otherness checkout <version>` instead of `pull`
- `/otherness.upgrade` shows changelog diff and asks confirmation before applying
- CHANGELOG.md maintained automatically on every merged PR to `main`

### Dependencies
Stage 4, AND explicit human decision to proceed
