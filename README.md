# otherness

_The goal is simple: software that builds itself._

You write the vision. otherness writes the code, reviews it, ships it, and keeps going — without you in the loop. No stand-ups, no PR reviews, no release ceremonies. Just a GitHub repo advancing on its own.

We are not there yet. But every session gets closer.

---

## What it does today

One session is an entire engineering team. It claims work from your backlog, implements it in an isolated branch, adversarially reviews its own PR, runs CI, merges, and moves to the next item. It also acts as scrum master and product manager — writing batch reports, tracking metrics, validating that the project is moving in the right direction.

The human's role: write the vision, read the reports, unblock the rare `[NEEDS HUMAN]`.

otherness runs on itself. Every improvement it makes to its own agent logic deploys to every project using it on their next session startup.

---

## Two modes

| Mode | Command | When to use |
|---|---|---|
| **Standalone** | `/otherness.run` | One session is the full team — coordinates, implements, reviews, releases |
| **Bounded** | `/otherness.run.bounded` | Scoped agent with declared boundaries — run multiple concurrently |

## Quick start

```bash
# Prerequisites: OpenCode, gh CLI, git, python3
npm install -g @opencode-ai/cli
brew install gh && gh auth login
git clone git@github.com:pnz1990/otherness.git ~/.otherness
uv tool install specify-cli && specify extension add maqa

# New project — from your project directory
/otherness.setup   # creates otherness-config.yaml, deploys commands
/otherness.run     # the agent reads your project, generates a backlog, starts working
```

That's it. The agent reads `AGENTS.md` and `docs/aide/`, generates a queue from your roadmap, and starts working. For an existing project with code already written, use `/otherness.onboard` first — it reads the codebase and generates the `docs/aide/` files automatically.

---

**Utility commands** (run once, not in a loop):

| Command | Purpose |
|---|---|
| `/otherness.setup` | One-time project init — creates config, deploys all commands |
| `/otherness.onboard` | Existing project — reads the codebase, generates `docs/aide/` drafts, seeds state |
| `/otherness.status` | What the agent is working on, CI state, open blockers |
| `/otherness.learn [repo ...]` | Study open-source projects and internalize patterns into skills |
| `/otherness.upgrade` | Check for updates to internal dependencies |

---

## Setup

```bash
# 1. Once per machine
uv tool install specify-cli
specify extension add maqa
gh auth login
git clone git@github.com:<your-username>/otherness.git ~/.otherness

# 2. New project
/otherness.setup

# 2b. Existing project
/otherness.onboard
# Review and merge the generated PR, then:

# 3. Run
/otherness.run
```

See **[onboarding-new-project.md](./onboarding-new-project.md)** and **[onboarding-existing-project.md](./onboarding-existing-project.md)** for full walkthroughs.

---

## Dependencies

### Required

**[OpenCode](https://opencode.ai)** — the AI coding agent runtime. Discovers `.opencode/command/*.md` files and exposes them as slash commands. Provides the Bash, Read, Write, Edit, Glob, Grep tools the agents use. otherness is tested with OpenCode only.

```bash
npm install -g @opencode-ai/cli
```

**[gh CLI](https://cli.github.com)** — all GitHub interaction: PR lifecycle, issue management, Projects board, CI status. GitHub is otherness's single source of truth.

```bash
brew install gh && gh auth login
```

**[git](https://git-scm.com)** — VCS, worktree isolation per feature branch, and the self-update mechanism (`git -C ~/.otherness pull` on every startup).

**[python3](https://python.org)** — config parsing (`otherness-config.yaml`) and state read/write (`.otherness/state.json`). Standard library only. 3.8+ required.

### Internal dependencies (managed by otherness, not you)

**[speckit](https://github.com/github/spec-kit)** — deploys `.opencode/command/*.md` files into your project. Called once by `/otherness.setup`, never at runtime.

```bash
uv tool install specify-cli
```

**[MAQA](https://github.com/GenieRobot/spec-kit-maqa-ext)** — entry-point shells and `state.json` conventions that otherness reads and writes.

**[aide](https://github.com/mnriem/spec-kit-extensions)** — work item generation from the roadmap. Called internally when the queue is empty.

### Optional

**[muse](https://github.com/ellistarn/muse)** — a distillation of how you specifically think, derived from your AI conversation history. Steers the agent to make decisions you'd agree with rather than generic ones. Recompose periodically as your thinking evolves.

```bash
go install github.com/ellistarn/muse@latest
muse compose
# Add to ~/.config/opencode/opencode.json:
# { "instructions": ["~/.muse/muse.md"] }
```

---

## How it fits together

```
Your project
  otherness-config.yaml         ← the only file you edit
  .otherness/state.json         ← team state (on _state branch)
  .opencode/command/
    otherness.run.md            ← /otherness.run
    otherness.run.bounded.md    ← /otherness.run.bounded
    otherness.onboard.md
    otherness.status.md
    otherness.setup.md
    otherness.upgrade.md
    otherness.learn.md

~/.otherness/                   ← shared, auto-updated on every startup
  agents/standalone.md          ← full autonomous team logic
  agents/bounded-standalone.md
  agents/onboard.md
  agents/otherness.learn.md
  agents/gh-features.md
  agents/skills/                ← reusable patterns, grown by /otherness.learn
```

---

## Running bounded sessions concurrently

```
Session 1: /otherness.run.bounded
           AGENT_NAME=Refactor Agent
           AGENT_ID=STANDALONE-REFACTOR
           SCOPE=Fix logic leaks in the health and auth packages
           ALLOWED_AREAS=area/health,area/auth
           ALLOWED_MILESTONES=v1.1.0
           ALLOWED_PACKAGES=pkg/health,pkg/auth
           DENY_PACKAGES=cmd/myapp,api/v1

Session 2: /otherness.run.bounded
           AGENT_NAME=CLI Agent
           AGENT_ID=STANDALONE-CLI
           SCOPE=CLI commands and output formatting
           ALLOWED_AREAS=area/cli
           ALLOWED_MILESTONES=v1.1.0
           ALLOWED_PACKAGES=cmd/myapp
           DENY_PACKAGES=pkg/core
```

Each session posts hourly updates to its own `[AGENT_NAME] Progress Log` GitHub issue.

---

## Observability

| What you want | Where |
|---|---|
| What's being worked on | Projects → Sprint board |
| Full backlog | Projects → Backlog |
| Release progress | GitHub Milestones |
| What shipped | GitHub Releases |
| Agent reports | Issue #REPORT_ISSUE |
| Per-agent progress | Each agent's Progress Log issue |
| Blocking decisions | Issues labeled `needs-human` |

---

## Updating the agents

Push to this repo. Every session self-updates via `git -C ~/.otherness pull` on startup.
