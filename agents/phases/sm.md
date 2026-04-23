
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

**Cognitive stance: historian — What pattern do we keep repeating?**
<!-- Design ref: docs/design/31-stage-2-skills-expansion.md §Future → ✅ (issue-795) -->

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

# §4a: M3 App adoption check — once per 5 SM cycles
# Design ref: docs/design/27-security-model.md §Future → ✅
# Check each managed project's otherness-scheduled.yml for OTHERNESS_USE_APP_TOKEN.
# Fail-open: API failure → skip silently. Duplicate suppression: check REPORT_ISSUE comments.
if [ $((${SM_CYCLE:-0} % 5)) -eq 0 ]; then
python3 - <<'M3EOF'
import subprocess, re, os, base64, json

REPO = os.environ.get('REPO', '')
REPORT_ISSUE = os.environ.get('REPORT_ISSUE', '')
MY_SESSION_ID = os.environ.get('MY_SESSION_ID', 'SM')
OTHERNESS_VERSION = os.environ.get('OTHERNESS_VERSION', 'unknown')

# Read monitor.projects
projects = []
try:
    in_monitor = in_projects = False
    for line in open('otherness-config.yaml'):
        if re.match(r'^monitor:', line): in_monitor = True
        if in_monitor and re.match(r'\s+projects:', line): in_projects = True
        if in_projects:
            m = re.match(r'\s+- (.+)', line)
            if m: projects.append(m.group(1).strip())
        elif in_monitor and re.match(r'^\w', line): in_projects = False
except Exception:
    pass

if not projects:
    print('[SM §4a] M3 check: no monitor.projects configured — skipping.')
    exit(0)

# Read recent REPORT_ISSUE comments to check for recent SECURITY-AMBER posts (dedup window: 7d)
recent_amber_projects = set()
try:
    from datetime import datetime, timezone, timedelta
    cutoff = (datetime.now(timezone.utc) - timedelta(days=7)).strftime('%Y-%m-%dT%H:%M:%SZ')
    r = subprocess.run(
        ['gh', 'issue', 'view', REPORT_ISSUE, '--repo', REPO,
         '--json', 'comments', '--jq',
         f'[.comments[] | select(.createdAt >= "{cutoff}") | .body] | .[]'],
        capture_output=True, text=True, timeout=20)
    if r.returncode == 0:
        for comment in r.stdout.splitlines():
            if '[SECURITY-AMBER]' in comment:
                for proj in projects:
                    if proj in comment:
                        recent_amber_projects.add(proj)
except Exception:
    pass

for project in projects:
    # Skip self (the otherness repo is checked differently)
    if project == REPO:
        continue
    try:
        r = subprocess.run(
            ['gh', 'api',
             f'repos/{project}/contents/.github/workflows/otherness-scheduled.yml'],
            capture_output=True, text=True, timeout=15)
        if r.returncode != 0:
            print(f'[SM §4a] M3 app adoption check: {project} mode=unknown (API error)')
            continue
        data = json.loads(r.stdout)
        content = base64.b64decode(data.get('content', '').replace('\n', '')).decode('utf-8', errors='replace')
        if 'OTHERNESS_USE_APP_TOKEN' in content:
            print(f'[SM §4a] M3 app adoption check: {project} mode=app')
        else:
            print(f'[SM §4a] M3 app adoption check: {project} mode=pat')
            # Post AMBER comment if not already posted in last 7 days
            if project not in recent_amber_projects:
                amber_msg = (
                    f'[SECURITY-AMBER | SM §4a | {MY_SESSION_ID} | otherness@{OTHERNESS_VERSION}] '
                    f'Project `{project}` appears to be using PAT fallback '
                    f'(no `OTHERNESS_USE_APP_TOKEN` found in `otherness-scheduled.yml`) — '
                    f'cross-repo blast radius risk. See `docs/design/27-security-model.md §M3`. '
                    f'Recommended: configure GitHub App token (M3) on this project.'
                )
                subprocess.run(
                    ['gh', 'issue', 'comment', REPORT_ISSUE, '--repo', REPO, '--body', amber_msg],
                    capture_output=True, timeout=15)
                print(f'[SM §4a] SECURITY-AMBER posted for {project} (PAT mode).')
            else:
                print(f'[SM §4a] SECURITY-AMBER already posted for {project} in last 7d — skipping duplicate.')
    except Exception as _e:
        print(f'[SM §4a] M3 check error for {project} (non-fatal): {_e}')

print('[SM §4a] M3 app adoption check complete.')
M3EOF
fi

# §4a: M7 full close — _state write integrity check (design doc 27 §Future → ✅)
# When GitHub App (M3) is active (OTHERNESS_USE_APP_TOKEN=true), validate that recent
# _state commits originate from the App identity (not a collaborator or PAT).
# Any anomalous push triggers [NEEDS HUMAN]. Fail-open. Once per 5 SM cycles.
# Design ref: docs/design/27-security-model.md §Future
if [ $((${SM_CYCLE:-0} % 5)) -eq 0 ]; then
python3 - <<'M7EOF'
import subprocess, json, os, re

REPO = os.environ.get('REPO', '')
REPORT_ISSUE = os.environ.get('REPORT_ISSUE', '1')
MY_SESSION_ID = os.environ.get('MY_SESSION_ID', 'SM')
OTHERNESS_VERSION = os.environ.get('OTHERNESS_VERSION', 'unknown')

# Only run when App mode is active
use_app_token = False
try:
    r = subprocess.run(
        ['gh', 'api', f'repos/{REPO}/actions/variables/OTHERNESS_USE_APP_TOKEN',
         '--jq', '.value'],
        capture_output=True, text=True, timeout=10)
    use_app_token = r.returncode == 0 and r.stdout.strip().lower() == 'true'
except Exception:
    pass

if not use_app_token:
    print('[SM §4a-M7] App mode not active (OTHERNESS_USE_APP_TOKEN != true) — skipping integrity check.')
    exit(0)

# Read last 10 commits to _state branch
try:
    r = subprocess.run(
        ['gh', 'api', f'repos/{REPO}/commits',
         '--field', 'sha=_state', '--field', 'per_page=10',
         '--jq', '[.[] | {sha: .sha[:8], author: (.commit.author.email // .commit.author.name), message: .commit.message[:40]}]'],
        capture_output=True, text=True, timeout=15)
    if r.returncode != 0:
        print(f'[SM §4a-M7] Could not read _state commits (non-fatal): {r.stderr.strip()[:80]}')
        exit(0)
    commits = json.loads(r.stdout.strip() or '[]')
except Exception as e:
    print(f'[SM §4a-M7] _state commit read error (non-fatal): {e}')
    exit(0)

# Check: commits should be from otherness[bot] or the App identity
# App commits have author email matching [bot]@users.noreply.github.com
BOT_PATTERN = re.compile(r'\[bot\]|otherness.*bot|github-actions', re.IGNORECASE)

anomalous = []
for commit in commits:
    author = commit.get('author', '')
    if not BOT_PATTERN.search(author):
        # Exclude bootstrap commit and empty state
        msg = commit.get('message', '')
        if 'bootstrap' in msg.lower() or msg.startswith('[cleanup]'):
            continue
        anomalous.append(f"sha={commit.get('sha')} author={author!r} msg={commit.get('message')!r}")

if anomalous:
    print(f'[SM §4a-M7] ⚠️ Anomalous _state commits detected: {len(anomalous)}')
    for a in anomalous[:3]:
        print(f'  {a}')
    # Check for existing NEEDS HUMAN issue (dedup)
    existing = subprocess.run(
        ['gh', 'issue', 'list', '--repo', REPO, '--state', 'open',
         '--search', 'M7-integrity', '--json', 'number', '--jq', 'length'],
        capture_output=True, text=True, timeout=15)
    if int(existing.stdout.strip() or '0') == 0:
        body = (
            f'## _state write integrity anomaly detected\n\n'
            f'SM §4a-M7 detected _state branch commits that do not originate from the '
            f'otherness[bot] App identity, despite `OTHERNESS_USE_APP_TOKEN=true`.\n\n'
            f'## Anomalous commits\n\n'
            + '\n'.join(f'- {a}' for a in anomalous[:5]) +
            f'\n\n## What to investigate\n\n'
            f'1. Check the commit authors above against known collaborators\n'
            f'2. Verify the PAT (GH_TOKEN) fallback is not being used in production runs\n'
            f'3. Check GitHub audit log for the anomalous push origin\n'
            f'4. If the push was human-initiated: close this issue (intentional)\n'
            f'5. If unexpected: consider rotating the GH_TOKEN PAT\n\n'
            f'## Security design reference\n\n'
            f'See `docs/design/27-security-model.md §M7`.\n\n'
            f'SM §4a-M7 | {MY_SESSION_ID} | otherness@{OTHERNESS_VERSION}'
        )
        r2 = subprocess.run(
            ['gh', 'issue', 'create', '--repo', REPO,
             '--title', '[NEEDS HUMAN] M7-integrity: anomalous _state commits detected',
             '--label', 'needs-human,area/tooling,priority/high,otherness',
             '--body', body],
            capture_output=True, text=True, timeout=15)
        if r2.returncode == 0:
            print(f'[SM §4a-M7] NEEDS HUMAN issue opened: {r2.stdout.strip()}')
        else:
            print(f'[SM §4a-M7] Issue creation failed (non-fatal): {r2.stderr.strip()[:100]}')
    else:
        print('[SM §4a-M7] NEEDS HUMAN issue already open — skipping duplicate.')
else:
    print(f'[SM §4a-M7] _state integrity OK — all {len(commits)} recent commits from bot identity.')

M7EOF
fi

# §4a-schema-conformance: metrics.md column drift detection (design doc 33 §Future → ✅)
# Compare header column count vs last data row column count.
# If they differ: open a kind/bug priority/high issue (idempotent).
# Fail-open: missing/empty metrics.md logs a warning and continues.
python3 - <<'SCHEMA_EOF'
import os
metrics_path = 'docs/aide/metrics.md'
try:
    lines_m = [l for l in open(metrics_path) if l.startswith('|')]
    header = next((l for l in lines_m if 'prs_merged' in l), None)
    data = [l for l in lines_m if '---|' not in l and 'prs_merged' not in l]
    if not header or not data: print('[SM] metrics.md has no data rows.'); exit(0)
    h = len([c for c in header.split('|') if c.strip()])
    d = len([c for c in data[-1].split('|') if c.strip()])
    if h == d: print(f'[SM] metrics schema OK ({h} cols)')
    else: print(f'[SM] SCHEMA MISMATCH: header={h} vs last_row={d}')
except FileNotFoundError: print('[SM] metrics.md not found — skipping.')
except Exception as e: print(f'[SM] schema error (non-fatal): {e}')
SCHEMA_EOF


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

# §4a-simplify: Simplification cycle — every 30 batches, ensure a chore issue exists.
# Design ref: docs/design/45-distil-and-simplify.md §45.5
# Skip at SM_CYCLE=0 (first run). Fail silently.
if [ $((${SM_CYCLE:-0} % 30)) -eq 0 ] && [ "${SM_CYCLE:-0}" -gt 0 ]; then
  _SIMPLIFY_EXISTING=$(gh issue list --repo "$REPO" --state open \
    --search "Simplification cycle" --json number --jq 'length' 2>/dev/null || echo "0")
  if [ "${_SIMPLIFY_EXISTING:-0}" -eq 0 ]; then
    gh issue create --repo "$REPO" \
      --title "chore: Simplification cycle — distil sm.md, coord.md, eng.md, qa.md" \
      --label "kind/chore,priority/high,size/m,area/agent-loop" \
      --body "Scheduled simplification cycle (every 30 batches, SM_CYCLE=${SM_CYCLE}).

Audit phase files for dead weight. See docs/design/45-distil-and-simplify.md.

Checklist:
- [ ] Count [AI-STEP] sections in all phase files; any >50% [AI-STEP] is a removal candidate
- [ ] Identify non-executing sections (no output in last 30 sessions)
- [ ] Distil: remove/compress dead weight, move aspirational content to design docs
- [ ] Verify core workflow chain executes completely after simplification" \
      2>/dev/null || true
    echo "[SM §4a-simplify] Simplification cycle issue opened (SM_CYCLE=${SM_CYCLE})."
  else
    echo "[SM §4a-simplify] Simplification cycle issue already open — skipping (SM_CYCLE=${SM_CYCLE})."
  fi
fi
```

---

## 4a-speckit. Speckit release check (every 10 SM cycles)

```bash
if [ $((${SM_CYCLE:-0} % 10)) -eq 0 ] && [ "${SM_CYCLE:-0}" -gt 0 ]; then
  LATEST_SPECKIT=$(gh release list --repo jaredpalmer/speckit --limit 1     --json tagName --jq '.[0].tagName' 2>/dev/null || echo "unknown")
  CURRENT_SPECKIT=$(specify --version 2>/dev/null | head -1 || echo "not installed")
  echo "[SM §4a-speckit] speckit: installed=$CURRENT_SPECKIT latest=$LATEST_SPECKIT"
  if [ "$LATEST_SPECKIT" != "unknown" ] && [ "$CURRENT_SPECKIT" != "not installed" ]; then
    [ "$LATEST_SPECKIT" != "$CURRENT_SPECKIT" ] &&       echo "[SM §4a-speckit] Update available: $CURRENT_SPECKIT → $LATEST_SPECKIT" ||       echo "[SM §4a-speckit] Up to date."
  fi
fi
```

## 4a-changelog. CHANGELOG.md auto-update (design doc 03 §Future → ✅)

After each batch, append entries for newly merged PRs to CHANGELOG.md.
Uses Keep a Changelog format. Idempotent: skips PRs already in the file.

```bash
python3 - <<'CHANGELOG_EOF'
import subprocess, json, os, re, datetime

REPO = os.environ.get('REPO', '')

changelog_path = 'CHANGELOG.md'
HEADER = "# Changelog\n\nAll notable changes are documented here. Maintained automatically by SM §4a.\n\n"
UNRELEASED_HEADER = "## [Unreleased]\n"

# Read current CHANGELOG.md
try:
    content = open(changelog_path).read()
except FileNotFoundError:
    content = HEADER + UNRELEASED_HEADER + "\n"

# Find existing PR numbers already in CHANGELOG
existing_prs = set(int(m) for m in re.findall(r'\(#(\d+)\)', content))

# Fetch recently merged PRs (last 24h, non-chore)
EXCLUDE_PAT = re.compile(
    r'^chore\(sm\)|^chore\(metrics\)|batch\s+\d+|session complete|PRs merged', re.IGNORECASE)
try:
    from datetime import datetime as _dt, timezone, timedelta
    since = (_dt.now(timezone.utc) - timedelta(hours=24)).strftime('%Y-%m-%dT%H:%M:%SZ')
    r = subprocess.run(
        ['gh', 'pr', 'list', '--repo', REPO, '--state', 'merged', '--limit', '30',
         '--json', 'number,title,mergedAt'],
        capture_output=True, text=True, timeout=20)
    prs = json.loads(r.stdout.strip() or '[]') if r.returncode == 0 else []
    recent = [pr for pr in prs
              if pr.get('mergedAt', '') >= since
              and not EXCLUDE_PAT.match(pr.get('title', ''))
              and pr['number'] not in existing_prs]
except Exception as e:
    print(f'[SM §4a-changelog] PR fetch error (non-fatal): {e}')
    recent = []

if not recent:
    print('[SM §4a-changelog] No new PRs to add to CHANGELOG.')
else:
    # Build new entries
    new_entries = ''.join(f"- {pr['title']} (#{pr['number']})\n" for pr in recent)
    # Insert after [Unreleased] header
    if UNRELEASED_HEADER in content:
        content = content.replace(
            UNRELEASED_HEADER,
            UNRELEASED_HEADER + '\n' + new_entries,
            1)
    else:
        content = content + '\n' + UNRELEASED_HEADER + '\n' + new_entries
    with open(changelog_path, 'w') as f:
        f.write(content)
    print(f'[SM §4a-changelog] Added {len(recent)} entries to CHANGELOG.md.')
    # Commit directly to main (SM doc-commit path)
    subprocess.run(['git', 'add', changelog_path], capture_output=True)
    r2 = subprocess.run(
        ['git', 'commit', '-m',
         f'chore(changelog): auto-update — {len(recent)} new entries (SM §4a)'],
        capture_output=True, text=True)
    if r2.returncode == 0:
        subprocess.run(['git', 'push', 'origin', 'main'], capture_output=True)
        print('[SM §4a-changelog] CHANGELOG.md committed and pushed.')
    else:
        print(f'[SM §4a-changelog] Commit failed (non-fatal): {r2.stderr.strip()[:100]}')
CHANGELOG_EOF

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

## 4b. Minimum viable batch report

# Design ref: docs/design/45-distil-and-simplify.md §O2
# The batch report must answer THREE questions in one read. Nothing more.
# Q1: Did meaningful work ship this session?
# Q2: What is in the queue?
# Q3: Is anything blocking?

```bash
# Q1: Did meaningful work ship?
MEANINGFUL_PRS=$(gh pr list --repo "$REPO" --state merged --limit 20 \
  --json title,mergedAt \
  --jq "[.[] | select(
    (.title | test("^feat|^fix|^refactor"; "i")) and
    (.title | test("^chore\\(sm\\)|^chore\\(metrics\\)|session complete|batch [0-9]"; "i") | not) and
    (.mergedAt >= \"$(date -u -v-6H +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d '6 hours ago' +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo '')\"  )
  ) | .title] | length" 2>/dev/null || echo "0")

SHIPPED_TITLES=$(gh pr list --repo "$REPO" --state merged --limit 10 \
  --json title,mergedAt \
  --jq "[.[] | select(
    (.title | test("^feat|^fix|^refactor"; "i")) and
    (.title | test("^chore\\(sm\\)|^chore\\(metrics\\)|session complete|batch [0-9]"; "i") | not)
  ) | .title] | .[:3] | join(\"  \n- \")" 2>/dev/null || echo "")

# §4b-velocity: meaningful_prs_per_week — time-normalised delivery rate (design doc 33 §Future → ✅)
# Count feat/fix/refactor PRs merged in the rolling 7-day window using GitHub API mergedAt.
# Fail-open: API error → write '?' so the row is never skipped.
MEANINGFUL_PRS_WEEK=$(python3 - <<'VELOCITY_EOF'
import subprocess, json, os, datetime, re

REPO = os.environ.get('REPO', '')
EXCLUDE_PAT = re.compile(
    r'^chore\(sm\)|^chore\(metrics\)|batch\s+\d+|session complete|PRs merged', re.IGNORECASE)

try:
    since = (datetime.datetime.now(datetime.timezone.utc) - datetime.timedelta(days=7)).strftime('%Y-%m-%dT%H:%M:%SZ')
    r = subprocess.run(
        ['gh', 'pr', 'list', '--repo', REPO, '--state', 'merged', '--limit', '100',
         '--json', 'title,mergedAt'],
        capture_output=True, text=True, timeout=20)
    if r.returncode != 0:
        print('?')
    else:
        prs = json.loads(r.stdout.strip() or '[]')
        meaningful = [
            pr for pr in prs
            if not EXCLUDE_PAT.match(pr.get('title', ''))
            and re.match(r'^(feat|fix|refactor)', pr.get('title', ''), re.IGNORECASE)
            and pr.get('mergedAt', '') >= since
        ]
        # Express as prs/week (float with 1 decimal)
        print(f'{len(meaningful):.1f}')
except Exception:
    print('?')
VELOCITY_EOF
)
export MEANINGFUL_PRS_WEEK
echo "[SM §4b-velocity] meaningful_prs_week=${MEANINGFUL_PRS_WEEK:-?}"

# Q2: What is in the queue?
TODO_COUNT=$(python3 -c "
import json, subprocess
try:
    r = subprocess.run(['git','show','origin/_state:.otherness/state.json'],
                       capture_output=True, text=True)
    s = json.loads(r.stdout)
    todo = [v for v in s.get('features',{}).values() if v.get('state')=='todo']
    print(len(todo))
    for v in todo[:3]:
        t = v.get('title','?')
        print(t[:60])
except: print('?')
" 2>/dev/null)
TODO_NUM=$(echo "$TODO_COUNT" | head -1)
TODO_TOP=$(echo "$TODO_COUNT" | tail -n +2 | head -3 | sed 's/^/  - /')

# Q3: Is anything blocking?
NEEDS_HUMAN=$(gh issue list --repo "$REPO" --state open --label "needs-human" \
  --json number,title --jq 'length' 2>/dev/null || echo "0")
NH_LIST=$(gh issue list --repo "$REPO" --state open --label "needs-human" \
  --json number,title --jq '.[:2] | .[] | "  - #\(.number) \(.title[:50])"' 2>/dev/null || echo "")
CI_RED=$(gh run list --repo "$REPO" --branch main --limit 1 \
  --json conclusion --jq 'if .[0].conclusion == "failure" then "YES" else "NO" end' 2>/dev/null || echo "NO")

# Health
HEALTH="GREEN"
[ "$MEANINGFUL_PRS" = "0" ] && HEALTH="AMBER ⚠️ (0 vision PRs this session)"
[ "${NEEDS_HUMAN:-0}" -gt 0 ] && HEALTH="AMBER ⚠️ (needs-human open)"
[ "$CI_RED" = "YES" ] && HEALTH="RED 🔴 (main CI failing)"

# §4b-competitive: read latest competitive standing row (design doc 17 §Future → ✅)
# Fail-open: if file absent or no data rows, omit the line silently.
COMPETITIVE_LINE=$(python3 - <<'COMP_EOF'
import re, os
try:
    content = open('docs/aide/competitive-standing.md').read()
    rows = [l for l in content.splitlines()
            if re.match(r'^\|\s*\d{4}-\d{2}-\d{2}', l)]
    if not rows:
        raise ValueError("no data rows")
    # Parse last row: | Date | Batch | Comparator | ... | delta |
    last = rows[-1]
    cells = [c.strip() for c in last.split('|')[1:-1]]
    if len(cells) >= 8:
        comparator = cells[2]
        delta = cells[7]
        date = cells[0]
        # Compute batches ago (use BATCH_COUNT env if available)
        batch_col = cells[1]
        try:
            batch_count = int(os.environ.get('BATCH_COUNT', '0') or '0')
            row_batch = int(batch_col)
            batches_ago = batch_count - row_batch
        except Exception:
            batches_ago = 0
        suffix = f'{batches_ago} batch(es) ago' if batches_ago > 0 else 'this batch'
        print(f'vs. {comparator}: {delta} (last checked: {suffix})')
    else:
        raise ValueError("malformed row")
except Exception:
    pass  # Fail-open: no output
COMP_EOF
)

# Post the report — three questions, nothing more
REPORT_BODY="[🔄 SDM | ${MY_SESSION_ID:-?} | otherness@${OTHERNESS_VERSION:-?}]

**Health: ${HEALTH}**

**Q1 — Did meaningful work ship?**
$([ "$MEANINGFUL_PRS" -gt 0 ] 2>/dev/null && echo "✅ Yes — $MEANINGFUL_PRS PR(s):" || echo "⚠️ No meaningful PRs this session")
$([ -n "$SHIPPED_TITLES" ] && echo "- $SHIPPED_TITLES" || true)

**Q2 — Queue depth: ${TODO_NUM:-?} items**
${TODO_TOP:-  (queue empty — vision scan will refill)}

**Q3 — Blocking?**
$([ "${NEEDS_HUMAN:-0}" -gt 0 ] && echo "⚠️ Yes — $NEEDS_HUMAN needs-human issue(s):
$NH_LIST" || echo "✅ Nothing blocking")
$([ "$CI_RED" = "YES" ] && echo "🔴 Main branch CI is red" || true)
$([ -n "$COMPETITIVE_LINE" ] && echo "$COMPETITIVE_LINE" || true)"

gh issue comment "$REPORT_ISSUE" --repo "$REPO" --body "$REPORT_BODY" 2>/dev/null
echo "[SM §4b] Batch report posted"

# §4b-qa-rejection: QA rejection pattern tracker (design doc 38 §Future 38.6 → ✅)
# Detect feat/* branches closed without merging (QA rejection proxy).
# Record rejection type in state.json. Open issue if same type repeats 3+ times.
# Design ref: docs/design/38-qa-ci-gate.md §Future 38.6
python3 - <<'QA_REJECT_EOF'
import subprocess, json, os, re
REPO = os.environ.get('REPO', '')
try:
    prs = json.loads(subprocess.check_output(
        ['gh','pr','list','--repo',REPO,'--state','closed',
         '--search','head:feat/ NOT is:merged','--limit','10',
         '--json','number,title,headRefName,body'],
        text=True, timeout=15))
except Exception as e:
    print(f"[SM] qa-rejection error (non-fatal): {e}"); raise SystemExit(0)
if not prs: print("[SM] No unmerged feat/* PRs."); raise SystemExit(0)
REJECT_PATTERNS = [
    (r'spec.*missing|no spec', 'missing-spec'),
    (r'ci.*fail|build.*fail', 'ci-failure'),
    (r'merge.*conflict', 'merge-conflict'),
    (r'abandon|stale', 'abandoned'),
    (r'scope.*too|too.*large', 'scope-too-large'),
]
with open('.otherness/state.json') as f: s = json.load(f)
rejections = s.setdefault('qa_rejections', [])
for pr in prs:
    pr_num = str(pr['number'])
    if any(r.get('pr') == pr_num for r in rejections): continue
    body = pr.get('body', '') or ''
    reason = next((lbl for pat,lbl in REJECT_PATTERNS if re.search(pat,body,re.I)), 'unknown')
    rejections.append({'pr': pr_num, 'title': pr.get('title','?')[:60], 'reason': reason})
    rejections[:] = rejections[-20:]
    print(f"[SM] PR #{pr_num} closed unmerged, reason={reason}")
with open('.otherness/state.json', 'w') as f: json.dump(s, f, indent=2)
QA_REJECT_EOF

```

## 4b-skill-citation. Skill loading discipline check (design doc 31 §Future → ✅)

Verify ENG is actually loading skills before implementation, not just accumulating them.
Check the last 5 merged feat/* PRs — each must include a "Loaded skill:" line in the description.

```bash
python3 - <<'SKILL_CITE_EOF'
import subprocess, json, os, re

REPO = os.environ.get('REPO', '')

# Fail-open: if API unavailable or fewer than 5 PRs, skip silently
try:
    r = subprocess.run(
        ['gh', 'pr', 'list', '--repo', REPO, '--state', 'merged',
         '--limit', '20', '--json', 'title,body,headRefName'],
        capture_output=True, text=True, timeout=20)
    if r.returncode != 0:
        print("[SM §4b-skill-citation] gh pr list failed — skipping (fail-open).")
        raise SystemExit(0)
    prs = json.loads(r.stdout)
except SystemExit:
    raise
except Exception as e:
    print(f"[SM §4b-skill-citation] API error — skipping: {e}")
    raise SystemExit(0)

# Filter to feat/* PRs only
feat_prs = [pr for pr in prs
            if pr.get('headRefName', '').startswith('feat/') or
               pr.get('title', '').lower().startswith('feat(')]

if len(feat_prs) < 5:
    print(f"[SM §4b-skill-citation] Only {len(feat_prs)} feat PRs found (need 5) — skipping.")
    raise SystemExit(0)

last_5 = feat_prs[:5]
cited_count = sum(
    1 for pr in last_5
    if re.search(r'[Ll]oaded [Ss]kill:', pr.get('body', '') or '')
)

print(f"[SM §4b-skill-citation] Last 5 feat PRs: {cited_count}/5 cite a skill file.")

if cited_count < 3:
    ISSUE_TITLE = "chore(skills): skill loading discipline has drifted — ENG is not citing skill files"
    existing = subprocess.run(
        ['gh', 'issue', 'list', '--repo', REPO, '--state', 'open',
         '--search', 'skill loading discipline has drifted',
         '--json', 'number', '--jq', 'length'],
        capture_output=True, text=True, timeout=15)
    count = int(existing.stdout.strip() or '0')
    if count == 0:
        subprocess.run(
            ['gh', 'issue', 'create', '--repo', REPO,
             '--title', ISSUE_TITLE,
             '--label', 'otherness,kind/chore,priority/medium,area/skills',
             '--body', (
                 "## SM §4b-skill-citation finding\n\n"
                 f"Only {cited_count} of the last 5 `feat/*` PRs include a `Loaded skill:` line "
                 "in their description (threshold: 3/5).\n\n"
                 "Skills accumulate in `agents/skills/` but agents are not confirming which "
                 "skills they loaded before implementation. This makes skill accumulation "
                 "unverifiable.\n\n"
                 "## What to fix\n\n"
                 "ENG §2c requires listing the skill files checked and logging "
                 "`Loaded skill: \`<filename>\`` in the PR description.\n\n"
                 "Review recent PRs and ensure ENG includes this line going forward.\n\n"
                 "Design ref: docs/design/31-stage-2-skills-expansion.md §Future"
             )],
            capture_output=True, timeout=15)
        print(f"[SM §4b-skill-citation] Opened chore issue: skill loading discipline drifted ({cited_count}/5).")
    else:
        print("[SM §4b-skill-citation] Issue already open — not duplicating.")
else:
    print(f"[SM §4b-skill-citation] Skill loading discipline OK ({cited_count}/5 PRs cite a skill).")
SKILL_CITE_EOF
```


## 4c. Cross-project learning (if AUTONOMOUS_MODE and monitor.projects configured)

```bash
# Once per 5 SM cycles: mine closed needs-human issues across monitored projects
# for recurring patterns → write generic entries to difficulty-ledger.md
BATCH_COUNT=$(python3 -c "
import json
try:
    s = json.load(open('.otherness/state.json'))
    print(s.get('sm_cycle_count', 0))
except: print(0)
" 2>/dev/null || echo "0")

if [ $((${BATCH_COUNT:-0} % 5)) -eq 0 ] && [ "${BATCH_COUNT:-0}" -gt 0 ]; then
  echo "[SM §4c] Cross-project learning cycle (batch_count=$BATCH_COUNT)..."
  MONITOR_PROJECTS=$(python3 -c "
import re
in_monitor=in_projects=False
projects=[]
for line in open('otherness-config.yaml'):
    if re.match(r'^monitor:',line): in_monitor=True
    if in_monitor and re.match(r'\s+projects:',line): in_projects=True
    if in_projects:
        m=re.match(r'\s+-\s+(.+)',line)
        if m: projects.append(m.group(1).strip())
print(' '.join(projects))
" 2>/dev/null)
  for _PROJ in $MONITOR_PROJECTS; do
    [ -z "$_PROJ" ] && continue
    gh issue list --repo "$_PROJ" --label needs-human --state closed --limit 10       --json title --jq '.[].title' 2>/dev/null | while read _TITLE; do
        echo "[SM §4c] $PROJ: $_TITLE"
      done
  done
  # Schedule learn if patterns suggest novel failure class
  if ! gh issue list --repo "$REPO" --state open --search "skill:" --json number --jq 'length' 2>/dev/null | grep -q "^0$"; then
    echo "[SM §4c] Skill issues already open — no new issues needed."
  fi
fi
```

## 4c-skill. Skill confidence check (every 10 SM cycles)

```bash
if [ $((${BATCH_COUNT:-0} % 10)) -eq 0 ] && [ "${BATCH_COUNT:-0}" -gt 0 ]; then
  UNREFERENCED=$(for f in ~/.otherness/agents/skills/*.md; do
    base=$(basename "$f" .md)
    grep -rl "$base" ~/.otherness/agents/phases/ ~/.otherness/agents/standalone.md       2>/dev/null | grep -q . || echo "unreferenced: $base"
  done)
  [ -n "$UNREFERENCED" ] && echo "[SM §4c-skill] $UNREFERENCED" || echo "[SM §4c-skill] All skills referenced."
fi
```

## 4g. Codebase hygiene scan (every 3 SM cycles)

Runs dead code / stale file / stale doc checks. Opens `kind/chore` issues for cleanup.
Nothing is deleted autonomously. Cap: `max_issues_per_scan` new issues per run (default 3).
**Runs on every managed project generically** — not otherness-specific.

**Design ref**: `docs/design/29-continuous-code-hygiene.md`

```bash
HYGIENE_CFG=$(python3 -c "
import re
section=None; ivl='3'; enb='true'; mx='3'
for line in open('otherness-config.yaml'):
    s=re.match(r'^(\w[\w_]*):', line)
    if s: section=s.group(1)
    if section=='hygiene':
        m=re.match(r'\s+cycle_interval:\s*(\d+)',line)
        if m: ivl=m.group(1)
        m=re.match(r'\s+enabled:\s*(true|false)',line)
        if m: enb=m.group(1)
        m=re.match(r'\s+max_issues_per_scan:\s*(\d+)',line)
        if m: mx=m.group(1)
print(ivl,enb,mx)
" 2>/dev/null || echo "3 true 3")
HYGIENE_INTERVAL=$(echo $HYGIENE_CFG | cut -d' ' -f1)
HYGIENE_ENABLED=$(echo $HYGIENE_CFG | cut -d' ' -f2)
HYGIENE_MAX=$(echo $HYGIENE_CFG | cut -d' ' -f3)
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

## 4g-anchor. Anchor gap detection (periodic)

```bash
# Anchor checks (feature→anchor gap, parity, upstream version, score) fire when
# anchor.workflow_file is set in otherness-config.yaml AND the workflow exists.
ANCHOR_WORKFLOW=$(python3 -c "
import re
section=None
for line in open('otherness-config.yaml'):
    s=re.match(r'^(\w[\w_]*):', line)
    if s: section=s.group(1)
    if section=='anchor':
        m=re.match(r'\s+workflow_file:\s*(\S+)', line)
        if m: print(m.group(1)); break
" 2>/dev/null || echo "")

if [ -n "$ANCHOR_WORKFLOW" ] && [ -f ".github/workflows/$ANCHOR_WORKFLOW" ]; then
  echo "[SM §4g-anchor] Anchor workflow: $ANCHOR_WORKFLOW — gap detection active."
  # [AI-STEP] Read the anchor workflow output (from REPORT_ISSUE comments tagged [ANCHOR]).
  # Compare current coverage score to target in otherness-config.yaml anchor.coverage_target.
  # If gap > 5%: open kind/chore issue "anchor: cover <area>" (dedup guard).
else
  echo "[SM §4g-anchor] No anchor workflow configured — skipping."
fi
```

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
      # autonomous-vision.md removed in cleanup — vision synthesis now handled by
      # Step A (vibe-vision-auto.md) in the scheduled workflow. Nothing to do here.
      echo "[SM §4h] Vision synthesis handled by Step A. Skipping SM trigger."
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

# §4f: VISION_PR_COUNT — design-doc-backed PR check (design doc 35 §35.1 → ✅)
# For each PR merged this session, check if title or body references a design doc.
# A PR is "vision-aligned" if title or body (first 500 chars) contains:
#   docs/design/ OR 🔲 → OR design doc (case-insensitive)
# Excludes: chore(sm), chore(metrics), batch N, session complete PR titles.
VISION_PR_COUNT=$(python3 - <<'VPCEOF'
import subprocess, json, re, os, sys

REPO = os.environ.get('REPO', '')

EXCLUDE_PAT = re.compile(
    r'^chore\(sm\)|^chore\(metrics\)|batch\s+\d+|session complete|PRs merged', re.IGNORECASE)
VISION_PAT = re.compile(
    r'docs/design/|🔲\s*→|design doc', re.IGNORECASE)

# Get PRs merged in last 24h
try:
    from datetime import datetime, timezone, timedelta
    since = (datetime.now(timezone.utc) - timedelta(hours=24)).strftime('%Y-%m-%dT%H:%M:%SZ')
    r = subprocess.run(
        ['gh', 'pr', 'list', '--repo', REPO, '--state', 'merged', '--limit', '30',
         '--json', 'number,title,mergedAt'],
        capture_output=True, text=True, timeout=20)
    if r.returncode != 0:
        print('0'); sys.exit(0)
    prs = json.loads(r.stdout.strip() or '[]')
    # Filter to last 24h and non-excluded
    recent = [pr for pr in prs
              if pr.get('mergedAt', '') >= since
              and not EXCLUDE_PAT.match(pr.get('title', ''))]
except Exception as e:
    print(f'0', file=sys.stderr)
    print('0'); sys.exit(0)

count = 0
for pr in recent:
    title = pr.get('title', '')
    # Fast-path: check title first
    if VISION_PAT.search(title):
        count += 1
        continue
    # Body scan (first 500 chars)
    try:
        rb = subprocess.run(
            ['gh', 'pr', 'view', str(pr['number']), '--repo', REPO,
             '--json', 'body', '--jq', '.body'],
            capture_output=True, text=True, timeout=10)
        body = rb.stdout.strip()[:500] if rb.returncode == 0 else ''
        if VISION_PAT.search(body):
            count += 1
    except Exception:
        pass

print(count)
VPCEOF
)
export VISION_PR_COUNT
echo "[SM §4f §35.1] VISION_PR_COUNT=${VISION_PR_COUNT} (design-doc-backed PRs this session)"

# Write vision_aligned + consecutive_vision_misaligned to state.json
python3 - <<'VA_EOF'
import json, os, subprocess
VISION_PR_COUNT = int(os.environ.get('VISION_PR_COUNT', '0') or '0')
REPO = os.environ.get('REPO', ''); REPORT_ISSUE = os.environ.get('REPORT_ISSUE', '1')
try:
    with open('.otherness/state.json') as f: s = json.load(f)
    aligned = (VISION_PR_COUNT > 0)
    s['vision_aligned'] = aligned
    consec = 0 if aligned else s.get('consecutive_vision_misaligned', 0) + 1
    s['consecutive_vision_misaligned'] = consec
    with open('.otherness/state.json', 'w') as f: json.dump(s, f, indent=2)
    print(f"[SM §4f] vision_aligned={aligned} consec_misaligned={consec}")
    if consec >= 2 and REPO:
        r = subprocess.run(['gh','issue','list','--repo',REPO,'--state','open',
            '--search','Queue audit needed','--json','number','--jq','length'],
            capture_output=True, text=True, timeout=15)
        if int(r.stdout.strip() or '0') == 0:
            body = (f"SM: {consec} consecutive batches with vision_aligned=false. "
                    f"Queue may lack design-doc-backed items. Run /otherness.vibe-vision "
                    f"to refresh design docs, or review coord §1b vision pressure set.")
            subprocess.run(['gh','issue','create','--repo',REPO,
                '--title','Queue audit: vision_aligned=false for 2+ batches',
                '--label','kind/chore,priority/high,area/agent-loop,otherness',
                '--body',body], capture_output=True, timeout=15)
except Exception as e:
    print(f"[SM §4f] vision_aligned write failed (non-fatal): {e}")
VA_EOF
# Throughput signal: AMBER if session_outcome is chore-only OR VISION_PR_COUNT == 0 (design doc 35 §35.1)
if [ "${SESSION_OUTCOME:-unknown}" = "chore-only" ] || [ "${VISION_PR_COUNT:-0}" -eq 0 ]; then
  HEALTH="AMBER"
  # §4f §35.2: include actionable vision-misaligned note in health comment (design doc 35-vision-alignment-signal.md §35.2 → ✅)
  THROUGHPUT_WARN=" ⚠️ ${SESSION_OUTCOME:-chore-only} session (${VISION_PR_COUNT:-0} vision-aligned PRs). Queue may have drifted from design docs. Run /otherness.vibe-vision or check coord §1b."
fi

ACTION="Active"
[ "${TODO_COUNT:-0}" -lt 5 ] && ACTION="Refilling queue"
[ "${TODO_COUNT:-0}" -eq 0 ] && ACTION="Queue empty — running vision+learn"

# §4f: Condensed report format (design doc 35 §Future → ✅)
# Headline: Batch N | progress: X | health: X | Vision PRs: N | Chores: N | Queue: N remaining | Journeys: N✅ N❌ | Next: [title]
# Verbose details go into a <details> block. Human can scan 10 comments in 30 seconds.

# Two-axis progress classification — design doc 35 §Future → ✅
# progress: ADVANCING | STABLE | STALLED (session-based, not history-based)
# ADVANCING: ≥1 vision-aligned PR merged this session (product moved)
# STABLE:    0 vision PRs but ≥1 PR merged this session (chores only, nothing broke)
# STALLED:   0 merged PRs AND 0 open PRs (silent session — agent ran but nothing shipped)
# Exported as SESSION_PROGRESS for downstream use (O7).
# When STABLE or STALLED + HEALTH=GREEN: upgrade HEALTH to AMBER (O2).
OPEN_PRS_4F=$(gh pr list --repo $REPO --state open --json number --jq 'length' 2>/dev/null || echo "0")

# Guard: if MERGED is unset (§4f called standalone without §4b), recompute it.
# This prevents a false STALLED classification in standalone calls.
# Design ref: fix(sm) issue-702
if [ -z "${MERGED+x}" ] || [ -z "${MERGED}" ]; then
  echo "[SM §4f] MERGED unset — recomputing from gh pr list (standalone guard)"
  MERGED=$(gh pr list --repo $REPO --state merged --limit 30 \
    --json title,mergedAt \
    --jq "[.[] | select(
      (.title | test(\"^feat|^fix|^refactor\"; \"i\")) and
      (.title | test(\"^chore\\\\(sm\\\\)|metrics|session complete|PRs merged|batch \"; \"i\") | not)
    ) | .title] | length" 2>/dev/null || echo "0")
fi

# Guard: if VISION_PRS is unset, recompute it.
if [ -z "${VISION_PRS+x}" ] || [ -z "${VISION_PRS}" ]; then
  echo "[SM §4f] VISION_PRS unset — recomputing (standalone guard)"
  VISION_PRS=$(gh pr list --repo $REPO --state merged --limit 30 \
    --json title,mergedAt \
    --jq "[.[] | select(
      (.title | test(\"^feat|^fix|^refactor\"; \"i\")) and
      (.title | test(\"^chore\\\\(sm\\\\)|metrics|session complete|PRs merged|batch \"; \"i\") | not)
    ) | .title] | length" 2>/dev/null || echo "0")
fi

PROGRESS_CLASS=$(python3 -c "
import os
vision_prs = int(os.environ.get('VISION_PRS', '0') or '0')
merged = int(os.environ.get('MERGED', '0') or '0')
open_prs = int(os.environ.get('OPEN_PRS_4F', '0') or '0')
if vision_prs > 0:
    print('ADVANCING')
elif merged > 0:
    print('STABLE')
elif merged == 0 and open_prs == 0:
    print('STALLED')
else:
    print('STABLE')
" 2>/dev/null || echo "ADVANCING")
export SESSION_PROGRESS="${PROGRESS_CLASS}"
echo "[SM §4f] progress=${PROGRESS_CLASS} (vision_prs=${VISION_PRS:-0} merged=${MERGED:-0} open=${OPEN_PRS_4F})"

# O2: STABLE or STALLED + GREEN → upgrade to AMBER
# A non-advancing system must never show GREEN to the human.
if [ "${PROGRESS_CLASS}" = "STABLE" ] || [ "${PROGRESS_CLASS}" = "STALLED" ]; then
  if [ "${HEALTH:-GREEN}" = "GREEN" ]; then
     HEALTH="AMBER"
     echo "[SM §4f] Health upgraded GREEN→AMBER: progress=${PROGRESS_CLASS}"
   fi
fi

# §4f: 0-meaningful-PRs honesty gate (design doc 21 §Future → ✅)
# If MEANINGFUL_PRS == 0 AND HEALTH is still GREEN: upgrade to AMBER.
# GREEN must mean "shipped real work" — not just "CI passed and queue was non-empty."
# Does not override RED. Fail-open: unset MEANINGFUL_PRS treated as non-zero.
_MEANINGFUL_WARN=""
if [ "${MEANINGFUL_PRS:-1}" = "0" ] && [ "${HEALTH:-GREEN}" = "GREEN" ]; then
  HEALTH="AMBER"
  _MEANINGFUL_WARN="⚠️ AMBER — 0 meaningful PRs this session (chore-only or zero-ship)"
  echo "[SM §4f] Health GREEN→AMBER: MEANINGFUL_PRS=0"
fi

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
# Fix issue-664: if no ## headers contain ✅/❌, show ? instead of 0
JOURNEY_OK=$(python3 -c "
import re
try:
    content = open('docs/aide/definition-of-done.md').read()
    # Count journey sections marked ✅ in their header or body
    sections = re.findall(r'^##\s+.+', content, re.MULTILINE)
    ok = sum(1 for s in sections if '✅' in s)
    fail = sum(1 for s in sections if '❌' in s)
    # If file exists but no sections have markers at all, data is unavailable
    if sections and ok == 0 and fail == 0:
        print('?')
    else:
        print(ok)
except: print('?')
" 2>/dev/null || echo "?")

JOURNEY_FAIL=$(python3 -c "
import re
try:
    content = open('docs/aide/definition-of-done.md').read()
    sections = re.findall(r'^##\s+.+', content, re.MULTILINE)
    ok = sum(1 for s in sections if '✅' in s)
    fail = sum(1 for s in sections if '❌' in s)
    # If file exists but no sections have markers at all, data is unavailable
    if sections and ok == 0 and fail == 0:
        print('?')
    else:
        print(fail)
except: print('?')
" 2>/dev/null || echo "?")

# Read dual improvement rates from state.json (written by PM §5n each batch)
SELF_FEAT_PRS=$(python3 -c "
import json
try:
    s = json.load(open('.otherness/state.json'))
    print(s.get('self_feat_prs_7d', '?'))
except: print('?')
" 2>/dev/null || echo "?")
MANAGED_FEAT_PRS=$(python3 -c "
import json
try:
    s = json.load(open('.otherness/state.json'))
    print(s.get('managed_feat_prs_7d', '?'))
except: print('?')
" 2>/dev/null || echo "?")

# §4f: Managed project velocity gate (design doc 16 §Future → ✅)
# GREEN requires BOTH self-progress AND managed project velocity.
# If managed project has shipped 0 feat/fix/refactor PRs in 14 days → AMBER.
# Fail-open: API errors or missing config leave HEALTH unchanged.
# Refactored (issue-790): single python block — no duplicate API call.
MANAGED_VELOCITY_WARN=""
MANAGED_VELOCITY_LABEL=""
_MGMT_OUTPUT=$(python3 - <<'MGMT_VEL_EOF'
import subprocess, re, os, sys, datetime

REPO = os.environ.get('REPO', '')
HEALTH_IN = os.environ.get('HEALTH', 'GREEN')

ref_project = None
try:
    in_monitor = in_projects = False
    for line in open('otherness-config.yaml'):
        if re.match(r'^monitor:', line): in_monitor = True
        if in_monitor and re.match(r'\s+projects:', line): in_projects = True
        if in_projects:
            m = re.match(r'\s+- (.+)', line)
            if m:
                r = m.group(1).strip()
                if not r.endswith('/otherness'):
                    ref_project = r
                    break
except Exception:
    pass

if not ref_project:
    print('[SM §4f] No reference project found — skipping managed velocity check.')
    sys.exit(0)

try:
    since_dt = (datetime.datetime.now(datetime.timezone.utc) -
                datetime.timedelta(days=14)).strftime('%Y-%m-%dT%H:%M:%SZ')
    r = subprocess.run(
        ['gh', 'pr', 'list', '--repo', ref_project, '--state', 'merged',
         '--limit', '100', '--json', 'title,mergedAt',
         '--jq', f'[.[] | select(.mergedAt >= "{since_dt}") | select(.title | test("^feat|^fix|^refactor"; "i"))] | length'],
        capture_output=True, text=True, timeout=15)
    if r.returncode != 0:
        print(f'[SM §4f] Managed velocity API error (non-fatal): {r.stderr.strip()[:80]}')
        sys.exit(0)
    count = int(r.stdout.strip() or '0')
    label = f'{count} feat PRs/14d (reference: {ref_project})'
    print(f'[SM §4f] Managed velocity: {label}')
    # Output env var markers for bash to parse
    print(f'MANAGED_VELOCITY_LABEL={label}')
    if count == 0 and HEALTH_IN == 'GREEN':
        print(f'MANAGED_VELOCITY_WARN= ⚠️ Managed stalled (0 feat PRs/14d: {ref_project})')
        print('MANAGED_HEALTH_DOWNGRADE=AMBER')
except Exception as e:
    print(f'[SM §4f] Managed velocity check error (non-fatal): {e}')
MGMT_VEL_EOF
2>/dev/null)

# Apply env vars from python output
while IFS='=' read -r _KEY _VAL; do
    case "$_KEY" in
        MANAGED_VELOCITY_LABEL) MANAGED_VELOCITY_LABEL="$_VAL" ;;
        MANAGED_VELOCITY_WARN)  MANAGED_VELOCITY_WARN="$_VAL" ;;
        MANAGED_HEALTH_DOWNGRADE)
            if [ "$_VAL" = "AMBER" ] && [ "${HEALTH:-GREEN}" = "GREEN" ]; then
                HEALTH="AMBER"
                echo "[SM §4f] Health GREEN→AMBER: managed project velocity=0 feat PRs/14d"
            fi ;;
    esac
done <<< "$_MGMT_OUTPUT"

# §4f: Metrics trend surfacing (design doc 33 §Future → ✅)
METRICS_TREND=$(python3 - <<'TREND_EOF'
import re, os

try:
    content = open('docs/aide/metrics.md').read()
    rows = [l for l in content.splitlines() if re.match(r'^\|\s*20', l)]
    if len(rows) < 2:
        raise ValueError("insufficient data")
    
    def _col(row, idx):
        cells = [c.strip() for c in row.split('|') if c.strip()]
        return float(cells[idx]) if idx < len(cells) and cells[idx].replace('.','').isdigit() else None
    
    # TTM trend (col 8), NH trend (col 3)
    trends = []
    for col, name in [(8, 'ttm'), (3, 'nh')]:
        vals = [_col(r, col) for r in rows[-5:] if _col(r, col) is not None]
        if len(vals) >= 2:
            direction = 'improving' if vals[-1] < vals[0] else 'worsening'
            trends.append(f'{name}: {direction} ({vals[-1]:.0f}←{vals[0]:.0f})')
    
    print(', '.join(trends) if trends else '')
except Exception:
    print('')
TREND_EOF
)
export METRICS_TREND

# §4f: Consecutive worsening detection → open kind/chore priority/high issue after 3 batches
# State: consecutive_worsening_ttm, consecutive_worsening_nh in state.json
try:
    with open('.otherness/state.json') as f: s = json.load(f)
except Exception:
    s = {}

def update_worsening(s, key, trend_str, metric_label):
    """Increment worsening counter if bad trend, reset if not. Open issue at streak=3."""
    is_bad = 'trend: bad' in trend_str if trend_str else False
    current = s.get(key, 0)
    new_val = current + 1 if is_bad else 0
    s[key] = new_val
    if new_val >= 3:
        # Open an issue (dedup guard)
        title = f'SM trend alert: {metric_label} worsening for 3 consecutive batches'
        try:
            r = subprocess.run(
                ['gh', 'issue', 'list', '--repo', REPO, '--state', 'open',
                 '--search', title[:60], '--json', 'number', '--jq', 'length'],
                capture_output=True, text=True, timeout=15)
            if int(r.stdout.strip() or '0') == 0:
                body = (
                    f'## SM Trend Alert\n\n'
                    f'`{metric_label}` has been worsening for {new_val} consecutive batches.\n\n'
                    f'Last trend reading: `{trend_str}`\n\n'
                    f'## Actions\n'
                    f'1. Inspect `docs/aide/metrics.md` for the last {new_val} rows\n'
                    f'2. Identify root cause: slow CI? blocked items? escalations?\n'
                    f'3. Open a targeted fix issue if root cause is identified\n\n'
                    f'Reported by SM §4f | {MY_SESSION_ID} | otherness@{OTHERNESS_VERSION}'
                )
                cr = subprocess.run(
                    ['gh', 'issue', 'create', '--repo', REPO,
                     '--title', title,
                     '--label', 'kind/chore,priority/high,area/agent-loop,otherness',
                     '--body', body],
                    capture_output=True, text=True, timeout=15)
                if cr.returncode == 0:
                    print(f'[SM §4f] Trend alert issue opened for {metric_label}: {cr.stdout.strip().split(chr(10))[-1]}',
                          file=__import__('sys').stderr)
        except Exception as e:
            pass  # fail-open
    return new_val

update_worsening(s, 'consecutive_worsening_ttm', ttm_trend, 'time-to-merge')
update_worsening(s, 'consecutive_worsening_nh',  nh_trend,  'needs-human')

try:
    with open('.otherness/state.json', 'w') as f: json.dump(s, f, indent=2)
except Exception:
    pass

print('\n'.join(trend_lines))
TREND_EOF
)

# §4f: Structured health table (design doc 39 §39.1 → ✅)
# Replace verbose prose comment with a scannable markdown table (≤12 lines).
# All previous signals preserved; format changed to table. Human can read in 30 seconds.
_HEALTH_ICON=$([ "${HEALTH:-GREEN}" = "GREEN" ] && echo "🟢" || ([ "${HEALTH:-GREEN}" = "AMBER" ] && echo "🟡" || echo "🔴"))
_LAST_PR_TITLE=$(gh pr list --repo $REPO --state merged --limit 1 --json title --jq '.[0].title' 2>/dev/null | head -c 50)
_LAST_PR_DISPLAY="${_LAST_PR_TITLE:-none}"
_VISION_RATIO=$(python3 -c "
merged=int('${MERGED:-0}' or '0')
vision=int('${VISION_PRS:-0}' or '0')
if merged>0: print(f'{vision}/{merged} ({vision*100//merged}%)')
else: print('0/0')
" 2>/dev/null || echo "${VISION_PRS:-0}/${MERGED:-0}")

# §4f: Skills and learn-date signal (design doc 31 §Future → ✅)
# Compute skills_count (*.md in agents/skills/ excl. README, PROVENANCE) and
# last learn date from PROVENANCE.md. Fail-open on any read error.
_SKILLS_LEARN=$(python3 - <<'SKILLS_EOF'
import re, os, datetime

# skills_count: *.md files in agents/skills/ excluding README.md and PROVENANCE.md
skills_dir = os.path.expanduser('~/.otherness/agents/skills')
try:
    files = [f for f in os.listdir(skills_dir)
             if f.endswith('.md') and f not in ('README.md', 'PROVENANCE.md')]
    skills_count = len(files)
except Exception:
    skills_count = '?'

# Last learn date: most recent ## YYYY-MM-DD header in PROVENANCE.md
provenance_path = os.path.join(skills_dir, 'PROVENANCE.md')
last_learn_date = None
try:
    with open(provenance_path) as f:
        for line in f:
            m = re.match(r'^## (\d{4}-\d{2}-\d{2})', line)
            if m:
                d = m.group(1)
                if last_learn_date is None or d > last_learn_date:
                    last_learn_date = d
except Exception:
    pass

# Color-code the learn date
if last_learn_date:
    try:
        learn_dt = datetime.date.fromisoformat(last_learn_date)
        age_days = (datetime.date.today() - learn_dt).days
        if age_days < 14:
            color = '🟢'
        elif age_days <= 30:
            color = '🟡'
        else:
            color = '🔴'
        learn_label = f'{color} {last_learn_date} ({age_days}d ago)'
    except Exception:
        learn_label = last_learn_date
else:
    learn_label = 'unknown'

print(f'SKILLS_COUNT={skills_count}')
print(f'LAST_LEARN={learn_label}')
SKILLS_EOF
)
SKILLS_COUNT=$(echo "$_SKILLS_LEARN" | grep '^SKILLS_COUNT=' | cut -d= -f2-)
LAST_LEARN=$(echo "$_SKILLS_LEARN" | grep '^LAST_LEARN=' | cut -d= -f2-)

# §36.5 Vision pressure utilisation — design doc 36 §36.5 → ✅
# Display vision-backed claims ratio in health comment.
# VISION_BACKED_CLAIMS_THIS_SESSION and TOTAL_CLAIMS_THIS_SESSION set by COORD §36.5.
# Fail-open: if either unset, display "?/? (untracked)".
_VPS_UTIL=$(python3 -c "
import os
backed = os.environ.get('VISION_BACKED_CLAIMS_THIS_SESSION', '')
total = os.environ.get('TOTAL_CLAIMS_THIS_SESSION', '')
if backed == '' or total == '':
    print('?/? (untracked)')
else:
    b = int(backed or '0')
    t = int(total or '0')
    pct = f' ({b*100//t}%)' if t > 0 else ''
    print(f'{b}/{t}{pct}')
" 2>/dev/null || echo "?/? (untracked)")

REPORT_BODY=$(cat <<BODY_EOF
## otherness health — batch ${SM_CYCLE:-?}

| Signal | Value | Note |
|---|---|---|
| Health | ${_HEALTH_ICON} ${HEALTH:-GREEN} | ${PROGRESS_CLASS:-ADVANCING} |
| Batch | #${SM_CYCLE:-?} | session: \`${MY_SESSION_ID:-?}\` |
| PRs shipped | ${MEANINGFUL_PRS:-0} meaningful (${MERGED:-0} total) | vision ${_VISION_RATIO} |
| Queue | ${TODO_COUNT:-0} todo | in-review: ${IN_REVIEW:-0} |
| Last PR | ${_LAST_PR_DISPLAY} | |
 | Skills | ${SKILLS_COUNT:-?} skill files | last learn: ${LAST_LEARN:-unknown} |
 | Needs-human | ${NEEDS_HUMAN_COUNT:-0} open | ${ACTION:-continue} |
 | Managed | ${MANAGED_VELOCITY_LABEL:-unknown} | ${MANAGED_VELOCITY_WARN:-} |
 | Vision pressure | ${_VPS_UTIL} vision-backed claims | session |
${_MEANINGFUL_WARN:+| Honesty gate | ${_MEANINGFUL_WARN} | |
}${METRICS_TREND:+
> ${METRICS_TREND}}
BODY_EOF
)

gh issue comment $REPORT_ISSUE --repo $REPO --body "$REPORT_BODY" 2>/dev/null

# §4f: Silent-session detection (design doc 35 §Future → ✅)
# A silent session: 0 PRs merged AND 0 open PRs. Streak >= 2 → escalate.
OPEN_PRS=$(gh pr list --repo $REPO --state open --json number --jq 'length' 2>/dev/null || echo "0")
python3 - <<'SILENT_EOF'
import json, os, subprocess
REPO = os.environ.get('REPO', ''); MERGED = int(os.environ.get('MERGED', '0') or '0')
OPEN_PRS = int(os.environ.get('OPEN_PRS', '0') or '0')
REPORT_ISSUE = os.environ.get('REPORT_ISSUE', '1')
MY_SESSION_ID = os.environ.get('MY_SESSION_ID', 'sess-unknown')
OTHERNESS_VERSION = os.environ.get('OTHERNESS_VERSION', 'unknown')
try:
    with open('.otherness/state.json') as f: s = json.load(f)
    is_silent = (MERGED == 0 and OPEN_PRS == 0)
    current = s.get('consecutive_silent_sessions', 0)
    new_count = current + 1 if is_silent else 0
    s['consecutive_silent_sessions'] = new_count
    with open('.otherness/state.json', 'w') as f: json.dump(s, f, indent=2)
    if is_silent: print(f'[SM §4f] Silent session. streak={new_count}')
    if new_count >= 2:
        r = subprocess.run(['gh','issue','list','--repo',REPO,'--state','open',
            '--search','Silent session streak','--json','number','--jq','length'],
            capture_output=True, text=True, timeout=15)
        if int(r.stdout.strip() or '0') == 0:
            subprocess.run(['gh','issue','create','--repo',REPO,
                '--title','[NEEDS HUMAN] Silent session streak: 2+ sessions with 0 PRs',
                '--label','needs-human,priority/high,area/agent-loop,otherness',
                '--body',f'SM: {new_count} consecutive silent sessions (0 merged, 0 open PRs).\nAgent may be stalled. Session: {MY_SESSION_ID} | otherness@{OTHERNESS_VERSION}'],
                capture_output=True, timeout=15)
except Exception as e: print(f'[SM §4f] Silent session error (non-fatal): {e}')
SILENT_EOF
# Runs every batch — always reflects current reality, not stale history.
python3 - <<'PROGRESS_EOF'
import subprocess, json, os, re, datetime

REPO = os.environ.get('REPO', ''); HEALTH = os.environ.get('HEALTH', 'GREEN')
TODO_COUNT = os.environ.get('TODO_COUNT', '0'); IN_REVIEW = os.environ.get('IN_REVIEW', '0')
VISION_PRS = os.environ.get('VISION_PRS', '0'); SM_CYCLE = os.environ.get('SM_CYCLE', '?')
OTHERNESS_VERSION = os.environ.get('OTHERNESS_VERSION', 'unknown')
progress_path = 'docs/aide/progress.md'
if not os.path.exists(progress_path):
    print(f"[SM] {progress_path} not found — skipping"); exit(0)
last_pr_title = '(none)'; last_pr_date = ''
try:
    r = subprocess.run(['gh','pr','list','--repo',REPO,'--state','merged','--limit','20',
        '--json','title,mergedAt','--jq',
        '[.[]|select(.title|test("^feat|^fix|^refactor";"i"))|select(.title|test("^chore\\\\(sm\\\\)|metrics|session complete";"i")|not)][0]'],
        capture_output=True, text=True, timeout=15)
    if r.returncode==0 and r.stdout.strip() not in ('','null'):
        pr=json.loads(r.stdout.strip()); last_pr_title=pr.get('title','?')[:80]; last_pr_date=pr.get('mergedAt','')[:10]
except Exception: pass
today = datetime.date.today().isoformat()
health_icon = {'GREEN':'🟢','RED':'🔴'}.get(HEALTH,'🟡')
try:
    content = open(progress_path).read()
    header = (f"# otherness: Current Progress\n\n"
              f"> Updated by SM every batch. Last: {today}\n\n"
              f"## Current State\n\n"
              f"- **Health**: {health_icon} {HEALTH}\n"
              f"- **Last shipped**: {last_pr_title}{' (' + last_pr_date + ')' if last_pr_date else ''}\n"
              f"- **Queue depth**: {TODO_COUNT} todo, {IN_REVIEW} in_review\n"
              f"- **Vision PRs this batch**: {VISION_PRS}\n"
              f"- **SM cycle**: {SM_CYCLE} | otherness@{OTHERNESS_VERSION}\n")
    m = re.search(r'^## (Stage Completion|Stage [0-9]|Key milestones)', content, re.MULTILINE)
    new_content = header + '\n' + content[m.start():] if m else header + '\n' + content
    open(progress_path,'w').write(new_content)
    print(f"[SM] progress.md: {HEALTH} | queue={TODO_COUNT}")
except Exception as e: print(f"[SM] progress.md error (non-fatal): {e}")
PROGRESS_EOF


# §4f: README "Last shipped" line update (design doc 06 §Future → ✅)
# Update README.md with the most recent non-chore merged PR title and date.
# Idempotent: replaces existing "Last shipped:" line.
python3 - <<'README_SHIPPED_EOF'
import subprocess, json, os, re
REPO = os.environ.get('REPO', '')
EXCL = re.compile(r'^chore\(sm\)|^chore\(metrics\)|^chore\(readme\)|batch\s+\d+|session complete|PRs merged', re.I)
try:
    r = subprocess.run(['gh','pr','list','--repo',REPO,'--state','merged','--limit','20',
        '--json','number,title,mergedAt'],capture_output=True,text=True,timeout=15)
    prs = [p for p in json.loads(r.stdout or '[]') if not EXCL.match(p.get('title',''))]
    if not prs: print('[SM] No non-chore PR — skipping README update.'); exit(0)
    lp=prs[0]; line=f'**Last shipped:** {lp["title"]} (#{lp["number"]}, {lp.get("mergedAt","")[:10]})'
    readme = open('README.md').read()
    new_readme = re.sub(r'\*\*Last shipped:\*\*.*', line, readme)
    if new_readme == readme: new_readme = readme.rstrip() + f'\n\n{line}\n'
    open('README.md','w').write(new_readme)
    print(f'[SM] README.md: {lp["title"][:60]}')
except Exception as e: print(f'[SM] README update error (non-fatal): {e}')
README_SHIPPED_EOF

```

---

## 4f-integrity. Design doc integrity spot-check (every 5 SM batches)

```bash
if [ $((${SM_CYCLE:-0} % 5)) -eq 0 ] && [ "${SM_CYCLE:-0}" -gt 0 ]; then
  echo "[SM §4f-integrity] Running design doc integrity check..."
  python3 - <<'INTEGRITY_EOF'
import re, os, subprocess

REPO = os.environ.get('REPO', '')
design_dir = 'docs/design'
if not os.path.isdir(design_dir):
    print("[SM §4f-integrity] No docs/design/ — skipping.")
else:
    for fname in sorted(os.listdir(design_dir)):
        if not fname.endswith('.md'): continue
        content = open(f'{design_dir}/{fname}').read()
        present = re.findall(r'✅ (.+)', content)
        for item in present:
            desc = re.sub(r'\s*\(PR.*\)', '', item).strip().lower()[:60]
            r = subprocess.run(['gh','pr','list','--repo',REPO,'--state','merged',
                                '--search',desc,'--json','number','--jq','length'],
                               capture_output=True, text=True)
            count = int(r.stdout.strip() or '0')
            if count == 0:
                print(f"[SM §4f-integrity] ⚠️ No merged PR for ✅ {fname}: {item[:60]}")
INTEGRITY_EOF
fi
```

## 4g. Merge session branch PR (opencode/* branches only)

When the agent runs via GitHub Actions, OpenCode creates a PR from the session branch
(`opencode/schedule-*` or `opencode/dispatch-*`) to `main`. This branch accumulates
session-level changes (state.json, metrics.md, command file syncs) that must land on main.
Without this step these PRs pile up open indefinitely.

```bash
# Detect if running on an opencode/* session branch
SESSION_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
# Detached HEAD in GitHub Actions runner — fall back to GITHUB_HEAD_REF
if [ -z "$SESSION_BRANCH" ] || [ "$SESSION_BRANCH" = "HEAD" ]; then
  SESSION_BRANCH="${GITHUB_HEAD_REF:-}"
fi
# Final fallback: parse from GITHUB_REF (refs/heads/opencode/schedule-...)
if [ -z "$SESSION_BRANCH" ] || [ "$SESSION_BRANCH" = "HEAD" ]; then
  SESSION_BRANCH=$(echo "${GITHUB_REF:-}" | sed 's|refs/heads/||')
fi

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
