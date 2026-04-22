# 43: GitHub Project Management Layer

> Status: Active | Created: 2026-04-21
> Applies to: all projects managed by otherness

---

## What this does

GitHub Projects, milestones, epics, and board statuses are the human-visible
health signal for a project. When they are wrong — items stuck on `No Status`,
0 milestones assigned, no open epics — a human looking at the board sees noise,
not signal. The autonomous team is shipping work but the board doesn't reflect it.

This design doc specifies what the agents are required to maintain on the GitHub
project management layer, and exactly where in the loop each operation fires.

---

## The four operations

### 1. Board status lifecycle (per item)

Every issue that enters the otherness work queue must have a board status that
reflects where it actually is. The mapping:

| Agent phase | Board status | When |
|---|---|---|
| COORD §1d (queue gen / issue created) | `Todo` | Issue created, added to board |
| ENG §2a (item claimed) | `In Progress` | Session starts working on it |
| ENG §2f (PR opened) | `In Review` | PR is open, CI running |
| QA §3e (PR merged) | `Done` | Same moment as gh issue close |
| SM §4a (stale triage) | `Blocked` | NEEDS HUMAN or CI stuck >24h |

Implementation — each phase calls:
```bash
# Get the project ID from config
PROJECT_ID=$(python3 -c "
import re
section=None
for line in open('otherness-config.yaml'):
    s=re.match(r'^(\w[\w_]*):', line)
    if s: section=s.group(1)
    if section=='project':
        m=re.match(r'^\s+board_project_id:\s*(\S+)', line)
        if m: print(m.group(1)); break
" 2>/dev/null || echo "")

# Get the item ID for this issue on the board
ITEM_ID_BOARD=$(gh api graphql -f query='
query($project: ID!, $issue: Int!) {
  node(id: $project) {
    ... on ProjectV2 {
      items(first: 100) {
        nodes {
          id
          content { ... on Issue { number } }
        }
      }
    }
  }
}' -f project="$PROJECT_ID" -F issue="$_ISSUE_NUM" \
  --jq ".data.node.items.nodes[] | select(.content.number == $_ISSUE_NUM) | .id" 2>/dev/null)

# Set the status
STATUS_FIELD_ID=$(gh api graphql -f query='
query($project: ID!) {
  node(id: $project) {
    ... on ProjectV2 {
      fields(first: 20) {
        nodes {
          ... on ProjectV2SingleSelectField {
            id name
            options { id name }
          }
        }
      }
    }
  }
}' -f project="$PROJECT_ID" \
  --jq '.data.node.fields.nodes[] | select(.name=="Status") | .id' 2>/dev/null)

OPTION_ID=$(gh api graphql -f query='
query($project: ID!) {
  node(id: $project) {
    ... on ProjectV2 {
      fields(first: 20) {
        nodes {
          ... on ProjectV2SingleSelectField {
            name
            options { id name }
          }
        }
      }
    }
  }
}' -f project="$PROJECT_ID" \
  --jq ".data.node.fields.nodes[] | select(.name==\"Status\") | .options[] | select(.name==\"$STATUS_VALUE\") | .id" 2>/dev/null)

gh api graphql -f mutation="mutation {
  updateProjectV2ItemFieldValue(input: {
    projectId: \"$PROJECT_ID\"
    itemId: \"$ITEM_ID_BOARD\"
    fieldId: \"$STATUS_FIELD_ID\"
    value: { singleSelectOptionId: \"$OPTION_ID\" }
  }) { projectV2Item { id } }
}" 2>/dev/null && echo "[PM] Board status set to $STATUS_VALUE for issue #$_ISSUE_NUM"
```

### 2. Milestone assignment (per item)

Every issue must be assigned the milestone matching its roadmap stage. COORD
reads the current active milestone from `otherness-config.yaml`:

```bash
ACTIVE_MILESTONE=$(python3 -c "
import re
section=None
for line in open('otherness-config.yaml'):
    s=re.match(r'^(\w[\w_]*):', line)
    if s: section=s.group(1)
    if section=='project':
        m=re.match(r'^\s+active_milestone:\s*[\"\'']?([^\"\'#\n]+)[\"\'']?', line)
        if m: print(m.group(1).strip()); break
" 2>/dev/null || echo "")

if [ -n "$ACTIVE_MILESTONE" ] && [ -n "$_ISSUE_NUM" ]; then
  # Get milestone number
  MILESTONE_NUM=$(gh api "repos/$REPO/milestones" \
    --jq ".[] | select(.title == \"$ACTIVE_MILESTONE\") | .number" 2>/dev/null)
  if [ -n "$MILESTONE_NUM" ]; then
    gh issue edit "$_ISSUE_NUM" --repo "$REPO" --milestone "$MILESTONE_NUM" 2>/dev/null && \
      echo "[PM] Milestone set to $ACTIVE_MILESTONE for issue #$_ISSUE_NUM"
  fi
fi
```

### 3. Epic creation and child linking

When a new design doc stage is started (a new design doc with Future items is
created), COORD opens an epic issue and links all child issues to it.

```bash
# When COORD generates issues from a new design doc:
EPIC_TITLE="Epic: <stage name> (design doc <N>)"
EPIC_NUM=$(gh issue create --repo "$REPO" \
  --title "$EPIC_TITLE" \
  --label "epic,$PR_LABEL" \
  --body "Tracks all issues for design doc docs/design/<N>-<area>.md.

## Child issues
<!-- Auto-populated by COORD as issues are created from this design doc -->

Design ref: docs/design/<N>-<area>.md" \
  --json number --jq '.number' 2>/dev/null)

# Link each child issue to the epic via parent_issue
for child_num in $CHILD_ISSUE_NUMS; do
  gh api "repos/$REPO/issues/$child_num" \
    --method PATCH \
    -f "body=$CHILD_BODY

Parent epic: #$EPIC_NUM" 2>/dev/null || true
done
```

### 4. speckit tasks.md — enforced, not aspirational

Before writing any code in ENG §2d, a `tasks.md` must exist. It is the
agent's commit to a verifiable work plan. The tasks are typed:

```markdown
# Tasks: issue-NNN <title>

## Pre-implementation
- [CMD] `cd $MY_WORKTREE && go build ./...` — verify clean build before changes
- [CMD] `cd $MY_WORKTREE && go test ./... 2>/dev/null | tail -5` — baseline test state

## Implementation
- [AI] Write <component>: <what it must do, one sentence per step>
- [CMD] `cd $MY_WORKTREE && <verification command>`
- [AI] Update spec.md: flip 🔲 → ✅ for this item

## Post-implementation
- [CMD] `cd $MY_WORKTREE && bash scripts/validate.sh 2>&1 | tail -3` — validate
- [CMD] `cd $MY_WORKTREE && <lint/test command>`
```

**`[AI]` steps require judgment** — the agent decides how.
**`[CMD]` steps are deterministic** — a specific command with a specific expected output.

If a `[CMD]` step fails: stop. Fix before proceeding. Do not skip `[CMD]` steps.
If a `[AI]` step is ambiguous: re-read spec.md Zone 1 before acting.

---

## Present (✅)

- ✅ 43.1 — `otherness-config-template.yaml`: added `project.board_project_id` (GraphQL node ID of the GitHub Projects v2 board) and `project.active_milestone` fields under the `project:` section, with documentation comments explaining their purpose and how to find the values. When set, these fields are read by COORD, ENG, and QA to set board status and milestone. When empty: all board operations are silently skipped.
- ✅ 43.3 — COORD §1e: when claiming an item (after posting the claim comment), set board `Status: In Progress` for the issue via GraphQL mutation. Non-blocking: failure (no board configured, API error) is silently skipped. Reads `board_project_id` from `project.board_project_id` in config. (PR #925, 2026-04-22)

---

## Future (🔲)

- 🔲 43.2 — COORD §1d: when creating a GitHub issue, immediately add it to the project board with `Status: Todo` and set the `active_milestone`. Two API calls after `gh issue create`.
- 🔲 43.4 — ENG §2f: when opening the PR, set board `Status: In Review`. One GraphQL mutation.
- 🔲 43.5 — QA §3e: when merging PR (same block that closes the issue), set board `Status: Done`. One GraphQL mutation alongside `gh issue close`.
- 🔲 43.6 — SM §4a triage: when a `needs-human` issue is open >48h or CI is red >24h, set board `Status: Blocked`. Clear it when the issue is closed.
- 🔲 43.7 — COORD §1d: when a new design doc is introduced (new file in docs/design/ with Future items), create an epic issue and link all generated child issues to it. Epic title: "Epic: <design doc title> (doc <N>)".
- 🔲 43.8 — ENG §2b: `tasks.md` creation is mandatory before code. If `.specify/specs/$ITEM_ID/tasks.md` does not exist when ENG §2d starts: create it with the typed task structure ([AI] / [CMD]) BEFORE writing any code. QA §3b must verify tasks.md exists and has at least one [CMD] verification step. No tasks.md = WRONG finding.
- 🔲 43.9 — Backfill: set `active_milestone` on all open issues on kardinal-promoter (v0.6.0) and kro-ui (v0.10.0). Add them to the project board with `Status: Todo`. Run once as a chore issue.

---

## Zone 1 — Obligations

**O1 — Every issue in the work queue has a board status that reflects reality.**
A human looking at the board must see the actual state: Todo = queued, In Progress = claimed,
In Review = PR open, Done = merged, Blocked = stuck. No issue stays on `No Status` after
being created by COORD.

**O2 — Every issue is assigned the active milestone at creation time.**
`project.active_milestone` in `otherness-config.yaml` is the source of truth. If the field
is empty, no milestone is assigned (graceful degradation). If it is set, COORD always assigns
it at issue creation.

**O3 — tasks.md is written before code, not after.**
An ENG phase that writes code without a tasks.md is violating the spec. QA must reject PRs
where the `.specify/specs/$ITEM_ID/tasks.md` file is absent.

**O4 — Epics are open while work is in progress, closed when the design doc stage is done.**
An epic is closed when all its child issues are closed. COORD opens the epic when it generates
the first child issue from a design doc. SM §4a closes the epic when all children are done.

**O5 — Board operations are non-blocking.** A GraphQL mutation failure must never
stop the agent loop. `2>/dev/null || true` on all board update calls.

---

## Zone 2 — Implementer's judgment

- GraphQL mutations for board status require the project item ID, which requires a query.
  Cache `ITEM_ID_BOARD` in the session's env (set once in ENG §2a, reuse in §2f and QA).
- For repos without a project board configured (`board_project_id` empty), skip all board
  operations silently. Log `[PM] No board configured — skipping status update.`
- The `active_milestone` should be updated in `otherness-config.yaml` when a new version
  milestone is created — this is a human action (creating the milestone) paired with a
  config update (setting `active_milestone`).

---

## Zone 3 — Scoped out

- GitHub Projects automations (built-in Rules) — we use explicit API calls, not platform automations
- Sub-issue relationships via GitHub's native parent/child (beta) — we use body text links for now
- Multiple parallel milestones — one active milestone per project at a time
- Sprint or iteration fields — not needed at current team size
