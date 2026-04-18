# Onboarding: New Project

This guide walks through setting up otherness on a **brand new project** — one that doesn't have any code yet. You are starting from scratch.

---

## Prerequisites (install once per machine)

```bash
# 1. GitHub CLI
brew install gh && gh auth login

# 2. otherness agent files
git clone git@github.com:<your-username>/otherness.git ~/.otherness
```

---

## Step 1 — Create the GitHub repo

```bash
gh repo create my-org/my-project --private --clone
cd my-project
```

---

## Step 2 — Run otherness setup

```bash
/otherness.setup
```

This creates `otherness-config.yaml` from the template and auto-fills `project.repo` and `project.name` from your git remote. Edit the file to configure CI, board field IDs, and cycle settings.

If your project has a UI (web app, mobile app, frontend), set `project.job_family: FEE`. For infrastructure/platform projects, set `project.job_family: SysDE`. For backend-only projects the default (`SDE`) is correct — you can omit the field.

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
- Error handling: `<your error wrapping pattern, e.g. fmt.Errorf("context: %w", err)>` — no bare errors
- Logging: `<your logging library and call pattern>` — no print statements
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
| Task `[x]` without implementation | QA adversarial review |
| <your project-specific anti-patterns> | QA |

## Files Agents Must Not Modify

- `docs/aide/vision.md`
- `docs/aide/roadmap.md`
- `AGENTS.md`
- `.specify/memory/constitution.md`
- `.specify/memory/sdlc.md`

## D4 ENFORCEMENT

This project enforces D4. Agents may only act within their declared mode.

| Zone | Permitted by |
|---|---|
| CODE (implementation) | /otherness.run only |
| DOCS (vision/design) | /otherness.vibe-vision only |
| Everything else | READ-ONLY |

Any agent that attempts to act outside its mode must stop and print:
  [🚫 D4 GATE] <zone> writes require <command>. Current session: <mode>.
```

---

## Step 5 — Create `docs/aide/` — the agent source of truth

Create this directory structure:

```
docs/aide/
  vision.md              ← what the project is and why it exists (required)
  roadmap.md             ← development stages and deliverables (required)
  definition-of-done.md  ← user journeys that must pass end-to-end (required)
  progress.md            ← current state (standalone agent updates this)
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

### `docs/aide/progress.md` — created by standalone agent, seed it manually

```markdown
# my-project: Current Progress

> Updated by standalone agent after each batch.

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

---

## Step 6 — Set up `.specify/memory/` (optional but recommended)

### `constitution.md` — generate or adapt from another otherness project

The constitution governs agent behavior. Copy from another otherness project and adapt, or ask the agent to generate it from your AGENTS.md.

### `sdlc.md` — generated by speckit, lightly customized

Run `specify constitution` to generate an initial version, then review and adapt.

---

## Step 7 — Create the GitHub report issue

```bash
gh issue create --repo my-org/my-project \
  --title "📊 Autonomous Team Reports" \
  --body "Subscribe to this issue for all team reports. The standalone agent updates the body after every batch and posts [BATCH COMPLETE] comments here." \
  --label "report"
```

Note the issue number — it becomes `REPORT_ISSUE` in `AGENTS.md`.

---

## Step 8 — Set up GitHub Projects board (fully automated via API)

All board fields and options can be created via the GitHub GraphQL API — no UI needed.
The only step that requires the browser is the initial project creation.

### 8a — Create the project in the browser (once)

Go to https://github.com/users/YOUR-USERNAME/projects/new, choose **Board** or **Table**,
name it (e.g. `my-project`), click Create. Note the project number from the URL
(`/projects/N`).

### 8b — Get the project ID and create all fields via API

```bash
REPO="my-org/my-project"
OWNER="my-org-or-username"    # just the owner, no slash
PROJECT_NUMBER=1               # from the URL

# 1. Get the project node ID
PROJECT_ID=$(gh api graphql -f query='{
  user(login: "'"$OWNER"'") {
    projectV2(number: '"$PROJECT_NUMBER"') { id }
  }
}' --jq '.data.user.projectV2.id' 2>/dev/null || \
gh api graphql -f query='{
  organization(login: "'"$OWNER"'") {
    projectV2(number: '"$PROJECT_NUMBER"') { id }
  }
}' --jq '.data.organization.projectV2.id')
echo "Project ID: $PROJECT_ID"

# 2. Update Status field with all 5 options
# First get the existing Status field ID
STATUS_FIELD_ID=$(gh api graphql -f query='{
  node(id: "'"$PROJECT_ID"'") {
    ... on ProjectV2 { fields(first: 20) { nodes {
      ... on ProjectV2SingleSelectField { id name }
    }}}
  }
}' --jq '.data.node.fields.nodes[] | select(.name=="Status") | .id')

gh api graphql -f query='mutation {
  updateProjectV2Field(input: {
    fieldId: "'"$STATUS_FIELD_ID"'"
    singleSelectOptions: [
      {name: "Todo",        color: GRAY,   description: ""},
      {name: "In Progress", color: BLUE,   description: ""},
      {name: "In Review",   color: YELLOW, description: ""},
      {name: "Done",        color: GREEN,  description: ""},
      {name: "Blocked",     color: RED,    description: ""}
    ]
  }) {
    projectV2Field { ... on ProjectV2SingleSelectField { id name options { id name } } }
  }
}'

# 3. Create Priority field
gh api graphql -f query='mutation {
  createProjectV2Field(input: {
    projectId: "'"$PROJECT_ID"'"
    dataType: SINGLE_SELECT
    name: "Priority"
    singleSelectOptions: [
      {name: "Critical", color: RED,    description: "P0"},
      {name: "High",     color: ORANGE, description: "P1"},
      {name: "Medium",   color: YELLOW, description: "P2"},
      {name: "Low",      color: BLUE,   description: "P3"}
    ]
  }) {
    projectV2Field { ... on ProjectV2SingleSelectField { id name options { id name } } }
  }
}'

# 4. Create Size field
gh api graphql -f query='mutation {
  createProjectV2Field(input: {
    projectId: "'"$PROJECT_ID"'"
    dataType: SINGLE_SELECT
    name: "Size"
    singleSelectOptions: [
      {name: "XS", color: GREEN,  description: ""},
      {name: "S",  color: GREEN,  description: ""},
      {name: "M",  color: YELLOW, description: ""},
      {name: "L",  color: ORANGE, description: ""},
      {name: "XL", color: RED,    description: ""}
    ]
  }) {
    projectV2Field { ... on ProjectV2SingleSelectField { id name options { id name } } }
  }
}'

# 5. Create Team field (add bounded agent names as needed)
gh api graphql -f query='mutation {
  createProjectV2Field(input: {
    projectId: "'"$PROJECT_ID"'"
    dataType: SINGLE_SELECT
    name: "Team"
    singleSelectOptions: [
      {name: "STANDALONE-ENG", color: PURPLE, description: "Unbounded standalone agent"}
    ]
  }) {
    projectV2Field { ... on ProjectV2SingleSelectField { id name options { id name } } }
  }
}'

# 6. Create Target date field
gh api graphql -f query='mutation {
  createProjectV2Field(input: {
    projectId: "'"$PROJECT_ID"'"
    dataType: DATE
    name: "Target date"
  }) {
    projectV2Field { ... on ProjectV2Field { id name } }
  }
}'

# 7. Read back all field IDs to paste into otherness-config.yaml
gh api graphql -f query='{
  node(id: "'"$PROJECT_ID"'") {
    ... on ProjectV2 { fields(first: 30) { nodes {
      ... on ProjectV2SingleSelectField { id name options { id name } }
      ... on ProjectV2Field { id name }
    }}}
  }
}' --jq '.data.node.fields.nodes[]'
```

The final query prints every field ID and option ID. Copy them into `otherness-config.yaml`.

**Note**: the token used by `gh` must have the `read:project` scope to query project fields.
Run `gh auth refresh -s read:project` if you get scope errors.

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
# Unbounded: one session plays all roles
/otherness.run

# Bounded: multiple concurrent sessions with declared scope
# (inject boundary fields in the prompt)
/otherness.run.bounded
```

The standalone agent will:
1. Self-update from the otherness repo
2. Read all docs/aide/ files and AGENTS.md
3. Check vision.md for immediate priority
4. Generate queue-001
5. Begin implementing Stage 0

## Minimum viable file set

If you want the absolute minimum to get started:

```
AGENTS.md                              ← required (project identity + commands)
otherness-config.yaml                  ← required (mode, CI, board field IDs)
docs/aide/vision.md                    ← required (what you're building)
docs/aide/roadmap.md                   ← required (stages)
docs/aide/definition-of-done.md       ← required (acceptance criteria)
.otherness/state.json                  ← required (seed with empty state)
```

Without any of these, agents will either crash or produce wrong behavior.

**Not required to start** (agents will work without them, or will generate them):
- `docs/aide/team.yml` — generic boilerplate, not read by runtime agents
- `docs/aide/pr-template.md` — optional, agents open PRs without it
- `.specify/memory/constitution.md` — recommended but gracefully absent; agent reads AGENTS.md instead
- `.specify/memory/sdlc.md` — the process is embedded in `standalone.md`; this file is for the old multi-session model
