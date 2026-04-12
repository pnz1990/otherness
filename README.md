# otherness

_In memory of mankind_

Autonomous software development. One session is an entire team.

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

## Dependencies

### Required

#### [OpenCode](https://opencode.ai)

**What it provides:** The AI coding agent runtime. OpenCode discovers `.opencode/command/*.md` files in your project and exposes them as slash commands. When you type `/speckit.maqa.standalone`, OpenCode loads that file and sends its body as the LLM prompt. It also provides the Bash, Read, Write, Edit, Glob, Grep tools the agent uses to interact with your filesystem and run commands.

**Why it's required:** OpenCode is the runtime that executes the agents. Without it there is no `/speckit.*` dispatch. The agents are markdown files — OpenCode is what runs them.

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

**What it provides:** Inline YAML parsing and JSON read/write. Agents use it exclusively to parse config files (`AGENTS.md`, `maqa-config.yml`, `github-projects-config.yml`) and read/write `.maqa/state.json`. Only standard library modules are used (`re`, `json`, `os`, `datetime`). No pip packages required.

**Why it's required:** Config parsing and state management. Failures are wrapped in `2>/dev/null` fallbacks so the agent degrades gracefully (empty config values) rather than crashing — but core functionality will be missing without it.

```bash
python3 --version  # 3.8+ required; usually pre-installed
```

---

### Soft Required (deploy-time only)

#### [speckit](https://github.com/github/spec-kit)

**What it provides:** The command infrastructure. speckit deploys the `.opencode/command/*.md` files (the entry-point commands) and the `.specify/` directory structure into your project. It also provides optional spec-lifecycle commands (`/speckit.aide.create-queue`, `/speckit.aide.create-item`, `/speckit.verify-tasks.run`, `/speckit.analyze`, `/speckit.worktree.*`) that agents call for queue generation and spec analysis.

**Why soft required:** The speckit CLI binary is not called at runtime — what matters are the files it deployed. If those files already exist in your project (they will after `specify extension add maqa`), speckit itself does not need to be installed on the machine where agents run. It is required once per project to bootstrap the command files.

```bash
uv tool install specify-cli    # or: pip install specify-cli
```

#### [MAQA extension](https://github.com/GenieRobot/spec-kit-maqa-ext)

**What it provides:** The entry-point command files for otherness — specifically `speckit.maqa.standalone` and `speckit.maqa.bounded-standalone`. These are thin shells that read `agents_path` from `maqa-config.yml` and redirect to the actual agent files in `~/.otherness/agents/`. MAQA also defines the `maqa-config.yml` schema and the `.maqa/state.json` conventions that otherness reads and writes.

**Why soft required:** MAQA is the deploy vehicle for the command files. Once deployed (via `specify extension add maqa`), the files are static and MAQA does not need to be present at runtime. otherness is built *on top of* MAQA — it adds the actual agent behavior (loops, roles, GitHub PM) that MAQA's shells redirect to.

```bash
specify extension add maqa
```

#### [aide extension](https://github.com/mnriem/spec-kit-extensions)

**What it provides:** Queue and work item generation. When `current_queue` is null (new project or after all items are done), the standalone agent calls `/speckit.aide.create-queue` and `/speckit.aide.create-item` to bootstrap the next batch of work from the roadmap. aide reads `docs/aide/vision.md`, `docs/aide/roadmap.md`, and `docs/aide/progress.md` to determine what to build next.

**Why conditionally required:** Only needed when generating a new queue. For projects that already have populated queue files, aide is not called. For new projects, it is the mechanism that translates the roadmap into implementable items.

```bash
specify extension add aide   # if not already installed
```

---

## How it fits the stack

```
OpenCode         — agent runtime (executes .md files as LLM prompts, provides tools)
  └── speckit    — deploys command files, spec lifecycle commands
        └── MAQA — entry-point commands (speckit.maqa.*) + maqa-config.yml schema
              └── otherness — actual agent loops, GitHub PM, release protocol
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

## Setup

```bash
# 1. Once per machine
uv tool install specify-cli
specify extension add maqa
gh auth login
git clone git@github.com:<your-username>/otherness.git ~/.otherness

# 2. Once per project
cp ~/.otherness/maqa-config-template.yml maqa-config.yml
# Edit AGENTS.md and docs/aide/ — see onboarding-new-project.md

# 3. Run
/speckit.maqa.standalone          # unbounded: one session, full team
/speckit.maqa.bounded-standalone  # bounded: inject scope in prompt
```

See **[onboarding-new-project.md](./onboarding-new-project.md)** for full setup.
See **[onboarding-existing-project.md](./onboarding-existing-project.md)** for adopting otherness into an existing codebase.

---

## Running bounded sessions concurrently

```
Session 1: /speckit.maqa.bounded-standalone
           AGENT_NAME=Refactor Agent
           AGENT_ID=STANDALONE-REFACTOR
           SCOPE=Fix logic leaks in health and scm packages
           ALLOWED_AREAS=area/health,area/scm
           ALLOWED_MILESTONES=v0.2.1
           ALLOWED_PACKAGES=pkg/health,pkg/scm
           DENY_PACKAGES=cmd/myapp,api/v1

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
| Agent reports | Issue #REPORT_ISSUE |
| Per-agent progress | Each agent's `[Name] Progress Log` issue |
| Blocking decisions | Issues labeled `needs-human` |

---

## Future

**Claude Code support** — currently tested with OpenCode only. Adding Claude Code support (`.claude/commands/`) is planned for a future session.

**GitHub native agent sessions** — GitHub now shows live agent session status in project boards via `agentAssignment` API. Currently requires GitHub Copilot's native model — otherness sessions are external. When GitHub exposes this for external agents, otherness will integrate automatically.
Tracked: https://github.com/orgs/community/discussions/190731

---

## Updating the process

Push to this repo. Every agent self-updates on next startup via `git -C ~/.otherness pull`.
