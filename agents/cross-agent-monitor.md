---
name: cross-agent-monitor
description: "Cross-project health monitor. Checks all otherness-managed projects for heartbeat freshness, velocity, blockers, and needs-human items. Run periodically or on demand."
tools: Bash, Read
---

> **Self-update first.**
```bash
git -C ~/.otherness pull --quiet 2>/dev/null || true
```

You are the CROSS-AGENT MONITOR. You observe, measure, and report — you do not modify any project.

---

## Step 1 — Resolve project list

```bash
# Parse explicit repos from $ARGUMENTS (space or comma separated)
# e.g. /otherness.cross-agent-monitor owner/project-one owner/project-two
EXPLICIT_REPOS="$ARGUMENTS"

# If no explicit repos given, read from otherness-config.yaml monitor.projects
# (falls back to current repo only if nothing configured)
if [ -z "$EXPLICIT_REPOS" ]; then
  REPOS=$(python3 -c "
import re, os
repos = []
section = None
in_projects = False
for line in open('otherness-config.yaml'):
    s = re.match(r'^(\w[\w_]*):', line)
    if s: section = s.group(1); in_projects = False
    if section == 'monitor':
        if re.match(r'\s+projects:', line): in_projects = True; continue
        if in_projects:
            m = re.match(r'\s+-\s+(\S+)', line)
            if m: repos.append(m.group(1))
            elif re.match(r'^\w', line): break
if repos:
    print(' '.join(repos))
else:
    # fallback: current repo
    import subprocess
    r = subprocess.check_output(['git','remote','get-url','origin'],text=True).strip()
    r = r.split('github.com')[-1].strip(':/ ').replace('.git','')
    print(r)
" 2>/dev/null)
else
  REPOS=$(echo "$EXPLICIT_REPOS" | tr ',' ' ')
fi

echo "Monitoring: $REPOS"
```

---

## Step 2 — Collect data for each project

**Key lesson learned**: CI run timestamps are unreliable as activity signals. CI can re-run on a branch hours after the last actual push (re-triggered by PR events, retries, manual re-runs). The only reliable "agent is working NOW" signal is: **a new commit was pushed to a feature branch within the window**.

Activity signals in priority order:

1. **Last commit on open feature branch within 30min** → WORKING mid-item (agent is pushing code)
2. **needs-human open AND open PRs with 0 new commits in >30min** → WAITING FOR HUMAN (correct, not stuck)
3. **_state written within 4h, no open feature branch** → BETWEEN ITEMS (just finished, starting next)
4. **No commit activity >4h, no open feature branches, _state >4h** → IDLE or STOPPED

```bash
WINDOW=$(python3 -c "import datetime; print((datetime.datetime.now(datetime.timezone.utc)-datetime.timedelta(minutes=30)).strftime('%Y-%m-%dT%H:%M:%SZ'))")

age_hours() {
  python3 -c "
import datetime, sys
try:
    dt=datetime.datetime.fromisoformat(sys.argv[1].replace('Z','+00:00'))
    now=datetime.datetime.now(datetime.timezone.utc)
    print(f'{(now-dt).total_seconds()/3600:.1f}')
except: print('9999')
" "$1" 2>/dev/null || echo 9999
}

for REPO in $REPOS; do
  echo ""
  echo "━━━ $REPO"

  # --- Signal 1: Last commit on any open feat/* or fix/* branch ---
  # Get all open PRs on feature branches, find the most recent commit date across them
  OPEN_FEAT_BRANCHES=$(gh pr list --repo $REPO --state open \
    --json headRefName,number,title \
    --jq '[.[] | select(.headRefName | startswith("feat/") or startswith("fix/"))]' \
    2>/dev/null || echo "[]")
  OPEN_FEAT_COUNT=$(echo "$OPEN_FEAT_BRANCHES" | python3 -c "import json,sys; print(len(json.load(sys.stdin)))" 2>/dev/null || echo 0)

  LATEST_PUSH=""
  LATEST_PUSH_BRANCH=""
  if [ "$OPEN_FEAT_COUNT" -gt 0 ]; then
    # For each open feature branch, get its latest commit timestamp
    while IFS= read -r branch; do
      COMMIT_DATE=$(gh api repos/$REPO/branches/$branch \
        --jq '.commit.commit.committer.date' 2>/dev/null || echo "")
      if [ -n "$COMMIT_DATE" ]; then
        if [ -z "$LATEST_PUSH" ] || [[ "$COMMIT_DATE" > "$LATEST_PUSH" ]]; then
          LATEST_PUSH="$COMMIT_DATE"
          LATEST_PUSH_BRANCH="$branch"
        fi
      fi
    done < <(echo "$OPEN_FEAT_BRANCHES" | python3 -c "
import json,sys
for pr in json.load(sys.stdin): print(pr['headRefName'])
" 2>/dev/null)
  fi

  PUSH_AGE=$([ -n "$LATEST_PUSH" ] && age_hours "$LATEST_PUSH" || echo "9999")

  # --- Signal 2: needs-human blockers ---
  NH_COUNT=$(gh issue list --repo $REPO --state open --label "needs-human" \
    --json number --jq 'length' 2>/dev/null || echo 0)
  NH_ITEMS=$(gh issue list --repo $REPO --state open --label "needs-human" \
    --json number,title --jq '.[] | "     #\(.number) \(.title)"' 2>/dev/null || echo "")

  # --- Signal 3: _state age ---
  LAST_STATE=$(gh api repos/$REPO/branches/_state \
    --jq '.commit.commit.committer.date' 2>/dev/null || echo "")
  STATE_AGE=$([ -n "$LAST_STATE" ] && age_hours "$LAST_STATE" || echo "9999")

  # --- Determine true status ---
  if python3 -c "exit(0 if float('$PUSH_AGE') <= 0.5 else 1)" 2>/dev/null; then
    # Commit within 30 min — genuinely working
    echo "  🟢 WORKING — last push ${PUSH_AGE}h ago on $LATEST_PUSH_BRANCH"
    if [ "$NH_COUNT" -gt 0 ]; then
      echo "  ⚠️  Note: $NH_COUNT needs-human also open (agent may finish current item then stop)"
    fi
  elif [ "$NH_COUNT" -gt 0 ] && [ "$OPEN_FEAT_COUNT" -gt 0 ]; then
    # Has open PR + needs-human → WAITING FOR HUMAN (correct behavior, not broken)
    echo "  ⏸️  WAITING FOR HUMAN — open PR with no recent commits (last push ${PUSH_AGE}h ago)"
    echo "  📌 Open PR on: $LATEST_PUSH_BRANCH"
    echo "  🚨 NEEDS-HUMAN: $NH_COUNT — unblock to resume"
    echo "$NH_ITEMS"
  elif [ "$NH_COUNT" -gt 0 ] && [ "$OPEN_FEAT_COUNT" -eq 0 ]; then
    # No open branch + needs-human → STOPPED waiting
    echo "  🛑 STOPPED — waiting for human, no active branch"
    echo "  🚨 NEEDS-HUMAN: $NH_COUNT — merge or answer to resume"
    echo "$NH_ITEMS"
  elif python3 -c "exit(0 if float('$STATE_AGE') < 4 else 1)" 2>/dev/null; then
    echo "  ✅ BETWEEN ITEMS — finished item ${STATE_AGE}h ago, picking up next"
  elif python3 -c "exit(0 if float('$STATE_AGE') < 24 else 1)" 2>/dev/null; then
    echo "  🟡 IDLE — no commits in ${PUSH_AGE}h, state ${STATE_AGE}h ago — may need restart"
  else
    echo "  🔴 STOPPED — no activity. Last push: ${PUSH_AGE}h ago. State: ${STATE_AGE}h ago."
  fi

  # Always show blockers if present and not already shown above
  if [ "$NH_COUNT" -gt 0 ] && python3 -c "exit(0 if float('$PUSH_AGE') <= 0.5 else 1)" 2>/dev/null; then
    echo "  🚨 NEEDS-HUMAN: $NH_COUNT open (won't block until current item done)"
    echo "$NH_ITEMS"
  fi

  # --- Signal 5: CI health on main ---
  CI_STATUS=$(gh run list --repo $REPO --branch main --limit 3 \
    --json conclusion,name,createdAt \
    --jq '[.[] | select(.conclusion != null)] | .[0] | "\(.conclusion) (\(.name))"' 2>/dev/null || echo "unknown")
  if echo "$CI_STATUS" | grep -q "success"; then
    echo "  ✅ CI: $CI_STATUS"
  elif echo "$CI_STATUS" | grep -q "failure"; then
    echo "  🔴 CI: $CI_STATUS — FAILING"
  else
    echo "  ⚪ CI: $CI_STATUS"
  fi

done
```

---

## Step 3 — Overall assessment

After collecting all signals, produce a structured assessment:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CROSS-AGENT MONITOR REPORT
$(date -u '+%Y-%m-%d %H:%M UTC')
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

For each project, assign one of these overall statuses:

| Status | Criteria |
|---|---|
| 🟢 WORKING | Commit pushed to feature branch within 30 min |
| ⏸️ WAITING FOR HUMAN | Open feature branch, last push >30min ago, needs-human open — correct pause behavior |
| 🛑 STOPPED | needs-human open, no active feature branch — fully blocked |
| ✅ BETWEEN ITEMS | No open feature branch, _state <4h — just finished, picking up next |
| 🟡 IDLE | No open feature branch, _state 4–24h, no commits — may need restart |
| 🔴 STOPPED | No activity anywhere >24h with open queue items — needs restart |
| 🚨 CI BROKEN | CI failing on main — agent will not start new items |
| ⚫ UNKNOWN | _state branch missing |

Then produce the **Human Action Required** list — only items that genuinely need the human:

```
HUMAN ACTION REQUIRED:
  - <repo>: <exactly what to do> (<link>)

AGENT ACTION SUGGESTED (restart stalled sessions):
  - <repo>: /otherness.run — last active Xh ago
```

Do not include healthy projects in the action list. Healthy = no action needed.

---

## Step 4 — Post to report issue (if blockers found)

If ANY project has status 🔴 BLOCKED or any project has needs-human open:

```bash
# Read THIS project's report issue from config
THIS_REPO=$(git remote get-url origin 2>/dev/null | sed 's|.*github.com[:/]||;s|\.git$||')
REPORT_ISSUE=$(python3 -c "
import re
for line in open('AGENTS.md'):
    m = re.match(r'^REPORT_ISSUE:\s*(\S+)', line.strip())
    if m: print(m.group(1)); break
" 2>/dev/null || echo "1")

BODY="[🔭 MONITOR] Cross-agent health check — $(date -u '+%Y-%m-%d %H:%M UTC')

<paste the full report here>

---
Run \`/otherness.cross-agent-monitor $REPOS\` to refresh."

gh issue comment $REPORT_ISSUE --repo $THIS_REPO --body "$BODY" 2>/dev/null
```

If all projects are healthy, do not post — avoid noise on the report issue.

---

## Step 5 — Output the final report to stdout

Print the complete structured report so the human sees it directly in the terminal.
This is the primary output — the issue comment is a secondary notification.

---

## Configuration (optional)

Projects to monitor can be added to `otherness-config.yaml` under a `monitor` section:

```yaml
monitor:
  projects:
    - owner/project-one
    - owner/project-two
    - owner/project-three
  # alert thresholds (optional, these are the defaults)
  stale_hours: 24          # heartbeat older than this = STALLED
  idle_hours: 4            # heartbeat older than this = IDLE
```

If this section is absent, the command monitors only the current repo.
