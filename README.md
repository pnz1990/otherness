# otherness

_in memory of mankind_

<!-- D4 logo goes here -->

**D4** — Declarative Design-Driven Development.

You declare the vision. The design follows. The implementation follows the design. Repeat.

otherness writes the code, reviews it, ships it, and keeps going — without you in the loop. No stand-ups, no PR reviews, no release ceremonies. Just a GitHub repo advancing on its own.

We are not there yet. But every session gets closer.

---

## The D4 model

Every feature on every project follows the same hierarchy. No exceptions.

```
vision.md          you write this once
    ↓
roadmap.md         stages of delivery
    ↓
docs/design/       how each area works — written before implementation
    ↓
spec.md            one item, one PR — references its design doc
    ↓
code               the implementation, nothing more
    ↓
design doc update  🔲 Future → ✅ Present, in the same PR
```

The agent enforces this structurally:
- QA blocks any PR whose spec is missing a `## Design reference`
- The coordinator reads `🔲 Future` items in design docs as its primary work queue
- The PM flags any roadmap stage that has no `docs/design/` file

The result: every line of code is traceable to a design that existed before it was written.

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
| `/otherness.run` | Start the autonomous team loop (coordinator → engineer → QA → SM → PM → repeat) |
| `/otherness.run.bounded` | Scoped agent with declared boundaries — run multiple concurrently |
| `/otherness.status [--fleet]` | What the agent is working on, CI state, open blockers; `--fleet` for all monitored projects |
| `/otherness.learn [repo ...]` | Study open-source projects and internalize patterns into skills |
| `/otherness.upgrade` | Check for updates to internal dependencies |
| `/otherness.arch-audit` | Architectural audit — checks docs vs source, finds drift and structural issues |
| `/otherness.cross-agent-monitor` | Cross-project health monitor — heartbeat, velocity, blockers across all monitored repos |

---

## Setup

```bash
# 1. Once per machine
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

If something goes wrong, see **[RECOVERY.md](./RECOVERY.md)** — how to stop, reset, and clean up.

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

**[speckit](https://github.com/github/spec-kit)** — optional: if you already use speckit in your project, it can manage `.opencode/command/` deployment. Not required — `/otherness.setup` deploys command files directly via `cp`.

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
