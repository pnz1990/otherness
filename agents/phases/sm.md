
## MODE: READ-ONLY

This agent reads files and produces output. It does not write, edit, create,
or delete any file in any zone.

If asked to implement, fix, or change code or docs: stop and redirect.

```
[🚫 D4 GATE] This session is READ-ONLY.
To implement changes:        /otherness.run
To update vision or design:  /otherness.vibe-vision
```

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

# Stale specs: .specify/specs/ dirs older than 30 days with no merged PR
python3 - <<'STALE_SPEC_EOF'
import os, subprocess, re, datetime

REPO = os.environ.get('REPO', '')
specs_dir = '.specify/specs'
if not os.path.isdir(specs_dir):
    exit(0)

try:
    merged = subprocess.check_output(
        ['gh','pr','list','--repo',REPO,'--state','merged','--limit','100',
         '--json','title,mergedAt','--jq','.[] | .title'],
        text=True, timeout=15).lower()
except:
    merged = ''

for spec_id in os.listdir(specs_dir):
    spec_path = f'{specs_dir}/{spec_id}'
    if not os.path.isdir(spec_path): continue
    spec_file = f'{spec_path}/spec.md'
    if not os.path.exists(spec_file): continue
    # Check age via git log
    age_r = subprocess.run(['git','log','--follow','--format=%ci','--',spec_file],
                           capture_output=True, text=True, timeout=10)
    dates = re.findall(r'(\d{4}-\d{2}-\d{2})', age_r.stdout)
    if not dates: continue
    try:
        oldest = datetime.datetime.fromisoformat(dates[-1])
        age = (datetime.datetime.utcnow() - oldest).days
    except: continue
    if age < 30: continue
    # Check if there's a merged PR referencing this spec
    spec_key = spec_id.lower()[:40]
    if spec_key in merged: continue
    # Open stale-spec issue
    title = f'chore(refactor): stale spec {spec_id} — {age}d old, no merged PR'
    existing = subprocess.run(
        ['gh','issue','list','--repo',REPO,'--state','open','--search',title[:50],'--json','number','--jq','length'],
        capture_output=True, text=True, timeout=10)
    if int(existing.stdout.strip() or '0') == 0:
        subprocess.run(['gh','issue','create','--repo',REPO,
            '--title',title,'--label','kind/chore,priority/low,size/xs',
            '--body',f'SM §4a: `.specify/specs/{spec_id}/` is {age} days old with no corresponding merged PR.\n\nOptions:\n1. Delete if the feature was shipped under a different name\n2. Update the spec if still relevant\n3. Archive if deferred indefinitely'],
            capture_output=True, timeout=15)
        print(f'[SM §4a] Stale spec issue: {title[:60]}')

print('[SM §4a] Stale spec check complete.')
STALE_SPEC_EOF

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

# §4b: Session outcome classification (design doc 35 §Future → ✅)
# Count vision PRs: feat/fix/refactor titles that are NOT chore/metrics/session-report
VISION_PRS=$(gh pr list --repo $REPO --state merged --limit 30 \
  --json title,mergedAt \
  --jq "[.[] | select(
    (.title | test(\"^feat|^fix|^refactor\"; \"i\")) and
    (.title | test(\"^chore\\\\(sm\\\\)|metrics|session complete|PRs merged|batch \"; \"i\") | not)
  ) | .title] | length" 2>/dev/null || echo "0")

# Classify session outcome based on vision_prs ratio
SESSION_OUTCOME=$(python3 -c "
import sys
try:
    vision = int('${VISION_PRS:-0}')
    merged = int('${MERGED:-0}') if '${MERGED:-0}'.isdigit() else 0
    if vision == 0:
        print('chore-only')
    elif merged > 0 and vision >= merged / 2:
        print('feature-rich')
    else:
        print('mixed')
except:
    print('unknown')
" 2>/dev/null || echo "unknown")

export VISION_PRS SESSION_OUTCOME
echo "[SM §4b] Session outcome: ${SESSION_OUTCOME} (vision_prs=${VISION_PRS}, prs_merged=${MERGED})"

# Append row to metrics.md
DATE=$(date +%Y-%m-%d)
# [AI-STEP] Append a new row to docs/aide/metrics.md with today's metrics.
# Row format (as of PR that added arch_convergence + sim_floor_delta):
#   | $DATE | $BATCH | $MERGED | $NEEDS_HUMAN | 0 | $SKILLS | $TODO_SHIPPED | ~Xmin | $VISION_PRS | $SESSION_OUTCOME | $ARCH_CONVERGENCE | $SIM_FLOOR_DELTA | <notes> |
# $ARCH_CONVERGENCE: from scripts/sim-params.json arch_convergence_score field (default: — if calibration not run)
# $SIM_FLOOR_DELTA: $MERGED - sim_predicted_floor from scripts/sim-params.json (default: — if missing)
# Historical rows (before PR #655) have only 9 columns — do not modify them.
# Historical rows from PR #655 (vision_prs + session_outcome) have 11 columns — do not modify them.
# Use the pull-rebase-retry pattern to push directly to main (low-risk doc change).

# Pull-rebase-retry push pattern (parallel-safe for direct main commits)
git add docs/aide/metrics.md
git commit -m "chore(sm): batch metrics update $DATE" 2>/dev/null || true
for i in 1 2 3; do
  git pull --rebase origin main --quiet 2>/dev/null && \
  git push origin main && break || sleep $((i * 2))
done

# Regression detection: read back last 3 rows and auto-open issues on 2-batch regressions
python3 - <<'REGEOF'
import re, subprocess, os

REPO = os.environ.get('REPO', '')
REPORT_ISSUE = os.environ.get('REPORT_ISSUE', '')

def parse_rows(content):
    rows = []
    for line in content.splitlines():
        m = re.match(r'^\|\s*\d{4}-\d{2}-\d{2}\s*\|(.+)', line)
        if m:
            cells = [c.strip() for c in line.split('|')[1:-1]]
            if len(cells) >= 7:
                try:
                    rows.append({
                        'batch': cells[1],
                        'needs_human': int(cells[3]) if cells[3].isdigit() else -1,
                        'todo_shipped': int(cells[6]) if cells[6].isdigit() else -1,
                    })
                except (ValueError, IndexError):
                    pass
    return rows

def open_if_absent(title, body):
    """Open a kind/chore issue only if none with the same title is currently open."""
    existing = subprocess.run(
        ['gh', 'issue', 'list', '--repo', REPO, '--state', 'open',
         '--search', title, '--json', 'number', '--jq', 'length'],
        capture_output=True, text=True)
    count = int(existing.stdout.strip() or '0')
    if count == 0:
        r = subprocess.run(
            ['gh', 'issue', 'create', '--repo', REPO,
             '--title', title, '--label', 'kind/chore,otherness', '--body', body],
            capture_output=True, text=True)
        if r.returncode == 0:
            print(f'[SM] Opened regression issue: {r.stdout.strip()}')
        else:
            print(f'[SM] Failed to open regression issue: {r.stderr.strip()}')
    else:
        print(f'[SM] Regression issue already open — skipping duplicate for: {title}')

try:
    content = open('docs/aide/metrics.md').read()
    rows = parse_rows(content)
except Exception:
    rows = []

if len(rows) < 3:
    print(f'[SM] Regression check: only {len(rows)} rows — need ≥ 3, skipping.')
else:
    n2, n1, n0 = rows[-3], rows[-2], rows[-1]

    # needs_human regression: last 2 batches both higher than N-2
    if n2['needs_human'] >= 0 and n1['needs_human'] >= 0 and n0['needs_human'] >= 0:
        if n1['needs_human'] > n2['needs_human'] and n0['needs_human'] > n2['needs_human']:
            open_if_absent(
                '[METRIC REGRESSION] needs_human increasing — investigate',
                f'SM regression check triggered.\n\n'
                f'`needs_human` increased for 2 consecutive batches vs baseline:\n'
                f'- Batch {n2["batch"]}: {n2["needs_human"]}\n'
                f'- Batch {n1["batch"]}: {n1["needs_human"]}\n'
                f'- Batch {n0["batch"]}: {n0["needs_human"]}\n\n'
                f'Review open needs-human issues and identify the root cause.'
            )
        else:
            print(f'[SM] needs_human: no regression '
                  f'({n2["needs_human"]} → {n1["needs_human"]} → {n0["needs_human"]})')

    # todo_shipped regression: last 2 batches both = 0
    if n1['todo_shipped'] >= 0 and n0['todo_shipped'] >= 0:
        if n1['todo_shipped'] == 0 and n0['todo_shipped'] == 0:
            open_if_absent(
                '[METRIC REGRESSION] no items shipped in 2 batches',
                f'SM regression check triggered.\n\n'
                f'`todo_shipped` = 0 for 2 consecutive batches:\n'
                f'- Batch {n1["batch"]}: shipped={n1["todo_shipped"]}\n'
                f'- Batch {n0["batch"]}: shipped={n0["todo_shipped"]}\n\n'
                f'Check the queue: is it empty? Are items blocked? See docs/aide/roadmap.md.'
            )
        else:
            print(f'[SM] todo_shipped: no regression '
                   f'({n1["todo_shipped"]} → {n0["todo_shipped"]})')
REGEOF
```

# Difficulty ledger: append when any hard case is detected
# [AI-STEP] Check last batch metrics (from rows[-1]):
#   - needs_human > 0 (an escalation occurred)
#   - todo_shipped = 0 for 2 consecutive batches (velocity stalled)
#   - time_to_merge_avg_min > 60 (items are taking too long)
# If any trigger fires: append an entry to ~/.otherness/agents/skills/difficulty-ledger.md
# Format: ## YYYY-MM-DD: <abstract situation> / **Situation** / **What resolved it** / **Guard**
# Keep abstract — no project names.

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
  # [AI-STEP] Cross-project needs-human pattern mining:
  # 1. Read monitor.projects from otherness-config.yaml (list of owner/repo strings)
  # 2. For each project in the list:
  #    gh issue list --repo <project> --label needs-human --state closed --limit 10
  #    --json number,title,body,comments → collect titles and comment bodies
  # 3. Analyze patterns across ALL projects:
  #    - Look for needs-human issues with similar root causes (e.g. "CI red >24h",
  #      "spec missing", "merge conflict", "stale branch")
  #    - A pattern qualifies if it appears in ≥2 different projects
  # 4. For each qualifying pattern:
  #    - Write a generic entry to ~/.otherness/agents/skills/difficulty-ledger.md
  #    - Format: ## DATE: <abstract pattern name>
  #      **Situation**: <abstract description — no project names>
  #      **What resolved it**: <resolution pattern>
  #      **Guard**: <preventive check for future>
   # 5. If the pattern represents an entirely new failure class not yet in any skill file:
   #    gh issue create --repo $REPO --title "skill: <pattern>" --label otherness
  # If only 1 project or no patterns found: log "[SM] No cross-project patterns found."

  # §4c-propagate: Cross-project pressure propagation (design doc 28 §Future → ✅)
  # When a pattern is detected across ≥2 monitored projects, flag the pressure context
  # in each affected project so their next vibe-vision scan targets the shared gap.
  # This opens a GitHub issue on each monitored repo — the agent running there picks it up.
  # Direct workflow edits are NOT made here (D4 design-first: issue → design doc → PR).
  python3 - <<'PROPAGATE_EOF'
import re, os, subprocess, datetime

REPO = os.environ.get('REPO', '')
REPORT_ISSUE = os.environ.get('REPORT_ISSUE', '1')
MY_SESSION_ID = os.environ.get('MY_SESSION_ID', 'sess-unknown')
OTHERNESS_VERSION = os.environ.get('OTHERNESS_VERSION', 'unknown')

# Step 1: Read monitor.projects
monitored = []
try:
    in_monitor = in_projects = False
    for line in open('otherness-config.yaml'):
        if re.match(r'^monitor:', line): in_monitor = True
        if in_monitor and re.match(r'\s+projects:', line): in_projects = True
        if in_projects:
            m = re.match(r'\s+- (.+)', line)
            if m:
                r = m.group(1).strip()
                if r: monitored.append(r)
        # Stop reading monitor section when we hit a new top-level key
        if in_projects and re.match(r'^\w', line) and not re.match(r'^monitor:', line):
            break
except Exception as e:
    print(f'[SM §4c-propagate] Config read error: {e}')

if len(monitored) < 2:
    print(f'[SM §4c-propagate] Fewer than 2 monitored projects — skipping cross-project propagation.')
    exit(0)

# Step 2: For each project, collect recent merged PR titles as a proxy for addressed areas
project_pr_titles = {}
for proj in monitored:
    try:
        result = subprocess.run(
            ['gh', 'pr', 'list', '--repo', proj, '--state', 'merged',
             '--limit', '20', '--json', 'title', '--jq', '.[].title'],
            capture_output=True, text=True, timeout=20)
        if result.returncode == 0:
            project_pr_titles[proj] = result.stdout.lower().splitlines()
        else:
            project_pr_titles[proj] = []
    except Exception:
        project_pr_titles[proj] = []

# Step 3: Find patterns — areas that appear as gaps across ≥2 projects
# A "gap" = a known pressure category NOT mentioned in recent PRs for a project
PRESSURE_CATEGORIES = [
    ('test coverage', ['test', 'coverage', 'spec', 'unit test']),
    ('error handling', ['error', 'handle', 'fallback', 'retry']),
    ('ci stability', ['ci', 'workflow', 'pipeline', 'lint', 'build']),
    ('documentation', ['doc', 'readme', 'comment', 'guide']),
    ('performance', ['perf', 'speed', 'latency', 'slow', 'optim']),
    ('security', ['security', 'auth', 'permission', 'token', 'secret']),
]

def has_coverage(pr_titles, keywords):
    """Return True if any keyword appears in any PR title."""
    return any(any(kw in title for kw in keywords) for title in pr_titles)

# Identify categories missing from ≥2 projects
shared_gaps = []
for category_name, keywords in PRESSURE_CATEGORIES:
    missing_in = [proj for proj in monitored
                  if not has_coverage(project_pr_titles.get(proj, []), keywords)]
    if len(missing_in) >= 2:
        shared_gaps.append((category_name, keywords, missing_in))

if not shared_gaps:
    print('[SM §4c-propagate] No shared pressure gaps found across monitored projects.')
    exit(0)

print(f'[SM §4c-propagate] Shared gaps detected: {[g[0] for g in shared_gaps]}')

# Step 4: For each monitored project with a shared gap, open a pressure issue
today = datetime.date.today().isoformat()
propagated = []

for category_name, keywords, missing_in in shared_gaps[:2]:  # limit to top 2 gaps
    for proj in missing_in:
        title = f'feat: cross-project pressure — rewrite vision pressure context for {category_name}'
        # Dedup: skip if similar issue already open
        try:
            existing = subprocess.run(
                ['gh', 'issue', 'list', '--repo', proj, '--state', 'open',
                 '--search', 'cross-project pressure', '--json', 'number', '--jq', 'length'],
                capture_output=True, text=True, timeout=15)
            if int(existing.stdout.strip() or '0') > 0:
                print(f'[SM §4c-propagate] {proj}: pressure issue already open — skipping.')
                continue
        except Exception:
            pass

        body = (
            f'## Cross-project pressure propagation\n\n'
            f'**Pattern detected**: `{category_name}` is a shared gap across '
            f'{len(missing_in)} monitored projects (no recent PRs addressing this area).\n\n'
            f'**Action required**: Update the `Context for this vision scan:` block in '
            f'this project\'s scheduled workflow to add explicit pressure on `{category_name}`.\n\n'
            f'This issue was opened automatically by SM §4c-propagate on `{REPO}` as part of '
            f'cross-project pressure propagation (design doc 28).\n\n'
            f'## What to do\n'
            f'1. Find the `otherness-scheduled.yml` (or equivalent) workflow.\n'
            f'2. In the Step A (vibe-vision) `prompt:` block, add or strengthen:\n'
            f'   ```\n'
            f'   - Is {category_name} coverage sufficient?\n'
            f'   ```\n'
            f'3. Open a PR updating the workflow.\n\n'
            f'Reported by SM §4c-propagate | {MY_SESSION_ID} | otherness@{OTHERNESS_VERSION} | {today}'
        )

        try:
            r = subprocess.run(
                ['gh', 'issue', 'create', '--repo', proj,
                 '--title', title,
                 '--label', 'otherness,kind/enhancement,priority/low,area/agent-loop',
                 '--body', body],
                capture_output=True, text=True, timeout=20)
            if r.returncode == 0:
                issue_url = r.stdout.strip()
                print(f'[SM §4c-propagate] Created pressure issue on {proj}: {issue_url}')
                propagated.append(f'{proj}: {category_name}')
            else:
                # Label may not exist on target repo — retry without label
                r2 = subprocess.run(
                    ['gh', 'issue', 'create', '--repo', proj,
                     '--title', title, '--body', body],
                    capture_output=True, text=True, timeout=20)
                if r2.returncode == 0:
                    print(f'[SM §4c-propagate] Created pressure issue (no label) on {proj}: {r2.stdout.strip()}')
                    propagated.append(f'{proj}: {category_name}')
        except Exception as e:
            print(f'[SM §4c-propagate] Could not create issue on {proj}: {e}')

# Step 5: Post audit comment to REPORT_ISSUE
if propagated:
    summary = '\n'.join(f'  - {p}' for p in propagated)
    try:
        subprocess.run(
            ['gh', 'issue', 'comment', REPORT_ISSUE, '--repo', REPO,
             '--body', (
                 f'[SM §4c-propagate | {MY_SESSION_ID} | otherness@{OTHERNESS_VERSION}] '
                 f'Cross-project pressure propagation complete.\n'
                 f'Shared gaps: {[g[0] for g in shared_gaps]}\n'
                 f'Issues created:\n{summary}'
             )],
            capture_output=True, timeout=15)
    except Exception:
        pass
else:
    print('[SM §4c-propagate] No new pressure issues needed — all covered or already open.')

PROPAGATE_EOF
fi

# Increment SM cycle count
python3 -c "
import json
with open('.otherness/state.json') as f: s = json.load(f)
s['sm_cycle_count'] = s.get('sm_cycle_count', 0) + 1
with open('.otherness/state.json', 'w') as f: json.dump(s, f, indent=2)
" 2>/dev/null

# §4c: Explicit 14-day learn-cadence enforcement (design doc 31 §Future → ✅)
# The Type B rate trigger (§4d-learn) is necessary but not sufficient.
# This check enforces a hard 14-day floor regardless of Type B rate.
python3 - <<'LEARN_CADENCE_EOF'
import re, datetime, os, subprocess

REPO = os.environ.get('REPO', '')
REPORT_ISSUE = os.environ.get('REPORT_ISSUE', '1')
MY_SESSION_ID = os.environ.get('MY_SESSION_ID', 'sess-unknown')
OTHERNESS_VERSION = os.environ.get('OTHERNESS_VERSION', 'unknown')
MAX_DAYS = 14

# Step 1: Read last PROVENANCE.md entry date
try:
    content = open(os.path.expanduser('~/.otherness/agents/skills/PROVENANCE.md')).read()
    dates = re.findall(r'^## (\d{4}-\d{2}-\d{2})', content, re.MULTILINE)
    if dates:
        last_date = datetime.date.fromisoformat(sorted(dates)[-1])
        days_since = (datetime.date.today() - last_date).days
    else:
        days_since = 999
except Exception:
    days_since = 999  # PROVENANCE.md missing — treat as overdue

print(f'[SM §4c] Learn cadence: {days_since}d since last PROVENANCE.md entry (max={MAX_DAYS}d)')

if days_since < MAX_DAYS:
    print(f'[SM §4c] Learn cadence OK — {days_since}d < {MAX_DAYS}d floor. No action needed.')
else:
    # Step 2: Check if a learn issue is already open or a learn branch is active
    try:
        open_learn = subprocess.run(
            ['gh', 'issue', 'list', '--repo', REPO, '--state', 'open',
             '--search', 'learn(arch)', '--json', 'number', '--jq', 'length'],
            capture_output=True, text=True, timeout=15)
        open_count = int(open_learn.stdout.strip() or '0')
    except Exception:
        open_count = 0

    try:
        learn_branch = subprocess.run(
            ['git', 'ls-remote', '--heads', 'origin'],
            capture_output=True, text=True, timeout=10)
        branch_active = any(
            'feat/learn' in line
            for line in learn_branch.stdout.splitlines()
        )
    except Exception:
        branch_active = False

    if open_count > 0:
        print(f'[SM §4c] Learn issue already open ({open_count}) — cadence reminder satisfied.')
    elif branch_active:
        print(f'[SM §4c] Learn branch active — cadence satisfied (in progress).')
    else:
        print(f'[SM §4c] Learn overdue ({days_since}d > {MAX_DAYS}d floor) — opening priority/high issue.')
        title = f'learn(arch): cadence enforcement — PROVENANCE.md overdue ({days_since}d since last learn)'
        body = (
            f'## Learn cadence enforcement\n\n'
            f'`PROVENANCE.md` last entry was {days_since} days ago. '
            f'The 14-day floor (design doc 31 §Future) requires a learn session.\n\n'
            f'This issue was opened automatically by SM §4c cadence enforcement.\n\n'
            f'## What to do\n'
            f'Run `/otherness.learn` in the next available session. '
            f'Pick a repo from a different paradigm than the last session.\n\n'
            f'Reported by SM §4c | {MY_SESSION_ID} | otherness@{OTHERNESS_VERSION}'
        )
        r = subprocess.run(
            ['gh', 'issue', 'create', '--repo', REPO,
             '--title', title, '--label', 'otherness,priority/high,area/skills,kind/chore',
             '--body', body],
            capture_output=True, text=True, timeout=15)
        if r.returncode == 0:
            print(f'[SM §4c] Learn cadence issue created: {r.stdout.strip()}')
            # Post to report issue
            subprocess.run(
                ['gh', 'issue', 'comment', REPORT_ISSUE, '--repo', REPO,
                 '--body', f'[SM §4c | {MY_SESSION_ID}] Learn cadence overdue ({days_since}d). Created learn issue.'],
                capture_output=True, timeout=10)
        else:
            print(f'[SM §4c] Failed to create learn issue: {r.stderr.strip()[:100]}')
LEARN_CADENCE_EOF
```

---

## 4c-skill. Skill confidence check (every 10 SM cycles)

```bash
if [ $((${BATCH_COUNT:-0} % 10)) -eq 0 ] && [ "${BATCH_COUNT:-0}" -gt 0 ]; then
  echo "[SM] Running skill confidence check..."
  # [AI-STEP] Check each skill file in ~/.otherness/agents/skills/ (excluding PROVENANCE, README):
  # For each skill:
  # 1. Check if it is referenced in phases/*.md or standalone.md:
  #    grep -r "<skill-basename>" ~/.otherness/agents/phases/ ~/.otherness/agents/standalone.md
  #    If not found: note as "unreferenced"
  # 2. Check age: git -C ~/.otherness log --format='%ar' -1 -- agents/skills/<skill>.md
  #    If last modified >180 days ago: note as "stale"
  # 3. Check for obvious contradictions: if 2 skill files have the same topic heading:
  #    note both as "possibly overlapping"
  # Compile a report. Post it as a comment on $REPORT_ISSUE (informational only).
  # Do NOT modify any skill file. Do NOT post [NEEDS HUMAN].
  # Example comment: "[SM] Skill confidence: 12 skills checked. unreferenced: [X]. stale: [Y]."
fi

# §4c: Skill decay tracking (design doc 31 §Future → ✅)
# Skills added >90 days ago without a PROVENANCE.md mention are candidates for revision.
if [ $((${BATCH_COUNT:-0} % 10)) -eq 0 ] && [ "${BATCH_COUNT:-0}" -gt 0 ]; then
  python3 - <<'DECAY_EOF'
import os, datetime, re, subprocess

REPO = os.environ.get('REPO', '')
REPORT_ISSUE = os.environ.get('REPORT_ISSUE', '1')
MY_SESSION_ID = os.environ.get('MY_SESSION_ID', 'sess-unknown')
SKILLS_DIR = os.path.expanduser('~/.otherness/agents/skills')
PROVENANCE = os.path.join(SKILLS_DIR, 'PROVENANCE.md')
DECAY_DAYS = 90
now = datetime.date.today()

if not os.path.isdir(SKILLS_DIR):
    print('[SM §4c-decay] Skills dir not found — skipping.')
    exit(0)

# Read PROVENANCE.md for skill name mentions (last 90 days)
recent_mentions = set()
try:
    prov = open(PROVENANCE).read()
    # Find all YYYY-MM-DD headers and collect text in subsequent 30 lines
    blocks = re.split(r'^## (\d{4}-\d{2}-\d{2})', prov, flags=re.MULTILINE)
    for i in range(1, len(blocks), 2):
        try:
            block_date = datetime.date.fromisoformat(blocks[i])
            if (now - block_date).days <= DECAY_DAYS and i+1 < len(blocks):
                # Extract skill file mentions from this block
                mentions = re.findall(r'\b([\w-]+\.md)\b', blocks[i+1])
                recent_mentions.update(m.replace('.md','') for m in mentions)
                # Also check for skill name mentions (without .md)
                for fname in os.listdir(SKILLS_DIR):
                    if fname.endswith('.md') and fname not in ('PROVENANCE.md','README.md'):
                        skill_name = fname.replace('.md','')
                        if skill_name in blocks[i+1]:
                            recent_mentions.add(skill_name)
        except Exception:
            pass
except Exception:
    pass

# Check each skill file age via git log
stale_skills = []
try:
    for fname in sorted(os.listdir(SKILLS_DIR)):
        if fname in ('PROVENANCE.md', 'README.md') or not fname.endswith('.md'):
            continue
        fpath = os.path.join(SKILLS_DIR, fname)
        skill_name = fname.replace('.md', '')
        try:
            r = subprocess.run(
                ['git', '-C', SKILLS_DIR, 'log', '--format=%ci', '-1', '--', fname],
                capture_output=True, text=True, timeout=10)
            if r.stdout.strip():
                date_str = r.stdout.strip()[:10]
                file_date = datetime.date.fromisoformat(date_str)
                age_days = (now - file_date).days
            else:
                age_days = 0
        except Exception:
            age_days = 0

        if age_days >= DECAY_DAYS and skill_name not in recent_mentions:
            stale_skills.append((skill_name, age_days))
except Exception as e:
    print(f'[SM §4c-decay] Error scanning skills: {e}')
    exit(0)

if stale_skills:
    stale_list = ', '.join(f'{n} ({d}d)' for n, d in stale_skills[:5])
    msg = (f'[SM §4c-decay | {MY_SESSION_ID}] Skill decay check: '
           f'{len(stale_skills)} skill(s) not reinforced in {DECAY_DAYS}d: {stale_list}. '
           f'Consider refreshing via the next learn session.')
    print(f'[SM §4c-decay] {len(stale_skills)} stale skills: {stale_list}')
    subprocess.run(
        ['gh', 'issue', 'comment', REPORT_ISSUE, '--repo', REPO, '--body', msg],
        capture_output=True, timeout=10)
else:
    print(f'[SM §4c-decay] All skills reinforced within {DECAY_DAYS} days. No decay detected.')
DECAY_EOF
fi
```

---

## 4d. Simulation calibration (every 10 batches)

Run `scripts/calibrate.py` every 10 batches to keep simulation parameters
anchored to real observed behavior. Check the arch-convergence signal and
escalate to human if architectural monoculture is detected.

```bash
SM_CYCLE=$(python3 -c "
import json
try:
    s = json.load(open('.otherness/state.json'))
    print(s.get('sm_cycle_count', 0))
except: print(0)
" 2>/dev/null || echo "0")

if [ $((SM_CYCLE % 10)) -eq 0 ] && [ "$SM_CYCLE" -gt 0 ]; then
    echo "[SM §4d] Running simulation calibration (sm_cycle=$SM_CYCLE)..."

    # Phase 2a: per-project calibration — use local metrics if ≥10 batches available
    METRICS_ROWS=$(grep -c '^\|\s*[0-9][0-9][0-9][0-9]-' docs/aide/metrics.md 2>/dev/null || echo 0)
    if [ "${METRICS_ROWS:-0}" -ge 10 ]; then
        echo "[SM §4d] Using project-specific metrics ($METRICS_ROWS batches) for calibration."
        CALIB_ARGS="--runs 3 --cycles 50 --metrics docs/aide/metrics.md"
    else
        echo "[SM §4d] Using otherness default calibration (only ${METRICS_ROWS:-0} batches available)."
        CALIB_ARGS="--runs 3 --cycles 50"
    fi

    if python3 scripts/calibrate.py $CALIB_ARGS 2>/dev/null; then
        echo "[SM §4d] Calibration complete — sim-params.json updated."

        # Persist sim-params.json to _state branch
        if [ -f "scripts/sim-params.json" ]; then
            python3 - <<'PARAMS_EOF'
import subprocess, json, os, tempfile, time, shutil

state_wt = os.path.join(tempfile.gettempdir(), 'otherness-simparams-' + str(os.getpid()))
sm_cycle = os.environ.get('SM_CYCLE', '0')

try:
    if os.path.exists(state_wt):
        subprocess.run(['git','worktree','remove',state_wt,'--force'], capture_output=True)
    subprocess.run(['git','worktree','add','--no-checkout',state_wt,'origin/_state'],
                   capture_output=True, check=True)
    target = os.path.join(state_wt,'.otherness','sim-params.json')
    os.makedirs(os.path.dirname(target), exist_ok=True)
    import shutil as _sh
    _sh.copy('scripts/sim-params.json', target)
    subprocess.run(['git','-C',state_wt,'add',target], capture_output=True)
    r = subprocess.run(['git','-C',state_wt,'commit',
                        '-m', f'calibration: update sim-params.json (sm_cycle={sm_cycle})'],
                       capture_output=True)
    if r.returncode == 0:
        subprocess.run(['git','-C',state_wt,'push','origin','HEAD:_state'], capture_output=True)
        print(f"[SM §4d] sim-params.json persisted to _state (sm_cycle={sm_cycle})")
    else:
        print("[SM §4d] sim-params.json unchanged — no commit needed")
except Exception as e:
    print(f"[SM §4d] sim-params persist error (non-fatal): {e}")
finally:
    try:
        subprocess.run(['git','worktree','remove',state_wt,'--force'], capture_output=True)
    except: pass
subprocess.run(['git','worktree','prune'], capture_output=True)
PARAMS_EOF
        fi

        # Fleet defaults: if this is the otherness repo, write sim-defaults.json
        # to scripts/ and push to main. Managed projects pick it up on next git pull.
        # O4: skip silently on managed projects.
        IS_OTHERNESS=$(python3 -c "
import re, os
try:
    for line in open('otherness-config.yaml'):
        m = re.match(r'^\s+repo:\s*(.+)', line)
        if m:
            print('true' if m.group(1).strip().endswith('/otherness') else 'false')
            exit()
except: pass
print('false')
" 2>/dev/null || echo "false")

        if [ "$IS_OTHERNESS" = "true" ] && [ -f "scripts/sim-params.json" ]; then
            python3 - <<'FLEETEOF'
import subprocess, json, os, datetime, shutil

sm_cycle = os.environ.get('SM_CYCLE', '0')
try:
    params = json.load(open('scripts/sim-params.json'))
    defaults = dict(params)
    defaults['fleet_calibrated_at'] = datetime.datetime.now(datetime.timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')
    defaults['source'] = 'otherness'
    json.dump(defaults, open('scripts/sim-defaults.json', 'w'), indent=2)
    print(f"[SM §4d] sim-defaults.json written (sm_cycle={sm_cycle})")

    # Commit and push to main — managed projects pick up on next git pull startup
    subprocess.run(['git','add','scripts/sim-defaults.json'], capture_output=True)
    r = subprocess.run(['git','commit','-m',f'chore(sm): update sim-defaults.json (sm_cycle={sm_cycle})'],
                       capture_output=True, text=True)
    if r.returncode != 0:
        print("[SM §4d] sim-defaults.json: no changes to commit")
    else:
        for attempt in range(3):
            subprocess.run(['git','pull','--rebase','origin','main','--quiet'],
                           capture_output=True)
            push_r = subprocess.run(['git','push','origin','HEAD:main'],
                                    capture_output=True, text=True)
            if push_r.returncode == 0:
                print("[SM §4d] sim-defaults.json pushed to main (fleet update)")
                break
            import time; time.sleep(2 * (attempt + 1))
        else:
            print("[SM §4d] sim-defaults.json push failed after 3 attempts — non-fatal")
except Exception as e:
    print(f"[SM §4d] sim-defaults.json error (non-fatal): {e}")
FLEETEOF
        fi

        # Phase 2c: write sim-results.json to _state branch
        python3 - <<'SIMRES_EOF'
import subprocess, json, os, tempfile, datetime, shutil

state_wt = os.path.join(tempfile.gettempdir(), 'otherness-simresults-' + str(os.getpid()))
sm_cycle = os.environ.get('SM_CYCLE', '0')
metrics_rows = int(os.environ.get('METRICS_ROWS', '0'))

try:
    sim_params = json.load(open('scripts/sim-params.json'))
except Exception:
    sim_params = {}

results = {
    "calibrated_at": datetime.datetime.utcnow().isoformat() + "Z",
    "best_rmse": sim_params.get("rmse"),
    "source": "project-specific" if metrics_rows >= 10 else "otherness-defaults",
    "params": sim_params
}

try:
    if os.path.exists(state_wt):
        subprocess.run(['git','worktree','remove',state_wt,'--force'], capture_output=True)
    subprocess.run(['git','worktree','add','--no-checkout',state_wt,'origin/_state'],
                   capture_output=True, check=True)
    target = os.path.join(state_wt,'.otherness','sim-results.json')
    os.makedirs(os.path.dirname(target), exist_ok=True)
    json.dump(results, open(target,'w'), indent=2)
    subprocess.run(['git','-C',state_wt,'add',target], capture_output=True)
    subprocess.run(['git','-C',state_wt,'commit',
                    '-m', f'calibration: sim-results.json (sm_cycle={sm_cycle})'],
                   capture_output=True)
    subprocess.run(['git','-C',state_wt,'push','origin','HEAD:_state'], capture_output=True)
    print(f"[SM §4d] sim-results.json written to _state (source={results['source']})")
except Exception as e:
    print(f"[SM §4d] sim-results write error (non-fatal): {e}")
finally:
    try:
        subprocess.run(['git','worktree','remove',state_wt,'--force'], capture_output=True)
    except: pass
subprocess.run(['git','worktree','prune'], capture_output=True)
SIMRES_EOF

        # Write sim-prediction.json to _state branch (design doc 23 §Step 2)
        # Derives floor/ceiling from simulation run with calibrated parameters.
        python3 - <<'SIMPRED_EOF'
import subprocess, json, os, tempfile, datetime, shutil

state_wt = os.path.join(tempfile.gettempdir(), 'otherness-simpred-' + str(os.getpid()))
sm_cycle = os.environ.get('SM_CYCLE', '0')

try:
    params = json.load(open('scripts/sim-params.json'))
except Exception:
    print("[SM §4d] sim-params.json not found — skipping sim-prediction.json")
    exit(0)

try:
    import sys as _sys; _sys.path.insert(0, '.')
    from scripts.simulate import SimConfig, run_simulation
    cfg = SimConfig(
        n_agents=4, n_cycles=50, seed=42,
        decay_rate=params.get('decay_rate', 0.92),
        jump_multiplier=params.get('jump_multiplier', 1.6),
        skill_boldness_coefficient=params.get('skill_boldness_coefficient', 0.015),
    )
    metrics, _ = run_simulation(cfg)
    last_10 = [m.completion_rate for m in metrics[-10:]]
    sorted_rates = sorted(last_10)
    prs_floor = max(1, int(sorted_rates[1]))      # 10th percentile
    prs_ceiling = max(prs_floor + 1, int(sorted_rates[-2]) + 1)  # 90th percentile
    arch_conv = round(metrics[-1].mean_arch_convergence, 3)
    skill_growth = round(
        (metrics[-1].skill_diversity - metrics[-5].skill_diversity) / 5
        if len(metrics) >= 5 else 0.0, 3)
except Exception as e:
    print(f"[SM §4d] sim-prediction simulation error (non-fatal): {e}")
    exit(0)

prediction = {
    "prs_next_batch_floor": prs_floor,
    "prs_next_batch_ceiling": prs_ceiling,
    "arch_convergence_score": arch_conv,
    "skill_growth_rate": skill_growth,
    "calibrated_params": {
        "decay_rate": params.get("decay_rate"),
        "jump_multiplier": params.get("jump_multiplier"),
        "skill_boldness_coefficient": params.get("skill_boldness_coefficient"),
    },
    "calibrated_at": datetime.datetime.now(datetime.timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ'),
}

try:
    if os.path.exists(state_wt):
        subprocess.run(['git','worktree','remove',state_wt,'--force'], capture_output=True)
    subprocess.run(['git','worktree','add','--no-checkout',state_wt,'origin/_state'],
                   capture_output=True, check=True)
    target = os.path.join(state_wt, '.otherness', 'sim-prediction.json')
    os.makedirs(os.path.dirname(target), exist_ok=True)
    json.dump(prediction, open(target, 'w'), indent=2)
    subprocess.run(['git','-C',state_wt,'add',target], capture_output=True)
    subprocess.run(['git','-C',state_wt,'commit',
                    '-m', f'calibration: sim-prediction.json (sm_cycle={sm_cycle})'],
                   capture_output=True)
    subprocess.run(['git','-C',state_wt,'push','origin','HEAD:_state'], capture_output=True)
    print(f"[SM §4d] sim-prediction.json written: floor={prs_floor}, ceiling={prs_ceiling}, "
          f"arch_conv={arch_conv}, skill_growth={skill_growth}")
except Exception as e:
    print(f"[SM §4d] sim-prediction write error (non-fatal): {e}")
finally:
    try:
        subprocess.run(['git','worktree','remove',state_wt,'--force'], capture_output=True)
    except: pass
subprocess.run(['git','worktree','prune'], capture_output=True)
SIMPRED_EOF

        # Read arch_convergence from latest sim-params.json
        ARCH_CONV=$(python3 -c "
import json, os
try:
    p = json.load(open('scripts/sim-params.json'))
    # Run a quick simulation to get current arch_convergence
    import sys; sys.path.insert(0,'.')
    from scripts.simulate import SimConfig, run_simulation
    cfg = SimConfig(
        n_agents=4, n_cycles=50, seed=42,
        decay_rate=p.get('decay_rate', 0.92),
        jump_multiplier=p.get('jump_multiplier', 1.6),
        skill_boldness_coefficient=p.get('skill_boldness_coefficient', 0.015),
    )
    m, s = run_simulation(cfg)
    print(f'{m[-1].mean_arch_convergence:.3f}')
except Exception as e:
    print('0.0')
" 2>/dev/null || echo "0.0")

        echo "[SM §4d] Current arch_convergence: $ARCH_CONV"

        # Arch-convergence alarm: > 0.7 = architectural monoculture
        # Open an autonomous learn trigger issue (design doc 23 §arch_convergence signal).
        # This is NOT a [NEEDS HUMAN] — COORD picks it up and runs /otherness.learn.
        ALARM=$(python3 -c "print('true' if float('$ARCH_CONV') > 0.7 else 'false')" 2>/dev/null || echo "false")
        if [ "$ALARM" = "true" ]; then
            echo "[SM §4d] ⚠ Architectural monoculture detected (arch_convergence=$ARCH_CONV > 0.7)"

            # Deduplication check — only open if no open learn(arch): issue already exists
            EXISTING=$(gh issue list --repo "$REPO" --state open \
              --search "learn(arch):" --json number --jq 'length' 2>/dev/null || echo "0")

            if [ "${EXISTING:-0}" -eq 0 ]; then
                LEARN_TITLE="learn(arch): arch_convergence at ${ARCH_CONV} — run /otherness.learn"
                gh issue create --repo "$REPO" \
                  --title "$LEARN_TITLE" \
                  --label "otherness,area/agent-loop,kind/chore,priority/high" \
                  --body "## Simulation calibration signal — arch_convergence

SM §4d calibration (sm_cycle=$SM_CYCLE) detected **arch_convergence = $ARCH_CONV** (threshold: 0.7).

This means agents are proposing items of the same structural type repeatedly — a sign
of architectural frame-lock rather than genuine exploration.

## Recovery action

Run \`/otherness.learn\` to inject novel patterns from an external open-source repo.
This is an autonomous trigger — COORD will pick this issue up on its next queue cycle.

**Reference**: \`docs/design/23-simulation-as-anchor.md §The arch_convergence signal\`" 2>/dev/null \
                  && echo "[SM §4d] Learn trigger issue opened (arch_convergence=$ARCH_CONV)." \
                  || echo "[SM §4d] Could not open learn trigger issue."

                # Also post observation to report issue (audit trail)
                gh issue comment $REPORT_ISSUE --repo $REPO \
                  --body "[🔄 SM §4d | $MY_SESSION_ID] arch_convergence=$ARCH_CONV > 0.7 detected. Learn trigger issue opened." 2>/dev/null || true
            else
                echo "[SM §4d] Learn trigger already open ($EXISTING issue) — skipping duplicate."
            fi
        fi
    else
        echo "[SM §4d] Calibration skipped (calibrate.py not available or failed)."
    fi
else
     echo "[SM §4d] Calibration skipped (sm_cycle=$SM_CYCLE, next at $((((SM_CYCLE / 10) + 1) * 10)))."
fi

# Phase 1c: Automatic /otherness.learn trigger (every 10 cycles, same cadence as calibration)
if [ $((SM_CYCLE % 10)) -eq 0 ] && [ "${SM_CYCLE:-0}" -gt 0 ]; then
  echo "[SM §4d-learn] Checking learn trigger..."

  # [AI-STEP]
  # Step 1: Read last 3 rows from docs/aide/metrics.md.
  #   Parse 'needs_human' column (col 4, 1-indexed from date). Keep last 3 rows.
  #
  # Step 2: Check if needs_human = 0 for all 3 batches.
  #   If any row has needs_human > 0: log "[SM §4d-learn] Skipping — escalations present." exit.
  #
  # Step 3: Compare real Type B rate (proxy: needs_human avg over last 10 batches)
  #   against simulated floor from scripts/sim-params.json (default 0.1 if missing).
  #   sim_floor = sim_params.get('expected_type_b_rate', 0.1)
  #   If real_rate >= sim_floor: log "[SM §4d-learn] Type B rate OK — no learn trigger."; exit.
  #
  # Step 4: If real_rate < sim_floor for 3 consecutive batches AND no escalations:
  #   LEARN_BRANCH="feat/learn-$(date +%Y%m%d)"
  #   Check if branch exists: git ls-remote --heads origin $LEARN_BRANCH
  #   If exists: log "[SM §4d-learn] Learn branch already exists — skipping."; exit.
  #
  #   Create branch and worktree:
  #   git push origin "HEAD:refs/heads/$LEARN_BRANCH"
  #   LEARN_WT="../${REPO_NAME}.learn-$(date +%Y%m%d)"
  #   git worktree add "$LEARN_WT" "$LEARN_BRANCH"
  #
  #   Post notice:
  #   gh issue comment $REPORT_ISSUE --repo $REPO \
  #     --body "[🔄 SM §4d-learn | $MY_SESSION_ID] Auto-learn triggered (Type B deficit: real=${real_rate:.2f} < floor=${sim_floor:.2f}). Starting /otherness.learn."
  #
  #   Read and follow ~/.otherness/agents/otherness.learn.md from $LEARN_WT.
  #   After learn PR open and CI green: merge and clean up (same pattern as coord.md learn scheduling).

  echo "[SM §4d-learn] Learn trigger check complete."
fi
```

---

## 4e. Calibration update + divergence detection

Every N SM cycles (default 5, configurable): re-calibrate simulation parameters against real metrics
and write `.otherness/sim-prediction.json` to `_state`. Every cycle: divergence check.

**Design ref**: `docs/design/23-simulation-as-anchor.md §Future → §Step 3`.

### 4e-i. Per-5-cycle calibration update

```bash
# Read calibration frequency (default: 5 cycles)
CALIB_CYCLES_4E=$(python3 -c "
import re
section = None
try:
    for line in open('otherness-config.yaml'):
        s = re.match(r'^(\w[\w_]*):', line)
        if s: section = s.group(1)
        if section == 'simulation':
            m = re.match(r'\s+calibration_cycles:\s*(\d+)', line)
            if m: print(m.group(1)); exit()
except: pass
print('5')
" 2>/dev/null || echo "5")

if [ $((SM_CYCLE % CALIB_CYCLES_4E)) -eq 0 ] && [ "${SM_CYCLE:-0}" -gt 0 ]; then
  echo "[SM §4e] Calibration cycle (sm_cycle=$SM_CYCLE, every ${CALIB_CYCLES_4E})..."
  if [ -f "scripts/calibrate.py" ] && [ -f "docs/aide/metrics.md" ]; then
    METRICS_ROWS=$(python3 -c "
import re
n=0
for line in open('docs/aide/metrics.md'):
    if re.match(r'^\|\s*20', line): n+=1
print(n)
" 2>/dev/null || echo "0")
    if [ "${METRICS_ROWS:-0}" -ge 5 ]; then
      if python3 scripts/calibrate.py --runs 2 2>/dev/null; then
        echo "[SM §4e] Calibration complete (${METRICS_ROWS} batches)."
        # Write sim-prediction.json to _state
        python3 - <<'PREDEOF'
import json, os, subprocess, tempfile, datetime, sys

sm_cycle = int(os.environ.get('SM_CYCLE', '0'))
try:
    import sys as _sys; _sys.path.insert(0, '.')
    from scripts.simulate import SimConfig, run_simulation
    params = json.load(open('scripts/sim-params.json'))
    cfg = SimConfig(
        n_agents=3, cycles=50,
        decay_rate=float(params.get('decay_rate', 0.9)),
        jump_multiplier=float(params.get('jump_multiplier', 1.3)),
        skill_boldness_coefficient=float(params.get('skill_boldness_coefficient', 0.018)),
        seed=42
    )
    results = run_simulation(cfg)
    prs_list = [r.get('prs_merged', 0) for r in results if isinstance(r, dict)]
    prs_floor = max(1, int(sorted(prs_list)[int(len(prs_list)*0.1)] if prs_list else 1))
    prs_ceiling = int(sorted(prs_list)[int(len(prs_list)*0.9)] + 1) if prs_list else 10
    arch_conv = float(results[-1].get('arch_convergence', 0.3)) if results else 0.3
    skill_rate = float(params.get('skills_growth_per_batch', 0.1))
    prediction = {
        'prs_next_batch_floor': prs_floor,
        'prs_next_batch_ceiling': prs_ceiling,
        'arch_convergence_score': round(arch_conv, 3),
        'skill_growth_rate': round(skill_rate, 4),
        'calibrated_params': {
            'decay_rate': params.get('decay_rate'),
            'skill_boldness_coefficient': params.get('skill_boldness_coefficient'),
            'jump_multiplier': params.get('jump_multiplier'),
        },
        'calibrated_at': datetime.datetime.now(datetime.timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ'),
        'source': '4e-calibration',
        'sm_cycle': sm_cycle,
    }
    # Write to _state branch
    state_wt = os.path.join(tempfile.gettempdir(), 'otherness-pred4e-' + str(os.getpid()))
    try:
        if os.path.exists(state_wt):
            subprocess.run(['git','worktree','remove',state_wt,'--force'], capture_output=True)
        subprocess.run(['git','worktree','add','--no-checkout',state_wt,'origin/_state'],
                       capture_output=True, check=True)
        target = os.path.join(state_wt, '.otherness', 'sim-prediction.json')
        os.makedirs(os.path.dirname(target), exist_ok=True)
        subprocess.run(['git','-C',state_wt,'checkout','_state','--','.otherness/sim-prediction.json'],
                       capture_output=True)
        json.dump(prediction, open(target, 'w'), indent=2)
        subprocess.run(['git','-C',state_wt,'add',target], capture_output=True)
        subprocess.run(['git','-C',state_wt,'commit',
                        '-m', f'4e-calibration: sim-prediction.json (sm_cycle={sm_cycle})'],
                       capture_output=True)
        r = subprocess.run(['git','-C',state_wt,'push','origin','HEAD:_state'],
                           capture_output=True)
        if r.returncode == 0:
            print(f"[SM §4e] sim-prediction.json written: floor={prs_floor}, ceiling={prs_ceiling}, arch_conv={arch_conv:.3f}")
        else:
            print("[SM §4e] sim-prediction.json push failed (non-fatal)")
    except Exception as e:
        print(f"[SM §4e] sim-prediction write error (non-fatal): {e}")
    finally:
        try:
            subprocess.run(['git','worktree','remove',state_wt,'--force'], capture_output=True)
        except: pass
    subprocess.run(['git','worktree','prune'], capture_output=True)
except Exception as e:
    print(f"[SM §4e] sim-prediction simulation error (non-fatal): {e}")
PREDEOF
      else
        echo "[SM §4e] calibrate.py failed — skipping sim-prediction update (non-fatal)."
      fi
    else
      echo "[SM §4e] Only ${METRICS_ROWS} metric rows — need ≥5 for calibration. Skipping."
    fi
  else
    # Fleet defaults fallback: when calibrate.py is absent (managed project), inherit
    # sim-defaults.json from the otherness fleet and write it as sim-prediction.json.
    # This satisfies the managed project adoption design:
    # "kardinal-promoter and kro-ui SM inherit otherness defaults, re-calibrate after ≥5 batches"
    # Design ref: docs/design/23-simulation-as-anchor.md §Per-project calibration and fleet defaults
    FLEET_DEFAULTS="$HOME/.otherness/scripts/sim-defaults.json"
    if [ -f "$FLEET_DEFAULTS" ]; then
      echo "[SM §4e] calibrate.py absent — inheriting fleet defaults from sim-defaults.json"
      python3 - <<'FLEETPREDEOF'
import json, os, subprocess, tempfile, datetime

sm_cycle = int(os.environ.get('SM_CYCLE', '0'))
fleet_path = os.path.expanduser('~/.otherness/scripts/sim-defaults.json')
try:
    defaults = json.load(open(fleet_path))
    prediction = {
        'prs_next_batch_floor': defaults.get('prs_next_batch_floor', 1),
        'prs_next_batch_ceiling': defaults.get('prs_next_batch_ceiling', 10),
        'arch_convergence_score': defaults.get('arch_convergence_score', 0.3),
        'skill_growth_rate': round(float(defaults.get('skills_growth_per_batch',
                                        defaults.get('skill_growth_rate', 0.1))), 4),
        'calibrated_params': {
            'decay_rate': defaults.get('decay_rate'),
            'skill_boldness_coefficient': defaults.get('skill_boldness_coefficient'),
            'jump_multiplier': defaults.get('jump_multiplier'),
        },
        'calibrated_at': datetime.datetime.now(datetime.timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ'),
        'source': 'fleet-defaults',
        'fleet_calibrated_at': defaults.get('fleet_calibrated_at'),
        'sm_cycle': sm_cycle,
    }
    state_wt = os.path.join(tempfile.gettempdir(), 'otherness-pred4e-fleet-' + str(os.getpid()))
    try:
        if os.path.exists(state_wt):
            subprocess.run(['git','worktree','remove',state_wt,'--force'], capture_output=True)
        subprocess.run(['git','worktree','add','--no-checkout',state_wt,'origin/_state'],
                       capture_output=True, check=True)
        target = os.path.join(state_wt, '.otherness', 'sim-prediction.json')
        os.makedirs(os.path.dirname(target), exist_ok=True)
        subprocess.run(['git','-C',state_wt,'checkout','_state','--','.otherness/sim-prediction.json'],
                       capture_output=True)
        json.dump(prediction, open(target, 'w'), indent=2)
        subprocess.run(['git','-C',state_wt,'add',target], capture_output=True)
        subprocess.run(['git','-C',state_wt,'commit',
                        '-m', f'4e-fleet-defaults: sim-prediction.json (sm_cycle={sm_cycle})'],
                       capture_output=True)
        r = subprocess.run(['git','-C',state_wt,'push','origin','HEAD:_state'],
                           capture_output=True)
        if r.returncode == 0:
            print(f"[SM §4e] fleet sim-prediction.json written (source=fleet-defaults, sm_cycle={sm_cycle})")
        else:
            print("[SM §4e] fleet sim-prediction.json push failed (non-fatal)")
    except Exception as e:
        print(f"[SM §4e] fleet sim-prediction write error (non-fatal): {e}")
    finally:
        try:
            subprocess.run(['git','worktree','remove',state_wt,'--force'], capture_output=True)
        except: pass
    subprocess.run(['git','worktree','prune'], capture_output=True)
except Exception as e:
    print(f"[SM §4e] fleet defaults fallback error (non-fatal): {e}")
FLEETPREDEOF
    else
      echo "[SM §4e] calibrate.py and fleet sim-defaults.json both absent — skipping (non-fatal)."
    fi
  fi
else
  echo "[SM §4e] Calibration skipped (sm_cycle=${SM_CYCLE:-0}, every ${CALIB_CYCLES_4E} cycles)."
fi
```

### 4e-ii. Divergence detection (every SM cycle)

Compare actual `todo_shipped` to the simulated prediction floor.
Post `[⚠️ Simulation divergence]` after 3 consecutive below-floor batches.
Divergence is informational — it does not block CI or open `[NEEDS HUMAN]` issues.

**Design ref**: `docs/design/23-simulation-as-anchor.md §Step 3`.

```bash
python3 - <<'DIVEOF'
import json, re, os, subprocess, datetime, tempfile, shutil

REPO = os.environ.get('REPO', '')
REPORT_ISSUE = os.environ.get('REPORT_ISSUE', '')
MY_SESSION_ID = os.environ.get('MY_SESSION_ID', 'SM')

# Step 1: Read predicted floor from scripts/sim-params.json
pred_floor = 1  # fallback: 1 item per batch is the minimum healthy floor
try:
    params = json.load(open('scripts/sim-params.json'))
    # Use observed_completion_rate × 0.5 as a conservative lower bound
    obs_rate = float(params.get('observed_completion_rate', 1.0))
    pred_floor = max(1, int(obs_rate * 0.5))
except Exception:
    pass  # Use fallback

# Step 2: Read last row of docs/aide/metrics.md for actual todo_shipped
actual_shipped = None
try:
    content = open('docs/aide/metrics.md').read()
    rows = []
    for line in content.splitlines():
        if '|' not in line: continue
        cells = [c.strip() for c in line.split('|')]
        if len(cells) < 8: continue
        if not cells[1].startswith('20'): continue
        try:
            shipped = int(cells[6]) if cells[6].isdigit() else -1
            if shipped >= 0:
                rows.append({'date': cells[1], 'batch': cells[2], 'todo_shipped': shipped})
        except: pass
    if rows:
        actual_shipped = rows[-1]['todo_shipped']
        batch_id = rows[-1]['batch']
except Exception as e:
    print(f'[SM §4e] Metrics read error (skipping): {e}')
    exit(0)

if actual_shipped is None:
    print('[SM §4e] No metrics rows found — skipping divergence check.')
    exit(0)

print(f'[SM §4e] Divergence check: actual_shipped={actual_shipped}, pred_floor={pred_floor}')

# Step 3: Read persistent consecutive count from _state
state_wt = os.path.join(tempfile.gettempdir(), 'otherness-div-' + str(os.getpid()))
div_path = None
consecutive_count = 0
try:
    if os.path.exists(state_wt):
        subprocess.run(['git','worktree','remove',state_wt,'--force'], capture_output=True)
    subprocess.run(['git','worktree','add','--no-checkout',state_wt,'origin/_state'],
                   capture_output=True, check=True)
    div_path = os.path.join(state_wt, '.otherness', 'divergence_count.json')
    os.makedirs(os.path.dirname(div_path), exist_ok=True)
    subprocess.run(['git','-C',state_wt,'checkout','_state','--','.otherness/divergence_count.json'],
                   capture_output=True)
    if os.path.exists(div_path):
        d = json.load(open(div_path))
        consecutive_count = int(d.get('count', 0))
except Exception as e:
    print(f'[SM §4e] divergence_count read error (non-fatal): {e}')

# Step 4: Increment or reset counter
if actual_shipped < pred_floor:
    consecutive_count += 1
    print(f'[SM §4e] Below floor ({actual_shipped} < {pred_floor}), consecutive={consecutive_count}')
else:
    if consecutive_count > 0:
        print(f'[SM §4e] At or above floor ({actual_shipped} >= {pred_floor}) — resetting consecutive count')
    consecutive_count = 0

# Step 5: Persist updated count to _state
try:
    if div_path:
        json.dump({'count': consecutive_count,
                   'updated_at': datetime.datetime.now(datetime.timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ'),
                   'last_pred_floor': pred_floor,
                   'last_actual': actual_shipped},
                  open(div_path, 'w'), indent=2)
        subprocess.run(['git','-C',state_wt,'add',div_path], capture_output=True)
        subprocess.run(['git','-C',state_wt,'commit','-m',f'sm: divergence_count={consecutive_count}'],
                       capture_output=True)
        subprocess.run(['git','-C',state_wt,'push','origin','HEAD:_state'], capture_output=True)
        print(f'[SM §4e] divergence_count={consecutive_count} persisted to _state')
except Exception as e:
    print(f'[SM §4e] divergence_count persist error (non-fatal): {e}')
finally:
    try:
        subprocess.run(['git','worktree','remove',state_wt,'--force'], capture_output=True)
    except: pass
subprocess.run(['git','worktree','prune'], capture_output=True)

# Step 6: Post divergence signal after 3 consecutive below-floor batches
if consecutive_count >= 3:
    signal_body = (
        f"[⚠️ Simulation divergence | SM §4e | {MY_SESSION_ID}] "
        f"Actual shipped: {actual_shipped}/batch. Predicted floor: {pred_floor}. "
        f"{consecutive_count} consecutive below-floor batches.\n\n"
        f"Possible causes:\n"
        f"- Queue stall (no unclaimed items)\n"
        f"- Skill growth halt (arch_convergence approaching 1.0)\n"
        f"- CI red blocking new work\n"
        f"- Needs-human backlog consuming capacity\n\n"
        f"The autonomous loop will self-correct. See "
        f"`docs/design/23-simulation-as-anchor.md §Step 4`."
    )
    r = subprocess.run(
        ['gh','issue','comment',REPORT_ISSUE,'--repo',REPO,'--body',signal_body],
        capture_output=True, text=True)
    if r.returncode == 0:
        print(f'[SM §4e] Divergence signal posted (consecutive={consecutive_count})')
    else:
        print(f'[SM §4e] Could not post divergence signal (non-fatal)')
DIVEOF
```

---

## 4g. Codebase hygiene scan (every 3 SM cycles)

Runs dead code / stale file / stale doc checks. Opens `kind/chore` issues for cleanup.
Nothing is deleted autonomously. Cap: `max_issues_per_scan` new issues per run (default 3).
**Runs on every managed project generically** — not otherness-specific.

**Design ref**: `docs/design/29-continuous-code-hygiene.md`

```bash
HYGIENE_INTERVAL=$(python3 -c "
import re
section = None
for line in open('otherness-config.yaml'):
    s = re.match(r'^(\w[\w_]*):', line)
    if s: section = s.group(1)
    if section == 'hygiene':
        m = re.match(r'\s+cycle_interval:\s*(\d+)', line)
        if m: print(m.group(1)); break
" 2>/dev/null || echo "3")

HYGIENE_ENABLED=$(python3 -c "
import re
section = None
for line in open('otherness-config.yaml'):
    s = re.match(r'^(\w[\w_]*):', line)
    if s: section = s.group(1)
    if section == 'hygiene':
        m = re.match(r'\s+enabled:\s*(true|false)', line)
        if m: print(m.group(1)); break
" 2>/dev/null || echo "true")

HYGIENE_MAX=$(python3 -c "
import re
section = None
for line in open('otherness-config.yaml'):
    s = re.match(r'^(\w[\w_]*):', line)
    if s: section = s.group(1)
    if section == 'hygiene':
        m = re.match(r'\s+max_issues_per_scan:\s*(\d+)', line)
        if m: print(m.group(1)); break
" 2>/dev/null || echo "3")

if [ "$HYGIENE_ENABLED" = "true" ] && [ $((${SM_CYCLE:-0} % ${HYGIENE_INTERVAL:-3})) -eq 0 ] && [ "${SM_CYCLE:-0}" -gt 0 ]; then
  echo "[SM §4g] Running codebase hygiene scan (max $HYGIENE_MAX issues)..."

  python3 - <<PYEOF
import re, os, subprocess, json, datetime

REPO = os.environ.get('REPO', '')
MAX_ISSUES = int(os.environ.get('HYGIENE_MAX', '3'))
opened = 0

def issue_exists(title_frag):
    r = subprocess.run(['gh','issue','list','--repo',REPO,'--state','all',
        '--search',title_frag[:60],'--json','number'],
        capture_output=True, text=True, timeout=10)
    try: return len(json.loads(r.stdout)) > 0
    except: return True  # safe default

def open_issue(title, body):
    global opened
    if opened >= MAX_ISSUES: return
    if issue_exists(title[:50]): return
    subprocess.run(['gh','issue','create','--repo',REPO,
        '--title', title,
        '--label', 'kind/chore,priority/low,size/xs',
        '--body', body],
        capture_output=True, timeout=15)
    opened += 1
    print(f'[SM §4g] Opened issue: {title[:70]}')

# ── Check 1: Stale Present items in design docs ──────────────────────────
if os.path.isdir('docs/design'):
    for fname in sorted(os.listdir('docs/design')):
        if not fname.endswith('.md'): continue
        if opened >= MAX_ISSUES: break
        try:
            content = open(f'docs/design/{fname}').read()
            present_match = re.search(r'^## Present.*?\n(.*?)(?=^## |\Z)', content, re.MULTILINE | re.DOTALL)
            if not present_match: continue
            items = re.findall(r'^- ✅ .+', present_match.group(1), re.MULTILINE)
            for item in items:
                if opened >= MAX_ISSUES: break
                file_refs = re.findall(r'\`([a-zA-Z0-9_./-]+\.[a-zA-Z]{1,6})\`', item)
                for fref in file_refs:
                    # Check existence using the original path (handles dotfile paths like .opencode/, .specify/)
                    # and glob fallbacks for bare filenames in subdirectories or dotdirs (e.g. validate.sh → scripts/,
                    # otherness-scheduled.yml → .github/workflows/)
                    import glob as _glob
                    _fref_exists = (
                        os.path.exists(fref) or
                        os.path.exists(f'./{fref}') or
                        bool(_glob.glob(f'**/{fref}', recursive=True)) or
                        bool(_glob.glob(f'.github/**/{fref}', recursive=True)) or
                        bool(_glob.glob(f'.opencode/**/{fref}', recursive=True))
                    )
                    if not _fref_exists:
                        title = f'hygiene: stale Present item in {fname} — {fref} not found'
                        open_issue(title,
                            f'SM §4g hygiene scan: `{fname}` has a ✅ Present item referencing `{fref}` which no longer exists.\n\n'
                            f'Item: `{item[:120]}`\n\nAction: update the design doc to reflect current state.')
                        break
        except: pass

# ── Check 2: Orphaned TODO/FIXME/HACK comments (>14 days) ───────────────
try:
    result = subprocess.run(
        ['git', 'grep', '-rn', '--no-color',
         '-e', 'TODO:', '-e', 'FIXME:', '-e', 'HACK:',
         '--', '*.py', '*.go', '*.ts', '*.tsx', '*.js', '*.sh'],
        capture_output=True, text=True, timeout=20)
    todos = []
    for line in result.stdout.splitlines():
        m = re.match(r'^([^:]+):(\d+):.*(TODO|FIXME|HACK)[:\s]+(.+)$', line)
        if m:
            fpath, lineno, kind, msg = m.groups()
            msg_clean = msg.strip()[:80]
            if len(msg_clean) > 15:
                todos.append((fpath, lineno, kind, msg_clean))
    if todos and opened < MAX_ISSUES:
        # Check age of file via git log
        for fpath, lineno, kind, msg in todos[:5]:
            if opened >= MAX_ISSUES: break
            age_r = subprocess.run(['git','log','--follow','--format=%ci','--',''+fpath],
                                   capture_output=True, text=True, timeout=10)
            dates = re.findall(r'(\d{4}-\d{2}-\d{2})', age_r.stdout)
            age_days = 0
            if dates:
                try:
                    oldest = datetime.datetime.fromisoformat(dates[-1])
                    age_days = (datetime.datetime.utcnow() - oldest).days
                except: pass
            if age_days >= 14:
                title = f'hygiene: unresolved {kind} in {os.path.basename(fpath)}:{lineno}'
                open_issue(title,
                    f'SM §4g hygiene: `{fpath}:{lineno}` has an unresolved {kind} comment ({age_days} days old).\n\n'
                    f'Comment: `{msg[:100]}`\n\nAction: resolve, convert to an issue, or remove if stale.')
except: pass

# ── Check 3: Committed build artifacts ───────────────────────────────────
ARTIFACT_PATTERNS = [
    ('__pycache__/', 'Python bytecode cache'),
    ('dist/', 'build output'),
    ('.next/', 'Next.js build'),
    ('node_modules/', 'node_modules'),
    ('.pyc', 'compiled Python'),
]
if opened < MAX_ISSUES:
    try:
        tracked = subprocess.check_output(['git','ls-files'], text=True, timeout=15)
        for pattern, desc in ARTIFACT_PATTERNS:
            if opened >= MAX_ISSUES: break
            matches = [f for f in tracked.splitlines() if pattern in f]
            if matches:
                title = f'hygiene: build artifact committed — {pattern} should be in .gitignore'
                open_issue(title,
                    f'SM §4g hygiene: found committed build artifact matching `{pattern}` ({desc}).\n\n'
                    f'Examples: {", ".join(matches[:3])}\n\nAction: add to .gitignore and remove from tracking.')
    except: pass

# ── Check 4: Design docs with no Present items (Future-only docs) ────────
if os.path.isdir('docs/design') and opened < MAX_ISSUES:
    for fname in sorted(os.listdir('docs/design')):
        if not fname.endswith('.md') or fname.startswith('00-'): continue
        if opened >= MAX_ISSUES: break
        try:
            content = open(f'docs/design/{fname}').read()
            present_items = re.findall(r'^- ✅', content, re.MULTILINE)
            future_items = re.findall(r'^- 🔲', content, re.MULTILINE)
            # Check age
            age_r = subprocess.run(['git','log','--follow','--format=%ci','--',f'docs/design/{fname}'],
                                   capture_output=True, text=True, timeout=10)
            dates = re.findall(r'(\d{4}-\d{2}-\d{2})', age_r.stdout)
            age_days = 0
            if dates:
                try:
                    oldest = datetime.datetime.fromisoformat(dates[-1])
                    age_days = (datetime.datetime.utcnow() - oldest).days
                except: pass
            # Flag: >30 days old design doc with Future items but no Present items
            if len(present_items) == 0 and len(future_items) > 0 and age_days > 30:
                title = f'hygiene: design doc {fname} has no Present items after {age_days}d'
                open_issue(title,
                    f'SM §4g hygiene: `docs/design/{fname}` has {len(future_items)} Future item(s) '
                    f'but 0 Present items after {age_days} days.\n\n'
                    f'Either these items have been shipped (design doc needs updating) '
                    f'or they have stalled (needs re-evaluation).')
        except: pass

print(f'[SM §4g] Hygiene scan complete. {opened} new issue(s) opened.')
PYEOF

  echo "[SM §4g] Codebase hygiene scan complete."
fi
```

---

## 4g-anchor. Feature→anchor gap detection (every 10 SM cycles)

Check how many ✅ Present features have anchor coverage. Post coverage ratio.
Open anchor-growth issues for uncovered features. Skip gracefully if no §Anchor section.

**Design ref**: `docs/design/24-project-anchor-framework.md §The feature → anchor gap`.

```bash
if [ $((SM_CYCLE % 10)) -eq 0 ] && [ "${SM_CYCLE:-0}" -gt 0 ]; then
  echo "[SM §4g-anchor] Running feature→anchor gap detection..."

  python3 - <<'ANCHOREOF'
import re, os, subprocess

REPO = os.environ.get('REPO', '')
REPORT_ISSUE = os.environ.get('REPORT_ISSUE', '')
MY_SESSION_ID = os.environ.get('MY_SESSION_ID', 'SM')
PR_LABEL = os.environ.get('PR_LABEL', 'otherness')

# Step 1: Check for AGENTS.md §Anchor section
try:
    agents_content = open('AGENTS.md').read()
    anchor_m = re.search(r'^## Anchor\s*\n(.*?)(?=^## |\Z)', agents_content,
                         re.MULTILINE | re.DOTALL)
    if not anchor_m:
        print('[SM §4g-anchor] No ## Anchor section in AGENTS.md — skipping.')
        exit(0)
    anchor_section = anchor_m.group(1)
    print('[SM §4g-anchor] Found ## Anchor section in AGENTS.md')
except Exception as e:
    print(f'[SM §4g-anchor] AGENTS.md read error (skipping): {e}')
    exit(0)

# Step 2: Collect ✅ Present features from docs/design/*.md
features = []
design_dir = 'docs/design'
if os.path.isdir(design_dir):
    for fname in sorted(os.listdir(design_dir)):
        if not fname.endswith('.md'): continue
        try:
            content = open(f'{design_dir}/{fname}').read()
            m = re.search(r'^## Present.*?\n(.*?)(?=^## |\Z)', content,
                          re.MULTILINE | re.DOTALL)
            if m:
                items = re.findall(r'^- ✅ (.+)', m.group(1), re.MULTILINE)
                for item in items:
                    # Extract short name (before '—' or '(PR')
                    name = re.sub(r'\s*[—(].+$', '', item).strip()[:60]
                    features.append({'full': item, 'name': name, 'source': fname})
        except Exception:
            pass

total_features = len(features)
if total_features == 0:
    print('[SM §4g-anchor] No ✅ Present features found — skipping.')
    exit(0)

# Step 3: Count anchor-covered features (fuzzy match against §Anchor section)
covered_names = re.findall(r'^[-*]\s*(?:✅|\[x\])\s*(.+)', anchor_section,
                           re.MULTILINE | re.IGNORECASE)
covered_names_lower = [n.lower()[:50] for n in covered_names]

def is_covered(feature_name):
    fn = feature_name.lower()[:30]
    return any(fn in cn or cn[:30] in fn for cn in covered_names_lower)

covered = [f for f in features if is_covered(f['name'])]
uncovered = [f for f in features if not is_covered(f['name'])]
coverage_pct = int(len(covered) / total_features * 100) if total_features else 100

# Step 4: Post coverage ratio to REPORT_ISSUE
ratio_body = (
    f"[ANCHOR | SM §4g-anchor | {MY_SESSION_ID}] "
    f"Feature→anchor coverage: {len(covered)}/{total_features} ({coverage_pct}%)"
)
subprocess.run(['gh','issue','comment',REPORT_ISSUE,'--repo',REPO,'--body',ratio_body],
               capture_output=True)
print(f'[SM §4g-anchor] Coverage: {len(covered)}/{total_features} ({coverage_pct}%)')

# Step 5: Open anchor-growth issues for uncovered features (deduplicated)
issues_opened = 0
for feat in uncovered[:5]:  # cap at 5 per cycle to avoid flooding
    title = f"anchor: cover '{feat['name'][:50]}'"
    # Deduplication check
    existing = subprocess.run(
        ['gh','issue','list','--repo',REPO,'--state','open',
         '--search',feat['name'][:30],'--json','number','--jq','length'],
        capture_output=True, text=True)
    if int(existing.stdout.strip() or '0') > 0:
        continue
    body = (f"## Anchor coverage gap\n\n"
            f"Feature: {feat['full'][:200]}\n"
            f"Source: `docs/design/{feat['source']}`\n\n"
            f"This ✅ Present feature has no entry in AGENTS.md §Anchor coverage matrix.\n\n"
            f"**Action**: Add a scenario or validation step to the anchor that exercises\n"
            f"this feature. See `docs/design/24-project-anchor-framework.md`.")
    r = subprocess.run(
        ['gh','issue','create','--repo',REPO,'--title',title,
         '--label',f'{PR_LABEL},kind/chore,area/tooling,priority/medium','--body',body],
        capture_output=True, text=True)
    if r.returncode == 0:
        issues_opened += 1
        print(f'[SM §4g-anchor] Opened: {title[:60]}')

print(f'[SM §4g-anchor] Gap detection complete: {issues_opened} issues opened, '
      f'{len(uncovered)} uncovered features.')
ANCHOREOF

  echo "[SM §4g-anchor] Feature→anchor gap detection complete."
fi
```

---

## 4g-anchor-parity. Spec→journey parity check (every 10 SM cycles)

For projects with a journey test suite: read the spec inventory from AGENTS.md
§Anchor (Merged rows), diff against existing journey file names, open anchor-growth
issues for specs with no journey. Skip gracefully if not configured.

**Design ref**: `docs/design/26-anchor-kro-ui.md §Feature→journey parity`.

```bash
JOURNEYS_DIR=$(python3 -c "
import re
section = None
for line in open('otherness-config.yaml'):
    s = re.match(r'^(\w[\w_]*):', line)
    if s: section = s.group(1)
    if section == 'anchor':
        m = re.match(r'\s+journeys_dir:\s*(\S+)', line)
        if m: print(m.group(1)); break
" 2>/dev/null || echo "")

if [ -n "$JOURNEYS_DIR" ] && [ $((SM_CYCLE % 10)) -eq 0 ] && [ "${SM_CYCLE:-0}" -gt 0 ]; then
  echo "[SM §4g-anchor-parity] Running spec→journey parity check..."

  python3 - <<'PARITYEOF'
import re, os, subprocess, json

REPO = os.environ.get('REPO', '')
REPORT_ISSUE = os.environ.get('REPORT_ISSUE', '')
MY_SESSION_ID = os.environ.get('MY_SESSION_ID', 'SM')
PR_LABEL = os.environ.get('PR_LABEL', 'otherness')
JOURNEYS_DIR = os.environ.get('JOURNEYS_DIR', '')

# Step 1: Check for AGENTS.md §Anchor section with spec inventory
try:
    agents_content = open('AGENTS.md').read()
    anchor_m = re.search(r'^## Anchor\s*\n(.*?)(?=^## |\Z)', agents_content,
                         re.MULTILINE | re.DOTALL)
    if not anchor_m:
        print('[SM §4g-anchor-parity] No ## Anchor section in AGENTS.md — skipping.')
        exit(0)
    anchor_section = anchor_m.group(1)
except Exception as e:
    print(f'[SM §4g-anchor-parity] AGENTS.md read error (skipping): {e}')
    exit(0)

# Step 2: Extract merged spec names from §Anchor section
# Looks for lines with ✅ or [x] entries in a coverage matrix or spec list
spec_names = re.findall(r'^[-*|]\s*(?:✅|\[x\])\s*([^\|]+)', anchor_section,
                        re.MULTILINE | re.IGNORECASE)
spec_names = [s.strip()[:60] for s in spec_names if len(s.strip()) > 3]

if not spec_names:
    print('[SM §4g-anchor-parity] No ✅ spec entries in §Anchor — skipping.')
    exit(0)

# Step 3: Read journey file names from JOURNEYS_DIR
journey_files = []
if os.path.isdir(JOURNEYS_DIR):
    for fname in os.listdir(JOURNEYS_DIR):
        if fname.endswith(('.ts', '.js', '.spec.ts', '.spec.js', '.py', '.md')):
            journey_files.append(fname.lower())
else:
    print(f'[SM §4g-anchor-parity] Journeys dir {JOURNEYS_DIR} not found — skipping.')
    exit(0)

# Step 4: Fuzzy match: for each spec, check if a journey file covers it
def is_journeyed(spec_name):
    fn = re.sub(r'[^a-z0-9]', '', spec_name.lower())[:20]
    return any(fn in jf or jf[:20] in fn for jf in journey_files if len(fn) > 3)

covered = [s for s in spec_names if is_journeyed(s)]
uncovered = [s for s in spec_names if not is_journeyed(s)]
parity_pct = int(len(covered) / len(spec_names) * 100) if spec_names else 100

# Step 5: Post parity ratio
ratio_body = (
    f"[SM §4g-anchor-parity | {MY_SESSION_ID}] "
    f"Spec→journey parity: {len(covered)}/{len(spec_names)} ({parity_pct}%)"
)
subprocess.run(['gh','issue','comment',REPORT_ISSUE,'--repo',REPO,'--body',ratio_body],
               capture_output=True)
print(f'[SM §4g-anchor-parity] {ratio_body}')

# Step 6: Open anchor-growth issues for uncovered specs (cap at 3)
issues_opened = 0
for spec in uncovered[:3]:
    title = f"anchor: add journey for '{spec[:50]}'"
    existing = subprocess.run(
        ['gh','issue','list','--repo',REPO,'--state','open',
         '--search',spec[:30],'--json','number','--jq','length'],
        capture_output=True, text=True)
    if int(existing.stdout.strip() or '0') > 0:
        continue
    body = (f"## Spec→journey parity gap\n\n"
            f"Spec: {spec}\n\n"
            f"This merged spec has no corresponding journey file in `{JOURNEYS_DIR}`.\n\n"
            f"**Action**: Add a journey file that exercises this spec's features end-to-end.\n"
            f"See `docs/design/26-anchor-kro-ui.md §Feature→journey parity`.")
    r = subprocess.run(
        ['gh','issue','create','--repo',REPO,'--title',title,
         '--label',f'{PR_LABEL},kind/chore,area/tooling,priority/low','--body',body],
        capture_output=True, text=True)
    if r.returncode == 0:
        issues_opened += 1
        print(f'[SM §4g-anchor-parity] Opened: {title[:60]}')

print(f'[SM §4g-anchor-parity] Parity check done: {issues_opened} issues opened, '
      f'{len(uncovered)} uncovered specs.')
PARITYEOF

  echo "[SM §4g-anchor-parity] Spec→journey parity check complete."
fi
```

---

## 4g-anchor-design-gap. Feature→design-doc scenario gap (every SM cycle)

Read ✅ Present items from all `docs/design/*.md` files. Diff against the `## Present`
section of anchor design docs (files whose names contain `anchor`). Open `anchor: cover`
issues for features that appear in no anchor doc. Skip gracefully if no design docs exist.

**Design ref**: `docs/design/25-anchor-kardinal-promoter.md §Future`
(Feature→scenario gap detection: SM §4g-anchor reads ✅ Present items, diffs against coverage matrix)

```bash
echo "[SM §4g-anchor-design-gap] Running feature→design-doc scenario gap check..."

python3 - <<'DESIGNGAPEOF'
import re, os, subprocess, json

REPO = os.environ.get('REPO', '')
MY_SESSION_ID = os.environ.get('MY_SESSION_ID', 'SM')
PR_LABEL = os.environ.get('PR_LABEL', 'otherness')

design_dir = 'docs/design'
if not os.path.isdir(design_dir):
    print('[SM §4g-anchor-design-gap] No docs/design/ — skipping.')
    exit(0)

# Step 1: Collect ✅ Present feature names from all design docs
features = []
for fname in sorted(os.listdir(design_dir)):
    if not fname.endswith('.md'):
        continue
    try:
        content = open(f'{design_dir}/{fname}').read()
        present_m = re.search(r'^## Present.*?\n(.*?)(?=^## |\Z)', content,
                               re.MULTILINE | re.DOTALL)
        if not present_m:
            continue
        items = re.findall(r'^- ✅ (.+)', present_m.group(1), re.MULTILINE)
        for item in items:
            # Short name: strip parenthetical provenance, keep first 60 chars
            name = re.sub(r'\s*[—(].+$', '', item).strip()[:60]
            if name:
                features.append({'name': name, 'full': item, 'source': fname})
    except Exception:
        pass

if not features:
    print('[SM §4g-anchor-design-gap] No ✅ Present features found — skipping.')
    exit(0)

print(f'[SM §4g-anchor-design-gap] Found {len(features)} ✅ Present features across design docs.')

# Step 2: Read coverage matrix from anchor design docs (names containing "anchor")
anchor_coverage_text = ''
for fname in sorted(os.listdir(design_dir)):
    if 'anchor' not in fname.lower() or not fname.endswith('.md'):
        continue
    try:
        content = open(f'{design_dir}/{fname}').read()
        # Collect Present section + scenario tables
        present_m = re.search(r'^## Present.*?\n(.*?)(?=^## |\Z)', content,
                               re.MULTILINE | re.DOTALL)
        if present_m:
            anchor_coverage_text += present_m.group(1).lower() + '\n'
        # Also collect scenario table rows
        for row in re.findall(r'\|[^\n]+\|', content):
            anchor_coverage_text += row.lower() + '\n'
    except Exception:
        pass

if not anchor_coverage_text:
    print('[SM §4g-anchor-design-gap] No anchor design docs found — skipping.')
    exit(0)

# Step 3: Identify uncovered features (not mentioned in anchor coverage text)
def is_covered(feature_name):
    fn = feature_name.lower()[:40]
    # Check if first 40 chars of feature name appear anywhere in anchor coverage
    return fn in anchor_coverage_text

covered = [f for f in features if is_covered(f['name'])]
uncovered = [f for f in features if not is_covered(f['name'])]
coverage_pct = int(len(covered) / len(features) * 100) if features else 100

print(f'[SM §4g-anchor-design-gap] Coverage: {len(covered)}/{len(features)} ({coverage_pct}%)')
print(f'[SM §4g-anchor-design-gap] {len(uncovered)} uncovered features.')

# Step 4: Open anchor-growth issues for uncovered features (cap 5, deduplicated)
issues_opened = 0
for feat in uncovered[:5]:
    title = f"anchor: cover '{feat['name'][:50]}'"
    # Deduplication: skip if open issue with same title prefix exists
    existing = subprocess.run(
        ['gh', 'issue', 'list', '--repo', REPO, '--state', 'open',
         '--search', feat['name'][:30], '--json', 'number', '--jq', 'length'],
        capture_output=True, text=True, timeout=15)
    try:
        if int(existing.stdout.strip() or '0') > 0:
            continue
    except Exception:
        continue
    body = (
        f"## Anchor coverage gap\n\n"
        f"Feature: `{feat['full'][:200]}`\n"
        f"Source: `docs/design/{feat['source']}`\n\n"
        f"This ✅ Present feature is not mentioned in any anchor design doc's coverage matrix.\n\n"
        f"**Action**: Add a PDCA scenario or validation step to the anchor that exercises "
        f"this feature. See `docs/design/24-project-anchor-framework.md`.\n\n"
        f"Generated by SM §4g-anchor-design-gap."
    )
    r = subprocess.run(
        ['gh', 'issue', 'create', '--repo', REPO,
         '--title', title,
         '--label', f'{PR_LABEL},kind/chore,area/tooling,priority/medium',
         '--body', body],
        capture_output=True, text=True, timeout=15)
    if r.returncode == 0:
        issues_opened += 1
        print(f'[SM §4g-anchor-design-gap] Opened: {title[:60]}')

print(f'[SM §4g-anchor-design-gap] Done: {issues_opened} issues opened.')
DESIGNGAPEOF

echo "[SM §4g-anchor-design-gap] Feature→design-doc scenario gap check complete."
```

---

## 4g-anchor-upstream. Upstream version tracking — open anchor-growth issue on version bump (every SM cycle)

When a managed project's upstream dependency version bumps, SM opens an anchor-growth
issue to ensure the new API surface gets coverage. Configurable via `otherness-config.yaml`
`anchor.upstream_version_file` and `anchor.upstream_version_pattern`. Skips gracefully if
not configured.

**Design ref**: `docs/design/26-anchor-kro-ui.md §Future`
(kro upstream tracking: when kro version bumps, SM opens anchor-growth issue for new API surface)

```bash
UPSTREAM_VERSION_FILE=$(python3 -c "
import re
section = None
for line in open('otherness-config.yaml'):
    s = re.match(r'^(\w[\w_]*):', line)
    if s: section = s.group(1)
    if section == 'anchor':
        m = re.match(r'\s+upstream_version_file:\s*(\S+)', line)
        if m: print(m.group(1).strip()); break
" 2>/dev/null || echo "")

UPSTREAM_VERSION_PATTERN=$(python3 -c "
import re
section = None
for line in open('otherness-config.yaml'):
    s = re.match(r'^(\w[\w_]*):', line)
    if s: section = s.group(1)
    if section == 'anchor':
        m = re.match(r'\s+upstream_version_pattern:\s*[\"\'']?([^\"\'#\n]+)[\"\'']?', line)
        if m: print(m.group(1).strip()); break
" 2>/dev/null || echo "")

if [ -n "$UPSTREAM_VERSION_FILE" ] && [ -n "$UPSTREAM_VERSION_PATTERN" ] && [ -f "$UPSTREAM_VERSION_FILE" ]; then
  echo "[SM §4g-anchor-upstream] Checking upstream version in $UPSTREAM_VERSION_FILE..."

  python3 - <<'UPSTREAMEOF'
import re, os, subprocess, json, tempfile, time

REPO = os.environ.get('REPO', '')
PR_LABEL = os.environ.get('PR_LABEL', 'otherness')
MY_SESSION_ID = os.environ.get('MY_SESSION_ID', 'SM')
version_file = os.environ.get('UPSTREAM_VERSION_FILE', '')
version_pattern = os.environ.get('UPSTREAM_VERSION_PATTERN', '')

# Step 1: Extract current upstream version from file
current_version = None
try:
    content = open(version_file).read()
    # Search for pattern: the line containing the pattern, extract the version string
    # Expected patterns: "github.com/foo/bar v1.2.3", "kro v0.9.1", etc.
    m = re.search(r'(' + re.escape(version_pattern) + r')\s+v?([\d]+\.[\d]+\.?[\d]*)', content)
    if not m:
        # Fallback: search for version in the same line as pattern
        for line in content.splitlines():
            if version_pattern in line:
                vm = re.search(r'v?([\d]+\.[\d]+\.?[\d]*)', line)
                if vm:
                    current_version = vm.group(1)
                    break
    else:
        current_version = m.group(2)
except Exception as e:
    print(f'[SM §4g-anchor-upstream] Error reading version file (skipping): {e}')
    exit(0)

if not current_version:
    print(f'[SM §4g-anchor-upstream] No version found matching "{version_pattern}" in {version_file} — skipping.')
    exit(0)

print(f'[SM §4g-anchor-upstream] Current upstream version: {current_version}')

# Step 2: Read last-known version from state.json
try:
    with open('.otherness/state.json') as f: state = json.load(f)
except Exception:
    state = {}

last_version = state.get('anchor_upstream_version', {}).get(version_pattern)
print(f'[SM §4g-anchor-upstream] Last known version: {last_version or "none"}')

# Step 3: Persist current version to state (always update)
state.setdefault('anchor_upstream_version', {})[version_pattern] = current_version
try:
    with open('.otherness/state.json', 'w') as f: json.dump(state, f, indent=2)
except Exception as e:
    print(f'[SM §4g-anchor-upstream] State write error (non-fatal): {e}')

# Step 4: If version unchanged or no previous: skip
if not last_version or last_version == current_version:
    if not last_version:
        print(f'[SM §4g-anchor-upstream] First run — recording version {current_version}.')
    else:
        print(f'[SM §4g-anchor-upstream] Version unchanged ({current_version}) — no action.')
    exit(0)

# Step 5: Version bumped — open anchor-growth issue (deduplicated)
title = f'anchor-growth: {version_pattern} bumped from {last_version} to {current_version}'
# Deduplication: skip if open issue with same title prefix exists
existing = subprocess.run(
    ['gh', 'issue', 'list', '--repo', REPO, '--state', 'open',
     '--search', title[:50], '--json', 'number', '--jq', 'length'],
    capture_output=True, text=True, timeout=15)
try:
    if int(existing.stdout.strip() or '0') > 0:
        print(f'[SM §4g-anchor-upstream] Anchor-growth issue already open — skipping duplicate.')
        exit(0)
except Exception:
    pass

body = (
    f"## Upstream version bump detected\n\n"
    f"SM §4g-anchor-upstream detected a version bump:\n\n"
    f"- **Dependency**: `{version_pattern}`\n"
    f"- **Previous version**: `{last_version}`\n"
    f"- **New version**: `{current_version}`\n\n"
    f"## Action required\n\n"
    f"Review the changelog for `{version_pattern}` between `{last_version}` and `{current_version}` "
    f"and identify new API surface that should be covered by this project's anchor suite.\n\n"
    f"For each new API feature:\n"
    f"1. Add a spec entry in the appropriate design doc\n"
    f"2. Create or update an E2E journey to exercise the new surface\n\n"
    f"**Reference**: `docs/design/` — anchor design doc for this project"
)

r = subprocess.run(
    ['gh', 'issue', 'create', '--repo', REPO,
     '--title', title,
     '--label', f'{PR_LABEL},kind/chore,area/tooling,priority/medium',
     '--body', body],
    capture_output=True, text=True, timeout=15)

if r.returncode == 0:
    print(f'[SM §4g-anchor-upstream] Opened anchor-growth issue: {r.stdout.strip()}')
else:
    print(f'[SM §4g-anchor-upstream] Failed to open issue (non-fatal): {r.stderr.strip()[:100]}')
UPSTREAMEOF

  echo "[SM §4g-anchor-upstream] Upstream version check complete."
else
  echo "[SM §4g-anchor-upstream] anchor.upstream_version_file/pattern not configured — skipping."
fi
```

---

## 4g-anchor-score. Anchor workflow score reading (every SM cycle)

Read the latest `[ANCHOR | * | *]` comment from the project's report issue.
Track coverage trend for stagnation detection. Skip gracefully if no anchor configured.

**Design ref**: `docs/design/25-anchor-kardinal-promoter.md §The anchor score comment format`.

```bash
ANCHOR_WORKFLOW=$(python3 -c "
import re
section = None
for line in open('otherness-config.yaml'):
    s = re.match(r'^(\w[\w_]*):', line)
    if s: section = s.group(1)
    if section == 'anchor':
        m = re.match(r'\s+workflow:\s*(\S+)', line)
        if m: print(m.group(1)); break
" 2>/dev/null || echo "")

if [ -n "$ANCHOR_WORKFLOW" ]; then
  echo "[SM §4g-anchor-score] Reading anchor scores from report issue..."

  python3 - <<'SCOREEOF'
import re, os, subprocess, json, datetime

REPO = os.environ.get('REPO', '')
REPORT_ISSUE = os.environ.get('REPORT_ISSUE', '')
MY_SESSION_ID = os.environ.get('MY_SESSION_ID', 'SM')

# Read score_pattern and stagnation_sessions from otherness-config.yaml
score_pattern = None
stagnation_sessions = 3
try:
    section = None
    for line in open('otherness-config.yaml'):
        s = re.match(r'^(\w[\w_]*):', line)
        if s: section = s.group(1)
        if section == 'anchor':
            m = re.match(r'\s+score_pattern:\s*["\']?([^"\'#\n]+)["\']?', line)
            if m: score_pattern = m.group(1).strip()
            m2 = re.match(r'\s+stagnation_sessions:\s*(\d+)', line)
            if m2: stagnation_sessions = int(m2.group(1))
except Exception:
    pass

# Fetch last 20 comments from report issue to find ANCHOR score comments
try:
    r = subprocess.run(
        ['gh', 'issue', 'view', REPORT_ISSUE, '--repo', REPO,
         '--json', 'comments', '--jq', '[.comments[-20:][].body]'],
        capture_output=True, text=True, timeout=30)
    comments = json.loads(r.stdout) if r.returncode == 0 else []
except Exception:
    comments = []

# Parse anchor score comments: [ANCHOR | <project> | DATE] coverage: N/M (X%) | ...
anchor_comments = []
for body in comments:
    m = re.search(
        r'\[ANCHOR\s*\|[^\|]+\|\s*(\d{4}-\d{2}-\d{2})\]\s*coverage:\s*(\d+)/(\d+)\s*\((\d+)%\)',
        body)
    if m:
        entry = {
            'date': m.group(1),
            'pass_count': int(m.group(2)),
            'total': int(m.group(3)),
            'coverage_pct': int(m.group(4)),
            'pass': None,
            'fail': None,
        }
        # Also extract PASS=A FAIL=B if score_pattern is set
        if score_pattern:
            try:
                sm = re.search(score_pattern, body)
                if sm and len(sm.groups()) >= 2:
                    entry['pass'] = int(sm.group(1))
                    entry['fail'] = int(sm.group(2))
            except Exception:
                pass
        anchor_comments.append(entry)

if not anchor_comments:
    print('[SM §4g-anchor-score] No anchor score comments found in report issue — skipping.')
    exit(0)

latest = anchor_comments[-1]

# Load state for stagnation tracking
try:
    with open('.otherness/state.json') as f: state = json.load(f)
except Exception:
    state = {}

anchor_scores = state.setdefault('anchor_scores', {}).setdefault(REPO, [])

# Append latest score (deduplicate by date)
if not anchor_scores or anchor_scores[-1].get('date') != latest['date']:
    anchor_scores.append(latest)
    # Keep only last 5 scores
    state['anchor_scores'][REPO] = anchor_scores[-5:]
    with open('.otherness/state.json', 'w') as f: json.dump(state, f, indent=2)

# Stagnation check: last N scores all have same or lower coverage_pct
scores_window = state['anchor_scores'][REPO]
stagnating = False
if len(scores_window) >= stagnation_sessions:
    window = scores_window[-stagnation_sessions:]
    if all(w.get('coverage_pct', 0) <= window[0].get('coverage_pct', 0)
           for w in window[1:]):
        stagnating = True

stagnation_count = 0
if len(scores_window) >= 2:
    for sc in reversed(scores_window):
        if sc.get('coverage_pct', 0) <= scores_window[-1].get('coverage_pct', 0):
            stagnation_count += 1
        else:
            break

# Build summary comment
pass_str = f"PASS={latest['pass']} FAIL={latest['fail']}" if latest['pass'] is not None else ""
score_summary = (
    f"[SM §4g-anchor-score | {MY_SESSION_ID}] "
    f"Latest anchor: coverage {latest['pass_count']}/{latest['total']} "
    f"({latest['coverage_pct']}%)"
    + (f" | {pass_str}" if pass_str else "")
    + f" | stagnation={stagnation_count}/{stagnation_sessions}"
)
subprocess.run(['gh', 'issue', 'comment', REPORT_ISSUE, '--repo', REPO,
                '--body', score_summary], capture_output=True)
print(f'[SM §4g-anchor-score] {score_summary}')

# Stagnation warning
if stagnating:
    warn = (
        f"[ANCHOR | stagnation] coverage has not improved in {stagnation_sessions} sessions "
        f"({scores_window[-stagnation_sessions]['coverage_pct']}% → "
        f"{latest['coverage_pct']}%). "
        f"Consider prioritizing anchor-growth items."
    )
    subprocess.run(['gh', 'issue', 'comment', REPORT_ISSUE, '--repo', REPO,
                    '--body', warn], capture_output=True)
    print(f'[SM §4g-anchor-score] Stagnation warning posted.')
SCOREEOF

  echo "[SM §4g-anchor-score] Anchor score read complete."
fi
```

---

## 4h. Autonomous vision trigger (every SM cycle)

When the queue is empty and the system has been stable for ≥3 cycles, run the
autonomous vision agent to synthesize new ⚠️ Inferred Future items.

```bash
echo "[SM §4h] Checking autonomous vision trigger..."

TODO_COUNT=$(python3 -c "
import json
try:
    s = json.load(open('.otherness/state.json'))
    print(len([d for d in s.get('features',{}).values() if d.get('status') in ('todo','in_review')]))
except: print(0)
" 2>/dev/null || echo "0")

if [ "${TODO_COUNT:-0}" -gt 0 ]; then
  echo "[SM §4h] Queue not empty (${TODO_COUNT} items) — skipping autonomous vision."
else
  PENDING_STUBS=$(python3 -c "
import re, os
total = 0
for f in os.listdir('docs/design'):
    if not f.endswith('.md'): continue
    content = open(f'docs/design/{f}').read()
    total += len(re.findall(r'^- 🔲 ⚠️', content, re.MULTILINE))
print(total)
" 2>/dev/null || echo "0")

  if [ "${PENDING_STUBS:-0}" -gt 5 ]; then
    echo "[SM §4h] ${PENDING_STUBS} pending ⚠️ stubs — skipping (convert stubs to items first)."
  else
    LAST_AUTO=$(python3 -c "
import json
try: print(json.load(open('.otherness/state.json')).get('last_auto_vision_cycle', 0))
except: print(0)
" 2>/dev/null || echo "0")
    CYCLES_SINCE=$(python3 -c "print(max(0, int('${SM_CYCLE:-0}') - int('$LAST_AUTO')))" 2>/dev/null || echo "0")

    if [ "${CYCLES_SINCE:-0}" -lt 3 ]; then
      echo "[SM §4h] Rate limit: ${CYCLES_SINCE} cycles since last run (min: 3) — skipping."
    else
      if [ -f ~/.otherness/agents/autonomous-vision.md ]; then
        echo "[SM §4h] Running autonomous vision synthesis..."
        # [AI-STEP: follow ~/.otherness/agents/autonomous-vision.md inline]
        echo "[SM §4h] Autonomous vision synthesis complete."
        python3 - <<PYEOF
import json
try:
    s = json.load(open('.otherness/state.json'))
    s['last_auto_vision_cycle'] = int('${SM_CYCLE:-0}')
    open('.otherness/state.json', 'w').write(json.dumps(s, indent=2))
except: pass
PYEOF
      else
        echo "[SM §4h] ~/.otherness/agents/autonomous-vision.md not found — skipping."
      fi
    fi
  fi
fi

echo "[SM §4h] Autonomous vision trigger check complete."
```

---

## 4e. Write session handoff

```bash
# Write handoff to the _state branch — NOT to main working tree.
# _state is the distributed store: parallel-safe, machine-independent,
# survives clean checkouts. Works whether agents run on one machine or many.
python3 - <<'EOF'
import subprocess, json, datetime, os, tempfile, shutil

REPO = os.environ.get('REPO', '')
now = datetime.datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ')

# Merged PRs (last 10)
try:
    merged = subprocess.check_output(
        ['gh','pr','list','--repo',REPO,'--state','merged','--limit','10',
         '--json','number,title,mergedAt',
         '--jq','.[] | "- PR #\(.number) \(.title) (\(.mergedAt[:10]))"'],
        text=True).strip()
except:
    merged = '(unavailable)'

# Queue from state.json
try:
    with open('.otherness/state.json') as f: s = json.load(f)
    features = s.get('features', {})
    todo = [f"- {k}: {v.get('title','')}" for k,v in features.items() if v.get('state')=='todo']
    in_prog = [f"- {k}: {v.get('title','')}" for k,v in features.items() if v.get('state') in ('assigned','in_review')]
    queue_text = ('**In progress:**\n' + '\n'.join(in_prog) + '\n' if in_prog else '') + \
                 ('**Todo:**\n' + '\n'.join(todo) if todo else '**Queue empty**')
    next_item = todo[0].lstrip('- ').split(':')[0] if todo else 'none'
except:
    queue_text = '(unavailable)'
    next_item = 'unknown'

# CI status
try:
    ci = subprocess.check_output(
        ['gh','run','list','--repo',REPO,'--branch','main','--limit','1',
         '--json','conclusion,status','--jq','.[0] | (.conclusion // .status)'],
        text=True).strip()
except:
    ci = 'unknown'

handoff = f"""## Session Handoff — {now}

### Recent merges (last 10)
{merged}

### Queue
{queue_text}

### CI status (main)
{ci}

### Next item
{next_item}

### Notes
Session: {os.environ.get('MY_SESSION_ID','unknown')} | otherness@{os.environ.get('OTHERNESS_VERSION','unknown')}
"""

# Write to _state branch via worktree (same pattern as state.json writes)
state_wt = os.path.join(tempfile.gettempdir(), 'otherness-handoff-' + str(os.getpid()))
try:
    subprocess.run(['git','worktree','remove',state_wt,'--force'], capture_output=True)
    subprocess.run(['git','worktree','add','--no-checkout',state_wt,'origin/_state'],
                   capture_output=True, check=True)
    handoff_path = os.path.join(state_wt, '.otherness', 'handoff.md')
    os.makedirs(os.path.dirname(handoff_path), exist_ok=True)
    with open(handoff_path, 'w') as f: f.write(handoff)
    subprocess.run(['git','-C',state_wt,'add','.otherness/handoff.md'], capture_output=True)
    subprocess.run(['git','-C',state_wt,'commit','-m',f'handoff {now}'], capture_output=True)
    r = subprocess.run(['git','-C',state_wt,'push','origin','HEAD:_state'], capture_output=True)
    if r.returncode == 0:
        print(f'[SDM] Handoff written to _state branch (next_item={next_item})')
    else:
        print(f'[SDM] Handoff push failed (non-fatal): {r.stderr.decode()[:100]}')
except Exception as e:
    print(f'[SDM] Handoff write error (non-fatal): {e}')
finally:
    try:
        subprocess.run(['git','worktree','remove',state_wt,'--force'], capture_output=True)
    except: pass
    subprocess.run(['git','worktree','prune'], capture_output=True)
EOF
```

---

## 4f. Post SDM review to report issue

```bash
# Compute health signal and run-level throughput check
HEALTH="GREEN"
CI_STATUS=$(gh run list --repo $REPO --branch main --limit 1 --json conclusion --jq '.[0].conclusion' 2>/dev/null)
[ "$CI_STATUS" = "failure" ] && HEALTH="AMBER"
NEEDS_HUMAN_COUNT=$(gh issue list --repo $REPO --label needs-human --state open --json number --jq 'length' 2>/dev/null || echo 0)
[ "${NEEDS_HUMAN_COUNT:-0}" -gt 0 ] && HEALTH="AMBER"
TODO_COUNT=$(python3 -c "import json; s=json.load(open('.otherness/state.json')); print(len([d for d in s.get('features',{}).values() if d.get('state')=='todo']))" 2>/dev/null || echo 0)
IN_REVIEW=$(python3 -c "import json; s=json.load(open('.otherness/state.json')); print(len([d for d in s.get('features',{}).values() if d.get('state')=='in_review']))" 2>/dev/null || echo 0)

# Count design-doc-backed PRs merged THIS session (not metrics/chore/session report PRs)
SESSION_START=$(python3 -c "
import json, os
try:
    s = json.load(open('.otherness/state.json'))
    hb = s.get('session_heartbeats', {}).get(os.environ.get('MY_SESSION_ID',''), {})
    print(hb.get('session_start', ''))
except: print('')
" 2>/dev/null || echo "")

# Use VISION_PRS and SESSION_OUTCOME from §4b if already set; recompute if not (§4f called standalone)
if [ -z "${VISION_PRS+x}" ]; then
  VISION_PRS=$(gh pr list --repo $REPO --state merged --limit 30 \
    --json title,mergedAt \
    --jq "[.[] | select(
      (.title | test(\"^feat|^fix|^refactor\"; \"i\")) and
      (.title | test(\"^chore\\\\(sm\\\\)|metrics|session complete|PRs merged|batch \"; \"i\") | not)
    ) | .title] | length" 2>/dev/null || echo "0")
  SESSION_OUTCOME="unknown"
fi

# Throughput signal: AMBER if session_outcome is chore-only (design doc 35 §O4)
if [ "${SESSION_OUTCOME:-unknown}" = "chore-only" ] || [ "${VISION_PRS:-0}" -eq 0 ]; then
  HEALTH="AMBER"
  THROUGHPUT_WARN=" ⚠️ ${SESSION_OUTCOME:-chore-only} session (0 vision PRs)"
fi

ACTION="Active"
[ "${TODO_COUNT:-0}" -lt 5 ] && ACTION="Refilling queue"
[ "${TODO_COUNT:-0}" -eq 0 ] && ACTION="Queue empty — running vision+learn"

# §4f: Condensed report format (design doc 35 §Future → ✅)
# Headline: Batch N | Health: X | Progress: X | Vision PRs: N | Chores: N | Queue: N remaining | Journeys: N✅ N❌ | Next: [title]
# Verbose details go into a <details> block. Human can scan 10 comments in 30 seconds.

# Progress classification (O4)
PROGRESS_CLASS="ADVANCING"
[ "${VISION_PRS:-0}" -eq 0 ] && [ "${MERGED:-0}" -gt 0 ] && PROGRESS_CLASS="STEADY"
[ "${MERGED:-0}" -eq 0 ] && PROGRESS_CLASS="STALLED"

# Chores count: MERGED minus VISION_PRS (non-negative)
CHORES_COUNT=$(python3 -c "
merged = int('${MERGED:-0}') if '${MERGED:-0}'.isdigit() else 0
vision = int('${VISION_PRS:-0}') if '${VISION_PRS:-0}'.isdigit() else 0
print(max(0, merged - vision))
" 2>/dev/null || echo "0")

# Next item title (O6)
NEXT_ITEM=$(python3 -c "
import json
try:
    s = json.load(open('.otherness/state.json'))
    PRIORITY_MAP = {'critical': 0, 'high': 1, 'medium': 2, 'low': 3}
    candidates = []
    for id, d in s.get('features', {}).items():
        if d.get('state') != 'todo': continue
        pri = PRIORITY_MAP.get(d.get('priority'), 4)
        title = d.get('title', '').lower()
        labels = d.get('labels', [])
        is_hygiene = title.startswith('hygiene:') or 'kind/chore' in labels
        candidates.append((pri + (10 if is_hygiene else 0), d.get('title', '(none)')))
    candidates.sort()
    print(candidates[0][1][:40] if candidates else '(queue empty)')
except: print('(?)')
" 2>/dev/null || echo "(?)")

# Journey counts (O5): count ## sections in definition-of-done.md
JOURNEY_OK=$(python3 -c "
import re
try:
    content = open('docs/aide/definition-of-done.md').read()
    # Count journey sections marked ✅ in their header or body
    sections = re.findall(r'^##\s+.+', content, re.MULTILINE)
    ok = sum(1 for s in sections if '✅' in s)
    print(ok)
except: print('?')
" 2>/dev/null || echo "?")

JOURNEY_FAIL=$(python3 -c "
import re
try:
    content = open('docs/aide/definition-of-done.md').read()
    sections = re.findall(r'^##\s+.+', content, re.MULTILINE)
    fail = sum(1 for s in sections if '❌' in s)
    print(fail)
except: print('?')
" 2>/dev/null || echo "?")

REPORT_BODY=$(cat <<BODY_EOF
Batch ${SM_CYCLE:-?} | Health: ${HEALTH} | Progress: ${PROGRESS_CLASS} | Vision PRs: ${VISION_PRS:-0} | Chores: ${CHORES_COUNT} | Queue: ${TODO_COUNT:-0} remaining | Journeys: ${JOURNEY_OK}✅ ${JOURNEY_FAIL}❌ | Next: [${NEXT_ITEM}]

<details><summary>Details</summary>

- Session: \`${MY_SESSION_ID:-sess-unknown}\` | Agent: otherness@${OTHERNESS_VERSION:-unknown}
- Outcome: ${SESSION_OUTCOME:-unknown}${THROUGHPUT_WARN:-}
- In-review: ${IN_REVIEW:-0} | Action: ${ACTION}
- Needs-human open: ${NEEDS_HUMAN_COUNT:-0}

</details>
BODY_EOF
)

gh issue comment $REPORT_ISSUE --repo $REPO --body "$REPORT_BODY" 2>/dev/null

# §4f: Silent-session detection (design doc 35 §Future → ✅)
# A silent session: 0 PRs merged AND 0 open PRs. Two consecutive silent sessions → escalate.
OPEN_PRS=$(gh pr list --repo $REPO --state open --json number --jq 'length' 2>/dev/null || echo "0")
python3 - <<'SILENT_EOF'
import json, os, subprocess

REPO = os.environ.get('REPO', '')
MERGED = os.environ.get('MERGED', '0')
OPEN_PRS = os.environ.get('OPEN_PRS', '0')
REPORT_ISSUE = os.environ.get('REPORT_ISSUE', '1')
MY_SESSION_ID = os.environ.get('MY_SESSION_ID', 'sess-unknown')
OTHERNESS_VERSION = os.environ.get('OTHERNESS_VERSION', 'unknown')

# Determine if this is a silent session
try:
    merged_count = int(MERGED) if str(MERGED).isdigit() else 0
    open_count = int(OPEN_PRS) if str(OPEN_PRS).isdigit() else 0
except:
    merged_count = 1  # fail-open: assume not silent
    open_count = 1

is_silent = (merged_count == 0 and open_count == 0)

try:
    with open('.otherness/state.json') as f: s = json.load(f)
    current_count = s.get('silent_session_count', 0)

    if is_silent:
        new_count = current_count + 1
        print(f'[SM §4f] Silent session detected. streak={new_count}')
    else:
        new_count = 0
        if current_count > 0:
            print(f'[SM §4f] Session is active — resetting silent streak (was {current_count})')

    s['silent_session_count'] = new_count
    with open('.otherness/state.json', 'w') as f: json.dump(s, f, indent=2)

    # Check for streak: ≥2 consecutive silent sessions → [NEEDS HUMAN]
    if new_count >= 2:
        issue_title = '[NEEDS HUMAN: silent-session-streak] Loop is spinning without shipping'
        existing = subprocess.run(
            ['gh', 'issue', 'list', '--repo', REPO, '--state', 'open',
             '--search', 'silent-session-streak', '--json', 'number', '--jq', 'length'],
            capture_output=True, text=True)
        if int(existing.stdout.strip() or '0') == 0:
            body = (
                f'## Silent session streak detected\n\n'
                f'`silent_session_count = {new_count}` — the loop has run {new_count} consecutive '
                f'sessions with 0 merged PRs and 0 open PRs.\n\n'
                f'This means the agent is starting, running, and exiting without shipping anything. '
                f'Common causes:\n'
                f'- Queue is empty and vision synthesis is not producing claimable items\n'
                f'- All items are stuck in conflict or require human unblock\n'
                f'- CI is red on main and blocking new PRs\n'
                f'- Agent is failing silently in an early phase\n\n'
                f'## Actions\n'
                f'1. Check the report issue comments for the last 2 sessions\n'
                f'2. Check `_state` branch for recent state.json changes\n'
                f'3. Check GitHub Actions run logs for errors\n'
                f'4. If queue empty: run `/otherness.vibe-vision` to inject new items\n\n'
                f'Reported by SM §4f | {MY_SESSION_ID} | otherness@{OTHERNESS_VERSION}'
            )
            r = subprocess.run(
                ['gh', 'issue', 'create', '--repo', REPO,
                 '--title', issue_title, '--label', 'needs-human,otherness',
                 '--body', body],
                capture_output=True, text=True)
            if r.returncode == 0:
                print(f'[SM §4f] Opened silent-session-streak issue: {r.stdout.strip()}')
            else:
                print(f'[SM §4f] Failed to open streak issue: {r.stderr.strip()[:100]}')
        else:
            print(f'[SM §4f] Silent streak issue already open — skipping duplicate.')

except Exception as e:
    print(f'[SM §4f] Silent-session detection error (non-fatal): {e}')
SILENT_EOF
# Design ref: docs/design/06-command-surface.md §Future (🔲 → ✅)
# Runs every batch — always reflects current reality, not stale history.
python3 - <<'PROGRESS_EOF'
import subprocess, json, os, re, datetime

REPO = os.environ.get('REPO', '')
HEALTH = os.environ.get('HEALTH', 'GREEN')
TODO_COUNT = os.environ.get('TODO_COUNT', '0')
IN_REVIEW = os.environ.get('IN_REVIEW', '0')
VISION_PRS = os.environ.get('VISION_PRS', '0')
SM_CYCLE = os.environ.get('SM_CYCLE', '?')
OTHERNESS_VERSION = os.environ.get('OTHERNESS_VERSION', 'unknown')

progress_path = 'docs/aide/progress.md'
if not os.path.exists(progress_path):
    print(f"[SM §4f] {progress_path} not found — skipping progress update (non-fatal)")
    exit(0)

# Get last shipped PR (non-chore, non-session)
last_pr_title = '(none this session)'
last_pr_date = ''
try:
    r = subprocess.run(
        ['gh', 'pr', 'list', '--repo', REPO, '--state', 'merged', '--limit', '20',
         '--json', 'title,mergedAt',
         '--jq', '[.[] | select(.title | test("^feat|^fix|^refactor"; "i")) | select(.title | test("^chore\\\\(sm\\\\)|metrics|session complete|PRs merged"; "i") | not)][0]'],
        capture_output=True, text=True, timeout=15)
    if r.returncode == 0 and r.stdout.strip() and r.stdout.strip() != 'null':
        pr = json.loads(r.stdout.strip())
        last_pr_title = pr.get('title', '(none)')[:80]
        merged_at = pr.get('mergedAt', '')
        if merged_at:
            last_pr_date = merged_at[:10]
except Exception as e:
    print(f"[SM §4f] last-PR lookup failed (non-fatal): {e}")

# Read current progress.md to extract current stage (preserve human-authored stage info)
try:
    content = open(progress_path).read()
except Exception as e:
    print(f"[SM §4f] progress.md read error (non-fatal): {e}")
    exit(0)

today = datetime.date.today().isoformat()
health_icon = '🟢' if HEALTH == 'GREEN' else '🟡' if HEALTH == 'AMBER' else '🔴'

# Build new header block — overwrite only the dynamic fields
new_header = f"""# otherness: Current Progress

> Updated automatically by SM §4f every batch. Last update: {today}

## Current State

- **Health**: {health_icon} {HEALTH}
- **Last shipped**: {last_pr_title}{' (' + last_pr_date + ')' if last_pr_date else ''}
- **Queue depth**: {TODO_COUNT} todo, {IN_REVIEW} in_review
- **Vision PRs this batch**: {VISION_PRS}
- **SM cycle**: {SM_CYCLE} | Agent: otherness@{OTHERNESS_VERSION}
"""

# Replace the header block (everything up to and including ## Stage Completion or ## Key milestones)
# Keep the rest of the file (stage table, milestones) intact
m = re.search(r'^## (Stage Completion|Stage [0-9]|Key milestones)', content, re.MULTILINE)
if m:
    tail = content[m.start():]
    new_content = new_header + '\n' + tail
else:
    # Fallback: replace the first ## Current State section only
    new_content = re.sub(
        r'^# otherness: Current Progress.*?(?=^## Stage Completion|^## Key milestones|\Z)',
        new_header + '\n',
        content,
        count=1,
        flags=re.MULTILINE | re.DOTALL
    )
    if new_content == content:
        # No match — prepend header
        new_content = new_header + '\n' + content

try:
    with open(progress_path, 'w') as f:
        f.write(new_content)
    print(f"[SM §4f] progress.md updated: {HEALTH} | queue={TODO_COUNT} | last-PR={last_pr_title[:40]}")
except Exception as e:
    print(f"[SM §4f] progress.md write error (non-fatal): {e}")
    exit(0)

# Commit and push directly to main (low-risk doc change — same pattern as §4b metrics.md)
try:
    subprocess.run(['git', 'add', progress_path], capture_output=True)
    cr = subprocess.run(
        ['git', 'commit', '-m',
         f'chore(sm): update progress.md — {HEALTH} batch {SM_CYCLE} [{today}]'],
        capture_output=True, text=True)
    if cr.returncode != 0 and 'nothing to commit' in cr.stdout + cr.stderr:
        print("[SM §4f] progress.md unchanged — no commit needed")
    elif cr.returncode != 0:
        print(f"[SM §4f] progress.md commit error (non-fatal): {cr.stderr[:100]}")
    else:
        for i in range(1, 4):
            pull_r = subprocess.run(
                ['git', 'pull', '--rebase', 'origin', 'main', '--quiet'],
                capture_output=True)
            push_r = subprocess.run(
                ['git', 'push', 'origin', 'main'],
                capture_output=True)
            if push_r.returncode == 0:
                print(f"[SM §4f] progress.md committed and pushed to main")
                break
            import time; time.sleep(i * 2)
        else:
            print("[SM §4f] progress.md push failed after 3 retries (non-fatal)")
except Exception as e:
    print(f"[SM §4f] progress.md commit/push error (non-fatal): {e}")
PROGRESS_EOF
```

---

## 4g. Merge session branch PR (opencode/* branches only)

When the agent runs via GitHub Actions, OpenCode creates a PR from the session branch
(`opencode/schedule-*` or `opencode/dispatch-*`) to `main`. This branch accumulates
session-level changes (state.json, metrics.md, command file syncs) that must land on main.
Without this step these PRs pile up open indefinitely.

```bash
# Detect if running on an opencode/* session branch
SESSION_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")

if echo "$SESSION_BRANCH" | grep -qE '^opencode/(schedule|dispatch)-'; then
  echo "[SM §4g] Running on session branch: $SESSION_BRANCH — locating open PR to merge."

  SESSION_PR=$(gh pr list --repo "$REPO" --head "$SESSION_BRANCH" --state open \
    --json number --jq '.[0].number' 2>/dev/null)

  if [ -n "$SESSION_PR" ] && [ "$SESSION_PR" != "null" ]; then
    echo "[SM §4g] Found session PR #${SESSION_PR} — merging."

    # Check if branch is behind main and update if needed
    _SESSION_STATE=$(gh pr view "$SESSION_PR" --repo "$REPO" \
      --json mergeStateStatus --jq '.mergeStateStatus' 2>/dev/null)
    if [ "$_SESSION_STATE" = "BEHIND" ]; then
      echo "[SM §4g] Session branch BEHIND main — updating."
      gh pr update-branch "$SESSION_PR" --repo "$REPO" 2>/dev/null || true
      sleep 10
    fi

    # Wait for CI — use gh pr checks --json (authoritative, all checks)
    # Design ref: docs/design/38-qa-ci-gate.md §O5
    _CI_WAIT=0
    while [ $_CI_WAIT -lt 60 ]; do  # up to 30 min (60 × 30s)
      _CI_JSON=$(gh pr checks "$SESSION_PR" --repo "$REPO" \
        --json name,state,conclusion 2>/dev/null || echo "[]")
      _CI_FAILING=$(echo "$_CI_JSON" | python3 -c "
import json, sys
checks = json.load(sys.stdin)
failing=[c['name'] for c in checks if c.get('conclusion') in ('failure','timed_out','action_required')]
pending=[c for c in checks if c.get('state')=='PENDING' or c.get('conclusion') is None]
print(f'failing={len(failing)} pending={len(pending)}')
for c in failing: print(f'FAIL:{c}')
" 2>/dev/null || echo "failing=0 pending=0")

      if echo "$_CI_FAILING" | grep -q "^FAIL:"; then
        echo "[SM §4g] Session PR CI failing — will close rather than merge broken code to main"
        gh pr close "$SESSION_PR" --repo "$REPO" \
          --comment "[SM §4g] Session branch CI failing — not merged to avoid breaking main. Failing checks: $(echo "$_CI_FAILING" | grep "^FAIL:" | sed 's/^FAIL://' | tr '\n' ','). Fix the failure and re-open or let the next session handle it." \
          2>/dev/null || true
        break 2  # exit both the CI loop and the outer if block
      fi

      if ! echo "$_CI_FAILING" | grep -q "pending=[^0]"; then
        break  # all checks complete, none failing
      fi

      echo "[SM §4g] CI pending — waiting 30s (attempt $((_CI_WAIT+1))/60)..."
      sleep 30
      _CI_WAIT=$((_CI_WAIT + 1))
    done

    # Final CI gate before merge — verify no failures (in case loop exited on timeout)
    _FINAL_FAILING=$(gh pr checks "$SESSION_PR" --repo "$REPO" \
      --json name,conclusion 2>/dev/null | python3 -c "
import json,sys
checks=json.load(sys.stdin)
failing=[c['name'] for c in checks if c.get('conclusion') in ('failure','timed_out','action_required')]
print(','.join(failing))
" 2>/dev/null || echo "")

    if [ -n "$_FINAL_FAILING" ]; then
      echo "[SM §4g] Final CI gate: failing checks: $_FINAL_FAILING — closing session PR"
      gh pr close "$SESSION_PR" --repo "$REPO" \
        --comment "[SM §4g] Closing — CI failing: $_FINAL_FAILING. Not merged to protect main." \
        2>/dev/null || true
    else
      # CI all green — merge: try squash → squash --admin
      if gh pr merge "$SESSION_PR" --repo "$REPO" --squash --delete-branch 2>/dev/null; then
        echo "[SM §4g] Session PR #${SESSION_PR} merged to main."
      elif gh pr merge "$SESSION_PR" --repo "$REPO" --squash --delete-branch --admin 2>/dev/null; then
        echo "[SM §4g] Session PR #${SESSION_PR} merged to main (--admin)."
      else
        echo "[SM §4g] Merge failed — closing session PR #${SESSION_PR} as superseded."
        gh pr close "$SESSION_PR" --repo "$REPO" \
          --comment "[SM §4g] Session branch closed — changes were applied directly during session. Branch: $SESSION_BRANCH" \
          2>/dev/null || true
      fi
    fi
  else
    echo "[SM §4g] No open session PR found for $SESSION_BRANCH — nothing to do."
  fi
else
  echo "[SM §4g] Not on session branch ($SESSION_BRANCH) — skipping."
fi
```
