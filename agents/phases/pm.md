
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
  #
  # Phase 2c: also include simulation health in validation report.
  # Read .otherness/sim-results.json from _state branch (if it exists):
  #   SIM_RESULTS=$(git show origin/_state:.otherness/sim-results.json 2>/dev/null || echo "")
  #   if [ -n "$SIM_RESULTS" ]: parse sim-results.json and include in report:
  #     calibrated_at, best_rmse, source → summary line in PM report
  #   If rmse > 0.3: note "simulation calibration quality LOW — consider more batches"
  #   If rmse <= 0.3: note "simulation calibration quality OK"
  # If sim-results.json not found: log "[PM] No sim-results found — skipping sim health."
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
  # [AI-STEP] Cross-project improvement proposals:
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
  # 6. Competitive observation: for each competitor version update found in PM §5 competitive
  #    scan — write a ⚠️ Inferred stub to docs/design/ if the capability is not covered:
  #    INFERRED_FILE="docs/design/<area>-competitive-gaps.md"
  #    If file doesn't exist: create it with standard template + Present (empty) + Future section.
  #    Append: "- 🔲 ⚠️ Inferred: <capability> — competitor <name> has this, we do not. (PM §5c, <date>)"
  #    This makes the gap visible to COORD queue gen immediately.
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

<<<<<<< HEAD
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
=======
## 5g. Simulation health score + self-correction (runs every N_PM_CYCLES)

Produce GREEN/AMBER/RED health signal. AMBER auto-triggers /otherness.learn.

```bash
if [ $((${PM_CYCLE:-0} % ${N_PM_CYCLES:-3})) -eq 0 ]; then
  echo "[PM §5g] Running simulation health check..."

  # [AI-STEP]
  # Step 0: Graceful fallback.
  #   SIM_RESULTS=$(git show origin/_state:.otherness/sim-results.json 2>/dev/null || echo "")
  #   METRICS_ROWS=$(grep -c '^\|\s*[0-9][0-9][0-9][0-9]-' docs/aide/metrics.md 2>/dev/null || echo 0)
  #   If either absent or METRICS_ROWS < 3: echo "[PM §5g] Skipping — insufficient data."; exit
  #
  # Step 1: Read real completion rate from last 3 batches (metrics.md).
  #   avg_shipped = mean(todo_shipped[-3:])
  #
  # Step 2: Run quick sim (1 run, 30 cycles) with calibrated params from sim-results.json.
  #   Get arch_convergence from sim output.
  #
  # Step 3: Determine health signal.
  #   GREEN: arch_conv < 0.5 AND last_batch_shipped >= 1
  #   AMBER: arch_conv 0.5-0.7 OR last_batch_shipped = 0 in last 1-2 batches
  #   RED:   arch_conv > 0.7 OR last_batch_shipped = 0 for >= 2 consecutive batches
  #
  # Step 4: Act on signal.
  #   GREEN: log "[PM §5g] Health: GREEN"; no action.
  #   AMBER:
  #     Post comment on REPORT_ISSUE: "[PM §5g] Health: AMBER — <reason>. Self-correcting."
  #     Self-correction: find design doc with highest Future/total ratio (lowest boldness area).
  #     LEARN_BRANCH="feat/learn-$(date +%Y%m%d)"
  #     Check if branch exists: git ls-remote --heads origin $LEARN_BRANCH
  #     If branch already exists: skip (learn in progress from SM).
  #     If not: create branch, worktree, read and follow ~/.otherness/agents/otherness.learn.md,
  #       merge after CI green, clean up.
  #   RED:
  #     Post [NEEDS HUMAN] issue: "PM §5g Health: RED — <reason>. Requires investigation."
  #     gh issue create --repo $REPO --title "[NEEDS HUMAN] PM §5g: RED health signal — <reason>"
  #       --label "needs-human,area/agent-loop" --body "<full report>"

  echo "[PM §5g] Simulation health check complete."
fi
```

---

## 5h. Self-generating validation criteria (runs every N_PM_CYCLES)

Scan shipped Present items for gaps in definition-of-done.md journeys.
Also detect emergent patterns: Present items with no design doc coverage.

```bash
if [ $((${PM_CYCLE:-0} % ${N_PM_CYCLES:-3})) -eq 0 ]; then
  echo "[PM §5h] Scanning for validation criteria gaps and emergent patterns..."

  # [AI-STEP]
  # Step 0: Read definition-of-done.md content. If absent: skip.
  #   DOD_CONTENT=$(cat docs/aide/definition-of-done.md 2>/dev/null || echo "")
  #   if [ -z "$DOD_CONTENT" ]: echo "[PM §5h] No definition-of-done.md — skipping."; exit
  #
  # Step 1: For each docs/design/*.md file, read ✅ Present items.
  #   present_items = re.findall(r'^- ✅ (.+)', content, re.MULTILINE)
  #
  # Step 2: For each Present item, check if its description (first 40 chars)
  #   appears in definition-of-done.md (case-insensitive substring).
  #   If not found: this is a validation gap.
  #   title = f"docs: definition-of-done.md missing journey for: {item_desc[:60]}"
  #   open_if_absent(title, "kind/docs,otherness,priority/low")
  #
  # Step 3: Duplicate suppression (open_if_absent pattern).
  #
  # Step 4: Emergent pattern detection (⚠️ Observed — new in this version):
  #   merged_pr_titles = gh pr list --repo $REPO --state merged --limit 200 --json title
  #   design_covered_terms = set of words from all docs/design/ Present + Future items
  #   for pr_title in merged_pr_titles:
  #     if not any(term in pr_title.lower() for term in design_covered_terms):
  #       # This PR shipped something with no design doc coverage
  #       # Candidate for ⚠️ Observed entry
  #       title = f"docs: ⚠️ Observed — '{pr_title[:50]}' shipped with no design doc coverage"
  #       open_if_absent(title, "kind/docs,otherness,priority/low")
  #   Note: only flag PRs merged >14 days ago (recent PRs may still have design docs in draft)
  #
  # Step 5: Post count: "[PM §5h] Validation gaps: <N>. Emergent patterns: <M>."

  echo "[PM §5h] Self-generating validation criteria check complete."
fi
```

---

## 5i. README/AGENTS.md claims cross-check (runs every N_PM_CYCLES)

Verify machine-checkable claims in README.md and AGENTS.md still hold.
Opens `kind/docs priority/high` issues for false claims.

```bash
if [ $((${PM_CYCLE:-0} % ${N_PM_CYCLES:-3})) -eq 0 ]; then
  echo "[PM §5g] Cross-checking README/AGENTS.md claims..."

  # [AI-STEP]
  # Step 1: File existence claims — command files in .opencode/command/.
  #   For each command listed in the README.md command table
  #   (lines matching /^\| `\/otherness\.\w+`/):
  #   Extract the command name (e.g. /otherness.run → otherness.run.md).
  #   Verify: os.path.exists(f".opencode/command/{cmd_file}")
  #   If missing: open kind/docs priority/high issue:
  #     "docs: README lists /otherness.<name> but .opencode/command/<name>.md is missing"
  #
  # Step 2: File existence claims — Package Layout section in AGENTS.md.
  #   Find the Package Layout fenced code block in AGENTS.md.
  #   For each line matching /^\s+\S+\.md/ (markdown files listed):
  #   Verify the file exists relative to the repo root.
  #   If missing: open kind/docs issue: "docs: AGENTS.md Package Layout lists <file> but it does not exist"
  #   (Lower priority than step 1 — use priority/medium)
  #
  # Step 3: validate.sh step count claim.
  #   Count actual steps: grep -c 'echo "\[' scripts/validate.sh
  #   Find claimed count in AGENTS.md (look for "validate.sh performs" or "[N/N]" pattern).
  #   If mismatch: open kind/docs issue: "docs: validate.sh step count mismatch (README claims N, actual M)"
  #
  # Step 4: BUILD_COMMAND/TEST_COMMAND/LINT_COMMAND scripts exist.
  #   Read BUILD_COMMAND, TEST_COMMAND, LINT_COMMAND from AGENTS.md.
  #   For each: if it references a local script (starts with "bash scripts/"), verify the script exists.
  #   If missing: open kind/docs priority/high issue.
  #
  # Step 5: Duplicate suppression.
  #   Use open_if_absent pattern (same as §5f):
  #     gh issue list --repo $REPO --state open --search "<title[:60]>" --json number --jq length
  #     Open only if count == 0.

  echo "[PM §5g] README/AGENTS.md claims cross-check complete."
fi
```

---

## 5j. Reference project health check (runs every N_PM_CYCLES)

Detect Journey 2 failure. Open [NEEDS HUMAN] issue once per stall.

```bash
if [ $((${PM_CYCLE:-0} % ${N_PM_CYCLES:-3})) -eq 0 ]; then
  echo "[PM §5j] Checking reference project health..."

  # [AI-STEP]
  # Step 1: Read reference project from otherness-config.yaml.
  #   REF_PROJECT=$(python3 -c "
  #     import re
  #     in_monitor = in_projects = False
  #     for line in open('otherness-config.yaml'):
  #         if re.match(r'^monitor:',line): in_monitor=True
  #         if in_monitor and re.match(r'\s+projects:',line): in_projects=True
  #         if in_projects:
  #             m=re.match(r'\s+- (.+)',line)
  #             if m:
  #                 r=m.group(1).strip()
  #                 if not r.endswith('/otherness'): print(r); break
  #   " 2>/dev/null)
  #   if [ -z "$REF_PROJECT" ]: echo "[PM §5j] No reference project found — skipping."; exit
  #
  # Step 2: Check _state branch age.
  #   LAST_COMMIT=$(gh api "repos/$REF_PROJECT/branches/_state"
  #     --jq '.commit.commit.committer.date' 2>/dev/null || echo "")
  #   if [ -z "$LAST_COMMIT" ]: echo "[PM §5j] No _state branch on $REF_PROJECT — skipping."; exit
  #   AGE_H=$(python3 -c "
  #     import datetime
  #     d = datetime.datetime.fromisoformat('$LAST_COMMIT'.replace('Z','+00:00'))
  #     print(int((datetime.datetime.now(datetime.timezone.utc) - d).total_seconds() / 3600))
  #   ")
  #
   # Step 3: If AGE_H > 72 (Journey 2 failing):
   #   TITLE="[NEEDS HUMAN] Journey 2: reference project stalled >72h — restart otherness on $REF_PROJECT"
   #   EXISTING=$(gh issue list --repo $REPO --state open --search "$TITLE" --json number --jq 'length')
   #   if [ "$EXISTING" -eq 0 ]:
   #     gh issue create --repo $REPO --title "$TITLE"
   #       --label "needs-human,area/agent-loop"
   #       --body "Reference project $REF_PROJECT has not had _state activity in ${AGE_H}h (threshold: 72h).
   #               Journey 2 is failing. Run /otherness.run on $REF_PROJECT to restart."
   #   fi
   #
   # Step 3b: AMBER/RED escalation based on stall duration (for PM §5g health signal):
   #   If AGE_H > 72 AND AGE_H <= 168 (24–72h mapped to AMBER, >72h is already RED):
   #     Set JOURNEY2_HEALTH="AMBER" (override if current HEALTH is GREEN)
   #   If AGE_H > 168 (>7 days):
   #     Set JOURNEY2_HEALTH="RED"
   #   PM §5g reads JOURNEY2_HEALTH as an additional signal when computing overall health:
   #     if JOURNEY2_HEALTH == "RED": overall HEALTH = "RED"
   #     elif JOURNEY2_HEALTH == "AMBER" and overall HEALTH == "GREEN": overall HEALTH = "AMBER"
   #
   # Step 4: If AGE_H <= 72:
   #   echo "[PM §5j] Journey 2 OK: $REF_PROJECT last active ${AGE_H}h ago."

  echo "[PM §5j] Reference project health check complete."
fi
```

---

## 5k. Vision age check (runs every N_PM_CYCLES)

Suggest /otherness.vibe-vision when the vision hasn't been updated and queue is empty.

```bash
if [ $((${PM_CYCLE:-0} % ${N_PM_CYCLES:-3})) -eq 0 ]; then
  echo "[PM §5k] Checking vision age..."

  # [AI-STEP]
  # Step 1: Check if queue is empty AND design docs have no recent activity.
  #   TODO_COUNT=$(python3 -c "import json; s=json.load(open('.otherness/state.json')); print(len([d for d in s.get('features',{}).values() if d.get('state')=='todo']))")
  #   if [ "${TODO_COUNT:-0}" -gt 0 ]: echo "[PM §5k] Queue active — skipping vision age check."; exit
  #
  # Step 2: Check last design doc activity (git log on docs/design/).
  #   LAST_DESIGN_COMMIT=$(git log -1 --format=%ct -- docs/design/ 2>/dev/null || echo "0")
  #   DESIGN_AGE_DAYS=$(python3 -c "import time; print(int((time.time() - int('$LAST_DESIGN_COMMIT')) / 86400))")
  #
  # Step 3: If DESIGN_AGE_DAYS > 30 (queue empty AND no new design activity):
  #   TITLE="[📋 PM] Vision may need updating — queue has been empty and no new design activity in ${DESIGN_AGE_DAYS}d"
  #   EXISTING=$(gh issue list --repo $REPO --state open --search "Vision may need updating" --json number --jq 'length')
  #   if [ "$EXISTING" -eq 0 ]:
  #     gh issue comment $REPORT_ISSUE --repo $REPO \
  #       --body "[📋 PM §5k] The vision has not been updated in ${DESIGN_AGE_DAYS}d and the queue is empty.
  #               Consider running /otherness.vibe-vision to expand the roadmap.
  #               (This is a suggestion, not a blocker — the loop continues in standby.)"
  #
  # Step 4: If DESIGN_AGE_DAYS <= 30: echo "[PM §5k] Vision active (${DESIGN_AGE_DAYS}d ago)."; exit

  echo "[PM §5k] Vision age check complete."
fi
```

---

## 5m. ⚠️ Inferred ratio check (runs every N_PM_CYCLES)

Surface when machine-generated items dominate — human direction may be needed.

```bash
if [ $((${PM_CYCLE:-0} % ${N_PM_CYCLES:-3})) -eq 0 ]; then
  echo "[PM §5m] Checking ⚠️ Inferred ratio..."

  # [AI-STEP]
  # Step 1: Count total 🔲 Future items and ⚠️ Inferred subset across all docs/design/*.md.
  #   total_future = 0; inferred_count = 0
  #   for each docs/design/*.md (excluding code blocks):
  #     items = re.findall(r'^- 🔲 (?!.*🚫)(.+)', future_section, re.MULTILINE)
  #     total_future += len(items)
  #     inferred_count += sum(1 for i in items if '⚠️ inferred' in i.lower() or '⚠️ observed' in i.lower())
  #
  # Step 2: If total_future == 0: echo "[PM §5m] No Future items — skipping."; exit
  #
  # Step 3: ratio = inferred_count / total_future
  #   If ratio > 0.8 (>80% machine-generated):
  #     TITLE="[📋 PM §5m] ⚠️ Inferred items are ${ratio*100:.0f}% of the queue — human direction may be needed"
  #     EXISTING=$(gh issue list --repo $REPO --state open --search "Inferred items are" --json number --jq 'length')
  #     if [ "$EXISTING" -eq 0 ]:
  #       gh issue comment $REPORT_ISSUE --repo $REPO \
  #         --body "[📋 PM §5m] ${inferred_count} of ${total_future} Future items (${ratio*100:.0f}%) are ⚠️ Inferred (machine-generated).
  #                 The system is filling the queue autonomously, but human vision direction would strengthen it.
  #                 Consider running /otherness.vibe-vision.
  #                 (This is a suggestion — the loop continues.)"
  #   fi
  #   Else: echo "[PM §5m] Inferred ratio OK: ${ratio*100:.0f}% (${inferred_count}/${total_future})"

  echo "[PM §5m] ⚠️ Inferred ratio check complete."
fi
```
