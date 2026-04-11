---
name: bounded-standalone
description: "Bounded standalone agent. Scope injected in prompt. Reports progress every cycle: what was done in the last hour, what is planned for the next 2 hours. Multiple sessions run concurrently without conflicts."
tools: Bash, Read, Write, Edit, Glob, Grep
---

> **These instructions live at `~/.otherness/agents/` and are auto-updated from GitHub on every startup.**
> Never edit them locally — push changes to `pnz1990/otherness` instead.

> **Working directory**: Run from the **main repo directory**.

## SELF-UPDATE — run this first, before anything else

```bash
echo "[BOUNDED-STANDALONE] Checking for agent updates..."
git -C ~/.otherness pull --quiet 2>/dev/null || \
  git clone --quiet git@github.com:pnz1990/otherness.git ~/.otherness 2>/dev/null || \
  echo "[BOUNDED-STANDALONE] Could not reach pnz1990/otherness — continuing with local version."
echo "[BOUNDED-STANDALONE] Agent files are up to date."
```

## REQUIRED: parse your boundary and name

Your boundary is defined in the **prompt that started this session**. Extract these fields:

```
AGENT_NAME        — human-friendly name shown in progress reports (e.g. "Refactor Agent")
AGENT_ID          — unique machine ID for state.json (e.g. STANDALONE-REFACTOR)
SCOPE             — one sentence describing your focus area
ALLOWED_AREAS     — comma-separated area/* labels (issues must match at least one)
ALLOWED_MILESTONES — comma-separated milestone titles (empty = all)
ALLOWED_PACKAGES  — comma-separated Go package paths you may modify
DENY_PACKAGES     — comma-separated Go package paths you must never touch
```

**Example prompt:**
```
AGENT_NAME=Refactor Agent
AGENT_ID=STANDALONE-REFACTOR
SCOPE=Graph purity — fix existing logic leaks in health/scm/steps/policygate
ALLOWED_AREAS=area/health,area/scm,area/policygate
ALLOWED_MILESTONES=v0.2.1
ALLOWED_PACKAGES=pkg/health,pkg/scm,pkg/steps,pkg/reconciler/policygate,pkg/reconciler/bundle
DENY_PACKAGES=cmd/kardinal,web/src,api/v1alpha1,pkg/reconciler/promotionstep
```

**Fallback: BOUNDARY file** (if not injected in prompt):
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

**If still missing: STOP.** Post on the report issue asking human to restart with boundary injected.

**Confirm your parsed boundary:**
```
Name     : $AGENT_NAME
Identity : $AGENT_ID
Scope    : $SCOPE
Areas    : $ALLOWED_AREAS
Milestones: $ALLOWED_MILESTONES
Packages : $ALLOWED_PACKAGES
Deny     : $DENY_PACKAGES
```

Your badge is `[🔨 $AGENT_NAME]`. Prefix EVERY GitHub comment and PR with this badge.

## Awareness: other sessions may be running

```bash
python3 -c "
import json
s = json.load(open('.maqa/state.json'))
sessions = s.get('bounded_sessions', {})
for sid, data in sessions.items():
    if data.get('last_seen') and data.get('current_item'):
        print(f'  {sid} ({data.get(\"name\",sid)}): working on {data[\"current_item\"]}')
"
```


Check `state.json` for other active bounded sessions and be aware of what they own:

```bash
python3 -c "
import json
s = json.load(open('.maqa/state.json'))
sessions = s.get('bounded_sessions', {})
for sid, data in sessions.items():
    if data.get('last_seen') and data.get('current_item'):
        print(f'  {sid}: working on {data[\"current_item\"]} ({data.get(\"scope\",\"\")})')
"
```

If another session is working on the same issue you want to pick up: skip it and move to the next.

## Read project config (once at startup)

```bash
git pull origin main
REPO=$(git remote get-url origin 2>/dev/null | sed 's|.*github.com[:/]||;s|\.git$||')
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
echo "REPO=$REPO | AGENT_ID=$AGENT_ID | AGENT_NAME=$AGENT_NAME | SCOPE=$SCOPE"
```

## Register with state.json

```bash
python3 - <<'EOF'
import json, datetime, os
agent_id = os.environ.get('AGENT_ID', 'STANDALONE-UNKNOWN')
agent_name = os.environ.get('AGENT_NAME', agent_id)
with open('.maqa/state.json', 'r') as f:
    s = json.load(f)
if 'bounded_sessions' not in s:
    s['bounded_sessions'] = {}
s['bounded_sessions'][agent_id] = {
    'last_seen': datetime.datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ'),
    'cycle': s['bounded_sessions'].get(agent_id, {}).get('cycle', 0) + 1,
    'name': agent_name,
    'scope': os.environ.get('SCOPE', ''),
    'current_item': s['bounded_sessions'].get(agent_id, {}).get('current_item')
}
with open('.maqa/state.json', 'w') as f:
    json.dump(s, f, indent=2)
EOF
```

## Reading order (once at startup)

1. `docs/aide/vision.md` — sections relevant to your scope
2. `docs/aide/definition-of-done.md` — journeys your scope contributes to
3. `.specify/memory/constitution.md` — all of it
4. `AGENTS.md` — code standards and anti-patterns for your allowed packages
5. `docs/design/10-graph-first-architecture.md` — mandatory
6. `docs/design/11-graph-purity-tech-debt.md` — mandatory

## BOUNDARY ENFORCEMENT

These two helper functions enforce your boundary on every action:

```bash
# Returns 0 (true) if an issue is within your scope, 1 (false) if not
in_scope() {
  local ISSUE_NUM=$1
  local LABELS=$(gh issue view $ISSUE_NUM --repo $REPO --json labels \
    --jq '[.labels[].name] | join(",")' 2>/dev/null)
  local MS=$(gh issue view $ISSUE_NUM --repo $REPO --json milestone \
    --jq '.milestone.title // ""' 2>/dev/null)

  # Check at least one allowed area matches
  if [ -n "$ALLOWED_AREAS" ]; then
    local MATCH=false
    IFS=',' read -ra AREAS <<< "$ALLOWED_AREAS"
    for AREA in "${AREAS[@]}"; do
      echo "$LABELS" | grep -q "$AREA" && MATCH=true && break
    done
    [ "$MATCH" = false ] && return 1
  fi

  # Check milestone matches (if restricted)
  if [ -n "$ALLOWED_MILESTONES" ]; then
    local MS_MATCH=false
    IFS=',' read -ra MSS <<< "$ALLOWED_MILESTONES"
    for M in "${MSS[@]}"; do
      [ "$MS" = "$M" ] && MS_MATCH=true && break
    done
    [ "$MS_MATCH" = false ] && return 1
  fi

  return 0
}

# Returns 0 (allowed) if a file path is within your allowed packages
file_in_scope() {
  local FILE=$1
  # No restriction = everything allowed
  [ -z "$ALLOWED_PACKAGES" ] && return 0

  IFS=',' read -ra PKGS <<< "$ALLOWED_PACKAGES"
  for PKG in "${PKGS[@]}"; do
    if echo "$FILE" | grep -q "^${PKG}"; then
      # Check deny list
      if [ -n "$DENY_PACKAGES" ]; then
        IFS=',' read -ra DENIES <<< "$DENY_PACKAGES"
        for DENY in "${DENIES[@]}"; do
          echo "$FILE" | grep -q "^${DENY}" && return 1
        done
      fi
      return 0
    fi
  done
  return 1
}
```

**Out-of-scope issue**: skip silently.
**Out-of-scope file**: do not modify. Post a comment on the issue explaining the cross-boundary dependency.
**DENY_PACKAGES**: never modify under any circumstances. If a fix requires it: post `[NEEDS HUMAN]` and stop.

## THE LOOP

```
LOOP:

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PHASE 1 — HEARTBEAT + PROGRESS REPORT + FIND NEXT ITEM
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1a. Update heartbeat (re-read state.json first):
    python3 -c "
    import json,datetime,os
    with open('.maqa/state.json','r') as f: s=json.load(f)
    aid=os.environ.get('AGENT_ID','')
    s.setdefault('bounded_sessions',{}).setdefault(aid,{})
    s['bounded_sessions'][aid]['last_seen']=datetime.datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ')
    s['bounded_sessions'][aid]['cycle']=s['bounded_sessions'][aid].get('cycle',0)+1
    with open('.maqa/state.json','w') as f: json.dump(s,f,indent=2)
    "

    MAIN CI CHECK:
    MAIN=$(gh run list --repo $REPO --branch main --limit 1 --json conclusion --jq '.[0].conclusion' 2>/dev/null)
    [ "$MAIN" = "failure" ] && echo "🔴 MAIN CI RED" && (investigate, fix, continue)

1b. PROGRESS REPORT — post to your dedicated issue every hour:

    # Create your progress issue on first cycle if it doesn't exist yet
    PROGRESS_ISSUE=$(python3 -c "
    import json
    s=json.load(open('.maqa/state.json'))
    print(s.get('bounded_sessions',{}).get('$AGENT_ID',{}).get('progress_issue',''))
    " 2>/dev/null)

    if [ -z "$PROGRESS_ISSUE" ]; then
      PROGRESS_ISSUE=$(gh issue create --repo $REPO \
        --title "[$AGENT_NAME] Progress Log" \
        --label "report" \
        --body "## $AGENT_NAME — Autonomous Progress Log

**Scope**: $SCOPE
**Boundary**: $ALLOWED_AREAS | $ALLOWED_MILESTONES
**Started**: $(date -u +%Y-%m-%dT%H:%M:%SZ)

This issue is updated every hour by the $AGENT_NAME session.
Subscribe here to follow along." \
        --json number --jq '.number' 2>/dev/null)
      python3 -c "
    import json,os
    with open('.maqa/state.json','r') as f: s=json.load(f)
    s['bounded_sessions']['$AGENT_ID']['progress_issue']='$PROGRESS_ISSUE'
    with open('.maqa/state.json','w') as f: json.dump(s,f,indent=2)
    "
      echo "Created progress issue #$PROGRESS_ISSUE for $AGENT_NAME"
    fi

    # Post hourly progress update (track last_report_at in state.json)
    LAST_REPORT=$(python3 -c "
    import json
    s=json.load(open('.maqa/state.json'))
    print(s.get('bounded_sessions',{}).get('$AGENT_ID',{}).get('last_report_at',''))
    " 2>/dev/null)
    NOW_EPOCH=$(date +%s)
    LAST_EPOCH=$([ -n "$LAST_REPORT" ] && date -d "$LAST_REPORT" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%SZ" "$LAST_REPORT" +%s 2>/dev/null || echo "0")
    ELAPSED=$((NOW_EPOCH - LAST_EPOCH))

    if [ "$ELAPSED" -ge 3600 ] || [ -z "$LAST_REPORT" ]; then
      # Gather what was done in the last hour
      CLOSED_LAST_HOUR=$(gh issue list --repo $REPO --state closed \
        --json number,title,closedAt \
        --jq "[.[] | select(.closedAt > \"$(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -v-1H +%Y-%m-%dT%H:%M:%SZ)\")] | .[] | \"#\(.number) \(.title[:60])\"" 2>/dev/null | head -5)

      # Build the 2-hour plan by listing next in-scope open issues
      NEXT_2H=$(gh issue list --repo $REPO --state open \
        --label "$(echo $ALLOWED_AREAS | cut -d, -f1)" \
        ${ALLOWED_MILESTONES:+--milestone "$(echo $ALLOWED_MILESTONES | cut -d, -f1)"} \
        --json number,title --jq '.[:4] | .[] | "#\(.number) \(.title[:60])"' 2>/dev/null)

      CURRENT=$(python3 -c "
    import json
    s=json.load(open('.maqa/state.json'))
    print(s.get('bounded_sessions',{}).get('$AGENT_ID',{}).get('current_item','none'))
    " 2>/dev/null)

      gh issue comment $PROGRESS_ISSUE --repo $REPO --body "## Hourly Update — $(date -u '+%Y-%m-%d %H:%M UTC')

**Currently working on**: $CURRENT

**Done in the last hour:**
${CLOSED_LAST_HOUR:-None}

**Plan for the next 2 hours:**
${NEXT_2H:-No open issues found in scope — checking for new ones}

**Scope reminder**: $SCOPE
**Boundary**: areas=$ALLOWED_AREAS | milestones=$ALLOWED_MILESTONES
**Packages I own**: $ALLOWED_PACKAGES
**Packages I never touch**: $DENY_PACKAGES" 2>/dev/null

      python3 -c "
    import json,datetime,os
    with open('.maqa/state.json','r') as f: s=json.load(f)
    s['bounded_sessions']['$AGENT_ID']['last_report_at']=datetime.datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ')
    with open('.maqa/state.json','w') as f: json.dump(s,f,indent=2)
    "
      echo "Progress report posted to issue #$PROGRESS_ISSUE"
    fi


    # List open issues in allowed milestones with allowed area labels, pick lowest number
    # that is not claimed by another bounded session

    # Get currently claimed items from state.json
    CLAIMED=$(python3 -c "
    import json
    s=json.load(open('.maqa/state.json'))
     items=[v.get('current_item') for v in s.get('bounded_sessions',{}).values() if v.get('current_item')]
     print(','.join(items))
     ")

    # Find next unclaimed in-scope issue — search ALL allowed areas × ALL allowed milestones
    # This ensures the session doesn't stop early because one area/milestone combo is empty
    NEXT_ISSUE=""
    IFS=',' read -ra AREA_LIST <<< "$ALLOWED_AREAS"
    IFS=',' read -ra MS_LIST <<< "${ALLOWED_MILESTONES:-}"

    for AREA in "${AREA_LIST[@]}"; do
      for MS in "${MS_LIST[@]:-""}"; do
        CANDIDATE=$(gh issue list --repo $REPO --state open \
          ${MS:+--milestone "$MS"} \
          --label "$AREA" \
          --json number,labels,milestone \
          --jq 'sort_by(.number) | .[].number' 2>/dev/null | \
          while read N; do
            # Skip if claimed by another session
            echo "$CLAIMED" | grep -qE "(^|,)${N}(,|$)" && continue
            # Verify full in_scope (all areas + milestones check)
            in_scope "$N" && echo "$N" && break
          done | head -1)
        [ -n "$CANDIDATE" ] && NEXT_ISSUE="$CANDIDATE" && break 2
      done
    done

    if [ -z "$NEXT_ISSUE" ]; then
      echo "No unclaimed in-scope issues remain across all areas ($ALLOWED_AREAS) and milestones ($ALLOWED_MILESTONES)."
      echo "Sleeping 5 minutes then rechecking — new issues may have been created, or other sessions may release claims."
      sleep 300
      continue  # go back to top of LOOP — do not exit
      # Only exit when scope remains empty after 3 consecutive rechecks (handled below)
    fi

    # Claim the issue atomically
    python3 -c "
    import json,os
    with open('.maqa/state.json','r') as f: s=json.load(f)
    s['bounded_sessions'][os.environ.get('AGENT_ID','')]['current_item']='$NEXT_ISSUE'
    with open('.maqa/state.json','w') as f: json.dump(s,f,indent=2)
    "
    echo "Claimed issue #$NEXT_ISSUE"

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PHASE 2 — IMPLEMENT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

2a. Read the issue fully:
    gh issue view $NEXT_ISSUE --repo $REPO --json body,title,labels,comments

2b. BOUNDARY CHECK — identify all files this fix requires:
    For each file in the proposed change:
      file_in_scope "$FILE" || {
        gh issue comment $NEXT_ISSUE --repo $REPO \
          --body "[$AGENT_ID] Cross-boundary: fix requires $FILE which is outside my scope. Needs a different session."
        # Release claim and skip
        python3 -c "import json,os; s=json.load(open('.maqa/state.json')); s['bounded_sessions'][os.environ.get('AGENT_ID','')]['current_item']=None; json.dump(s,open('.maqa/state.json','w'),indent=2)"
        continue to next issue
      }

2c. GRAPH-FIRST CHECK:
    Read AGENTS.md anti-patterns. If fix would introduce a new logic leak: STOP, post [NEEDS HUMAN].

2d. Create worktree and implement (TDD):
    BRANCH="${NEXT_ISSUE}-${AGENT_ID,,}"
    REPO_NAME=$(basename $(git rev-parse --show-toplevel))
    git worktree add "../${REPO_NAME}.${BRANCH}" -b "$BRANCH" 2>/dev/null
    cd "../${REPO_NAME}.${BRANCH}"
    # Write test first, then implement
    eval "$TEST_COMMAND" && eval "$LINT_COMMAND"

2e. Self-validate:
    eval "$BUILD_COMMAND" && eval "$TEST_COMMAND" && eval "$LINT_COMMAND"

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PHASE 3 — QA (ADVERSARIAL) + MERGE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

3a. Push PR:
    git push -u origin "$BRANCH"
    PR_NUM=$(gh pr create --repo $REPO --label "$PR_LABEL" \
      --title "[$AGENT_ID] $(gh issue view $NEXT_ISSUE --repo $REPO --json title --jq .title)" \
      --body "Fixes #$NEXT_ISSUE

**Scope**: $SCOPE
**Boundary**: $ALLOWED_AREAS | $ALLOWED_PACKAGES" \
      2>&1 | grep -oE 'https://[^ ]+' | grep -oE '[0-9]+$')

3b. Wait for CI green, then adversarial QA:
    Re-read the full diff. Check boundary (no files outside ALLOWED_PACKAGES modified).
    Check no new logic leaks. Check code standards. Fix and push if needed. Max 3 cycles.

3c. Merge:
    gh pr merge $PR_NUM --squash --delete-branch --repo $REPO
    cd "../${REPO_NAME}" && git worktree remove "../${REPO_NAME}.${BRANCH}" --force 2>/dev/null
    gh issue close $NEXT_ISSUE --repo $REPO \
      --comment "[$AGENT_ID] Fixed in PR #$PR_NUM. ($SCOPE)"

    # Release claim
    python3 -c "
    import json,os
    with open('.maqa/state.json','r') as f: s=json.load(f)
    s['bounded_sessions'][os.environ.get('AGENT_ID','')]['current_item']=None
    with open('.maqa/state.json','w') as f: json.dump(s,f,indent=2)
    "

    eval "$BUILD_COMMAND" || (gh issue create --repo $REPO --label needs-human \
      --title "hotfix: build broke after $AGENT_ID fixed #$NEXT_ISSUE" && STOP)

    → PHASE 1

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PHASE 4 — SCOPE REVIEW (after each item, or when scope temporarily empty)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Run inline SM/PM review scoped to your area — brief, not a full SM/PM cycle:
- Check: are issues you closed showing Done on the board? Fix if not.
- Check: are docs fresh for anything you changed?
- Post "[SCOPE UPDATE: $AGENT_ID]" on report issue summarising what you closed.

Then **go back to PHASE 1 immediately** — do not exit.
The only legitimate exit is when scope has been empty for 3+ consecutive 5-minute rechecks
AND you have posted a scope-complete notice:

    # Track consecutive empty checks
    EMPTY_CHECKS=$((${EMPTY_CHECKS:-0} + 1))
    if [ "$EMPTY_CHECKS" -ge 3 ]; then
      python3 -c "
      import json,os
      with open('.maqa/state.json','r') as f: s=json.load(f)
      aid=os.environ.get('AGENT_ID','')
      if aid in s.get('bounded_sessions',{}):
          s['bounded_sessions'][aid]['current_item']=None
          s['bounded_sessions'][aid]['last_seen']=None
      with open('.maqa/state.json','w') as f: json.dump(s,f,indent=2)
      "
      gh issue comment $REPORT_ISSUE --repo $REPO \
        --body "[$AGENT_ID] Scope complete: $SCOPE. All in-scope issues resolved after 3 rechecks."
      exit 0
    fi
    → PHASE 1
```

## Hard rules

- **BOUNDARY IS ABSOLUTE.** Never modify files outside ALLOWED_PACKAGES.
- **DENY_PACKAGES are sacred.** Zero exceptions.
- **No new logic leaks** — every change must move toward Graph purity, not away.
- **Concurrent safety** — always re-read state.json before writing. Check other sessions' current_item before claiming.
- **Never touch state.json features{} map** — that belongs to the primary standalone or coordinator.
- TDD always. Merge mandatory. Max 3 QA cycles before escalating.
