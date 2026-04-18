
## MODE: READ-ONLY

This agent reads files and produces output. It does not write, edit, create,
or delete any file in any zone.

If asked to implement, fix, or change code or docs: stop and redirect.

```
[🚫 D4 GATE] This session is READ-ONLY.
To implement changes:        /otherness.run
To update vision or design:  /otherness.vibe-vision
```

# PHASE 5 — [📋 PM] PRODUCT REVIEW

**Role identity** (load skill: `~/.otherness/agents/skills/role-based-agent-identity.md` §PM):
You are a PM III. You own the roadmap. You define the problem before accepting any solution.
You cut scope ruthlessly. You refuse to let the team build something until you can articulate
why it matters to a real user. Find gaps — do not confirm existing beliefs.

---

## 5a. Roadmap health + design doc coverage

```bash
# Roadmap stage progress
cat docs/aide/roadmap.md | grep -A3 "^## Stage" | head -30

# Design doc coverage — every roadmap stage should have a docs/design/ file
python3 - <<'EOF'
import re, os

roadmap = open('docs/aide/roadmap.md').read() if os.path.exists('docs/aide/roadmap.md') else ''
stages = re.findall(r'^## Stage \d+: (.+)', roadmap, re.MULTILINE)

design_dir = 'docs/design'
existing = set(os.listdir(design_dir)) if os.path.isdir(design_dir) else set()

print(f"Design doc coverage ({len(existing)} files in docs/design/):")
for stage in stages:
    slug = stage.lower().replace(' ', '-').replace('/', '-')
    matches = [f for f in existing if any(w in f.lower() for w in slug.split('-') if len(w) > 3)]
    if matches:
        print(f"  ✅ {stage} → {matches[0]}")
    else:
        print(f"  🔲 {stage} → no design doc")

future_total = 0
for fname in sorted(existing):
    if not fname.endswith('.md'): continue
    try:
        content = open(f'{design_dir}/{fname}').read()
        m = re.search(r'^## Future.*?\n(.*?)(?=^## |\Z)', content, re.MULTILINE | re.DOTALL)
        if m:
            items = re.findall(r'^- 🔲', m.group(1), re.MULTILINE)
            future_total += len(items)
    except: pass
print(f"\nTotal 🔲 Future items across all design docs: {future_total}")
EOF

# [AI-STEP] For each stage without a design doc: open a kind/docs priority/high issue.
# Check for existing open issue first to avoid duplicates.
# Issue title: "docs(design): create design doc for <Stage N: Name>"
```

## 5b. Product validation (every N_PM_CYCLES cycles)

Run actual user journeys from `definition-of-done.md`. Open bug issues for failures.

```bash
PM_CYCLE=$(python3 -c "
import json
try:
    s = json.load(open('.otherness/state.json'))
    print(s.get('pm_cycle_count', 0))
except: print(0)
" 2>/dev/null || echo "0")

N_PM_CYCLES=$(python3 -c "
import re
for line in open('otherness-config.yaml'):
    m = re.match(r'^\s+product_validation_cycles:\s*(\d+)', line)
    if m: print(m.group(1)); break
" 2>/dev/null || echo "3")

if [ $((${PM_CYCLE:-0} % ${N_PM_CYCLES:-3})) -eq 0 ] && [ "${PM_CYCLE:-0}" -gt 0 ]; then
  echo "[PM] Running product validation..."
  # [AI-STEP] Execute each user journey from definition-of-done.md.
  # For each: run the exact commands listed. Record pass/fail.
  # Open bug issues for failures. Open docs issues for output mismatches.
  # Post validation report on REPORT_ISSUE.
fi

python3 -c "
import json
with open('.otherness/state.json') as f: s = json.load(f)
s['pm_cycle_count'] = s.get('pm_cycle_count', 0) + 1
with open('.otherness/state.json', 'w') as f: json.dump(s, f, indent=2)
" 2>/dev/null
```

---

## 5c. Competitive check (every 10 PM cycles)

```bash
if [ $((${PM_CYCLE:-0} % 10)) -eq 0 ] && [ "${PM_CYCLE:-0}" -gt 0 ]; then
  echo "[PM] Running cross-project improvement check..."
  # [AI-STEP] Cross-project improvement proposals (Idea 5 from docs/future-ideas.md):
  # 1. Read monitor.projects from otherness-config.yaml
  # 2. For each project:
  #    - Check open [needs-human] issues: gh issue list --repo <proj> --label needs-human --state open
  #    - Check CI status: gh run list --repo <proj> --branch main --limit 1 --json conclusion
  #    - Check recent metrics (if accessible): look for todo_shipped = 0 in _state metrics
  # 3. Find common blockers across ≥2 projects:
  #    - Both have needs-human open → pattern: "unresolved escalation backlog"
  #    - Both have CI red → pattern: "CI reliability gap"
  #    - Both have 0 velocity → pattern: "queue generation or claiming issue"
  # 4. For each common blocker: open an issue on $REPO proposing the improvement.
  #    Title: "improvement(loop): <abstract pattern> affecting ≥2 managed projects"
  #    Body: abstract description (no project names) + suggested fix direction
  #    Labels: otherness,kind/enhancement,area/agent-loop
  # 5. Also check docs/future-ideas.md for ideas ready to implement.
  #    If an idea has a complexity tag of 'small' or 'xs' and hasn't been opened as an issue:
  #    open it now with a [PM proposal] prefix.
  # If only 1 project in monitor: log "[PM] Need ≥2 projects for cross-project analysis."
fi
```

---

## 5e. Stagnation detection (Stage 4 deliverable)

Check `docs/aide/metrics.md` batch log. If velocity has stalled, open a `kind/chore` issue.

```bash
python3 - <<'EOF'
import re, subprocess, os

REPO = os.environ.get('REPO', '')
REPORT_ISSUE = os.environ.get('REPORT_ISSUE', '')

# Parse batch log rows from docs/aide/metrics.md
# Table format: | Date | Batch | prs_merged | needs_human | ci_red_hours | skills_count | todo_shipped | ... |
try:
    content = open('docs/aide/metrics.md').read()
    rows = []
    for line in content.splitlines():
        # Match data rows (not header or separator): | 2026-... | N | ...
        m = re.match(r'^\|\s*\d{4}-\d{2}-\d{2}\s*\|(.+)', line)
        if m:
            cells = [c.strip() for c in line.split('|')[1:-1]]
            if len(cells) >= 7:
                try:
                    row = {
                        'date': cells[0],
                        'batch': cells[1],
                        'prs_merged': int(cells[2]) if cells[2].isdigit() else 0,
                        'needs_human': int(cells[3]) if cells[3].isdigit() else 0,
                        'todo_shipped': int(cells[6]) if cells[6].isdigit() else 0,
                    }
                    rows.append(row)
                except (ValueError, IndexError):
                    pass
except Exception:
    rows = []

if len(rows) < 2:
    print("[PM] Not enough batch rows in metrics.md to check stagnation (need ≥ 2).")
    exit(0)

last2 = rows[-2:]
stagnation = all(r['todo_shipped'] == 0 for r in last2)
needs_human_spike = all(r['needs_human'] > 0 for r in last2)

# Stagnation: open kind/chore issue if not already open
if stagnation:
    STALE_TITLE = '[STALE] Queue appears blocked — investigate roadmap'
    existing = subprocess.run(
        ['gh', 'issue', 'list', '--repo', REPO, '--state', 'open',
         '--search', STALE_TITLE, '--json', 'number', '--jq', 'length'],
        capture_output=True, text=True)
    count = int(existing.stdout.strip() or '0')
    if count == 0:
        r = subprocess.run(
            ['gh', 'issue', 'create', '--repo', REPO,
             '--title', STALE_TITLE,
             '--label', 'kind/chore,otherness',
             '--body', f'PM stagnation check triggered.\n\nLast 2 batches both had `todo_shipped = 0`:\n' +
                       '\n'.join(f'- Batch {r["batch"]} ({r["date"]}): shipped={r["todo_shipped"]}' for r in last2) +
                       '\n\nThis suggests the queue is empty or items are blocked. Check roadmap.md and open new issues.'],
            capture_output=True, text=True)
        if r.returncode == 0:
            print(f'[PM] Stagnation detected — opened issue: {r.stdout.strip()}')
        else:
            print(f'[PM] Stagnation detected but failed to open issue: {r.stderr.strip()}')
    else:
        print('[PM] Stagnation detected but issue already open — skipping duplicate.')
else:
    print(f'[PM] No stagnation. Last 2 batches: {[(r["batch"], r["todo_shipped"]) for r in last2]}')

# needs_human spike: post warning comment only (no issue — it may be legitimate)
if needs_human_spike:
    msg = ('[📋 PM | ' + os.environ.get('MY_SESSION_ID', 'sess-unknown') + ' | '
           + 'otherness@' + os.environ.get('OTHERNESS_VERSION', 'unknown') + '] '
           + f'⚠️  Persistent escalation: last 2 batches both had needs_human > 0 '
           + f'({last2[-2]["needs_human"]}, {last2[-1]["needs_human"]}). '
           + 'Review open needs-human issues.')
    subprocess.run(['gh', 'issue', 'comment', REPORT_ISSUE, '--repo', REPO, '--body', msg],
                   capture_output=True)
    print('[PM] needs_human spike warning posted.')
else:
    print(f'[PM] No needs_human spike. Last 2 batches: {[(r["batch"], r["needs_human"]) for r in last2]}')
EOF
```

---

## 5d. Post PM review

```bash
gh issue comment $REPORT_ISSUE --repo $REPO \
  --body "[📋 PM | ${MY_SESSION_ID:-sess-unknown} | otherness@${OTHERNESS_VERSION:-unknown}] Product review complete." 2>/dev/null
```

---

## 5g. Simulation health score (GREEN / AMBER / RED) — runs every N_PM_CYCLES

Run a quick simulation pass with calibrated parameters and compare against real
batch data. Produce a health signal. AMBER is self-correcting; RED escalates.

```bash
if [ $((${PM_CYCLE:-0} % ${N_PM_CYCLES:-3})) -eq 0 ]; then
  echo "[PM §5g] Running simulation health check..."

  # [AI-STEP]
  # Step 0: Graceful fallback — check sim-results.json and metrics.md exist.
  #   SIM_RESULTS=$(git show origin/_state:.otherness/sim-results.json 2>/dev/null || echo "")
  #   if [ -z "$SIM_RESULTS" ]: echo "[PM §5g] No sim-results found — skipping."; exit
  #   METRICS_ROWS=$(grep -c '^\|\s*[0-9][0-9][0-9][0-9]-' docs/aide/metrics.md 2>/dev/null || echo 0)
  #   if [ "$METRICS_ROWS" -lt 3 ]: echo "[PM §5g] Insufficient batch history — skipping."; exit
  #
  # Step 1: Read real completion rate from last 3 batches.
  #   avg_shipped = mean(todo_shipped[-3:])  # from metrics.md
  #   avg_needs_human = mean(needs_human[-3:])  # from metrics.md
  #
  # Step 2: Run quick simulation with calibrated params (1 run, 30 cycles).
  #   Load sim_params from SIM_RESULTS.
  #   Run: python3 -c "
  #     import sys; sys.path.insert(0,'scripts')
  #     from simulate import SimConfig, run_simulation
  #     cfg = SimConfig(n_agents=4, n_cycles=30, seed=42, **sim_params_subset)
  #     metrics, _ = run_simulation(cfg)
  #     print(metrics[-1].mean_arch_convergence, metrics[-1].mean_boldness)
  #   "
  #
  # Step 3: Determine health signal.
  #   GREEN: arch_convergence < 0.5 AND real_shipped >= 1 in last batch
  #   AMBER: (arch_convergence 0.5-0.7) OR (real_shipped = 0 in last 1-2 batches)
  #   RED:   arch_convergence > 0.7 OR (real_shipped = 0 for ≥2 consecutive batches)
  #
  # Step 4: Post signal.
  #   GREEN: log "[PM §5g] Health: GREEN"
  #   AMBER: post comment on REPORT_ISSUE: "[PM §5g] Health: AMBER — <reason>. Self-correcting."
  #   RED:   post comment + open [NEEDS HUMAN] issue: "[PM §5g] Health: RED — <reason>"

  echo "[PM §5g] Simulation health check complete."
fi
```

## 5f. Documentation health scan + freshness check (runs every N_PM_CYCLES)

Verify `docs/design/` files reflect reality: Present items have PR references,
Future items haven't been silently shipped, design docs aren't going stale.
Opens `kind/docs` issues for each gap. No file writes — issues only.

```bash
if [ $((${PM_CYCLE:-0} % ${N_PM_CYCLES:-3})) -eq 0 ]; then
  echo "[PM §5f] Running documentation health scan..."

  # [AI-STEP]
  # Step 0: Graceful fallback if no design docs exist.
  #   if [ ! -d "docs/design" ] || [ -z "$(ls docs/design/*.md 2>/dev/null)" ]; then
  #     echo "[PM §5f] No design docs found — skipping."; skip
  #   fi
  #
  # Step 1: Fetch merged PR titles once (reused across all steps).
  #   MERGED_TITLES=$(gh pr list --repo $REPO --state merged --limit 200 \
  #     --json title --jq '.[].title' 2>/dev/null | tr '[:upper:]' '[:lower:]')
  #
  # Step 2: For each docs/design/*.md file (duplicate-suppressed — open_if_absent):
  #
  #   2a. Check ✅ Present items for (PR #N) references.
  #     present_items = re.findall(r'^- ✅ (.+)', content, re.MULTILINE)
  #     for item in present_items:
  #       if not re.search(r'\(PR #\d+', item):
  #         title = f"docs: {fname} Present item missing PR reference: {item[:60]}"
  #         open_if_absent(title, "kind/docs,otherness")
  #
  #   2b. Check 🔲 Future items not silently shipped.
  #     future_items = re.findall(r'^- 🔲 (?!.*🚫)(.+)', content, re.MULTILINE)
  #     for item in future_items:
  #       desc_key = item[:60].lower().strip()
  #       if any(desc_key in pr for pr in MERGED_TITLES.splitlines()):
  #         title = f"docs: {fname} Future item may be shipped but not marked Present: {item[:60]}"
  #         open_if_absent(title, "kind/docs,otherness")
  #
  # Step 3: Duplicate suppression helper.
  #   def open_if_absent(title, labels):
  #     r = subprocess.run(['gh','issue','list','--repo',REPO,'--state','open',
  #                         '--search',title[:60],'--json','number','--jq','length'],
  #                        capture_output=True, text=True)
  #     if int(r.stdout.strip() or '0') == 0:
  #       subprocess.run(['gh','issue','create','--repo',REPO,
  #                       '--title',title,'--label',labels,'--body',
  #                       f'PM §5f health scan finding: {title}'], capture_output=True)
  #
  # Step 4: Post summary comment.
  #   gh issue comment $REPORT_ISSUE --repo $REPO \
  #     --body "[📋 PM §5f | $MY_SESSION_ID] Health scan complete. <N> issues opened."
  #
  # Step 5: Design doc freshness check (stale docs = no updates in >60 days).
  #   STALE_DAYS=60
  #   NOW=$(date +%s)
  #   for each docs/design/*.md file:
  #     LAST_MODIFIED=$(git log -1 --format=%ct -- "docs/design/$fname" 2>/dev/null || echo "")
  #     if [ -z "$LAST_MODIFIED" ]: skip (no git history)
  #     AGE_DAYS=$(( (NOW - LAST_MODIFIED) / 86400 ))
  #     if [ AGE_DAYS -gt STALE_DAYS ]:
  #       title = "docs: design doc $fname may be stale — no updates in ${AGE_DAYS} days"
  #       open_if_absent(title, "kind/docs,otherness,priority/low")

  echo "[PM §5f] Documentation health scan complete."
fi
```
