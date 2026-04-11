# Onboarding: New Project

This guide walks through setting up otherness on a **brand new project** — one that doesn't have any code yet. You are starting from scratch.

---

## Prerequisites (install once per machine)

```bash
# 1. speckit CLI
uv tool install specify-cli

# 2. MAQA extension
specify extension add maqa

# 3. GitHub CLI
brew install gh && gh auth login

# 4. otherness agent files
git clone git@github.com:pnz1990/otherness.git ~/.otherness
```

---

## Step 1 — Create the GitHub repo

```bash
gh repo create my-org/my-project --private --clone
cd my-project
```

---

## Step 2 — Initialize speckit

```bash
specify init
# Choose: opencode integration
```

This creates `.specify/`, `.opencode/`, and scaffolding files.

---

## Step 3 — Copy the otherness config template

```bash
cp ~/.otherness/maqa-config-template.yml maqa-config.yml
```

Edit `maqa-config.yml`:

```yaml
mode: "standalone"          # start standalone; switch to "team" when you have multiple sessions
agents_path: "~/.otherness/agents"
max_parallel: 3             # max concurrent engineer slots in team mode
```

---

## Step 4 — Create AGENTS.md

This is the single most important project-specific file. Agents read it at startup to learn about your project. Every field below is read at runtime — do not leave any blank.

```markdown
# my-project — Project Agent Context

## What This Is

<One paragraph describing what the project does, what technology it uses, and what problem it solves.>

**Status**: Pre-release. Design and specs complete. Implementation not started.

---

## SDLC Process

The team process lives in `.specify/memory/sdlc.md` — read it.
This file contains only project-specific context that specializes the generic process.

---

## Project Config

```yaml
PROJECT_NAME:   my-project
CLI_BINARY:     my-cli          # name of the CLI binary (for doc cross-reference scanning)
PR_LABEL:       my-project      # label applied to all feature PRs
REPORT_ISSUE:   1               # GitHub issue number for team reports
REPORT_URL:     https://github.com/my-org/my-project/issues/1
BOARD_URL:      https://github.com/users/my-org/projects/1
BUILD_COMMAND:  <build command>   # e.g. go build ./... or npm run build
TEST_COMMAND:   <test command>    # e.g. go test ./... -race or npm test
LINT_COMMAND:   <lint command>    # e.g. go vet ./... or npx eslint .
VULN_COMMAND:   <vuln command>    # e.g. govulncheck ./... (optional, leave empty if N/A)
```

---

## Architecture

<2-3 paragraphs describing the key architectural decisions: language/framework, how the system works at a high level, key packages/modules, how state is managed.>

## Package Layout

```
<directory tree of key packages, mirroring what will be built>
```

---

## Code Standards (read by QA — project-specific)

<List your project's code conventions. Examples:>
- Error handling: `fmt.Errorf("context: %w", err)` — no bare errors
- Logging: `zerolog.Ctx(ctx)` — no fmt.Println
- Tests: table-driven with `testify/assert` + `require`
- Copyright header: `// Copyright 2026 The my-project Authors.`

## Banned Filenames (CI + QA enforce)

<List filenames that should never exist: e.g. util.go, helpers.go, common.go>

## Label Taxonomy

All issues must have labels from each of these groups:

| Group | Labels |
|---|---|
| Kind | `kind/enhancement`, `kind/bug`, `kind/chore`, `kind/docs`, `kind/security` |
| Area | `area/<component1>`, `area/<component2>`, ... |
| Priority | `priority/critical`, `priority/high`, `priority/medium`, `priority/low` |
| Size | `size/xs`, `size/s`, `size/m`, `size/l`, `size/xl` |
| Type | `epic` |
| Workflow | `<PR_LABEL>`, `needs-human`, `blocked` |

## Anti-Patterns (QA blocks PRs containing these)

| Pattern | Caught by |
|---|---|
| Task `[x]` without implementation | `/speckit.verify-tasks.run` |
| <your project-specific anti-patterns> | QA |

## Files Agents Must Not Modify

- `docs/aide/vision.md`
- `docs/aide/roadmap.md`
- `AGENTS.md`
- `.specify/memory/constitution.md`
- `.specify/memory/sdlc.md`
```

---

## Step 5 — Create `docs/aide/` — the agent source of truth

Create this directory structure:

```
docs/aide/
  vision.md              ← what the project is and why it exists
  roadmap.md             ← development stages and deliverables
  definition-of-done.md  ← user journeys that must pass end-to-end
  progress.md            ← current state (coordinator updates this)
  team.yml               ← team configuration (copy template below)
  pr-template.md         ← PR body template
```

### `docs/aide/vision.md` — required, human-written, agents never modify

```markdown
# my-project: Vision

> Created: YYYY-MM-DD
> Status: Active

## Immediate Goal

<What is the team working towards right now? What must be true before moving to the next phase?>

## Project Overview

<What does this project do? Who uses it? What problem does it solve?>

### Why this project exists

<What gap does it fill? What alternatives exist and why are they insufficient?>

### Key design decisions

<2-5 architectural decisions that will not change. These constrain implementation.>

## Release and Versioning Philosophy

<How are versions numbered? What makes a minor vs patch? Any GA or pre-release constraints?>

## Workshop / Demo Benchmarks (optional)

<If there are reference demos or workshops that define what "working" means, list them here.
Agents use these as acceptance targets.>
```

### `docs/aide/roadmap.md` — required, human-written

```markdown
# my-project: Development Roadmap

> Based on: docs/aide/vision.md

---

## Current Gate: <what must happen before the next phase>

<Describe any active gate: what must be done, what issues block it, what happens after.>

---

## Stage 0: <name>

**Goal:** <one sentence>

### Deliverables
- <concrete deliverable 1>
- <concrete deliverable 2>

### Dependencies
None / Stages X, Y

---

## Stage 1: <name>
...
```

### `docs/aide/definition-of-done.md` — required, human-written

This is the most important document. Every agent reads it before starting work. If a journey fails, the project is not done regardless of what code exists.

```markdown
# Definition of Done

> The project is complete when every journey below passes end-to-end.

---

## Journey 1: <name>

**The user story**: <who does what and why, in one sentence>

### Exact steps that must work

\`\`\`bash
# Paste the exact commands a user would run
\`\`\`

### Pass criteria

- [ ] <specific observable outcome>
- [ ] <specific observable outcome>

---

## Journey Status

| Journey | Status | Last checked | Notes |
|---|---|---|---|
| 1: <name> | ❌ Not started | — | Requires Stages X-Y |
```

### `docs/aide/progress.md` — created by coordinator, seed it manually

```markdown
# my-project: Current Progress

> Updated by coordinator after each batch.

## Current State

- **Active queue**: none (not started)
- **Completed stages**: none
- **In-flight items**: none

## Stage Completion

| Stage | Name | Status | Notes |
|---|---|---|---|
| 0 | Project skeleton | 📋 Planned | |

## Spec Status

| Spec | Name | Status | Notes |
|---|---|---|---|
```

### `docs/aide/team.yml` — copy and adapt from kardinal-promoter

```yaml
# Team configuration — read by agents at startup
source_of_truth:
  - docs/aide/vision.md
  - docs/aide/roadmap.md
  - docs/aide/definition-of-done.md
  - docs/aide/team.yml
  - .specify/memory/sdlc.md
  - .specify/memory/constitution.md

board:
  provider: github-projects
  config: maqa-github-projects/github-projects-config.yml
  sync_strategy: "state.json is authoritative. Coordinator syncs board on every cycle."

reporting:
  issue_number: "see AGENTS.md REPORT_ISSUE"
  label: report
```

---

## Step 6 — Set up `.specify/memory/`

### `constitution.md` — copy from kardinal-promoter and adapt

The constitution governs agent behavior. Copy `.specify/memory/constitution.md` from kardinal-promoter as a starting point. The critical sections to keep verbatim:
- Article I–VI (core behavioral rules)
- Article IX (docs-first principle)
- Article XII (Graph-first, if applicable — remove if not a Graph-based project)

Adapt sections to your project's specific constraints.

### `sdlc.md` — generated by speckit, lightly customized

Run `specify constitution` to generate an initial version, then review and adapt.

---

## Step 7 — Create the GitHub report issue

```bash
gh issue create --repo my-org/my-project \
  --title "📊 Autonomous Team Reports" \
  --body "Subscribe to this issue for all team reports. The coordinator updates the body after every batch and posts [BATCH COMPLETE] comments here." \
  --label "report"
```

Note the issue number — it becomes `REPORT_ISSUE` in `AGENTS.md`.

---

## Step 8 — Set up GitHub Projects board

Create a board at https://github.com/users/YOUR-USERNAME/projects/new with:

**Status field** (single-select): Todo, In Progress, In Review, Done, Blocked
**Team field** (single-select): ENGINEER-1, ENGINEER-2, ENGINEER-3, STANDALONE-ENG
**Priority field** (single-select): P0 - Critical, P1 - High, P2 - Medium, P3 - Low
**Size field** (single-select): XS, S, M, L, XL
**Target date field** (date)

Then record the field IDs in `maqa-github-projects/github-projects-config.yml`:

```yaml
owner: "your-github-username"
project_number: "1"
project_id: "PVT_xxxx"

status_field_id: "PVTSSF_xxxx"
todo_option_id: "xxxx"
in_progress_option_id: "xxxx"
in_review_option_id: "xxxx"
done_option_id: "xxxx"
blocked_option_id: "xxxx"

team_field_id: "PVTSSF_xxxx"
team_engineer1_option_id: "xxxx"
team_engineer2_option_id: "xxxx"
team_engineer3_option_id: "xxxx"
team_standalone_option_id: "xxxx"

priority_field_id: "PVTSSF_xxxx"
priority_critical_option_id: "xxxx"
priority_high_option_id: "xxxx"
priority_medium_option_id: "xxxx"
priority_low_option_id: "xxxx"

size_field_id: "PVTSSF_xxxx"
size_xs_option_id: "xxxx"
size_s_option_id: "xxxx"
size_m_option_id: "xxxx"
size_l_option_id: "xxxx"
size_xl_option_id: "xxxx"

target_date_field_id: "PVTF_xxxx"
start_date_field_id: "PVTF_xxxx"

linked_repo: "your-org/your-project"
```

To find field IDs, run:
```bash
gh api graphql -f query='{node(id:"PVT_xxxx"){...on ProjectV2{fields(first:20){nodes{...on ProjectV2SingleSelectField{id name options{id name}}...on ProjectV2Field{id name}}}}}}'
```

---

## Step 9 — Create GitHub labels

```bash
# Kind
gh label create "kind/enhancement" --color "A2EEEF" --repo my-org/my-project
gh label create "kind/bug"         --color "B60205" --repo my-org/my-project
gh label create "kind/chore"       --color "EDEDED" --repo my-org/my-project
gh label create "kind/docs"        --color "0075CA" --repo my-org/my-project
gh label create "kind/security"    --color "B60205" --repo my-org/my-project

# Priority
gh label create "priority/critical" --color "B60205" --repo my-org/my-project
gh label create "priority/high"     --color "E4A04A" --repo my-org/my-project
gh label create "priority/medium"   --color "FBCA04" --repo my-org/my-project
gh label create "priority/low"      --color "0075CA" --repo my-org/my-project

# Size
gh label create "size/xs" --color "2EA44F" --repo my-org/my-project
gh label create "size/s"  --color "2EA44F" --repo my-org/my-project
gh label create "size/m"  --color "FBCA04" --repo my-org/my-project
gh label create "size/l"  --color "E4A04A" --repo my-org/my-project
gh label create "size/xl" --color "B60205" --repo my-org/my-project

# Workflow
gh label create "needs-human"     --color "B60205" --repo my-org/my-project
gh label create "blocked"         --color "E4A04A" --repo my-org/my-project
gh label create "epic"            --color "8B5CF6" --repo my-org/my-project
gh label create "doc-debt"        --color "E11D48" --repo my-org/my-project
gh label create "code-health"     --color "7C3AED" --repo my-org/my-project
gh label create "cleanup"         --color "6B7280" --repo my-org/my-project
gh label create "product-gap"     --color "F59E0B" --repo my-org/my-project
gh label create "product-proposal"--color "10B981" --repo my-org/my-project
gh label create "sdlc-improvement"--color "6366F1" --repo my-org/my-project

# Area labels — create one per major component of your project
gh label create "area/api"        --color "5319E7" --repo my-org/my-project
# ... add your project-specific area labels
```

---

## Step 10 — First run

```bash
# Start the standalone agent (single session, all roles)
/speckit.maqa.standalone

# Or start the full team (separate sessions):
# Session 1: /speckit.maqa.coordinator
# Session 2: /speckit.maqa.feature
# Session 3: /speckit.maqa.qa
```

The agent will:
1. Self-update from pnz1990/otherness
2. Read all docs/aide/ files and AGENTS.md
3. Run the PM spec gate
4. Generate queue-001
5. Begin implementing Stage 0

---

## Minimum viable file set

If you want the absolute minimum to get started:

```
AGENTS.md                              ← required (project identity + commands)
maqa-config.yml                        ← required (mode + agents_path)
docs/aide/vision.md                    ← required (what you're building)
docs/aide/roadmap.md                   ← required (stages)
docs/aide/definition-of-done.md       ← required (acceptance criteria)
docs/aide/progress.md                  ← required (seed with empty tables)
docs/aide/team.yml                     ← required (source of truth list)
.specify/memory/constitution.md        ← required (agent behavioral rules)
.specify/memory/sdlc.md               ← required (process definition)
maqa-github-projects/github-projects-config.yml  ← required (board field IDs)
.maqa/state.json                       ← required (seed with empty state)
```

Without any of these, agents will either crash or produce wrong behavior.
