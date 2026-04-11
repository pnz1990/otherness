# otherness

_In memory of mankind_

Autonomous SDLC agent layer. Runs a full software development team — coordinator, engineers, QA, Scrum Master, Product Manager — without human involvement. Built on top of [speckit](https://github.com/github/spec-kit) and the [MAQA extension](https://github.com/GenieRobot/spec-kit-maqa-ext).

## Why this exists

Most AI coding tools assist a human developer. otherness replaces the team loop entirely: from product spec to merged PR, batch audit, release cut, and next queue generation — all autonomous. The human's role is to define the vision, read the reports, and unblock the rare `[NEEDS HUMAN]` escalation.

The goal is **100% autonomous project management and execution**, with full observability through GitHub's native project management features — milestones, epics, sub-issues, boards, labels, releases. No external dashboards. No separate tracking tools. GitHub is the single source of truth, maintained perfectly because agents have no reason to cut corners.

## How it fits the dependency stack

```
speckit                     — spec authoring, memory, templates, slash commands
  └── MAQA extension        — multi-agent queue management, state machine, CI gates
        └── otherness       — role definitions, loops, GitHub PM integration, release protocol
              └── project   — vision, roadmap, AGENTS.md, maqa-config.yml (project-specific)
```

**speckit** provides the spec lifecycle: `create-queue`, `create-item`, `verify-tasks`, `analyze`, `memorylint`. It is project-agnostic and has no concept of roles or teams.

**MAQA** adds the execution layer: state.json, engineer slots, CI gating, QA review loop. It defines the state machine but not the behavior of each role.

**otherness** is the behavioral layer on top: it defines what the coordinator, engineer, QA, SM, and PM actually *do* — how they use GitHub Projects, milestones, epics, sub-issues, labels, releases, and the board. It is generic across projects but opinionated about process.

**The project** provides only what is project-specific: vision, roadmap, AGENTS.md (build commands, PR label, report issue, label taxonomy), maqa-config.yml (agents path, test command, mode), and github-projects-config.yml (board field IDs).

## What agents do autonomously

- Generate work queues from roadmap stages
- Implement features with TDD in isolated git worktrees
- Open PRs, monitor CI, conduct adversarial QA review, merge
- Create and maintain GitHub Issues with full label taxonomy (kind, area, priority, size)
- Link issues as sub-issues of milestone epics
- Sync board cards (Status, Team, Priority, Size, Target date) on every state transition
- Run SDLC health reviews and apply minor process improvements
- Run product reviews: vision alignment, doc freshness, competitive analysis
- Manage GitHub milestones: create, populate backlog, track progress
- Cut GitHub releases when a milestone's open issues reach zero and journeys pass
- Self-update from this repo on every session startup — process improvements propagate automatically

## Observability

Everything surfaces in GitHub without any external tooling:

| What you want to know | Where to look |
|---|---|
| What is being worked on right now | Projects → 🏃 Sprint board |
| Overall product plan and epic progress | Projects → 🗺️ Roadmap (Epics) |
| Full backlog by milestone | Projects → 📋 Backlog |
| How close is the next release | GitHub Milestones page |
| What shipped and when | GitHub Releases |
| Team health and process metrics | Issue #REPORT_ISSUE — batch reports in comments |
| Blocking decisions needed | Issues labeled `needs-human` |

## Future integration points

**GitHub native agent sessions** (March 2026 feature): GitHub now shows live agent session status (queued / working / waiting for review / completed) directly in issue sidebars and project board views when agents are assigned via the `agentAssignment` API. Currently requires GitHub Copilot's native agent model — otherness sessions are external (local OpenCode). When GitHub exposes this for external agent sessions via API or webhook, otherness will integrate to surface live session status natively in the board without any polling or comment-based workarounds. Tracked at: https://github.com/orgs/community/discussions/190731

## Agent files

```
agents/
  coordinator.md        continuous coordinator loop — assigns work, syncs board, runs batch audits
  engineer.md           feature engineer — TDD, PR, CI monitoring, merge
  qa-watcher.md         continuous PR reviewer — polls open PRs, adversarial review
  scrum-master.md       one-shot per batch — SDLC health, flow metrics, process improvements
  product-manager.md    one-shot per batch — vision, milestones, epics, backlog, releases
  standalone.md         single session — plays all roles sequentially, one item at a time
  gh-features.md        reference — GitHub fields, label taxonomy, sub-issue protocol
maqa-config-template.yml    copy to project root as maqa-config.yml
```

Agent files live outside any git repo (`~/.otherness/`) so all worktrees on all branches always read the latest version. Every agent self-updates from this repo on startup — push an improvement here and every running session picks it up on its next cycle.

## Prerequisites

- [speckit](https://github.com/github/spec-kit): `uv tool install specify-cli`
- MAQA extension: `specify extension add maqa`
- GitHub CLI: `gh auth login`

## New project setup

See **[onboarding-new-project.md](./onboarding-new-project.md)** for the full guide including:
- All required project files and their expected content
- GitHub board setup with field IDs
- Label taxonomy to create
- Minimum viable file set

**Quick start:**

```bash
# 1. Clone otherness once per machine
git clone git@github.com:pnz1990/otherness.git ~/.otherness

# 2. In your project repo
cp ~/.otherness/maqa-config-template.yml maqa-config.yml
# Edit AGENTS.md, docs/aide/, .specify/memory/, maqa-github-projects/
# (see onboarding-new-project.md for required content)

# 3. Run
/speckit.maqa.standalone
```

## Existing project setup

See **[onboarding-existing-project.md](./onboarding-existing-project.md)** for the full guide including:
- How to describe what already exists so agents don't re-implement it
- Seeding state.json with completed items
- Mapping existing issues/milestones to otherness taxonomy
- Common mistakes and how to avoid them

## Updating the process

Edit files in `~/.otherness/agents/` and push to this repo. Every agent picks up changes on next startup — no restarts, no rebases, no version bumps in consuming projects.
