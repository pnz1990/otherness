# Onboarding: Existing Project

This guide walks through adopting otherness into a **project that already has code** — an existing repo with an existing team, codebase, and potentially some CI/CD already.

---

## Fast path — let the agent do it

If your project already has `AGENTS.md` and a git history, skip the manual steps and run:

```bash
# 1. Prerequisites (once per machine)
gh auth login
git clone git@github.com:<your-username>/otherness.git ~/.otherness

# 2. Deploy otherness commands into your project
/otherness.setup

# 3. Let the agent read the codebase and generate everything
/otherness.onboard
```

`/otherness.onboard` will:
- Read your README, AGENTS.md, CI config, git log, merged PRs, and existing specs
- Generate `docs/aide/vision.md`, `roadmap.md`, `definition-of-done.md`, `progress.md` as drafts
- Auto-seed `.otherness/state.json` with all merged PRs marked as done (no manual JSON)
- Create `otherness-config.yaml` if not present
- Open a PR with everything for your review

Review the PR, correct anything that's wrong, merge, then:

```bash
/otherness.run
```

**The rest of this guide is the manual alternative** — useful if `/otherness.onboard` needs correction or if you want to understand what each file does.

---

## Prerequisites (install once per machine)

```bash
gh auth login
git clone git@github.com:<your-username>/otherness.git ~/.otherness
```

---

## Step 1 — Audit what you already have

Before creating any files, answer these questions:

```
□ What is the primary language and build tool?
□ What does `<build command>` produce?
□ What does `<test command>` run?
□ Is there an existing CI workflow? Which file?
□ Do you have a GitHub Projects board already? What are the column names?
□ What are the major packages/modules in the codebase?
□ What are the existing code conventions (error handling, logging, test style)?
□ What are the existing GitHub labels?
□ Is there an existing README with architecture documentation?
```

Agents will read your answers from `AGENTS.md` and `docs/aide/`. The more accurate these files are, the less likely agents will break existing patterns.

---

## Step 2 — Run otherness setup

```bash
/otherness.setup
```

This creates `otherness-config.yaml` from the template and auto-fills `project.repo` and `project.name` from your git remote. Edit the file to configure CI, board, and cycle settings.

If your project has a UI (web app, mobile app, frontend), set `project.job_family: FEE`. For infrastructure/platform projects, set `project.job_family: SysDE`. For backend-only projects the default (`SDE`) is correct — you can omit the field.

Start with `mode: standalone` regardless of team size — get one working loop before adding parallelism.

---

## Step 3 — Create AGENTS.md from your existing documentation

This is the most important step. Agents read AGENTS.md at startup to understand the project. **Write it based on what actually exists** — not what you plan to build. If you describe a pattern that isn't in the codebase yet, agents will reference code that doesn't exist.

Required fields — read directly by agent runtime:

```markdown
# my-project — Project Agent Context

## What This Is

<Describe the project using present tense — what it does today, not what it will do.>

---

## Project Config

\`\`\`yaml
PROJECT_NAME:   my-project
CLI_BINARY:     my-cli          # binary name agents will look for in docs/
PR_LABEL:       my-project      # label for feature PRs
REPORT_ISSUE:   <number>        # GitHub issue number for team reports (create one if needed)
REPORT_URL:     https://github.com/my-org/my-project/issues/<number>
BOARD_URL:      https://github.com/users/my-org/projects/<number>
BUILD_COMMAND:  <exact build command>
TEST_COMMAND:   <exact test command>
LINT_COMMAND:   <exact lint command>
VULN_COMMAND:   <exact vuln scan command, or leave empty>
\`\`\`

---

## Architecture

<Copy from your existing README/docs. Describe the system as it works today.>

## Package Layout

\`\`\`
<Actual directory tree of key packages as they exist today>
\`\`\`

---

## Code Standards

<Extract from your existing linting config, CONTRIBUTING.md, or code review notes.
Be specific and precise — agents enforce these in QA reviews.>

- Error handling: <your pattern>
- Logging: <your library and pattern>
- Tests: <your framework and conventions>
- Copyright: <your header format, if any>

## Banned Filenames

<List filenames you consider anti-patterns: util.go, helpers.go, etc.>

## Label Taxonomy

<Map your existing GitHub labels to the otherness taxonomy, or create new ones to match.
Agents expect kind/*, area/*, priority/*, size/* labels.>

## Anti-Patterns (QA enforces)

<List patterns that have caused bugs in this codebase before. Agents will block PRs containing them.>

## Files Agents Must Not Modify

- docs/aide/vision.md
- docs/aide/roadmap.md
- AGENTS.md
- .specify/memory/constitution.md
- .specify/memory/sdlc.md
- <any files that are human-owned and must not be auto-edited>
```

**Critical for existing projects**: if your codebase uses different patterns than what otherness defaults assume (e.g. you use a custom logger but agents might default to `log.Printf`), spell it out explicitly in Code Standards. Agents read this and adapt their checklist.

---

## Step 4 — Write docs/aide/ to describe current reality

The hardest part of adopting otherness on an existing project is writing accurate documentation before automation begins. Agents build on these docs — if they're wrong, the automation goes wrong.

### `docs/aide/vision.md`

Write this from your product perspective, not the codebase perspective. What problem does the project solve? For whom? What are the non-negotiable design constraints?

**Trap to avoid**: don't copy the README verbatim. The README describes the code; vision.md describes the product intent and constraints.

If the project already has a product document, copy it here and reformat to the expected structure.

### `docs/aide/roadmap.md`

For existing projects, the roadmap describes **what remains to be done**, not the full history. Think about it as "given where we are today, what are the remaining stages to reach our goal?"

Completed stages can be listed briefly as "Stage X: <name> — ✅ Complete" without full detail.

**Be honest about what's done vs what's planned**. Agents will assign items from the roadmap — if a stage is listed as Planned but the code already exists, agents will create duplicate work.

### `docs/aide/definition-of-done.md`

For existing projects, this is often the hardest file to write. You need to define what "working" means from a user's perspective, end-to-end. Not "the tests pass" but "a user can do X and get Y."

Start by listing the top 3-5 user scenarios you care most about. Write them as journeys with exact commands and expected output. Even if they don't pass yet, writing them down is what drives the automation.

**Tip**: look at your existing integration tests or manual QA scripts — these often describe journeys in executable form.

### `docs/aide/progress.md`

Write an honest current state. Which stages are complete? Which are in-flight? Which haven't started? Agents read this to avoid re-implementing what already exists.

```markdown
## Stage Completion

| Stage | Name | Status | Notes |
|---|---|---|---|
| 0 | <name> | ✅ Complete | <brief note on what was done> |
| 1 | <name> | ✅ Complete | |
| 2 | <name> | 🔄 In Progress | <what's left> |
| 3 | <name> | 📋 Planned | |
```

---

## Step 5 — Set up `.specify/memory/`

### Using speckit's existing constitution if present

If `specify init` was already run, you have a `constitution.md`. Read it and verify it accurately describes your project's constraints. Add any project-specific articles.

### If starting from scratch

Copy `constitution.md` from `~/.otherness` (ask the agent to generate it from your AGENTS.md).

### Critical article to add: your core architectural constraint

Every project has some architectural constraint that must never be violated. Add it as a numbered article. Example pattern (adapt to your project's constraint):

```
## XII. <Constraint Name>

<State the constraint as an absolute rule.>
<What the correct approach is.>
<What agents must do if they encounter a case that seems to require violating it.>

If an agent violates this constraint without explicit human approval, QA must block the PR.
```

---

## Step 6 — Inventory existing GitHub issues and milestones

Before agents create new issues, you need to prevent duplicates and misclassification.

```bash
# List existing open issues
gh issue list --repo my-org/my-project --state open --json number,title,labels --limit 100

# List existing milestones
gh api repos/my-org/my-project/milestones --jq '.[] | [.number, .title, .state] | @tsv'
```

Options:
- **If you have existing issues**: label them with the otherness taxonomy (`kind/*`, `area/*`, `priority/*`, `size/*`) so agents can understand and build on them.
- **If you have no issues**: agents will create them as they generate queues.
- **If you have existing milestones**: map them to the otherness versioning philosophy and update descriptions to include stage groupings.

---

## Step 7 — Seed `.otherness/state.json`

The state file must exist before agents start. Create it with the correct current state — mark completed stages as done:

```bash
mkdir -p .otherness
```

```json
{
  "version": "1.2",
  "project": "my-project",
  "mode": "standalone",
  "initialized": "YYYY-MM-DD",
  "last_updated": "YYYY-MM-DD",
  "current_queue": null,
  "last_sm_review": null,
  "last_pm_review": null,
  "batches_since_competitive_analysis": 0,
  "session_heartbeats": {},
  "features": {
    "<already-completed-item-id>": {
      "state": "done",
      "assigned_to": null,
      "pr_number": "<pr-number>",
      "pr_merged": true
    }
  }
}
```

**Important**: every item that was already implemented before adopting otherness should be listed as `"state": "done"` in `features`. Otherwise the coordinator will re-implement them.

**Tip — auto-seed from merged PRs**: for projects with many merged PRs, generate
the features map automatically rather than writing it by hand:

```bash
gh pr list --repo my-org/my-project --state merged \
  --json number,title --jq \
  '[.[] | {"key": ("pr-\(.number)"), "value": {"state":"done","assigned_to":null,"pr_number":.number,"pr_merged":true}}] | from_entries'
```

Pipe that into the `features` key of `state.json`.

---

## Step 8 — Set up the GitHub Projects board

All board fields can be created via the GitHub GraphQL API — no UI required beyond the initial project creation.

If you already have a board, add the missing fields (Priority, Size, Team, Target date) using the API scripts in Step 8 of `onboarding-new-project.md`. Then read back the field IDs and fill in `otherness-config.yaml`.

If you don't have a board yet, follow Step 8 in `onboarding-new-project.md` in full.

**Key mutations:**
- `createProjectV2Field` — creates Priority, Size, Team, Target date fields
- `updateProjectV2Field` — updates the existing Status field to add In Review + Blocked options

The token must have `read:project` scope. Run `gh auth refresh -s read:project` if you get scope errors.

---

## Step 9 — Create the team report issue

```bash
gh issue create --repo my-org/my-project \
  --title "📊 Autonomous Team Reports" \
  --body "Subscribe for team reports. Coordinator updates body after each batch." \
  --label "report"
```

Update `REPORT_ISSUE` in `AGENTS.md` with the issue number.

---

## Step 10 — Dry run: verify agent reads are correct

Before starting the full autonomous loop, do a verification pass:

```bash
# Check agents can read all required files
cat docs/aide/vision.md
cat docs/aide/roadmap.md
cat docs/aide/definition-of-done.md
cat AGENTS.md | grep -E "PROJECT_NAME|CLI_BINARY|BUILD_COMMAND|TEST_COMMAND"
cat otherness-config.yaml
cat .otherness/state.json | python3 -m json.tool > /dev/null && echo "state.json: valid JSON"

# Check build and test commands work
eval "$(grep BUILD_COMMAND AGENTS.md | cut -d: -f2- | xargs)"
eval "$(grep TEST_COMMAND AGENTS.md | cut -d: -f2- | xargs)"
```

Fix any issues before starting the agent. A misconfigured `BUILD_COMMAND` will cause every PR to fail CI and the agent will spin in a fix loop.

---

## Step 11 — First run

```bash
/otherness.run
```

The agent will:
1. Self-update from the otherness repo
2. Read `docs/aide/` and `AGENTS.md`
3. Check `state.json` — recognize already-done items and skip them
4. Run PM spec gate
5. Generate the first queue for remaining work

Watch the first batch closely. If the agent misidentifies something as needing re-implementation (because `state.json` wasn't seeded correctly), pause and fix `state.json` before continuing.

---

## Common mistakes on existing projects

**1. vision.md describes the future, not the present**
Agents implement what vision.md says should exist. If it describes features not yet built, agents will plan work that conflicts with existing code.

**2. State.json not seeded with done items**
The coordinator sees empty `features{}` and regenerates queue-001 including stages already complete. Fix: populate `state.json` with all completed items as `"state": "done"`.

**3. Code standards don't match existing code**
If the codebase uses `log.Printf` but AGENTS.md says "use zerolog", QA will block every PR that touches existing code. Write what the code *actually does* first, then plan a migration.

**4. Definition-of-done journeys are aspirational**
If Journey 1 requires a feature that doesn't exist yet, agents will try to implement it immediately rather than working through the roadmap. Write journeys that can be achieved incrementally.

**5. Missing area/* labels**
Agents create issues with `area/<component>` labels. If these labels don't exist in GitHub, `gh issue create` fails silently. Create all labels before starting.

---

## First-run smoke test

After running `/otherness.run` for the first time, verify the system is working within 20 minutes:

### 3 signals of a healthy first run

**Signal 1 — Startup comment on report issue**
```bash
REPO=$(git remote get-url origin | sed 's|.*github.com[:/]||;s|\.git$||')
REPORT_ISSUE=$(python3 -c "
import re
for line in open('AGENTS.md'):
    m = re.match(r'^REPORT_ISSUE:\s*(\S+)', line.strip())
    if m: print(m.group(1)); break
" 2>/dev/null || echo "")
gh issue view "$REPORT_ISSUE" --repo "$REPO" --comments \
  --jq '.comments[-1].body' 2>/dev/null | head -3
# Expected: "[STANDALONE | sess-XXXX | otherness@...] Session started. Repo: ..."
```

**Signal 2 — feat/* branch appeared on remote (item claimed)**
```bash
git fetch --prune --quiet 2>/dev/null
git ls-remote --heads origin 'feat/*' | head -5
# Expected: at least one feat/issue-XXXX branch
```

**Signal 3 — Open PR created**
```bash
gh pr list --repo "$REPO" --state open --json number,title,createdAt \
  --jq '.[] | "#\(.number) \(.title[:60]) (\(.createdAt[:10]))"' 2>/dev/null | head -5
# Expected: at least one open PR from this session
```

### If 20 minutes pass with no open PR and no [NEEDS HUMAN] issue

1. **Check _state branch activity** (most reliable signal):
   ```bash
   gh api "repos/$REPO/branches/_state" \
     --jq '.commit.commit.committer.date' 2>/dev/null
   # If older than 30 minutes: session may have stalled or not started
   ```

2. **Check GitHub Actions run**:
   ```bash
   gh run list --repo "$REPO" --limit 3 \
     --json status,conclusion,name,createdAt \
     --jq '.[] | "\(.status) \(.conclusion) \(.name) \(.createdAt[:16])"'
   # Look for in_progress or completed runs
   ```

3. **Check for [NEEDS HUMAN] issues**:
   ```bash
   gh issue list --repo "$REPO" --state open --label "needs-human" \
     --json number,title --jq '.[] | "#\(.number) \(.title[:60])"' 2>/dev/null
   # If present: read the issue — it will say exactly what failed
   ```

4. **If CI is red**: Check `scripts/validate.sh` locally — a failing validate check
   prevents the agent from starting meaningful work.

### Common first-run failures

| Symptom | Likely cause | Fix |
|---|---|---|
| No startup comment on report issue | Agent did not start / wrong GH_TOKEN | Check GitHub Actions logs |
| Startup comment but no feat/* branch | Queue empty or lock contention | Wait 5 min — next cycle |
| feat/* branch but no PR | Build/test failing | Check CI run for errors |
| [NEEDS HUMAN: no vision] | docs/aide/vision.md missing | Run `/otherness.vibe-vision` first |
| [NEEDS HUMAN: ci-red-3-attempts] | scripts/validate.sh failing | Run validate.sh locally and fix |

---

## Is the loop still working?

Run these three checks any time you want to confirm the autonomous loop is healthy (not just after first run — use this days or weeks later too). All three should take under 5 minutes combined.

### One-shot health check (< 2 minutes)

Copy-paste this entire block. It runs all three checks and prints a GREEN / AMBER / RED summary:

```bash
REPO=$(git remote get-url origin 2>/dev/null | sed 's|.*github.com[:/]||;s|\.git$||')

python3 - <<'EOF'
import subprocess, json, datetime, sys

REPO = subprocess.check_output(
    ['git','remote','get-url','origin'], text=True
).strip().split('github.com')[-1].lstrip(':/').rstrip('.git')

results = {}

# Check 1: _state updated in last 24h
try:
    r = subprocess.run(['gh','api',f'repos/{REPO}/branches/_state',
                        '--jq','.commit.commit.committer.date'],
                       capture_output=True, text=True, timeout=10)
    if r.returncode == 0 and r.stdout.strip():
        d = datetime.datetime.fromisoformat(r.stdout.strip().replace('Z','+00:00'))
        age_h = (datetime.datetime.now(datetime.timezone.utc) - d).total_seconds() / 3600
        results['_state age'] = ('PASS', f'{age_h:.0f}h ago') if age_h < 24 else ('FAIL', f'{age_h:.0f}h ago — stalled')
    else:
        results['_state age'] = ('FAIL', 'branch not found — loop never ran')
except Exception as e:
    results['_state age'] = ('WARN', f'could not check: {e}')

# Check 2: at least 1 PR in last 7 days
try:
    r = subprocess.run(['gh','pr','list','--repo',REPO,'--state','all','--limit','30',
                        '--json','title,createdAt,mergedAt'],
                       capture_output=True, text=True, timeout=10)
    if r.returncode == 0:
        prs = json.loads(r.stdout)
        cutoff = (datetime.datetime.now(datetime.timezone.utc) - datetime.timedelta(days=7)).isoformat()
        recent = [p for p in prs if (p.get('createdAt','') >= cutoff or
                                     (p.get('mergedAt') and p['mergedAt'] >= cutoff))]
        results['PRs last 7d'] = ('PASS', f'{len(recent)} PR(s)') if recent else ('FAIL', '0 PRs — loop alive but not shipping')
    else:
        results['PRs last 7d'] = ('WARN', 'could not list PRs')
except Exception as e:
    results['PRs last 7d'] = ('WARN', f'could not check: {e}')

# Check 3: no [NEEDS HUMAN] older than 48h
try:
    r = subprocess.run(['gh','issue','list','--repo',REPO,'--state','open',
                        '--label','needs-human','--json','number,title,createdAt'],
                       capture_output=True, text=True, timeout=10)
    if r.returncode == 0:
        issues = json.loads(r.stdout)
        cutoff = (datetime.datetime.now(datetime.timezone.utc) - datetime.timedelta(hours=48)).isoformat()
        stale = [i for i in issues if i.get('createdAt','') < cutoff]
        if stale:
            details = ', '.join(f'#{i["number"]}' for i in stale[:3])
            results['[NEEDS HUMAN]'] = ('FAIL', f'{len(stale)} stale escalation(s): {details}')
        else:
            results['[NEEDS HUMAN]'] = ('PASS', f'{len(issues)} open, none stale')
    else:
        results['[NEEDS HUMAN]'] = ('WARN', 'could not list issues')
except Exception as e:
    results['[NEEDS HUMAN]'] = ('WARN', f'could not check: {e}')

# Print results
any_fail = any(v[0] == 'FAIL' for v in results.values())
any_warn = any(v[0] == 'WARN' for v in results.values())
overall = 'RED' if any_fail else ('AMBER' if any_warn else 'GREEN')

print(f'\n{"="*50}')
print(f'  otherness health: {overall}')
print(f'{"="*50}')
for check, (status, detail) in results.items():
    icon = '✅' if status == 'PASS' else ('⚠️ ' if status == 'WARN' else '❌')
    print(f'  {icon} {check}: {detail}')
print()

if overall == 'GREEN':
    print('  Loop is healthy. No action needed.')
elif overall == 'AMBER':
    print('  Loop is probably fine — one check could not run. Inspect manually.')
else:
    print('  Action required — see failing check(s) above.')
EOF
```

---

### Individual checks (if you prefer step-by-step)

```bash
REPO=$(git remote get-url origin | sed 's|.*github.com[:/]||;s|\.git$||')
```

### Check 1 — `_state` branch updated in last 24h

```bash
LAST=$(gh api "repos/$REPO/branches/_state" \
  --jq '.commit.commit.committer.date' 2>/dev/null || echo "NOT FOUND")
AGE_H=$(python3 -c "
import datetime
try:
    d = datetime.datetime.fromisoformat('$LAST'.replace('Z','+00:00'))
    print(int((datetime.datetime.now(datetime.timezone.utc) - d).total_seconds() / 3600))
except:
    print(9999)
" 2>/dev/null || echo "9999")
echo "_state last updated: ${LAST} (${AGE_H}h ago)"
# PASS: AGE_H < 24
# FAIL: "NOT FOUND" → loop never ran; AGE_H ≥ 24 → loop has stalled
```

**What to do if failing:**
- `NOT FOUND` — the first session never completed; check GitHub Actions workflow for errors
- `>= 24h ago` — check whether the scheduled workflow is enabled: `gh workflow list --repo "$REPO"`

### Check 2 — At least one PR opened or merged in last 7 days

```bash
FEAT_PRS=$(gh pr list --repo "$REPO" --state all --limit 30 \
  --json title,createdAt,mergedAt \
  --jq '[.[] | select(
    (.createdAt >= (now - 604800 | strftime("%Y-%m-%dT%H:%M:%SZ"))) or
    (.mergedAt != null and .mergedAt >= (now - 604800 | strftime("%Y-%m-%dT%H:%M:%SZ")))
  ) | .title] | length' 2>/dev/null || echo "0")
echo "PRs in last 7 days: $FEAT_PRS"
# PASS: FEAT_PRS >= 1
# FAIL: 0 — loop is alive but not shipping work
```

**What to do if failing:**
- Check whether the queue is empty: `gh issue list --repo "$REPO" --label "otherness" --state open`
- If empty, run `/otherness.vibe-vision` to inject new work into the design docs

### Check 3 — No `[NEEDS HUMAN]` issues older than 48h

```bash
OLD_NH=$(gh issue list --repo "$REPO" --state open --label "needs-human" \
  --json number,title,createdAt \
  --jq '[.[] | select(.createdAt < (now - 172800 | strftime("%Y-%m-%dT%H:%M:%SZ")))] | length' \
  2>/dev/null || echo "0")
echo "[NEEDS HUMAN] issues older than 48h: $OLD_NH"
# PASS: OLD_NH == 0
# FAIL: > 0 — escalations are blocking the loop; read each issue and resolve or close
```

**What to do if failing:**
```bash
# List the stale escalations
gh issue list --repo "$REPO" --state open --label "needs-human" \
  --json number,title,createdAt \
  --jq '.[] | "#\(.number) (\(.createdAt[:10])) \(.title[:70])"'
```

---

**One-command alternative**: `/otherness.status` covers all three checks plus queue depth, simulation health, and reference project activity in a single dashboard view.
