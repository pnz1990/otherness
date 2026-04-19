# otherness: Development Roadmap

> Based on: docs/aide/vision.md

The build order is: tooling first, then agent loop improvements, then the self-improvement flywheel, then the eternal loop, then autonomous vision.

---

## Stage 9: Autonomous Vision Synthesis

**Goal:** The loop never stalls waiting for a human to bring new direction. When the
queue empties and no human is present, an autonomous vision agent reads the system's
own knowledge corpus and synthesizes new `🔲 ⚠️ Inferred` Future items. The loop
restarts itself.

The human remains the highest-fidelity source of direction — but between sessions,
the system maintains its own momentum.

### Deliverables

- `agents/autonomous-vision.md` — MODE: VISION, no dialogue step; reads design docs,
  ⚠️ stubs, metrics, simulation output; synthesizes `🔲 ⚠️ Inferred` items; writes
  to `docs/design/` only
- SM phase trigger — when queue empty + no pending ⚠️ stubs + GREEN/AMBER + ≥3
  batches since last run: create `vision/auto-<date>` branch, run agent, merge
- PM §5m: `⚠️ Inferred` ratio check — if >80% of Future items are machine-generated,
  post vibe-vision suggestion (human direction is needed)

### The threshold for "Stage 9 is working"

The queue empties. No human runs `/otherness.vibe-vision`. Within one SM cycle,
the autonomous vision agent produces at least 3 `🔲 ⚠️ Inferred` items. COORD picks
them up. A new batch runs. The loop never entered true standby.

### Dependencies

Stage 8 (Eternal Loop — health signal, spatial coordination, vision evolution cadence)

---

## Stage 8: Eternal Loop — Towards an Ever-Evolving Vision

**Goal:** The system runs indefinitely. It never declares itself done. It never
freezes. When the queue is empty, it waits. When new vision arrives — from the
human, from competitive observation, from its own self-scanning — it wakes and
builds. The human's only required role is to add vision. Everything else is autonomous.

This stage closes the gap between "the system works" and "the system is alive."

### Deliverables

**14 — Stop condition and health signal framing** (`docs/design/14-eternal-loop-stop-condition.md`)
- standalone.md: remove "final run" framing; replace with health signal reporting
- Phase 4 SM: batch completion posts health signal format (GREEN/AMBER/RED + journeys + queue)
- HARD RULES: "Never say 'final run' or 'complete'. Report health signal only."

**15 — Multi-session spatial coordination** (`docs/design/15-multi-session-spatial-coordination.md`)
- state.json: `file_spaces` field written at claim time
- coord.md §1e: collision detection before claiming
- coord.md §1c: queue generation spreads items across file spaces
- stale watchdog clears expired file_space declarations

**16 — Journey 2 reference project health** (`docs/design/16-journey-2-reference-project.md`)
- PM §5: detect Journey 2 failure, open [NEEDS HUMAN] issue once per stall
- PM §5g: Journey 2 stall → AMBER after 24h, RED after 72h
- definition-of-done.md: Journey 2 gains automated check command

**17 — Vision evolution cadence** (`docs/design/17-vision-evolution-cadence.md`)
- PM §5: vision age check — suggest vibe-vision when queue empty >30 days
- PM §5c: competitive observations written as `⚠️ Inferred` design doc stubs
- PM §5h: emergent patterns from ✅ Present become `⚠️ Observed` stubs

### The threshold for "Stage 8 is working"

1. The agent completes 10 consecutive batches without saying "final run" or "complete"
2. When the queue empties, the system enters standby and posts a GREEN health signal
3. When a new vibe-vision session adds Future items, the system wakes from standby and begins a new batch — without human instruction
4. Journey 2 (alibi) stays GREEN for 7 consecutive days — the reference project health gate works
5. At least one competitive observation generates a new design doc stub that COORD picks up as a queue item

### Dependencies
Stage 7 (Perpetual Autonomous Validation — architecture in place, needs full validation)

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

---

## Stage 6: Simulation-Anchored Self-Improvement

**Goal:** The simulation runs automatically, stays calibrated against real batch data,
and its output actively shapes agent behavior across all projects using otherness.
The system knows when it's stuck before the human notices.

This stage makes otherness self-diagnosing at scale.

### Deliverables
- `scripts/calibrate.py` — reads `docs/aide/metrics.md`, runs parameter grid search,
  writes `scripts/sim-params.json` with empirically calibrated defaults
- SM phase §4d — runs calibration every 10 batches; commits `sim-params.json` to
  `_state`; reads arch-convergence signal; opens needs-human issue if > threshold
- Phase 1 propagation — calibrated `sim-params.json` ships via `git -C ~/.otherness pull`
  to every project as default parameters
- Phase 2 per-project calibration — after ≥10 project batches, SM re-calibrates
  against project-specific `metrics.md`; stores in `_state` as override
- PM validation scenario 6 — verify simulation is running, calibrated, and has
  produced at least one arch-convergence signal in the last 30 days

### The threshold for "Stage 6 is working"
The simulation correctly predicted a genuine behavioral stall and surfaced it
to the human before they noticed it themselves. Once this happens once, Stage 6
is validated.

### Dependencies
Stage 4 (metrics infrastructure must exist), `scripts/simulate.py` (done)

---

## Stage 7: Perpetual Autonomous Validation

**Goal:** `/otherness.run` is perpetually self-sustaining. It always knows what to
do next, always knows whether it is on track, and surfaces to the human only when
it genuinely cannot determine either without external judgment. The system derives
its own validation criteria from its own design docs and simulation. "Done" is not
declared — it is derived.

This is not a feature added to otherness. It is the completion of what otherness
was always trying to become.

### Deliverables
- PM §5g: simulation health score — GREEN / AMBER / RED computed from real vs
  simulated completion rate and arch_convergence; not declared, derived
- PM self-correction on AMBER — automatically queues one `/otherness.learn` cycle;
  does not escalate to human yet
- Dynamic definition-of-done — PM §5b extends static journeys with criteria
  derived from current design doc Present/Future ratio
- Perpetual loop trigger — standalone.md STOP CONDITION: all journeys GREEN AND
  health score GREEN AND no unstarted Future items → standby; otherwise restart
- Self-generating validation criteria — PM derives candidate journeys from shipped
  Present items; proposes to human once; added permanently after confirmation
- Standby mode — when all criteria met, system checks daily for new Future items
  from vibe-vision sessions or self-generating proposals; restarts on finding any

### What "perpetual" means
The human does not restart the loop. The human does not define success.
The human does not monitor batches. The human re-enters only when:
1. Health score RED for 3 consecutive batches (genuine stall)
2. The system has a vision fork it cannot resolve (design decision required)
3. The system is in standby and the human has new intent to express

Between those moments: the system runs, ships, calibrates, self-corrects,
and advances the project on its own.

### The threshold for "Stage 7 is working"
The system completes 10 consecutive batches without human intervention,
self-corrects at least one AMBER signal autonomously, and correctly enters
standby when no Future items remain — then restarts when new ones are added
via a vibe-vision session.

### Dependencies
Stage 6 (simulation calibration must be active)
