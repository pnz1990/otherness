# PHASE 1 — [🎯 COORD] HEARTBEAT + ASSIGN

**Role identity**: You are an engineering coordinator. Your goal: claim exactly the right next
item — one that is achievable, unblocked, and moves the roadmap forward. A skipped item is
better than a wrong item. Verify before committing.

Load skill: `~/.otherness/agents/skills/role-based-agent-identity.md` §COORD before acting.

---

## 1a. Pull, heartbeat, rate-limit check, CI

```bash
git config pull.rebase false 2>/dev/null || true
git pull origin main --quiet
git fetch --prune --quiet 2>/dev/null || true

# Rate-limit guard — check before any API-heavy work
REMAINING=$(gh api rate_limit --jq '.rate.remaining' 2>/dev/null || echo "5000")
if [ "${REMAINING:-5000}" -lt 300 ]; then
  RESET_AT=$(gh api rate_limit --jq '.rate.reset' 2>/dev/null || echo "0")
  SLEEP_S=$(python3 -c "import time; print(max(30, $RESET_AT - int(time.time()) + 10))" 2>/dev/null || echo "60")
  echo "[COORD] Rate limited ($REMAINING remaining) — sleeping ${SLEEP_S}s"
  sleep $SLEEP_S
fi

# Write heartbeat
python3 - <<'EOF'
import json, datetime, os
try:
    with open('.otherness/state.json') as f: s = json.load(f)
    session = os.environ.get('MY_SESSION_ID', 'COORDINATOR')
    s.setdefault('session_heartbeats', {})[session] = {
        'last_seen': datetime.datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ'),
        'item': 'coord',
        'cycle': s.get('session_heartbeats', {}).get(session, {}).get('cycle', 0) + 1
    }
    with open('.otherness/state.json', 'w') as f: json.dump(s, f, indent=2)
except Exception as e:
    print(f"Heartbeat write failed (non-fatal): {e}")
EOF

# Stop sentinel
if [ -f ".otherness/stop-after-current" ] && [ -z "$ITEM_ID" ]; then
  python3 -c "
import json, datetime
with open('.otherness/state.json') as f: s = json.load(f)
s['handoff'] = {'stopped_at': datetime.datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ'),
                'reason': 'Graceful stop', 'resume_with': '/otherness.run'}
with open('.otherness/state.json', 'w') as f: json.dump(s, f, indent=2)
"
  rm -f .otherness/stop-after-current
  export STATE_MSG="graceful stop"
  # run STATE MANAGEMENT write block
  gh issue comment $REPORT_ISSUE --repo $REPO --body "[STANDALONE | ${MY_SESSION_ID:-sess-unknown} | otherness@${OTHERNESS_VERSION:-unknown}] Stopped cleanly." 2>/dev/null
  exit 0
fi

# CI check — dispatched by CI_PROVIDER
_CI_PROVIDER="${CI_PROVIDER:-github-actions}"
FAILED=""

case "$_CI_PROVIDER" in
  github-actions)
    CI_STATUS=$(gh run list --repo $REPO --branch main --limit 5 \
      --json conclusion,status,name,createdAt \
      --jq '[.[] | {conclusion,status,name,createdAt}]' 2>/dev/null || echo "[]")

    FAILED=$(echo "$CI_STATUS" | python3 -c "
import json, sys, datetime
runs = json.load(sys.stdin)
for r in runs:
    if r.get('conclusion') == 'failure':
        print(r['name']); exit()
for r in runs:
    if r.get('status') == 'in_progress':
        try:
            t = datetime.datetime.fromisoformat(r['createdAt'].replace('Z','+00:00'))
            mins = (datetime.datetime.now(datetime.timezone.utc) - t).total_seconds() / 60
            if mins > 30: print(f'HUNG: {r[\"name\"]} ({mins:.0f}m)'); exit()
        except: pass
" 2>/dev/null)
    ;;

  circleci)
    # Requires CIRCLE_TOKEN env var; warns and skips gate if unset
    if [ -z "$CIRCLE_TOKEN" ]; then
      echo "[COORD] ⚠️  CI_PROVIDER=circleci but CIRCLE_TOKEN not set — skipping CI gate"
    else
      CI_JSON=$(curl -s -H "Circle-Token: $CIRCLE_TOKEN" \
        "https://circleci.com/api/v2/project/gh/${REPO}/pipeline?branch=main" 2>/dev/null \
        || echo '{}')
      FAILED=$(echo "$CI_JSON" | python3 -c "
import json, sys
d = json.load(sys.stdin)
for p in d.get('items', []):
    state = p.get('state', '')
    if state == 'errored': print(f'CircleCI pipeline {p.get(\"id\",\"\")} errored'); exit()
" 2>/dev/null)
    fi
    ;;

  gitlab)
    # Requires GITLAB_TOKEN and GITLAB_URL env vars; warns and skips gate if unset
    if [ -z "$GITLAB_TOKEN" ] || [ -z "$GITLAB_URL" ]; then
      echo "[COORD] ⚠️  CI_PROVIDER=gitlab but GITLAB_TOKEN/GITLAB_URL not set — skipping CI gate"
    else
      ENCODED_REPO=$(python3 -c "import urllib.parse,os; print(urllib.parse.quote_plus(os.environ.get('REPO','')))")
      CI_JSON=$(curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
        "${GITLAB_URL}/api/v4/projects/${ENCODED_REPO}/pipelines?ref=main&per_page=5" 2>/dev/null \
        || echo '[]')
      FAILED=$(echo "$CI_JSON" | python3 -c "
import json, sys
pipelines = json.load(sys.stdin)
for p in pipelines:
    if p.get('status') in ('failed', 'canceled'):
        print(f'GitLab pipeline {p.get(\"id\",\"\")} {p.get(\"status\",\"\")}'); exit()
" 2>/dev/null)
    fi
    ;;

  *)
    echo "[COORD] ⚠️  Unknown CI_PROVIDER='$_CI_PROVIDER' — skipping CI gate (known: github-actions, circleci, gitlab)"
    ;;
esac

if [ -n "$FAILED" ]; then
  echo "[COORD] 🔴 CI BLOCKING: $FAILED — fix before new work"
  if echo "$FAILED" | grep -q "^HUNG:"; then
    gh run list --repo $REPO --branch main --json databaseId,status \
      --jq '.[] | select(.status=="in_progress") | .databaseId' 2>/dev/null | \
      xargs -I{} gh api --method POST "repos/$REPO/actions/runs/{}/cancel" 2>/dev/null
  fi
  HOURS_RED=$(gh run list --repo $REPO --branch main --limit 20 \
    --json conclusion,createdAt \
    --jq '[.[]|select(.conclusion=="failure")]|last.createdAt' 2>/dev/null | \
    python3 -c "
import datetime, sys
t = sys.stdin.read().strip().strip('\"')
if not t: print(0); exit()
try:
    dt = datetime.datetime.fromisoformat(t.replace('Z','+00:00'))
    print(int((datetime.datetime.now(datetime.timezone.utc)-dt).total_seconds()/3600))
except: print(0)
" 2>/dev/null || echo "0")
  if [ "${HOURS_RED:-0}" -ge 24 ]; then
    gh issue comment $REPORT_ISSUE --repo $REPO \
      --body "[STANDALONE | ${MY_SESSION_ID:-sess-unknown} | otherness@${OTHERNESS_VERSION:-unknown}] [NEEDS HUMAN] CI has been red on main for ${HOURS_RED}h. Failing job: $FAILED." 2>/dev/null
  fi
fi
```

---

## 1b. Queue generation (with distributed lock)

If queue is null or empty, acquire the queue-gen lock and generate.

**The lock uses `refs/heads/otherness/queue-gen`. The loser waits for `_state` to update.**

```bash
git fetch origin _state --quiet 2>/dev/null
git show origin/_state:.otherness/state.json > .otherness/state.json 2>/dev/null || true

TODO_COUNT=$(python3 -c "
import json
with open('.otherness/state.json') as f: s = json.load(f)
print(len([d for d in s.get('features',{}).values() if d.get('state')=='todo']))
" 2>/dev/null || echo "0")

if [ "${TODO_COUNT:-0}" -eq 0 ]; then
  # Acquire queue-gen lock — push to refs/heads/otherness/queue-gen
  # Use refs/heads/ namespace so git prune/fetch --prune cleans it up naturally
  QUEUE_LOCK_BRANCH="otherness/queue-gen"
  if git push origin "HEAD:refs/heads/$QUEUE_LOCK_BRANCH" 2>/dev/null; then
    echo "[COORD] Queue-gen lock acquired."
    QUEUE_GEN_WINNER=true
  else
    echo "[COORD] Queue-gen in progress by another session — waiting up to 90s..."
    for i in $(seq 1 9); do
      sleep 10
      git fetch origin _state --quiet 2>/dev/null
      FRESH=$(git show origin/_state:.otherness/state.json 2>/dev/null)
      HAS_TODO=$(echo "$FRESH" | python3 -c "
import json, sys
try:
    s = json.load(sys.stdin)
    print(len([d for d in s.get('features',{}).values() if d.get('state')=='todo']))
except: print(0)
" 2>/dev/null || echo "0")
      if [ "${HAS_TODO:-0}" -gt 0 ]; then
        echo "[COORD] Queue appeared ($HAS_TODO items). Proceeding."
        echo "$FRESH" > .otherness/state.json
        break
      fi
    done
    QUEUE_GEN_WINNER=false
  fi

  if [ "$QUEUE_GEN_WINNER" = "true" ]; then
    # Generate queue — uses speckit.specify for richer issue bodies when speckit present
    python3 - <<'PYEOF'
import subprocess, re, json, os

roadmap = open('docs/aide/roadmap.md').read()
REPO = os.environ.get('REPO', '')

# PRIMARY: state.json done items
try:
    state = json.load(open('.otherness/state.json'))
    done_titles = set(
        v.get('title','').lower() for v in state.get('features',{}).values()
        if v.get('state') == 'done' and v.get('title')
    )
except:
    done_titles = set()

# SECONDARY: last 100 merged PR titles
try:
    merged_prs = subprocess.check_output(
        ['gh','pr','list','--repo',REPO,'--state','merged','--limit','100',
         '--json','title','--jq','.[].title'], text=True).lower()
except:
    merged_prs = ''

# Also load project memory — avoid re-proposing decided topics
try:
    memory = open('.specify/memory/decisions.md').read().lower()
except:
    memory = ''

def is_done(d):
    d_lower = d.lower()
    if d_lower in done_titles: return True
    key = d.split('`')[1] if '`' in d else d[:40].lower()
    return key.lower() in merged_prs

stages = re.split(r'^## Stage', roadmap, flags=re.MULTILINE)
for stage in stages[1:]:
    deliverables = re.findall(r'^- (.+)', stage, re.MULTILINE)
    incomplete = [d for d in deliverables if not is_done(d)]
    if incomplete:
        print(f"STAGE: {stage.strip().split(chr(10))[0]}")
        for d in incomplete[:5]: print(f"ITEM: {d}")
        break
PYEOF

    # Create GitHub issues for each deliverable (max 5, prefer size/xs or s)
    # For each: check for duplicate first, then create with acceptance criterion
    # Format:
    # gh issue create --repo $REPO --title "..." --label "otherness,..." --body "..."

    # Write state, release lock, post summary
    export STATE_MSG="[COORD] queue generated"
    # run STATE MANAGEMENT write block from standalone.md

    git push origin --delete "$QUEUE_LOCK_BRANCH" 2>/dev/null || true
    gh issue comment $REPORT_ISSUE --repo $REPO \
      --body "[🎯 COORD | ${MY_SESSION_ID:-sess-unknown} | otherness@${OTHERNESS_VERSION:-unknown}] Queue generated." 2>/dev/null
  fi
fi
```

---

## 1c. Stale item watchdog (SM sub-task — run every coord cycle)

Reset items stuck in `assigned` with no live heartbeat for >2 hours. Delete the stale branch lock.

```bash
python3 - <<'EOF'
import json, datetime, subprocess, os

STALE_HOURS = 2
REPO = os.environ.get('REPO', '')

with open('.otherness/state.json') as f: s = json.load(f)
beats = s.get('session_heartbeats', {})
now = datetime.datetime.utcnow()
changed = False

for item_id, d in list(s.get('features', {}).items()):
    if d.get('state') != 'assigned': continue
    session = d.get('assigned_to', '')
    assigned_at_str = d.get('assigned_at', '')
    if not assigned_at_str: continue
    assigned_at = datetime.datetime.fromisoformat(assigned_at_str.replace('Z',''))
    age_h = (now - assigned_at).total_seconds() / 3600

    # Check heartbeat for this session
    last_hb_str = beats.get(session, {}).get('last_seen', '')
    if last_hb_str:
        last_hb = datetime.datetime.fromisoformat(last_hb_str.replace('Z',''))
        hb_age_h = (now - last_hb).total_seconds() / 3600
    else:
        hb_age_h = 9999

    if age_h > STALE_HOURS and hb_age_h > STALE_HOURS:
        print(f"[COORD] Stale: {item_id} assigned {age_h:.1f}h ago, heartbeat {hb_age_h:.1f}h ago — resetting to todo")
        branch = d.get('branch', f'feat/{item_id}')
        # Delete remote branch (releases lock)
        subprocess.run(['git','push',REPO,'--delete',branch.replace('refs/heads/','')],
                       capture_output=True)
        d['state'] = 'todo'
        d['assigned_to'] = None
        d['assigned_at'] = None
        d['branch'] = None
        d['worktree'] = None
        changed = True

# Also: recover stale queue-gen lock (held >10 min = crashed mid-generation)
qlock_ref = 'refs/heads/otherness/queue-gen'
qlock_result = subprocess.run(['git','ls-remote','--heads','origin',qlock_ref],
                               capture_output=True, text=True)
if qlock_result.stdout.strip():
    # The lock exists — check how old it is
    age_result = subprocess.run(
        ['git','log','--format=%ct','-1','origin/otherness/queue-gen'],
        capture_output=True, text=True)
    if age_result.returncode == 0 and age_result.stdout.strip():
        import time
        lock_age_min = (time.time() - int(age_result.stdout.strip())) / 60
        if lock_age_min > 10:
            print(f"[COORD] Stale queue-gen lock ({lock_age_min:.0f}m old) — deleting")
            subprocess.run(['git','push','origin','--delete','otherness/queue-gen'],
                           capture_output=True)

if changed:
    with open('.otherness/state.json', 'w') as f: json.dump(s, f, indent=2)
EOF
```

---

## 1c. Claim next item (branch-lock protocol)

Re-read state from `_state` first — always use canonical IDs from the queue-gen winner.

```bash
git fetch origin _state --quiet 2>/dev/null
git show origin/_state:.otherness/state.json > .otherness/state.json 2>/dev/null || true

ITEM_ID=$(python3 -c "
import json, subprocess
with open('.otherness/state.json') as f: s = json.load(f)

# Get claimed items from remote branches
claimed = set()
ls = subprocess.check_output(['git','ls-remote','--heads','origin'], text=True)
for line in ls.splitlines():
    if 'refs/heads/feat/' in line:
        claimed.add(line.split('refs/heads/feat/')[-1].strip())

# Dependency check: skip items whose depends_on items are not done
features = s.get('features', {})
def deps_met(item_id):
    deps = features.get(item_id, {}).get('depends_on', [])
    return all(features.get(dep, {}).get('state') == 'done' for dep in deps)

# Capability filter: check ALLOWED_AREAS from env (bounded mode)
import os
allowed_areas = [a.strip() for a in os.environ.get('ALLOWED_AREAS','').split(',') if a.strip()]

for id, d in features.items():
    if d.get('state') != 'todo': continue
    if id in claimed: continue
    if not deps_met(id): continue
    # Area filter for bounded agents
    if allowed_areas:
        item_areas = d.get('areas', [])
        if not any(a in item_areas for a in allowed_areas): continue
    print(id); break
" 2>/dev/null)

if [ -z "$ITEM_ID" ]; then
  # No unclaimed items — proactive work
  NEEDS_HUMAN=$(gh issue list --repo $REPO --state open --label "needs-human" \
    --json number --jq 'length' 2>/dev/null || echo "0")
  if [ "${NEEDS_HUMAN:-0}" -gt 0 ]; then
    echo "[COORD] $NEEDS_HUMAN needs-human items — attempting autonomous resolution..."
    # [AI-STEP] Read each needs-human issue. If resolvable (technical, not value judgment):
    #   resolve autonomously and post [AGENT RESOLVED: ...].
    # If judgment call needed: post [AGENT RECOMMENDATION: <option> because <reason>.
    #   Proceeding with this option unless you say otherwise within 24h.]
  fi

  # Learn scheduling: trigger if >14 days since last learn session
  DAYS_SINCE_LEARN=$(python3 -c "
import re, datetime, os
try:
    content = open(os.path.expanduser('~/.otherness/agents/skills/PROVENANCE.md')).read()
    dates = re.findall(r'^## (\d{4}-\d{2}-\d{2})', content, re.MULTILINE)
    if dates:
        last = datetime.date.fromisoformat(sorted(dates)[-1])
        print((datetime.date.today() - last).days)
    else: print(999)
except: print(999)
" 2>/dev/null || echo "999")

  if [ "${DAYS_SINCE_LEARN:-999}" -ge 14 ]; then
    LEARN_BRANCH="feat/learn-$(date +%Y%m%d)"
    if git push origin "HEAD:refs/heads/$LEARN_BRANCH" 2>/dev/null; then
      LEARN_WT="../${REPO_NAME}.learn-$(date +%Y%m%d)"
      [ -d "$LEARN_WT" ] && git worktree remove "$LEARN_WT" --force 2>/dev/null
      git worktree add "$LEARN_WT" "$LEARN_BRANCH"
      gh issue comment $REPORT_ISSUE --repo $REPO \
        --body "[STANDALONE | ${MY_SESSION_ID:-sess-unknown} | otherness@${OTHERNESS_VERSION:-unknown}] Autonomous learn session triggered (${DAYS_SINCE_LEARN}d since last)." 2>/dev/null
      # [AI-STEP] Navigate to $LEARN_WT, read and follow ~/.otherness/agents/otherness.learn.md
      # After learn PR open and CI green: merge and clean up
      gh pr merge "$LEARN_BRANCH" --repo "$REPO" --squash --delete-branch 2>/dev/null || true
      git worktree remove "$LEARN_WT" --force 2>/dev/null || true
      git worktree prune
    fi
  fi

  sleep 60 && continue
fi

# Atomic claim via branch creation
MY_BRANCH="feat/$ITEM_ID"
REPO_NAME=$(basename $(git rev-parse --show-toplevel))
MY_WORKTREE="../${REPO_NAME}.${ITEM_ID}"
# MY_SESSION_ID is set at startup (sess-XXXX) — preserve it; don't overwrite with item-scoped ID

if git push origin "HEAD:refs/heads/$MY_BRANCH" 2>/dev/null; then
  echo "[COORD] ✅ Claimed $ITEM_ID"
  export ITEM_ID MY_BRANCH MY_WORKTREE

  [ -d "$MY_WORKTREE" ] && git worktree remove "$MY_WORKTREE" --force 2>/dev/null
  git worktree add "$MY_WORKTREE" "$MY_BRANCH"

  # Write claim to state
  python3 - <<PYEOF
import json, datetime, subprocess
r = subprocess.run(['git','show','origin/_state:.otherness/state.json'],
                   capture_output=True, text=True)
s = json.loads(r.stdout) if r.returncode == 0 else json.load(open('.otherness/state.json'))
s['features']['$ITEM_ID'].update({
    'state': 'assigned',
    'assigned_to': '$MY_SESSION_ID',
    'assigned_at': datetime.datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ'),
    'branch': '$MY_BRANCH',
    'worktree': '$MY_WORKTREE'
})
s.setdefault('session_heartbeats', {})['$MY_SESSION_ID'] = {
    'last_seen': datetime.datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ'),
    'item': '$ITEM_ID', 'cycle': 1
}
with open('.otherness/state.json', 'w') as f: json.dump(s, f, indent=2)
PYEOF
  export STATE_MSG="[$MY_SESSION_ID] claimed $ITEM_ID"
  # run STATE MANAGEMENT write block

  ISSUE_NUM=$(echo $ITEM_ID | grep -oE '[0-9]+' | head -1)
  gh issue comment $ISSUE_NUM --repo $REPO \
    --body "[$MY_SESSION_ID | otherness@${OTHERNESS_VERSION:-unknown}] Starting implementation. Branch: \`$MY_BRANCH\`" 2>/dev/null

else
  echo "[COORD] ⚡ $ITEM_ID already claimed — picking another."
  ITEM_ID=""
  # loop back
fi
```
