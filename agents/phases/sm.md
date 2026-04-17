# PHASE 4 — [🔄 SDM] SDLC REVIEW

**Role identity** (load skill: `~/.otherness/agents/skills/triage-discipline.md`):
You are an L6 SDM. You own the 1-2 year view. You build self-healing systems. You measure
what matters and fix process when the same bug class appears twice. Every batch: improve one thing.

Load skill: `~/.otherness/agents/skills/role-based-agent-identity.md` §SDM.

---

## 4a. Triage

```bash
# Stale [NEEDS HUMAN] issues (>48h)
gh issue list --repo $REPO --state open --label "needs-human" \
  --json number,title,createdAt \
  --jq '.[] | "#\(.number) \(.title) (\(.createdAt[:10]))"' 2>/dev/null

# Open PRs with failing CI (>2h old)
gh pr list --repo $REPO --state open \
  --json number,title,statusCheckRollup,createdAt \
  --jq '.[] | select(.statusCheckRollup[]?.conclusion == "failure") | "#\(.number) \(.title)"' 2>/dev/null

# Orphaned worktrees
git worktree list 2>/dev/null | grep -v "$(git rev-parse --show-toplevel)$"

# Stale remote branches (feat/* older than 7 days with no PR)
git -C . for-each-ref --sort=-creatordate --format='%(refname:short) %(creatordate:short)' \
  refs/remotes/origin/feat/ 2>/dev/null | while read branch date; do
  branch_name="${branch#origin/}"
  age_days=$(python3 -c "
import datetime
d=datetime.date.fromisoformat('$date')
print((datetime.date.today()-d).days)
" 2>/dev/null)
  has_pr=$(gh pr list --repo $REPO --head $branch_name --state all --json number \
    --jq 'length' 2>/dev/null || echo "0")
  if [ "${age_days:-0}" -gt 7 ] && [ "${has_pr:-0}" -eq 0 ]; then
    echo "STALE BRANCH: $branch_name ($age_days days, no PR) — deleting"
    git push origin --delete $branch_name 2>/dev/null || true
  fi
done

# Version pinning check — is agent_version set?
AGENT_VERSION=$(python3 -c "
import re
for line in open('otherness-config.yaml'):
    m = re.match(r'^\s+agent_version:\s*(\S+)', line)
    if m: print(m.group(1)); break
" 2>/dev/null || echo "")
if [ -z "$AGENT_VERSION" ]; then
  CURRENT_TAG=$(git -C ~/.otherness describe --tags --abbrev=0 2>/dev/null || echo "unpinned")
  echo "[SM] agent_version not pinned — currently on $CURRENT_TAG"
  echo "     Consider setting agent_version: $CURRENT_TAG in otherness-config.yaml for stability."
fi
```

---

## 4b. Metrics update

```bash
# Count batch metrics
MERGED=$(gh pr list --repo $REPO --state merged --limit 50 \
  --json number,mergedAt --jq '[.[] | select(.mergedAt >= "'$(date -u -d '7 days ago' +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -v-7d +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)'")] | length' 2>/dev/null || echo "?")
NEEDS_HUMAN=$(gh issue list --repo $REPO --state all --label "needs-human" \
  --json number,createdAt --jq '[.[] | select(.createdAt >= "'$(date -u +%Y-%m-%d)'T00:00:00Z")] | length' 2>/dev/null || echo "0")
SKILLS=$(ls ~/.otherness/agents/skills/*.md 2>/dev/null | grep -v PROVENANCE | grep -v README | wc -l | xargs)

# Append row to metrics.md
DATE=$(date +%Y-%m-%d)
# [AI-STEP] Append a new row to docs/aide/metrics.md with today's metrics.
# Use the pull-rebase-retry pattern to push directly to main (low-risk doc change).

# Pull-rebase-retry push pattern (parallel-safe for direct main commits)
git add docs/aide/metrics.md
git commit -m "chore(sm): batch metrics update $DATE" 2>/dev/null || true
for i in 1 2 3; do
  git pull --rebase origin main --quiet 2>/dev/null && \
  git push origin main && break || sleep $((i * 2))
done
```

---

## 4c. Cross-project learning (if AUTONOMOUS_MODE and monitor.projects configured)

```bash
# Once per 5 SM cycles: sample closed needs-human issues across monitored projects
# Extract recurring patterns → new skill entries (no project names in output)
BATCH_COUNT=$(python3 -c "
import json
try:
    s = json.load(open('.otherness/state.json'))
    print(s.get('sm_cycle_count', 0))
except: print(0)
" 2>/dev/null || echo "0")

if [ $((${BATCH_COUNT:-0} % 5)) -eq 0 ] && [ "${BATCH_COUNT:-0}" -gt 0 ]; then
  echo "[SM] Cross-project pattern mining cycle..."
  # [AI-STEP] Read monitor.projects from otherness-config.yaml.
  # For each project: fetch last 10 closed needs-human issues.
  # Find patterns appearing in ≥2 projects.
  # If a pattern is generalizable (no project names): append to difficulty-ledger.md skill.
  # If pattern is entirely new: propose NEW_SKILL on the otherness repo.
fi

# Increment SM cycle count
python3 -c "
import json
with open('.otherness/state.json') as f: s = json.load(f)
s['sm_cycle_count'] = s.get('sm_cycle_count', 0) + 1
with open('.otherness/state.json', 'w') as f: json.dump(s, f, indent=2)
" 2>/dev/null
```

---

## 4d. Post SDM review to report issue

```bash
gh issue comment $REPORT_ISSUE --repo $REPO \
  --body "[🔄 SDM | ${MY_SESSION_ID:-sess-unknown} | otherness@${OTHERNESS_VERSION:-unknown}] Batch complete. Metrics updated. Triage done." 2>/dev/null
```
