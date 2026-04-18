# otherness: Vision

> Created: 2026-04-14 | Status: Active

## The goal

Software that builds itself. You write what you want. The system figures out how to build it, does the work, ships it, and keeps going.

That is the destination. otherness is the path toward it.

## What otherness is today

otherness is an autonomous software development system. One session plays the roles of coordinator, engineer, adversarial QA, scrum master, and product manager — in sequence, in a loop, without human input between cycles.

It reads a project's `AGENTS.md`, `docs/aide/`, and `state.json`. Then it loops: claims work from the backlog, implements it in an isolated branch, reviews its own PR with genuine skepticism, runs CI, merges, and moves to the next item. The PM phase checks that the work is moving in the right direction. The SM phase tracks metrics and spots regressions.

The human's role: write the vision, read the batch reports, unblock the rare `[NEEDS HUMAN]` escalation. Nothing else.

## What makes otherness different

Every AI coding tool that existed before this assists a human. The human still owns the loop — they decide what to build next, review every PR, trigger releases. The AI is a tool in a human process.

otherness eliminates the human from the execution loop. The human defines intent. The system executes. This is a different model of software delivery, not an incremental improvement on AI-assisted development.

The mechanism is deliberately simple: markdown instruction files, read by an AI coding agent. No compiled binary. No server. No database. Hackable by anyone with a text editor. Deployed with a `git clone`.

## The self-improvement loop

otherness runs on itself. The system that builds software is built by that same system.

Every improvement to otherness — a sharper QA checklist, a new skill learned from open-source, a better spec quality standard — deploys to every project using otherness on their next session startup, via `git -C ~/.otherness pull`.

The target: otherness improves itself faster than humans can improve it manually. We are not there yet. But every merged PR to this repo is a step toward it.

## Design decisions that will not change

**Markdown instructions, not code.** The agents are `.md` files. OpenCode runs them. This makes the system inspectable, forkable, and improvable by anyone — no build toolchain required.

**GitHub as the only external system.** All coordination, state, progress reporting, and delivery goes through GitHub. No Slack, no Jira, no custom dashboard. If it's not in GitHub, it doesn't exist.

**`~/.otherness` as a shared global install.** Every project on a machine shares the same agent files. Self-update on startup is the deployment mechanism. Simple to operate, instant to update.

**Branch-push as the distributed lock.** Parallel sessions don't collide because git's server-side ref update is atomic. No coordinator, no lock file, no heartbeat election needed.

**The codebase reflects only what is Present or Future.** Every file, function, and configuration in a project managed by otherness must correspond to either a ✅ Present item in a design doc (it was built intentionally and is documented) or a 🔲 Future item (it is being built toward). Code that exists with no corresponding design doc entry is a defect — not a style issue, a correctness issue. The SM phase surfaces unaccounted-for code as candidates for removal or documentation. Nothing is deleted autonomously; the human decides. But the accumulation of undocumented code is treated as drift from the design, and drift is always surfaced.

**State on `_state` branch, code on `main`.** This prevents merge conflicts between parallel sessions doing code work and state writes simultaneously.

## Current state

- Core loop (`standalone.md`): stable, in production on multiple reference projects
- Skills system: growing via `/otherness.learn`
- Self-improvement: active as of 2026-04-14
- Global deployment model (Option A): a CRITICAL tier regression affects all users immediately. Mitigated by the human review gate on CRITICAL files. Future Option B (versioned releases) documented in AGENTS.md for when the user base grows.

## What the simulation proved (2026-04-17)

`scripts/simulate.py` models N parallel agents with three-force boldness dynamics.
Running the falsification suite produced four findings that are now architectural facts,
not hypotheses:

**The skills library is the only force that matters long-term.** Remove skill growth
and the system converges to near-zero boldness regardless of how many agents run or
how often the human re-enters. Every other force — decay, Type B jumps, human
engagement — is secondary. A session that ships work but doesn't add to `agents/skills/`
is burning fuel without building the engine.

**Human re-entry is a recovery mechanism, not a growth driver.** The system reaches
the same boldness ceiling at engagement=0.0 as at engagement=0.7. At engagement=1.0
it actually performs slightly worse. The human should re-enter rarely — only when the
system has genuinely stalled, not on a schedule.

**Type B failures (disproved predictions) matter most in cycles 1–40.** After that,
skill growth dominates and the long-run ceiling is the same with or without them.
Adversarial review is most valuable early in a project's life. Front-load it.

**Monoculture is architectural, not skill-based.** The simulation could not surface
the predicted monoculture dynamic because all agents share `standalone.md` — the same
reasoning framework — regardless of how diverse their skill sets are. Skill diversity
is not conceptual diversity. The only mechanism that breaks architectural monoculture
today is `/otherness.learn` importing genuinely foreign patterns. This is the most
important investment for the system's long-term compounding.

## The simulation as anchor

The simulation (`scripts/simulate.py`) is not a research artifact. It is the
instrument by which otherness understands itself and calibrates its behavior.

The relationship between simulation and reality works in two directions:

**Reality calibrates simulation.** otherness's batch history (`docs/aide/metrics.md`)
is used to find simulation parameters that match observed behavior. When the
simulation's completion rate matches real PRs per batch, the parameters mean
something. Those calibrated parameters ship as defaults to every project via
`~/.otherness`.

**Simulation anchors reality.** Once calibrated, the simulation predicts what
healthy behavior looks like for a given project. When real behavior diverges from
simulation — when actual Type B rate drops below the simulated floor, when
arch_convergence signals frame-lock — the SM phase surfaces this as a signal
requiring human attention. The simulation is the early-warning system.

This is how the system knows when it's stuck before the human notices.
This is how every project using otherness benefits from what otherness learned
on itself. This is the propagation chain: observation → calibration → defaults →
inheritance → per-project re-calibration → fleet intelligence.

The simulation becomes the anchor not when it runs — it already runs. It becomes
the anchor when its output changes how agents behave. That is Stage 6.

## What "done" looks like

otherness is never done. It is a living system that improves continuously. The benchmark for "good enough to stop manually maintaining":

1. otherness ships at least one improvement to itself per week without human prompting
2. Reference projects continue advancing without human intervention
3. `/otherness.learn` discovers and internalizes at least one new pattern per month autonomously
4. The PM validation scenarios all pass: reference projects alive, skills growing, docs matching behavior
5. The simulation runs automatically, stays calibrated against real batch data, and its arch-convergence signal has correctly predicted at least one genuine stall — surfaced to the human before they noticed it themselves
