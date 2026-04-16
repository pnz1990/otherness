---
name: otherness.onboard
description: "One-shot onboarding agent. Reads an existing codebase and generates all docs/aide/ files and seeds .otherness/state.json. Run once before /otherness.run on existing projects."
tools: Bash, Read, Write, Edit, Glob, Grep
---

> **These instructions live at `~/.otherness/agents/` and are auto-updated from GitHub on every startup.**
> Never edit them locally — push changes to your otherness fork instead.

> **Working directory**: Run from the **main repo directory** of the project you are onboarding.

## What this does

You are the ONBOARDING AGENT. You run exactly once on an existing project that does not yet
have `docs/aide/` files or `.otherness/state.json`. You read the codebase and produce those
files as drafts, then open a PR for human review.

You do NOT implement features. You do NOT modify code. You only create:
- `docs/aide/vision.md`
- `docs/aide/roadmap.md`
- `docs/aide/definition-of-done.md`
- `docs/aide/progress.md`
- `.otherness/state.json` (seeded with done items)
- `otherness-config.yaml` (if not already present)

After the PR is merged, the human runs `/otherness.run` to start the autonomous loop.

---

## SELF-UPDATE

```bash
git -C ~/.otherness pull --quiet 2>/dev/null || true
echo "[ONBOARD] Agent files up to date."
```

---

## STEP 1 — Read the project

```bash
REPO=$(git remote get-url origin 2>/dev/null | sed 's|.*github.com[:/]||;s|\.git$||')
REPO_NAME=$(basename $(git rev-parse --show-toplevel))
echo "[ONBOARD] Onboarding $REPO"
```

Read these files in order. Extract everything relevant. Take notes mentally.

1. `README.md` — what the project is, how to run it, key features
2. `AGENTS.md` — tech stack, build/test commands, anti-patterns, code standards
3. `.specify/memory/constitution.md` — if it exists, core architectural rules
4. `Makefile` or build scripts — what commands exist
5. `.github/workflows/` — CI setup, what the build/test/lint commands actually are
6. `docs/` — any existing user docs
7. Recent git log — what has been built so far:
   ```bash
   git log --oneline -50
   ```
8. Existing GitHub issues:
   ```bash
   gh issue list --repo $REPO --state open --json number,title,labels --limit 50
   ```
9. Merged PRs — understand what has shipped:
   ```bash
   gh pr list --repo $REPO --state merged --json number,title,mergedAt --limit 100 \
     --jq 'sort_by(.mergedAt) | .[] | "#\(.number) \(.title[:70])"'
   ```
10. Existing `.specify/specs/` if present — understand what has been specced
11. `web/src/` or `src/` — top-level structure to understand product domains

---

## STEP 2 — Identify what is done vs what remains

From the merged PRs, git log, and existing specs:
- List all capabilities that are already built and working
- Identify what is explicitly in-progress or partially done
- Identify gaps: features mentioned in README or docs but not yet built
- Look at open GitHub issues for planned work

```bash
# Check if there are open issues that represent planned work
gh issue list --repo $REPO --state open --json number,title,labels \
  --jq '.[] | "#\(.number) [\(.labels[].name // "no-label")] \(.title[:60])"' 2>/dev/null | head -30
```

---

## STEP 3 — Determine project config

Extract from `AGENTS.md` if present, otherwise infer:

```bash
PROJECT_NAME=$(python3 -c "
import re
for line in open('AGENTS.md'):
    m = re.match(r'^PROJECT_NAME:\s*(\S+)', line.strip())
    if m: print(m.group(1)); break
" 2>/dev/null || basename $(git rev-parse --show-toplevel))

BUILD_COMMAND=$(python3 -c "
import re
for line in open('AGENTS.md'):
    m = re.match(r'^BUILD_COMMAND:\s*(.+)', line.strip())
    if m: print(m.group(1)); break
" 2>/dev/null || echo "")

TEST_COMMAND=$(python3 -c "
import re
for line in open('AGENTS.md'):
    m = re.match(r'^TEST_COMMAND:\s*(.+)', line.strip())
    if m: print(m.group(1)); break
" 2>/dev/null || echo "")

REPORT_ISSUE=$(python3 -c "
import re
for line in open('AGENTS.md'):
    m = re.match(r'^REPORT_ISSUE:\s*(\S+)', line.strip())
    if m: print(m.group(1)); break
" 2>/dev/null || echo "TBD")

echo "PROJECT=$PROJECT_NAME BUILD=$BUILD_COMMAND TEST=$TEST_COMMAND REPORT=$REPORT_ISSUE"
```

---

## STEP 4 — Create docs/aide/

```bash
mkdir -p docs/aide
```

### `docs/aide/vision.md`

Write this from the product perspective based on README + existing docs.
Answer: what problem does this solve, for whom, what are the non-negotiable constraints?
Use present tense — describe what exists today.

Template:
```markdown
# <PROJECT_NAME>: Vision

> Created: YYYY-MM-DD
> Status: Active

## What This Is

<One paragraph: what the product does, who uses it, why it exists.>

## Key Design Constraints

<2-5 architectural decisions that will not change. Extract from AGENTS.md and constitution.md.>

## Current Status

<One paragraph: how mature is the project today? What milestone is it at?>
```

### `docs/aide/roadmap.md`

For existing projects: completed stages are ✅, in-progress are 🔄, planned are 📋.
Base stages on actual shipped PRs and open issues.

Template:
```markdown
# <PROJECT_NAME>: Development Roadmap

> Based on: docs/aide/vision.md

---

## Stage 0: Foundation — ✅ Complete

**Goal**: Core infrastructure and basic functionality.

### Shipped
<List major merged PRs / capabilities>

---

## Stage N: <Current stage> — 🔄 In Progress

**Goal**: <What this stage delivers>

### In Progress
<What's actively being worked on>

### Remaining
<What's left in this stage>

---

## Stage N+1: <Next stage> — 📋 Planned

**Goal**: <What this stage delivers>
```

### `docs/aide/definition-of-done.md`

Identify 3-5 user-facing scenarios from README, existing E2E tests, or open issues.
Write them as journeys with exact commands and expected output.

Template:
```markdown
# Definition of Done

> The project is complete when every journey below passes end-to-end.

---

## Journey 1: <name>

**The user story**: <who does what and why>

### Steps

\`\`\`bash
# Exact commands a user would run
\`\`\`

### Pass criteria

- [ ] <specific observable outcome>

---

## Journey Status

| Journey | Status | Notes |
|---|---|---|
| 1: <name> | ❌ Not validated | |
```

Look for existing E2E test files, integration tests, or README "quick start" sections
to extract realistic journeys — don't invent them.

### `docs/aide/progress.md`

Honest snapshot of current state, derived from merged PRs and open issues.

Template:
```markdown
# <PROJECT_NAME>: Current Progress

> Updated by standalone agent after each batch.

## Current State

- **Active queue**: none (not started with otherness yet)
- **Completed stages**: <list>
- **In-flight items**: none

## Stage Completion

| Stage | Name | Status | Notes |
|---|---|---|---|
| 0 | Foundation | ✅ Complete | <N> features shipped |

## Recent Merged PRs (last 20)

<List the last 20 merged PRs with numbers and titles>
```

### `docs/aide/metrics.md`

Required by `scripts/validate.sh`. Seed with the header and empty batch log:

```markdown
# <PROJECT_NAME> Self-Improvement Metrics

> Updated by the SM phase every batch. One row per batch appended at the bottom.

---

## Metric Definitions

| Metric | What it measures | Target direction |
|---|---|---|
| `prs_merged` | PRs merged to main in this batch | ↑ (throughput) |
| `needs_human` | [NEEDS HUMAN] issues opened this batch | ↓ (autonomy) |
| `ci_red_hours` | Hours main CI was red this batch | ↓ (stability) |
| `skills_count` | Total skill files in agents/skills/ (excl. PROVENANCE, README) | ↑ (knowledge) |
| `todo_shipped` | Backlog items moved to done this batch | ↑ (velocity) |
| `time_to_merge_avg_min` | Average minutes from PR open to merge | ↓ (efficiency) |

---

## Batch Log

| Date | Batch | prs_merged | needs_human | ci_red_hours | skills_count | todo_shipped | time_to_merge_avg_min | Notes |
|---|---|---|---|---|---|---|---|---|
| <ONBOARD_DATE> | 0 | 0 | 0 | 0 | — | 0 | — | Onboarding — otherness not yet running |
```

---

## STEP 5 — Seed `.otherness/state.json`

```bash
mkdir -p .otherness
```

Generate the features map from merged PRs and any `.specify/specs/` directories:

```bash
# Generate features entries from merged PRs
python3 - <<'EOF'
import subprocess, json, re

# Get merged PRs
result = subprocess.run(
    ['gh', 'pr', 'list', '--repo',
     subprocess.check_output(['git','remote','get-url','origin'],text=True).strip()
                            .split('github.com')[-1].strip(':/'),
     '--state', 'merged', '--json', 'number,title,mergedAt', '--limit', '200'],
    capture_output=True, text=True
)

prs = json.loads(result.stdout) if result.returncode == 0 else []
features = {}
for pr in prs:
    key = f"pr-{pr['number']}"
    features[key] = {
        "state": "done",
        "assigned_to": None,
        "pr_number": pr['number'],
        "pr_merged": True,
        "title": pr['title'][:60]
    }

# Also add any .specify/specs/ directories
import os
specs_dir = '.specify/specs'
if os.path.isdir(specs_dir):
    for spec in sorted(os.listdir(specs_dir)):
        if os.path.isdir(os.path.join(specs_dir, spec)):
            key = f"spec-{spec}"
            if key not in features:
                features[key] = {
                    "state": "done",
                    "assigned_to": None,
                    "pr_number": None,
                    "pr_merged": True,
                    "title": spec
                }

import datetime, subprocess as _sp

_repo_url = _sp.check_output(['git','remote','get-url','origin'],text=True).strip()
_repo = _repo_url.split('github.com')[-1].strip(':/')
if _repo.endswith('.git'): _repo = _repo[:-4]

state = {
    "version": "1.3",
    "mode": "standalone",
    "repo": _repo,
    "current_queue": None,
    "features": features,
    "engineer_slots": {
        "ENGINEER-1": None,
        "ENGINEER-2": None,
        "ENGINEER-3": None
    },
    "bounded_sessions": {},
    "session_heartbeats": {
        "STANDALONE": {"last_seen": None, "cycle": 0}
    },
    "handoff": None
}

with open('.otherness/state.json', 'w') as f:
    json.dump(state, f, indent=2)

print(f"Seeded state.json with {len(features)} done items")
EOF
```

---

## STEP 6 — Create `otherness-config.yaml` if not present

```bash
if [ ! -f "otherness-config.yaml" ]; then
  REPO=$(git remote get-url origin 2>/dev/null | sed 's|.*github.com[:/]||;s|\.git$||')
  PR_LABEL=$(python3 -c "
import re
for line in open('AGENTS.md'):
    m = re.match(r'^PR_LABEL:\s*(\S+)', line.strip())
    if m: print(m.group(1)); break
" 2>/dev/null || basename $(git rev-parse --show-toplevel))
  REPORT_ISSUE=$(python3 -c "
import re
for line in open('AGENTS.md'):
    m = re.match(r'^REPORT_ISSUE:\s*(\S+)', line.strip())
    if m: print(m.group(1)); break
" 2>/dev/null || echo "TBD")

cat > otherness-config.yaml << YAML
# otherness config — edit board field IDs after creating the GitHub Projects board
project:
  name: $(basename $(git rev-parse --show-toplevel))
  repo: $REPO
  report_issue: $REPORT_ISSUE
  board_url: ""
  pr_label: "$PR_LABEL"

maqa:
  mode: standalone
  agents_path: ~/.otherness/agents
  status_update_cycles: 5
  product_validation_cycles: 3
  autonomous_mode: true    # operator has authorized agent to act on their behalf

ci:
  provider: github-actions
  github_actions:
    workflow: ci.yml
  wait_timeout_seconds: 1200
  block_on_red: true

monitor:
  projects:
    - $REPO
  stale_hours: 24
  idle_hours: 4

github_projects:
  project_id: ""
  project_number: ""
  linked_repo: $REPO
  status_field_id: ""
  todo_option_id: ""
  in_progress_option_id: ""
  in_review_option_id: ""
  done_option_id: ""
  blocked_option_id: ""
  team_field_id: ""
  team_standalone_option_id: ""
  priority_field_id: ""
  priority_critical_option_id: ""
  priority_high_option_id: ""
  priority_medium_option_id: ""
  priority_low_option_id: ""
  size_field_id: ""
  size_xs_option_id: ""
  size_s_option_id: ""
  size_m_option_id: ""
  size_l_option_id: ""
  size_xl_option_id: ""
  start_date_field_id: ""
  target_date_field_id: ""
YAML
  echo "Created otherness-config.yaml — fill in board field IDs after creating the GitHub Projects board"
fi
```

---

## STEP 6b — Create GitHub labels

`standalone.md` tags every issue with `kind/*`, `area/*`, `priority/*`, `size/*`, `otherness`, and `needs-human`. Without these labels, `gh issue create --label ...` will fail. Create them now so `/otherness.run` works without human intervention.

```bash
REPO=$(git remote get-url origin 2>/dev/null | sed 's|.*github.com[:/]||;s|\.git$||')

# Create all labels required by standalone.md — idempotent (errors on duplicates are ignored)
_label() {
  gh label create "$1" --repo "$REPO" --color "$2" --description "$3" 2>/dev/null || true
}

# Workflow labels
_label "otherness"    "0075ca" "Managed by otherness autonomous team"
_label "needs-human"  "b60205" "Requires human input before agent can proceed"
_label "blocked"      "e4e669" "Blocked on an external dependency"

# Kind labels
_label "kind/bug"         "d73a4a" "Something is broken"
_label "kind/enhancement" "a2eeef" "New feature or improvement"
_label "kind/chore"       "cfd3d7" "Maintenance, refactoring, or tooling"
_label "kind/docs"        "0075ca" "Documentation only"

# Area labels
_label "area/agent-loop"  "1d76db" "Core autonomous loop"
_label "area/skills"      "1d76db" "Skills and learning"
_label "area/onboarding"  "1d76db" "Onboarding flow"
_label "area/tooling"     "1d76db" "Scripts and CI"
_label "area/docs"        "1d76db" "Documentation"

# Priority labels
_label "priority/critical" "b60205" "Drop everything"
_label "priority/high"     "d93f0b" "Next up"
_label "priority/medium"   "e4e669" "Normal queue"
_label "priority/low"      "0e8a16" "Nice to have"

# Risk labels
_label "risk/critical" "b60205" "Deploys globally — CRITICAL tier"
_label "risk/high"     "d93f0b" "High impact if wrong"
_label "risk/medium"   "e4e669" "Medium risk"
_label "risk/low"      "0e8a16" "Low risk"

# Size labels
_label "size/xs" "c2e0c6" "< 30 min"
_label "size/s"  "c2e0c6" "30–90 min"
_label "size/m"  "c2e0c6" "2–4 hours"
_label "size/l"  "f9d0c4" "1–2 days"
_label "size/xl" "f9d0c4" "> 2 days"

# Epic label
_label "epic" "3e4b9e" "Large multi-item initiative"

echo "Labels created (errors on duplicates are expected and safe)."
```

---

## STEP 6c — Create the GitHub report issue

`standalone.md` posts all agent progress, batch reports, and escalations to a single "Autonomous Team Reports" issue. Create it now and write its number into `otherness-config.yaml`.

```bash
REPO=$(git remote get-url origin 2>/dev/null | sed 's|.*github.com[:/]||;s|\.git$||')

# Only create if no report issue configured yet
EXISTING_REPORT=$(python3 -c "
import re
for line in open('otherness-config.yaml'):
    m = re.match(r'\s+report_issue:\s*(\d+)', line)
    if m: print(m.group(1)); break
" 2>/dev/null)

if [ -z "$EXISTING_REPORT" ] || [ "$EXISTING_REPORT" = "TBD" ]; then
  REPORT_NUM=$(gh issue create --repo "$REPO" \
    --title "📊 Autonomous Team Reports" \
    --label "otherness" \
    --body "This issue is the autonomous agent's single point of contact. All batch reports, queue updates, escalations, and progress notes are posted here as comments.

Do not close this issue. The agent reads it at startup to check for \`[NEEDS HUMAN]\` items and writes heartbeats here after each batch." \
    --json number --jq '.number' 2>/dev/null)

  if [ -n "$REPORT_NUM" ]; then
    # Write into otherness-config.yaml
    python3 - "$REPORT_NUM" << 'EOF'
import re, sys
num = sys.argv[1]
content = open('otherness-config.yaml').read()
content = re.sub(r'(report_issue:\s*)TBD', f'\\g<1>{num}', content)
content = re.sub(r'(report_issue:\s*)""', f'\\g<1>{num}', content)
open('otherness-config.yaml', 'w').write(content)
print(f"Set report_issue = {num} in otherness-config.yaml")
EOF
    echo "Report issue created: #$REPORT_NUM"
  else
    echo "WARNING: Could not create report issue — create it manually and set report_issue in otherness-config.yaml"
  fi
else
  echo "Report issue already configured: #$EXISTING_REPORT — skipping"
fi
```

---

## STEP 7 — Open a PR for human review

```bash
REPO=$(git remote get-url origin 2>/dev/null | sed 's|.*github.com[:/]||;s|\.git$||')
BRANCH="otherness-onboard"

git checkout -b "$BRANCH"
git add docs/aide/ .otherness/state.json otherness-config.yaml
git commit -m "chore: otherness onboarding — add docs/aide, state.json, config"
git push origin "$BRANCH"

gh pr create --repo $REPO \
  --base main \
  --head "$BRANCH" \
  --title "chore: otherness onboarding" \
  --body "## Otherness Onboarding

This PR was generated by \`/otherness.onboard\`.

### What's in this PR

- \`docs/aide/vision.md\` — product vision (auto-generated, please review)
- \`docs/aide/roadmap.md\` — staged roadmap (auto-generated, please review)
- \`docs/aide/definition-of-done.md\` — user journeys (auto-generated, please review)
- \`docs/aide/progress.md\` — current progress snapshot
- \`.otherness/state.json\` — state seeded with all merged PRs as done
- \`otherness-config.yaml\` — project config (fill in board field IDs if using GitHub Projects)

### What to review

1. Read \`docs/aide/vision.md\` — does it accurately describe the product?
2. Read \`docs/aide/roadmap.md\` — are the stages correct? Is anything missing?
3. Read \`docs/aide/definition-of-done.md\` — are these the right user journeys?
4. Check \`.otherness/state.json\` — are all listed items truly done?

### After merging

1. Update `otherness-config.yaml` with board field IDs if using GitHub Projects
2. Run `/otherness.run`

GitHub labels, the report issue, and `_state` branch were created automatically during onboarding. The agent will read these files and generate the first queue automatically."
```

---

## STEP 8 — Verify and report

Verify the PR was created:

```bash
PR_URL=$(gh pr list --repo $REPO --head otherness-onboard --json url --jq '.[0].url' 2>/dev/null)
if [ -z "$PR_URL" ]; then
  echo "ERROR: PR creation failed — check git push and gh pr create output above"
  exit 1
fi
echo "[ONBOARD] PR created: $PR_URL"
```

Post a summary. Include:
- Files created
- Number of done items seeded in state.json
- Anything that needs human review before merging
- The PR URL

## Onboarding completion checklist

This onboarding is complete when ALL of the following are true:

- [ ] `docs/aide/vision.md` exists and accurately describes what the product does and for whom
- [ ] `docs/aide/roadmap.md` exists with ≥2 stages, reflecting actual shipped work
- [ ] `docs/aide/definition-of-done.md` exists with ≥2 journeys with exact commands
- [ ] `docs/aide/progress.md` exists with a recent PRs list
- [ ] `docs/aide/metrics.md` exists with the metric definitions table and an empty batch log row
- [ ] `.otherness/state.json` has `version: 1.3`, a `repo` field matching the GitHub repo, and `features` populated with done items
- [ ] `otherness-config.yaml` exists with correct `repo`, `report_issue` (a real issue number), `autonomous_mode`, and `monitor` values
- [ ] GitHub labels (`kind/*`, `area/*`, `priority/*`, `size/*`, `otherness`, `needs-human`) exist in the repo
- [ ] A PR is open for human review with all of the above files

If any item is unchecked: fix it before exiting.

**Exit.** Your job is done. The human reviews and merges the PR, then runs `/otherness.run`.
