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
# e.g. /otherness.cross-agent-monitor pnz1990/alibi pnz1990/kro-ui
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

For each repo in $REPOS, collect the following signals. Run in parallel where possible.

```bash
NOW_EPOCH=$(date +%s)

for REPO in $REPOS; do
  REPO_NAME=$(echo $REPO | cut -d/ -f2)
  echo ""
  echo "━━━ $REPO ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  # --- Signal 1: Heartbeat freshness (_state branch last commit) ---
  LAST_STATE=$(gh api repos/$REPO/branches/_state \
    --jq '.commit.commit.committer.date' 2>/dev/null || echo "")

  if [ -z "$LAST_STATE" ]; then
    echo "  ⚠️  _state branch: NOT FOUND (not onboarded to otherness or no activity yet)"
    STATE_AGE_H=999
  else
    STATE_AGE_H=$(python3 -c "
import datetime
d = '$LAST_STATE'
try:
    dt = datetime.datetime.fromisoformat(d.replace('Z','+00:00'))
    now = datetime.datetime.now(datetime.timezone.utc)
    print(f'{(now-dt).total_seconds()/3600:.1f}')
except: print('999')
")
    if python3 -c "exit(0 if float('$STATE_AGE_H') < 4 else 1)" 2>/dev/null; then
      echo "  ✅ Heartbeat: ${STATE_AGE_H}h ago (ACTIVE)"
    elif python3 -c "exit(0 if float('$STATE_AGE_H') < 24 else 1)" 2>/dev/null; then
      echo "  🟡 Heartbeat: ${STATE_AGE_H}h ago (IDLE — may need restart)"
    else
      echo "  🔴 Heartbeat: ${STATE_AGE_H}h ago (STALLED — likely stopped)"
    fi
  fi

  # --- Signal 2: NEEDS-HUMAN blockers ---
  BLOCKERS=$(gh issue list --repo $REPO --state open --label "needs-human" \
    --json number,title,createdAt \
    --jq '.[] | "#\(.number) \(.title) (open \(.createdAt))"' 2>/dev/null)
  BLOCKER_COUNT=$(echo "$BLOCKERS" | grep -c '#' 2>/dev/null || echo 0)

  if [ "$BLOCKER_COUNT" -gt 0 ]; then
    echo "  🚨 NEEDS-HUMAN: $BLOCKER_COUNT blocker(s)"
    echo "$BLOCKERS" | while IFS= read -r b; do [ -n "$b" ] && echo "     $b"; done
  else
    echo "  ✅ No needs-human blockers"
  fi

  # --- Signal 3: Velocity — PRs merged in last 24h and 7d ---
  MERGED_24H=$(gh pr list --repo $REPO --state merged \
    --json mergedAt --jq "[.[] | select(.mergedAt > \"$(date -u -v-24H '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date -u --date='24 hours ago' '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null)\")] | length" 2>/dev/null || echo 0)
  MERGED_7D=$(gh pr list --repo $REPO --state merged \
    --json mergedAt --jq "[.[] | select(.mergedAt > \"$(date -u -v-7d '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date -u --date='7 days ago' '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null)\")] | length" 2>/dev/null || echo 0)
  LATEST_PR=$(gh pr list --repo $REPO --state merged --limit 1 \
    --json title,mergedAt --jq '.[0] | "\(.title) (\(.mergedAt))"' 2>/dev/null || echo "none")

  echo "  📦 Velocity: ${MERGED_24H} PRs/24h | ${MERGED_7D} PRs/7d"
  echo "     Latest: $LATEST_PR"

  # --- Signal 4: Open work items ---
  OPEN_ITEMS=$(gh issue list --repo $REPO --state open \
    --json number --jq 'length' 2>/dev/null || echo "?")
  OPEN_PRS=$(gh pr list --repo $REPO --state open \
    --json number --jq 'length' 2>/dev/null || echo "?")
  echo "  📋 Queue: ${OPEN_ITEMS} open issues | ${OPEN_PRS} open PRs"

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
| 🟢 HEALTHY | Heartbeat <4h, no needs-human, CI green, PRs merging |
| 🟡 IDLE | Heartbeat 4–24h, no blockers, CI green — agent probably stopped |
| 🟠 SLOW | Heartbeat <24h but velocity is 0 PRs/7d and no visible reason |
| 🔴 BLOCKED | has needs-human open, or CI failing, or heartbeat >24h with open queue |
| ⚫ UNKNOWN | _state branch missing, no activity ever |

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
    - pnz1990/alibi
    - pnz1990/kardinal-promoter
    - pnz1990/kro-ui
    - pnz1990/otherness
  # alert thresholds (optional, these are the defaults)
  stale_hours: 24          # heartbeat older than this = STALLED
  idle_hours: 4            # heartbeat older than this = IDLE
```

If this section is absent, the command monitors only the current repo.
