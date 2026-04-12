# otherness

_In memory of mankind_

Autonomous software development. One session is an entire team.

Built on top of [speckit](https://github.com/github/spec-kit) and the [MAQA extension](https://github.com/GenieRobot/spec-kit-maqa-ext).

---

## Two modes, that's it

| Mode | Command | When to use |
|---|---|---|
| **Standalone** | `/speckit.maqa.standalone` | Full autonomous team — coordinates, implements, reviews, releases |
| **Bounded** | `/speckit.maqa.bounded-standalone` | Focused agent with a declared scope — multiple can run concurrently |

No coordinator. No engineer. No QA. No separate sessions. Each standalone *is* the team.

---

## Why this exists

Most AI coding tools assist a human. otherness replaces the team loop entirely. The human's role: define the vision, read the hourly reports, unblock the rare `[NEEDS HUMAN]`.

The goal: **100% autonomous project management and execution**, observable through GitHub — milestones, epics, sub-issues, boards, labels, releases. No external dashboards.

---

## How it fits the stack

```
speckit         — spec authoring, memory, templates, slash commands
  └── MAQA      — state machine, CI gates, queue management
        └── otherness — role behavior, GitHub PM integration, release protocol
              └── project — AGENTS.md, maqa-config.yml, vision, roadmap
```

---

## Agent files

```
agents/
  standalone.md           full autonomous team (unbounded)
  bounded-standalone.md   scoped agent — boundary injected in prompt
  gh-features.md          reference: GitHub fields, label taxonomy, sub-issues
```

---

## Prerequisites

```bash
uv tool install specify-cli    # speckit
specify extension add maqa     # MAQA extension
gh auth login                  # GitHub CLI
git clone git@github.com:pnz1990/otherness.git ~/.otherness
```

---

## New project setup

See **[onboarding-new-project.md](./onboarding-new-project.md)** — all required files with templates.

```bash
cp ~/.otherness/maqa-config-template.yml maqa-config.yml
# Edit AGENTS.md, docs/aide/, .specify/memory/
/speckit.maqa.standalone
```

## Existing project

See **[onboarding-existing-project.md](./onboarding-existing-project.md)** — seed state.json with done items, describe existing code accurately.

---

## Running bounded sessions concurrently

Each bounded session declares its scope in the prompt. Multiple sessions work on different areas simultaneously without conflicts:

```
Session 1: /speckit.maqa.bounded-standalone
           AGENT_NAME=Refactor Agent
           AGENT_ID=STANDALONE-REFACTOR
           SCOPE=Fix logic leaks in reconcilers
           ALLOWED_AREAS=area/controller,area/health
           ALLOWED_MILESTONES=v0.2.1
           ALLOWED_PACKAGES=pkg/reconciler,pkg/health
           DENY_PACKAGES=cmd/myapp,api/v1alpha1

Session 2: /speckit.maqa.bounded-standalone
           AGENT_NAME=CLI Agent
           AGENT_ID=STANDALONE-CLI
           SCOPE=CLI commands and output formatting
           ALLOWED_AREAS=area/cli
           ALLOWED_MILESTONES=v0.2.1
           ALLOWED_PACKAGES=cmd/myapp
           DENY_PACKAGES=pkg/reconciler
```

Each session creates its own `[AGENT_NAME] Progress Log` GitHub issue with hourly updates.

---

## Observability

| What you want | Where |
|---|---|
| What's being worked on | Projects → Sprint board |
| Product roadmap | Projects → Roadmap (Epics) |
| Full backlog | Projects → Backlog |
| Next release progress | GitHub Milestones |
| What shipped | GitHub Releases |
| Team health | Issue #REPORT_ISSUE |
| Per-agent progress | Each agent's Progress Log issue |
| Blocking decisions | Issues labeled `needs-human` |

---

## Future: GitHub native agent sessions

GitHub now shows live agent session status in project boards via `agentAssignment` API. Currently requires GitHub Copilot's native model — otherness sessions are external. When GitHub exposes this for external agents, otherness will integrate automatically.
Tracked: https://github.com/orgs/community/discussions/190731

---

## Updating the process

Push to this repo. Every agent self-updates on next startup.
