# otherness

_In memory of mankind_

Autonomous software development. One session is an entire team.

---

## Two modes, that's it

| Mode | Command | When to use |
|---|---|---|
| **Standalone** | `/otherness.run` | Full autonomous team — coordinates, implements, reviews, releases |
| **Bounded** | `/otherness.run.bounded` | Focused agent with a declared scope — multiple can run concurrently |

No coordinator. No engineer. No QA. No separate sessions. Each standalone *is* the team.

**Utility commands** (run once, not in a loop):

| Command | When to use |
|---|---|
| `/otherness.onboard` | First time on an existing project — reads the codebase, generates `docs/aide/` drafts, seeds `state.json` from merged PRs, opens a PR for review |
| `/otherness.status` | Check what the agent is currently working on, CI state, and open blockers |
| `/otherness.setup` | One-time project init — creates `otherness-config.yaml`, deploys all commands |

---

## Why this exists

Most AI coding tools assist a human. otherness replaces the team loop entirely. The human's role: define the vision, read the hourly reports, unblock the rare `[NEEDS HUMAN]`.

The goal: **100% autonomous project management and execution**, observable through GitHub — milestones, epics, sub-issues, boards, labels, releases. No external dashboards.

---

## Dependencies

### Required

#### [OpenCode](https://opencode.ai)

**What it provides:** The AI coding agent runtime. OpenCode discovers `.opencode/command/*.md` files in your project and exposes them as slash commands. When you type `/otherness.run`, OpenCode loads that file and sends its body as the LLM prompt. It also provides the Bash, Read, Write, Edit, Glob, Grep tools the agent uses to interact with your filesystem and run commands.

**Why it's required:** OpenCode is the runtime that executes the agents. Without it there is no command dispatch. The agents are markdown files — OpenCode is what runs them.

**Tested with:** OpenCode only. Claude Code support is planned but not yet implemented.

```bash
# Install OpenCode
npm install -g @opencode-ai/cli   # or see https://opencode.ai
```

#### [gh CLI](https://cli.github.com)

**What it provides:** All GitHub interaction. Agents use it for the complete PR lifecycle (create, CI check, merge), issue management (create, list, close, comment), Projects board updates (card status, field values), GraphQL API calls (sub-issues, board items), and CI status monitoring.

**Why it's required:** GitHub is otherness's single source of truth. Every coordination action — finding work, claiming issues, opening PRs, posting progress reports, syncing the board — calls `gh`. There is no alternative path.

```bash
brew install gh && gh auth login
```

#### [git](https://git-scm.com)

**What it provides:** VCS operations and the multi-worktree isolation model. Agents use `git worktree add` to create an isolated working directory for each feature, push branches for PRs, and use `git -C ~/.otherness pull` to self-update agent files from this repo on every startup.

**Why it's required:** The self-update mechanism, repo detection (`git remote get-url`, `git rev-parse`), feature branch isolation (`git worktree`), and all code delivery (`git push`) depend on git.

#### [python3](https://python.org)

**What it provides:** Inline YAML parsing and JSON read/write. Agents use it exclusively to parse `otherness-config.yaml` and read/write `.otherness/state.json`. Only standard library modules are used (`re`, `json`, `os`, `datetime`). No pip packages required.

**Why it's required:** Config parsing and state management. Failures are wrapped in `2>/dev/null` fallbacks so the agent degrades gracefully rather than crashing.

```bash
python3 --version  # 3.8+ required; usually pre-installed
```

---

### Soft Required (deploy-time only)

These are **otherness's internal dependencies** — customers never install or interact with them directly. otherness owns their versioning and upgrade cycle.

#### [speckit](https://github.com/github/spec-kit)

**What it provides:** The command infrastructure. speckit deploys the `.opencode/command/*.md` files into your project. otherness wraps speckit completely — customers only see `otherness.*` commands.

**Why soft required:** The speckit CLI binary is not called at runtime. It is required once per project to bootstrap the internal command files. otherness manages this via `/otherness.setup`.

```bash
uv tool install specify-cli    # or: pip install specify-cli
```

#### [MAQA extension](https://github.com/GenieRobot/spec-kit-maqa-ext)

**What it provides:** Entry-point shells and `.otherness/state.json` conventions that otherness reads and writes. otherness is built *on top of* MAQA — it adds the actual agent behavior (loops, roles, GitHub PM) that MAQA's shells redirect to.

#### [aide extension](https://github.com/mnriem/spec-kit-extensions)

**What it provides:** Queue and work item generation from the roadmap. otherness calls aide internally when `current_queue` is null. Customers never call aide directly.

---

## How it fits the stack

```
Customer project
  └── otherness-config.yaml       ← only file the customer edits
  └── .otherness/
        state.json                ← team state (on _state branch)
  └── .opencode/command/
        otherness.run.md          ← /otherness.run  (autonomous loop)
        otherness.run.bounded.md  ← /otherness.run.bounded (scoped loop)
        otherness.onboard.md      ← /otherness.onboard (existing project setup)
        otherness.status.md       ← /otherness.status (inspect state)
        otherness.setup.md        ← /otherness.setup (one-time init)
        otherness.upgrade.md      ← /otherness.upgrade (check dep updates)

~/.otherness/ (private, auto-updated on every agent startup)
  └── agents/standalone.md        ← full autonomous team logic
  └── agents/bounded-standalone.md
  └── agents/onboard.md           ← existing project onboarding logic
  └── agents/gh-features.md
```

---

## Agent files

```
agents/
  standalone.md           full autonomous team (unbounded)
  bounded-standalone.md   scoped agent — boundary injected in prompt
  onboard.md              one-shot existing project onboarding
  gh-features.md          reference: GitHub fields, label taxonomy, sub-issues
```

---

## Setup

```bash
# 1. Once per machine
uv tool install specify-cli
specify extension add maqa
gh auth login
git clone git@github.com:<your-username>/otherness.git ~/.otherness

# 2. Once per project (new project)
/otherness.setup                  # creates otherness-config.yaml, deploys commands

# 2b. Once per project (existing project with code)
/otherness.onboard                # reads codebase → generates docs/aide/ drafts + state.json → opens PR
# Review and merge the PR, then:

# 3. Run
/otherness.run                    # unbounded: one session, full team
/otherness.run.bounded            # bounded: inject scope in prompt

# Inspect at any time
/otherness.status                 # what's in progress, CI state, open blockers
```

See **[onboarding-new-project.md](./onboarding-new-project.md)** for full new project setup.
See **[onboarding-existing-project.md](./onboarding-existing-project.md)** for adopting otherness into an existing codebase.

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

Each session creates its own `[AGENT_NAME] Progress Log` GitHub issue with hourly updates.

---

## Observability

| What you want | Where |
|---|---|
| What's being worked on | Projects → Sprint board |
| Full backlog by milestone | Projects → Backlog |
| Next release progress | GitHub Milestones |
| What shipped | GitHub Releases |
| Agent reports | Issue #REPORT_ISSUE |
| Per-agent progress | Each agent's `[Name] Progress Log` issue |
| Blocking decisions | Issues labeled `needs-human` |

---

## Upgrading dependencies

otherness owns the version pins for speckit, maqa, and aide. To check for updates and apply them:

```bash
/otherness.upgrade
```

This checks the community catalog for new speckit/extension versions, shows a changelog diff, and applies updates with your confirmation. Customers never run this — it's a dev/maintainer command.

---

## Updating the process

Push to this repo. Every agent self-updates on next startup via `git -C ~/.otherness pull`.
