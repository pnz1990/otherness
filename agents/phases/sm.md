
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
    if python3 scripts/calibrate.py --runs 3 --cycles 50 2>/dev/null; then
        echo "[SM §4d] Calibration complete — sim-params.json updated."

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
        ALARM=$(python3 -c "print('true' if float('$ARCH_CONV') > 0.7 else 'false')" 2>/dev/null || echo "false")
        if [ "$ALARM" = "true" ]; then
            echo "[SM §4d] ⚠ Architectural monoculture detected (arch_convergence=$ARCH_CONV > 0.7)"
            gh issue create --repo "$REPO" \
              --title "[NEEDS HUMAN] Architectural monoculture detected (arch_convergence=$ARCH_CONV)" \
              --label "needs-human,area/agent-loop" \
              --body "## Simulation calibration signal

The SM phase simulation calibration (sm_cycle=$SM_CYCLE) detected mean_arch_convergence > 0.7.

This means agents are proposing items of the same structural type repeatedly — a sign
of architectural frame-lock rather than genuine exploration.

**arch_convergence:** $ARCH_CONV (threshold: 0.7)

## Recommended actions (choose one)
- Run \`/otherness.learn\` to inject novel patterns from external repos
- Run \`/otherness.vibe-vision\` to introduce new architectural direction
- Review the last 5 shipped items — are they all the same type of change?

The system will not take autonomous action. This is for your awareness." 2>/dev/null \
              && echo "[SM §4d] needs-human issue opened." \
              || echo "[SM §4d] Could not open needs-human issue."
        fi
    else
        echo "[SM §4d] Calibration skipped (calibrate.py not available or failed)."
    fi
else
    echo "[SM §4d] Calibration skipped (sm_cycle=$SM_CYCLE, next at $((((SM_CYCLE / 10) + 1) * 10)))."
fi
```

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
gh issue comment $REPORT_ISSUE --repo $REPO \
  --body "[🔄 SDM | ${MY_SESSION_ID:-sess-unknown} | otherness@${OTHERNESS_VERSION:-unknown}] Batch complete. Metrics updated. Triage done." 2>/dev/null
```
