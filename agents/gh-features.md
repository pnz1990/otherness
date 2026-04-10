# GitHub Project Management — Full Feature Reference
# Read this file when creating issues, epics, or managing the board.
# Field IDs are in maqa-github-projects/github-projects-config.yml

## Label taxonomy (set on every issue at creation)

### Required on all item issues
- `kind/*` — one of: `kind/enhancement`, `kind/bug`, `kind/chore`, `kind/docs`, `kind/security`
- `area/*` — read the area labels from the `AGENTS.md` label taxonomy section of your project.
  Each project defines its own area labels (e.g. area/controller, area/cli, area/api, etc.)
- `priority/*` — one of: `priority/critical`, `priority/high`, `priority/medium`, `priority/low`
- `size/*` — one of: `size/xs`, `size/s`, `size/m`, `size/l`, `size/xl`

### Required on epic issues
- `epic`
- `priority/*`

### Set automatically by agents
- `$PR_LABEL` (read from AGENTS.md) — on all feature item issues
- `needs-human` — when escalating
- `blocked` — when item is blocked

## Board field updates (after creating/updating issues)

Read all field IDs from `maqa-github-projects/github-projects-config.yml`.

### Set Priority on a board item
```bash
PRIORITY_FIELD=$(python3 -c "import re; [print(m.group(1)) for line in open('maqa-github-projects/github-projects-config.yml') for m in [re.match(r'^priority_field_id:\s*\"?([^\"#\n]+)\"?',line)] if m]")
PRIORITY_HIGH=$(python3 -c "import re; [print(m.group(1)) for line in open('maqa-github-projects/github-projects-config.yml') for m in [re.match(r'^priority_high_option_id:\s*\"?([^\"#\n]+)\"?',line)] if m]")
gh project item-edit --id $BOARD_ITEM_ID --project-id $BOARD_PROJECT_ID \
  --field-id $PRIORITY_FIELD --single-select-option-id $PRIORITY_HIGH
```

### Set Size on a board item
```bash
SIZE_FIELD=$(python3 -c "import re; [print(m.group(1)) for line in open('maqa-github-projects/github-projects-config.yml') for m in [re.match(r'^size_field_id:\s*\"?([^\"#\n]+)\"?',line)] if m]")
SIZE_M=$(python3 -c "import re; [print(m.group(1)) for line in open('maqa-github-projects/github-projects-config.yml') for m in [re.match(r'^size_m_option_id:\s*\"?([^\"#\n]+)\"?',line)] if m]")
gh project item-edit --id $BOARD_ITEM_ID --project-id $BOARD_PROJECT_ID \
  --field-id $SIZE_FIELD --single-select-option-id $SIZE_M
```

### Set Target date on a board item (epics get milestone due date)
```bash
TARGET_DATE_FIELD=$(python3 -c "import re; [print(m.group(1)) for line in open('maqa-github-projects/github-projects-config.yml') for m in [re.match(r'^target_date_field_id:\s*\"?([^\"#\n]+)\"?',line)] if m]")
# Derive TARGET_DATE from the milestone due date:
TARGET_DATE=$(gh api repos/$REPO/milestones --jq \
  '[.[] | select(.title == "'"$CURRENT_MILESTONE_TITLE"'")] | .[0].due_on // empty' \
  2>/dev/null | cut -c1-10)
[ -z "$TARGET_DATE" ] && TARGET_DATE=$(date -u -d '+90 days' +%Y-%m-%d 2>/dev/null || date -u -v+90d +%Y-%m-%d)
gh project item-edit --id $BOARD_ITEM_ID --project-id $BOARD_PROJECT_ID \
  --field-id $TARGET_DATE_FIELD --date "$TARGET_DATE"
```

### Set Team field (STANDALONE-ENG)
```bash
TEAM_FIELD=$(python3 -c "import re; [print(m.group(1)) for line in open('maqa-github-projects/github-projects-config.yml') for m in [re.match(r'^team_field_id:\s*\"?([^\"#\n]+)\"?',line)] if m]")
STANDALONE_TEAM=$(python3 -c "import re; [print(m.group(1)) for line in open('maqa-github-projects/github-projects-config.yml') for m in [re.match(r'^team_standalone_option_id:\s*\"?([^\"#\n]+)\"?',line)] if m]")
gh project item-edit --id $BOARD_ITEM_ID --project-id $BOARD_PROJECT_ID \
  --field-id $TEAM_FIELD --single-select-option-id $STANDALONE_TEAM
```

## Sub-issues (linking items to their epic)

Every item issue must be linked as a sub-issue of its milestone epic.

```bash
# Get epic issue node ID for the current milestone.
# Find the epic whose title best matches the item's capability area.
# List all epics for the milestone and pick the most relevant one:
EPICS=$(gh issue list --repo $REPO --milestone "$CURRENT_MILESTONE_TITLE" \
  --label "epic" --json id,number,title --jq '.[]')
# Select the epic whose title matches the item's area/stage.
# If only one epic exists for the milestone, use it directly:
EPIC_ID=$(gh issue list --repo $REPO --milestone "$CURRENT_MILESTONE_TITLE" \
  --label "epic" --json id,number --jq '.[0].id')

# Get item issue node ID  
ITEM_ID=$(gh issue view $ITEM_ISSUE_NUM --repo $REPO --json id --jq '.id')

# Link as sub-issue
gh api graphql -f query="
mutation {
  addSubIssue(input: {
    issueId: \"$EPIC_ID\"
    subIssueId: \"$ITEM_ID\"
  }) {
    issue { number }
    subIssue { number }
  }
}"
```

The parent epic shows a progress bar automatically as sub-issues are closed.

## Epic issue creation (PM responsibility)

When creating a new epic:
1. Create the issue with labels `epic`, `priority/high`
2. Set milestone
3. Add to board: `gh api graphql -f query='mutation { addProjectV2ItemById(...) }'`
4. Set Priority, Size (XL), Target date fields on the board item
5. Link existing item issues as sub-issues immediately

## Item issue creation (coordinator/standalone responsibility)

When creating a new item issue:
1. `gh issue create --repo $REPO --milestone "$MILESTONE" --label "$PR_LABEL,$KIND,$AREA,$PRIORITY,$SIZE"`
2. Add to board using the **robust add-or-update pattern** (never assume item is already on board):
```bash
# Step 1: get issue node ID
NODE_ID=$(gh issue view $ISSUE_NUM --repo $REPO --json id --jq '.id')

# Step 2: check if already on board
BOARD_ITEM_ID=$(gh api graphql -f query="
{
  repository(owner: \"<owner>\", name: \"<repo>\") {
    issue(number: $ISSUE_NUM) {
      projectItems(first: 5) { nodes { id project { id } } }
    }
  }
}" --jq ".data.repository.issue.projectItems.nodes[] | select(.project.id == \"$BOARD_PROJECT_ID\") | .id" 2>/dev/null)

# Step 3: add if not already on board
if [ -z "$BOARD_ITEM_ID" ]; then
  BOARD_ITEM_ID=$(gh api graphql -f query="
  mutation {
    addProjectV2ItemById(input: {
      projectId: \"$BOARD_PROJECT_ID\"
      contentId: \"$NODE_ID\"
    }) { item { id } }
  }" --jq '.data.addProjectV2ItemById.item.id' 2>/dev/null)
fi

# Step 4: set Status, Priority, Size fields
gh project item-edit --id "$BOARD_ITEM_ID" --project-id "$BOARD_PROJECT_ID" \
  --field-id "$STATUS_FIELD" --single-select-option-id "$OPT_TODO"
# ... set Priority and Size similarly
```
**IMPORTANT**: Only add issues (not PRs) to the board. Always check
`__typename == "Issue"` before calling `addProjectV2ItemById`.

3. Link as sub-issue of the milestone epic: `addSubIssue` mutation
4. The board Backlog view, Roadmap view, and milestone page all update automatically

## Board views — what each shows the manager

| View | Layout | Purpose | What to check |
|------|---------|---------|---------------|
| 📋 Backlog | Table, grouped by Milestone | Full backlog — all items across all milestones | Overall project health, milestone progress |
| 🗺️ Roadmap (Epics) | Table, filtered label:epic, grouped by Milestone | Product plan — epics with sub-issue progress bars | Are epics progressing? Which milestone is next? |
| 🏃 Sprint | Board, filtered to current milestone, no epics | Day-to-day task status | Nothing should sit in "In Progress" for > 2 days |

Note: view names and filters are configured in the GitHub Projects UI (not via API).
The above names are a recommended convention — configure them once in the UI.

## Project status updates (PM responsibility, each batch)

Post a project-level status update after each batch review:
```bash
# Mark project status (On track / At risk / Off track)
gh api graphql -f query='
mutation {
  updateProjectV2(input: {
    projectId: "'"$BOARD_PROJECT_ID"'"
    shortDescription: "<current milestone title> — <N>/<total> items done"
  }) {
    projectV2 { title shortDescription }
  }
}'
```
