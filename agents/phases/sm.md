
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

## 4e. Divergence detection (every SM cycle)

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

## 4g. Codebase hygiene scan (every 20 SM cycles)

Check whether non-trivial agent and script files have design doc coverage.
Opens `kind/chore` issues for files with no coverage. Nothing deleted autonomously.
**Runs on every managed project generically** — not otherness-specific.

```bash
if [ $((SM_CYCLE % 20)) -eq 0 ] && [ "${SM_CYCLE:-0}" -gt 0 ]; then
  echo "[SM §4g] Running codebase hygiene scan..."

  if [ ! -d "docs/design" ] || [ -z "$(ls docs/design/*.md 2>/dev/null)" ]; then
    echo "[SM §4g] No design docs — skipping hygiene scan."
  else
    python3 - <<'PYEOF'
import re, os, subprocess, json

REPO = os.environ.get('REPO', '')

# Step 1: Build coverage set from all design docs
covered_terms = set()
for fname in os.listdir('docs/design'):
    if not fname.endswith('.md'): continue
    try:
        content = open(f'docs/design/{fname}').read()
        # Extract words from Present and Future item lines
        items = re.findall(r'^- [✅🔲⚠️].+', content, re.MULTILINE)
        for item in items:
            words = re.findall(r'[a-z][a-z0-9_-]{3,}', item.lower())
            covered_terms.update(words)
    except: pass

# Step 2: Determine scan targets based on project type
scan_targets = []
# Agent files (otherness-specific)
if os.path.isdir('agents'):
    for f in os.listdir('agents'):
        if f.endswith('.md') and f not in ('PROVENANCE.md', 'README.md'):
            scan_targets.append(f'agents/{f}')

# Command files
if os.path.isdir('.opencode/command'):
    for f in os.listdir('.opencode/command'):
        if f.endswith('.md'): scan_targets.append(f'.opencode/command/{f}')

# Scripts
for d in ['scripts']:
    if os.path.isdir(d):
        for f in os.listdir(d):
            if f.endswith(('.sh','.py')) and 'template' not in f:
                scan_targets.append(f'{d}/{f}')

# Step 3: Check coverage for each file
uncovered = 0

def issue_exists(title_frag):
    r = subprocess.run(['gh','issue','list','--repo',REPO,'--state','open',
        '--search',title_frag[:60],'--json','number'],
        capture_output=True, text=True)
    try: return len(json.loads(r.stdout)) > 0
    except: return True  # safe default

for filepath in scan_targets:
    if not os.path.exists(filepath): continue
    if os.path.getsize(filepath) == 0: continue
    basename = re.sub(r'\.(md|sh|py)$','', os.path.basename(filepath)).lower()
    basename = re.sub(r'[^a-z0-9]','-',basename)
    # Check if any design doc covers this file by name
    name_words = re.findall(r'[a-z][a-z0-9]{2,}', basename)
    if any(w in covered_terms for w in name_words):
        continue  # covered
    # Not covered — open issue
    title = f'chore: uncovered file — {filepath} has no design doc entry'
    if not issue_exists(title[:55]):
        subprocess.run(['gh','issue','create','--repo',REPO,
            '--title', title,
            '--label', 'kind/chore,priority/low,size/xs',
            '--body', f'SM §4g codebase hygiene scan found `{filepath}` with no corresponding ✅ Present or 🔲 Future entry in any docs/design/*.md file.\n\nOptions:\n1. Add a design doc entry documenting this file''s purpose\n2. Delete the file if it is no longer needed\n\nNothing has been deleted. This issue is a candidate for human decision.'],
            capture_output=True)
        uncovered += 1

print(f'[SM §4g] Codebase hygiene scan complete. {uncovered} uncovered files found.')
PYEOF
  fi

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
# Compute health signal before posting
# [AI-STEP]
# HEALTH="GREEN"
# CI_STATUS=$(gh run list --repo $REPO --branch main --limit 1 --json conclusion --jq '.[0].conclusion' 2>/dev/null)
# [ "$CI_STATUS" != "success" ] && HEALTH="AMBER"
# NEEDS_HUMAN_COUNT=$(gh issue list --repo $REPO --label needs-human --state open --json number --jq 'length' 2>/dev/null || echo 0)
# [ "${NEEDS_HUMAN_COUNT:-0}" -gt 0 ] && HEALTH="AMBER"
# JOURNEYS_PASS=$(bash scripts/test.sh 2>/dev/null && echo "✅" || echo "❌")
# [ "$JOURNEYS_PASS" = "❌" ] && HEALTH="AMBER"
# TODO_COUNT=$(python3 -c "import json; s=json.load(open('.otherness/state.json')); print(len([d for d in s.get('features',{}).values() if d.get('state')=='todo']))" 2>/dev/null || echo 0)
# IN_REVIEW=$(python3 -c "import json; s=json.load(open('.otherness/state.json')); print(len([d for d in s.get('features',{}).values() if d.get('state')=='in_review']))" 2>/dev/null || echo 0)
# ACTION="Active"
# [ "${TODO_COUNT:-0}" -eq 0 ] && ACTION="Standby"

gh issue comment $REPORT_ISSUE --repo $REPO \
  --body "[🔄 SDM | ${MY_SESSION_ID:-sess-unknown} | otherness@${OTHERNESS_VERSION:-unknown}] Batch ${SM_CYCLE:-?} complete. Health: ${HEALTH:-GREEN} | Queue: ${TODO_COUNT:-0} todo ${IN_REVIEW:-0} in_review | Action: ${ACTION:-Active}" 2>/dev/null
```
