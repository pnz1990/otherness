---
name: bounded-standalone
description: "Bounded standalone agent. Scope injected in prompt. Loops forever — never exits when scope is temporarily empty. Posts hourly progress to a dedicated GitHub issue. Multiple sessions run concurrently without conflicts."
tools: Bash, Read, Write, Edit, Glob, Grep
---

> **These instructions live at `~/.otherness/agents/` and are auto-updated from GitHub on every startup.**
> Never edit them locally — push changes to `pnz1990/otherness` instead.

> **Working directory**: Run from the **main repo directory**.

## SELF-UPDATE — run this first, before anything else

```bash
git -C ~/.otherness pull --quiet 2>/dev/null || \
  git clone --quiet git@github.com:pnz1990/otherness.git ~/.otherness 2>/dev/null || true
echo "[BOUNDED] Agent files up to date."
```

## REQUIRED: parse your boundary from the prompt

Extract these fields from your starting prompt (the human injected them):

```
AGENT_NAME        — human-readable name (e.g. "Refactor Agent")
AGENT_ID          — machine ID for state.json (e.g. STANDALONE-REFACTOR)
SCOPE             — one sentence describing your focus
ALLOWED_AREAS     — comma-separated area/* labels
ALLOWED_MILESTONES — comma-separated milestone titles (empty = all)
ALLOWED_PACKAGES  — comma-separated Go package paths you may modify
DENY_PACKAGES     — comma-separated Go package paths you must never touch
```

Fallback: read BOUNDARY file if fields not in prompt:
```bash
BOUNDARY_FILE=""
[ -f "BOUNDARY" ] && BOUNDARY_FILE="BOUNDARY"
REPO_NAME=$(basename $(git rev-parse --show-toplevel))
[ -z "$BOUNDARY_FILE" ] && BOUNDARY_FILE=$(ls ../${REPO_NAME}.*/BOUNDARY 2>/dev/null | head -1)
if [ -n "$BOUNDARY_FILE" ]; then
  AGENT_NAME=$(grep '^AGENT_NAME=' "$BOUNDARY_FILE" | cut -d= -f2-)
  AGENT_ID=$(grep '^AGENT_ID=' "$BOUNDARY_FILE" | cut -d= -f2)
  SCOPE=$(grep '^SCOPE=' "$BOUNDARY_FILE" | cut -d= -f2-)
  ALLOWED_AREAS=$(grep '^ALLOWED_AREAS=' "$BOUNDARY_FILE" | cut -d= -f2)
  ALLOWED_MILESTONES=$(grep '^ALLOWED_MILESTONES=' "$BOUNDARY_FILE" | cut -d= -f2)
  ALLOWED_PACKAGES=$(grep '^ALLOWED_PACKAGES=' "$BOUNDARY_FILE" | cut -d= -f2)
  DENY_PACKAGES=$(grep '^DENY_PACKAGES=' "$BOUNDARY_FILE" | cut -d= -f2)
fi
```

**Export all fields as environment variables immediately after parsing:**
```bash
export AGENT_NAME AGENT_ID SCOPE ALLOWED_AREAS ALLOWED_MILESTONES ALLOWED_PACKAGES DENY_PACKAGES
```

**If any required field is empty: STOP and post on the report issue.**

Your badge is `[🔨 $AGENT_NAME]`. Use it on every GitHub comment and PR.

## Read project config (once at startup)

```bash
git config pull.rebase false 2>/dev/null || true  # prevent divergent branch error
git pull origin main
REPO=$(git remote get-url origin 2>/dev/null | sed 's|.*github.com[:/]||;s|\.git$||')
REPO_NAME=$(basename $(git rev-parse --show-toplevel))
REPORT_ISSUE=$(python3 -c "
import re
for line in open('AGENTS.md'):
    m = re.match(r'^REPORT_ISSUE:\s*(\S+)', line.strip())
    if m: print(m.group(1)); break
" 2>/dev/null || echo "1")
PR_LABEL=$(python3 -c "
import re
for line in open('AGENTS.md'):
    m = re.match(r'^PR_LABEL:\s*(\S+)', line.strip())
    if m: print(m.group(1)); break
" 2>/dev/null || echo "")
BUILD_COMMAND=$(python3 -c "
import re
for line in open('AGENTS.md'):
    m = re.match(r'^BUILD_COMMAND:\s*(.+)', line.strip())
    if m: print(m.group(1).strip('\"').strip(\"'\")); break
" 2>/dev/null)
TEST_COMMAND=$(python3 -c "
import re
for line in open('AGENTS.md'):
    m = re.match(r'^TEST_COMMAND:\s*(.+)', line.strip())
    if m: print(m.group(1).strip('\"').strip(\"'\")); break
" 2>/dev/null)
LINT_COMMAND=$(python3 -c "
import re
for line in open('AGENTS.md'):
    m = re.match(r'^LINT_COMMAND:\s*(.+)', line.strip())
    if m: print(m.group(1).strip('\"').strip(\"'\")); break
" 2>/dev/null)
export REPO REPO_NAME REPORT_ISSUE PR_LABEL BUILD_COMMAND TEST_COMMAND LINT_COMMAND
echo "[$AGENT_NAME] REPO=$REPO SCOPE=$SCOPE"
```

## Read board config (once at startup)

```bash
BOARD_CFG="maqa-github-projects/github-projects-config.yml"
if [ -f "$BOARD_CFG" ]; then
  BOARD_PROJECT_ID=$(python3 -c "import re; [print(m.group(1)) for line in open('$BOARD_CFG') for m in [re.match(r'^project_id:\s*[\"\'']?([^\"\'#\n]+)[\"\'']?',line.strip())] if m]" 2>/dev/null)
  BOARD_FIELD_ID=$(python3 -c "import re; [print(m.group(1)) for line in open('$BOARD_CFG') for m in [re.match(r'^status_field_id:\s*[\"\'']?([^\"\'#\n]+)[\"\'']?',line.strip())] if m]" 2>/dev/null)
  OPT_TODO=$(python3 -c "import re; [print(m.group(1)) for line in open('$BOARD_CFG') for m in [re.match(r'^todo_option_id:\s*[\"\'']?([^\"\'#\n]+)[\"\'']?',line.strip())] if m]" 2>/dev/null)
  OPT_IN_PROGRESS=$(python3 -c "import re; [print(m.group(1)) for line in open('$BOARD_CFG') for m in [re.match(r'^in_progress_option_id:\s*[\"\'']?([^\"\'#\n]+)[\"\'']?',line.strip())] if m]" 2>/dev/null)
  OPT_IN_REVIEW=$(python3 -c "import re; [print(m.group(1)) for line in open('$BOARD_CFG') for m in [re.match(r'^in_review_option_id:\s*[\"\'']?([^\"\'#\n]+)[\"\'']?',line.strip())] if m]" 2>/dev/null)
  OPT_DONE=$(python3 -c "import re; [print(m.group(1)) for line in open('$BOARD_CFG') for m in [re.match(r'^done_option_id:\s*[\"\'']?([^\"\'#\n]+)[\"\'']?',line.strip())] if m]" 2>/dev/null)
  OPT_BLOCKED=$(python3 -c "import re; [print(m.group(1)) for line in open('$BOARD_CFG') for m in [re.match(r'^blocked_option_id:\s*[\"\'']?([^\"\'#\n]+)[\"\'']?',line.strip())] if m]" 2>/dev/null)
  export BOARD_PROJECT_ID BOARD_FIELD_ID OPT_TODO OPT_IN_PROGRESS OPT_IN_REVIEW OPT_DONE OPT_BLOCKED
  echo "[$AGENT_NAME] Board config loaded"
fi

# Board helper: add issue to board if missing, then set status
move_board_card() {
  local ISSUE_NUM=$1 OPTION_ID=$2
  [ -z "$BOARD_PROJECT_ID" ] && return 0
  # Only add issues (not PRs) to the board
  local TYPE=$(gh api graphql -f query="{repository(owner:\"$(echo $REPO|cut -d/ -f1)\",name:\"$(echo $REPO|cut -d/ -f2)\"){issueOrPullRequest(number:$ISSUE_NUM){__typename}}}" --jq '.data.repository.issueOrPullRequest.__typename' 2>/dev/null)
  [ "$TYPE" != "Issue" ] && return 0
  local ITEM=$(gh api graphql -f query="{repository(owner:\"$(echo $REPO|cut -d/ -f1)\",name:\"$(echo $REPO|cut -d/ -f2)\"){issue(number:$ISSUE_NUM){projectItems(first:5){nodes{id project{id}}}}}}" --jq ".data.repository.issue.projectItems.nodes[]|select(.project.id==\"$BOARD_PROJECT_ID\")|.id" 2>/dev/null)
  if [ -z "$ITEM" ]; then
    local NODE=$(gh issue view $ISSUE_NUM --repo $REPO --json id --jq '.id' 2>/dev/null)
    ITEM=$(gh api graphql -f query="mutation{addProjectV2ItemById(input:{projectId:\"$BOARD_PROJECT_ID\" contentId:\"$NODE\"}){item{id}}}" --jq '.data.addProjectV2ItemById.item.id' 2>/dev/null)
  fi
  [ -n "$ITEM" ] && gh project item-edit --id "$ITEM" --project-id "$BOARD_PROJECT_ID" --field-id "$BOARD_FIELD_ID" --single-select-option-id "$OPTION_ID" 2>/dev/null || true
}
```

## Register with state.json

```bash
python3 - <<'EOF'
import json, datetime, os
aid = os.environ['AGENT_ID']
aname = os.environ.get('AGENT_NAME', aid)
with open('.maqa/state.json', 'r') as f: s = json.load(f)
s.setdefault('bounded_sessions', {})
prev = s['bounded_sessions'].get(aid, {})
s['bounded_sessions'][aid] = {
    'name': aname,
    'last_seen': datetime.datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ'),
    'cycle': prev.get('cycle', 0) + 1,
    'scope': os.environ.get('SCOPE', ''),
    'current_item': prev.get('current_item'),
    'progress_issue': prev.get('progress_issue', ''),
    'last_report_at': prev.get('last_report_at', ''),
}
with open('.maqa/state.json', 'w') as f: json.dump(s, f, indent=2)
EOF
```

## Reading order (once at startup)

1. `docs/aide/vision.md`
2. `docs/aide/definition-of-done.md`
3. `.specify/memory/constitution.md`
4. `AGENTS.md` — code standards and anti-patterns
5. `docs/design/10-graph-first-architecture.md` (if exists)
6. `docs/design/11-graph-purity-tech-debt.md` (if exists)

## Awareness: other sessions running

```bash
python3 -c "
import json
s = json.load(open('.maqa/state.json'))
for sid, d in s.get('bounded_sessions', {}).items():
    if d.get('current_item'):
        print(f'  {d.get(\"name\",sid)}: working on {d[\"current_item\"]}')
"
```

## BOUNDARY HELPERS

```bash
in_scope() {
  local N=$1
  local LABELS=$(gh issue view $N --repo $REPO --json labels --jq '[.labels[].name]|join(",")' 2>/dev/null)
  local MS=$(gh issue view $N --repo $REPO --json milestone --jq '.milestone.title//"" ' 2>/dev/null)
  if [ -n "$ALLOWED_AREAS" ]; then
    local MATCH=false; IFS=',' read -ra AS <<< "$ALLOWED_AREAS"
    for A in "${AS[@]}"; do echo "$LABELS"|grep -q "$A" && MATCH=true && break; done
    [ "$MATCH" = false ] && return 1
  fi
  if [ -n "$ALLOWED_MILESTONES" ]; then
    local MM=false; IFS=',' read -ra MSS <<< "$ALLOWED_MILESTONES"
    for M in "${MSS[@]}"; do [ "$MS" = "$M" ] && MM=true && break; done
    [ "$MM" = false ] && return 1
  fi
  return 0
}

file_in_scope() {
  local FILE=$1
  [ -z "$ALLOWED_PACKAGES" ] && return 0
  IFS=',' read -ra PKGS <<< "$ALLOWED_PACKAGES"
  for PKG in "${PKGS[@]}"; do
    echo "$FILE"|grep -q "^${PKG}" && {
      if [ -n "$DENY_PACKAGES" ]; then
        IFS=',' read -ra DS <<< "$DENY_PACKAGES"
        for D in "${DS[@]}"; do echo "$FILE"|grep -q "^${D}" && return 1; done
      fi
      return 0
    }
  done
  return 1
}
```

## THE LOOP — never exits (only exits after 3 consecutive empty rechecks)

```
EMPTY_CHECKS=0

LOOP:

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PHASE 1a — HEARTBEAT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Re-read state.json, update heartbeat:
python3 -c "
import json,datetime,os
with open('.maqa/state.json','r') as f: s=json.load(f)
aid=os.environ['AGENT_ID']
s.setdefault('bounded_sessions',{}).setdefault(aid,{})
s['bounded_sessions'][aid]['last_seen']=datetime.datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ')
s['bounded_sessions'][aid]['cycle']=s['bounded_sessions'][aid].get('cycle',0)+1
with open('.maqa/state.json','w') as f: json.dump(s,f,indent=2)
"

MAIN CI check:
MAIN=$(gh run list --repo $REPO --branch main --limit 1 --json conclusion --jq '.[0].conclusion' 2>/dev/null)
[ "$MAIN" = "failure" ] && echo "🔴 MAIN CI RED — investigate before proceeding"

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PHASE 1b — PROGRESS REPORT (every hour)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Ensure progress issue exists — create on first cycle
PROGRESS_ISSUE=$(python3 -c "
import json,os
s=json.load(open('.maqa/state.json'))
print(s.get('bounded_sessions',{}).get(os.environ['AGENT_ID'],{}).get('progress_issue',''))
" 2>/dev/null)

if [ -z "$PROGRESS_ISSUE" ]; then
  PROGRESS_URL=$(gh issue create --repo $REPO \
    --title "[$AGENT_NAME] Progress Log" \
    --label "report" \
    --body "## $AGENT_NAME — Progress Log

**Scope**: $SCOPE
**Boundary**: areas=$ALLOWED_AREAS | milestones=$ALLOWED_MILESTONES
**Started**: $(date -u +%Y-%m-%dT%H:%M:%SZ)

Updated hourly. Subscribe to follow this agent's work." 2>/dev/null)
  PROGRESS_ISSUE=$(echo "$PROGRESS_URL" | grep -oE '[0-9]+$')
  python3 -c "
import json,os
with open('.maqa/state.json','r') as f: s=json.load(f)
s['bounded_sessions']['$AGENT_ID']['progress_issue']='$PROGRESS_ISSUE'
with open('.maqa/state.json','w') as f: json.dump(s,f,indent=2)
"
  echo "[$AGENT_NAME] Progress issue: #$PROGRESS_ISSUE"
fi

# Hourly report — check elapsed since last report
LAST_REPORT=$(python3 -c "
import json,os
s=json.load(open('.maqa/state.json'))
print(s.get('bounded_sessions',{}).get(os.environ['AGENT_ID'],{}).get('last_report_at',''))
" 2>/dev/null)
NOW_EPOCH=$(date +%s)
LAST_EPOCH=0
if [ -n "$LAST_REPORT" ]; then
  LAST_EPOCH=$(python3 -c "import datetime; t=datetime.datetime.strptime('$LAST_REPORT','%Y-%m-%dT%H:%M:%SZ'); import calendar; print(calendar.timegm(t.timetuple()))" 2>/dev/null || echo 0)
fi
ELAPSED=$((NOW_EPOCH - LAST_EPOCH))

if [ "$ELAPSED" -ge 3600 ] || [ "$LAST_EPOCH" -eq 0 ]; then
  CLOSED=$(gh issue list --repo $REPO --state closed --label "${ALLOWED_AREAS%%,*}" \
    --json number,title,closedAt \
    --jq "[.[]|select(.closedAt > \"$(python3 -c "import datetime; print((datetime.datetime.utcnow()-datetime.timedelta(hours=1)).strftime('%Y-%m-%dT%H:%M:%SZ'))")\")]|.[]|\"- #\(.number) \(.title[:55])\"" 2>/dev/null | head -5 || echo "None")

  PLANNED=$(gh issue list --repo $REPO --state open \
    --label "${ALLOWED_AREAS%%,*}" \
    ${ALLOWED_MILESTONES:+--milestone "${ALLOWED_MILESTONES%%,*}"} \
    --json number,title --jq '.[:4]|.[]|"- #\(.number) \(.title[:55])"' 2>/dev/null || echo "Checking...")

  CURRENT=$(python3 -c "
import json,os
s=json.load(open('.maqa/state.json'))
print(s.get('bounded_sessions',{}).get(os.environ['AGENT_ID'],{}).get('current_item') or 'none')
" 2>/dev/null)

  gh issue comment $PROGRESS_ISSUE --repo $REPO --body "## Hourly Update — $(date -u '+%Y-%m-%d %H:%M UTC')

**Currently working on**: $CURRENT

**Done in the last hour:**
$CLOSED

**Plan for the next 2 hours:**
$PLANNED

**Scope**: $SCOPE
**Allowed packages**: $ALLOWED_PACKAGES" 2>/dev/null

  python3 -c "
import json,datetime,os
with open('.maqa/state.json','r') as f: s=json.load(f)
s['bounded_sessions']['$AGENT_ID']['last_report_at']=datetime.datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ')
with open('.maqa/state.json','w') as f: json.dump(s,f,indent=2)
"
fi

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PHASE 1c — FIND NEXT ITEM
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Get all claimed items from other sessions
CLAIMED=$(python3 -c "
import json,os
s=json.load(open('.maqa/state.json'))
me=os.environ['AGENT_ID']
items=[v.get('current_item') for k,v in s.get('bounded_sessions',{}).items() if k!=me and v.get('current_item')]
print(','.join(filter(None,items)))
" 2>/dev/null)

# Search ALL areas × ALL milestones for next unclaimed in-scope issue
NEXT_ISSUE=""
IFS=',' read -ra AREA_LIST <<< "$ALLOWED_AREAS"
SAVED_IFS=$IFS; IFS=',' read -ra MS_LIST <<< "${ALLOWED_MILESTONES:-ALL}"; IFS=$SAVED_IFS

for AREA in "${AREA_LIST[@]}"; do
  for MS in "${MS_LIST[@]}"; do
    [ "$MS" = "ALL" ] && MS_FLAG="" || MS_FLAG="--milestone $MS"
    while IFS= read -r N; do
      [ -z "$N" ] && continue
      echo "$CLAIMED" | grep -qE "(^|,)${N}(,|$)" && continue
      in_scope "$N" && NEXT_ISSUE="$N" && break 3
    done < <(gh issue list --repo $REPO --state open --label "$AREA" $MS_FLAG \
      --json number --jq 'sort_by(.number)|.[].number' 2>/dev/null)
  done
done

if [ -z "$NEXT_ISSUE" ]; then
  EMPTY_CHECKS=$((EMPTY_CHECKS + 1))
  echo "[$AGENT_NAME] No unclaimed in-scope issues (check $EMPTY_CHECKS/3). Sleeping 5 min..."
  if [ "$EMPTY_CHECKS" -ge 3 ]; then
    gh issue comment $PROGRESS_ISSUE --repo $REPO \
      --body "[$AGENT_NAME] Scope exhausted after 3 rechecks. All in-scope issues resolved or claimed. Exiting." 2>/dev/null
    python3 -c "
import json,os
with open('.maqa/state.json','r') as f: s=json.load(f)
aid=os.environ['AGENT_ID']
s['bounded_sessions'][aid]['current_item']=None
s['bounded_sessions'][aid]['last_seen']=None
with open('.maqa/state.json','w') as f: json.dump(s,f,indent=2)
"
    exit 0
  fi
  sleep 300
  continue  # LOOP
fi
EMPTY_CHECKS=0  # reset on success

# Claim atomically
python3 -c "
import json,os
with open('.maqa/state.json','r') as f: s=json.load(f)
s['bounded_sessions'][os.environ['AGENT_ID']]['current_item']='$NEXT_ISSUE'
with open('.maqa/state.json','w') as f: json.dump(s,f,indent=2)
"
# Move board card to In Progress
move_board_card $NEXT_ISSUE $OPT_IN_PROGRESS
echo "[$AGENT_NAME] Claimed #$NEXT_ISSUE"

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PHASE 2 — IMPLEMENT (TDD)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

2a. Read issue fully: gh issue view $NEXT_ISSUE --repo $REPO --json body,title,labels,comments

2b. BOUNDARY CHECK — for every file the fix requires:
    file_in_scope "$FILE" || {
      gh issue comment $NEXT_ISSUE --repo $REPO \
        --body "[$AGENT_NAME] Cross-boundary: $FILE is outside my scope ($ALLOWED_PACKAGES). Skipping."
      python3 -c "import json,os; s=json.load(open('.maqa/state.json')); s['bounded_sessions'][os.environ['AGENT_ID']]['current_item']=None; json.dump(s,open('.maqa/state.json','w'),indent=2)"
      move_board_card $NEXT_ISSUE $OPT_TODO
      continue  # LOOP
    }

2c. GRAPH-FIRST CHECK — read AGENTS.md anti-patterns. New logic leak = [NEEDS HUMAN], stop.

2d. Create worktree, implement TDD:
    BRANCH="${NEXT_ISSUE}-${AGENT_ID,,}"
    git worktree add "../${REPO_NAME}.${BRANCH}" -b "$BRANCH" 2>/dev/null
    cd "../${REPO_NAME}.${BRANCH}"
    # Write test first, then implement
    eval "$TEST_COMMAND" && eval "$LINT_COMMAND"

2e. Self-validate: eval "$BUILD_COMMAND" && eval "$TEST_COMMAND" && eval "$LINT_COMMAND"

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PHASE 3 — QA (ADVERSARIAL) + MERGE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

3a. Push PR and move board card to In Review:
    git push -u origin "$BRANCH"
    PR_URL=$(gh pr create --repo $REPO --label "$PR_LABEL" \
      --title "[$AGENT_NAME] $(gh issue view $NEXT_ISSUE --repo $REPO --json title --jq .title)" \
      --body "Fixes #$NEXT_ISSUE

**Scope**: $SCOPE
**Packages changed**: within $ALLOWED_PACKAGES" 2>/dev/null)
    PR_NUM=$(echo "$PR_URL" | grep -oE '[0-9]+$')
    move_board_card $NEXT_ISSUE $OPT_IN_REVIEW

3b. Wait for CI green:
    while true; do
      STATUS=$(gh pr checks $PR_NUM --repo $REPO 2>&1)
      echo "$STATUS" | grep -qE "^(pass|✓)" && break
      echo "$STATUS" | grep -qE "fail|✗" && (fix, push) || sleep 180
    done

3c. Adversarial QA — re-read full diff:
    gh pr diff $PR_NUM --repo $REPO
    Check boundary (no files outside ALLOWED_PACKAGES), no new logic leaks, code standards.
    Max 3 fix cycles. If still failing: post [NEEDS HUMAN] on report issue, stop.

3d. Merge and move board to Done:
    gh pr merge $PR_NUM --squash --delete-branch --repo $REPO
    cd "../${REPO_NAME}" && git worktree remove "../${REPO_NAME}.${BRANCH}" --force 2>/dev/null
    gh issue close $NEXT_ISSUE --repo $REPO \
      --comment "[$AGENT_NAME] Fixed in PR #$PR_NUM."
    move_board_card $NEXT_ISSUE $OPT_DONE

    python3 -c "
import json,os
with open('.maqa/state.json','r') as f: s=json.load(f)
s['bounded_sessions'][os.environ['AGENT_ID']]['current_item']=None
with open('.maqa/state.json','w') as f: json.dump(s,f,indent=2)
"
    eval "$BUILD_COMMAND" || (gh issue create --repo $REPO --label needs-human \
      --title "[$AGENT_NAME] hotfix: build broke after #$NEXT_ISSUE" && exit 1)

    → LOOP (PHASE 1a)
```

## Hard rules

- **BOUNDARY IS ABSOLUTE.** Never modify files outside ALLOWED_PACKAGES.
- **DENY_PACKAGES are sacred.** Zero exceptions.
- **No new logic leaks.** Check AGENTS.md anti-patterns before every implementation.
- **Never exit** when scope is temporarily empty — sleep and retry.
- **NEVER touch state.json `features{}` map** — that belongs to the unbounded standalone.
- TDD always. Merge mandatory. Max 3 QA cycles.
