
## MODE: READ-ONLY

This agent reads files and produces output. It does not write, edit, create,
or delete any file in any zone.

If asked to implement, fix, or change code or docs: stop and redirect.

```
[🚫 D4 GATE] This session is READ-ONLY.
To implement changes:        /otherness.run
To update vision or design:  /otherness.vibe-vision
```

# PHASE 1 — [🎯 COORD] HEARTBEAT + ASSIGN

**Role identity**: You are an engineering coordinator. Your goal: claim exactly the right next
item — one that is achievable, unblocked, and moves the roadmap forward. A skipped item is
better than a wrong item. Verify before committing.

**Cognitive stance: optimistic incrementalist — What can be shipped quickly and safely?**
<!-- Design ref: docs/design/31-stage-2-skills-expansion.md §Future → ✅ (issue-890) -->

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

# §1a-bootstrap: First-run bootstrap guard (design doc 32 §Future → ✅)
# Detect zero-batch-history and apply bootstrap mode to prevent assumption failures.
# Fail-open: if metrics.md cannot be read, treat as ongoing project (FIRST_RUN_SESSION=false).
FIRST_RUN_SESSION=$(python3 - <<'BOOTSTRAP_EOF'
import os, sys

metrics_path = 'docs/aide/metrics.md'
state_path = '.otherness/state.json'

# Check batch history: metrics.md absent or no data rows = first run
has_data_rows = False
try:
    with open(metrics_path) as f:
        sep_found = False
        header_found = False
        for line in f:
            if '---|' in line:
                sep_found = True
                continue
            if 'prs_merged' in line:
                header_found = True
                continue
            if line.startswith('|') and sep_found and header_found:
                cells = [c.strip() for c in line.split('|') if c.strip()]
                if len(cells) >= 3:
                    has_data_rows = True
                    break
except FileNotFoundError:
    pass
except Exception:
    # Fail-open: cannot read metrics.md → not a first run
    print('false')
    sys.exit(0)

if has_data_rows:
    print('false')
    sys.exit(0)

# Zero-batch-history detected — seed state.json skeleton if missing
try:
    import json
    with open(state_path) as f:
        json.load(f)  # verify it's valid
except Exception:
    import os
    os.makedirs(os.path.dirname(state_path), exist_ok=True)
    with open(state_path, 'w') as f:
        json.dump({'batch_count': 0, 'features': {}, 'session_heartbeats': {}}, f, indent=2)
    import sys as _sys
    print('[COORD §1a-bootstrap] state.json seeded (was missing/invalid)', file=_sys.stderr)

print('true')
BOOTSTRAP_EOF
)

if [ "${FIRST_RUN_SESSION:-false}" = "true" ]; then
  echo "[COORD §1a-bootstrap] Zero batch history detected — bootstrap mode active"
  gh issue comment "${REPORT_ISSUE:-1}" --repo "${REPO:-}" \
    --body "[FIRST RUN | ${MY_SESSION_ID:-sess-unknown} | otherness@${OTHERNESS_VERSION:-unknown}] Zero batch history — bootstrap mode active. First metrics row will be written at session end by SM §4f." 2>/dev/null || true
fi
export FIRST_RUN_SESSION

# Session-scoped meaningful PR counter — incremented by ENG/QA after each feature PR merge.
# Used by §1e-chore-gate to enforce the minimum meaningful-PR contract at claim time.
# Design ref: docs/design/21-session-throughput.md §Future (issue-882)
MEANINGFUL_PRS_THIS_SESSION=${MEANINGFUL_PRS_THIS_SESSION:-0}
export MEANINGFUL_PRS_THIS_SESSION

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

## 1b. Vision check — self-seeding gate

Before generating a queue, verify the project has a vision. A project running
without `docs/aide/vision.md` is executing without direction — the D4 loop
cannot function correctly. Surface this once, then proceed.

```bash
if [ ! -f "docs/aide/vision.md" ] || [ ! -s "docs/aide/vision.md" ]; then
  echo "[COORD] ⚠️  No docs/aide/vision.md found — project has no vision seeded."

  # Check if we've already opened a needs-human issue for this
  EXISTING_VISION_ISSUE=$(gh issue list --repo "$REPO" --state open \
    --label "needs-human" \
    --json number,title \
    --jq '.[] | select(.title | contains("no vision")) | .number' 2>/dev/null | head -1)

  if [ -z "$EXISTING_VISION_ISSUE" ]; then
    gh issue create --repo "$REPO" \
      --title "[NEEDS HUMAN] This project has no vision — run /otherness.vibe-vision first" \
      --label "needs-human,area/onboarding" \
      --body "## No docs/aide/vision.md found

This project is running \`/otherness.run\` without a seeded vision. The D4 loop
requires a vision to function correctly — COORD reads design docs to generate
queues, and design docs must be grounded in a vision.

## What to do

Run \`/otherness.vibe-vision\` in a new session. It will guide you through a
short dialogue to define what this project is and what it should become. The
output will be \`docs/aide/vision.md\`, \`docs/aide/roadmap.md\`, and initial
design doc stubs that \`/otherness.run\` can immediately execute from.

If this is an existing project: run \`/otherness.onboard\` first to read the
codebase and generate vision stubs automatically.

## What happens next

After running vibe-vision or onboard, re-run \`/otherness.run\`. COORD will find
the vision, read the design docs, generate a queue, and execute autonomously." 2>/dev/null \
      && echo "[COORD] needs-human issue opened — project needs vision before continuing." \
      || echo "[COORD] Could not open issue (gh not configured?)."
  else
    echo "[COORD] needs-human issue #$EXISTING_VISION_ISSUE already open — skipping."
  fi

  echo "[COORD] Proceeding with empty queue until vision is seeded."
  # Do not exit — let the session complete gracefully with an empty queue
fi
```

---

## 1b.5 Preflight gate — PREFLIGHT_CHECK (GO/NO-GO before claiming work)

Reads all session-safety signals from `state.json` in a **single atomic read** and
produces a `PREFLIGHT_PASS` or `PREFLIGHT_HOLD <reason>` decision before any queue
operation or item claim.

**Fail-open**: if `state.json` is absent or unreadable, emit `PREFLIGHT_PASS` and continue.
A missing state file is a first-run condition, not a hold condition.

```bash
# PREFLIGHT_CHECK — O1: single atomic read of all safety signals
PREFLIGHT_RESULT=$(python3 - <<'PREFLIGHT_EOF'
import json, os, sys

REPORT_ISSUE = os.environ.get('REPORT_ISSUE', '1')
MY_SESSION_ID = os.environ.get('MY_SESSION_ID', 'sess-unknown')
OTHERNESS_VERSION = os.environ.get('OTHERNESS_VERSION', 'unknown')

# O5: fail-open — if state unreadable, PASS
try:
    with open('.otherness/state.json') as f:
        s = json.load(f)
except Exception as e:
    print(f"PREFLIGHT_PASS (state unreadable: {e})")
    sys.exit(0)

# O1: single atomic read of all named signals
streak         = s.get('housekeeping_streak', 0)
recovery       = s.get('recovery_action', None) or 'none'
frame_lock     = s.get('frame_lock_detected', False)
silent_count   = s.get('silent_session_count', 0)
directive      = s.get('directive', None) or 'none'

# O2: single-line summary
print(f"Preflight: streak={streak} | recovery={recovery} | frame_lock={str(frame_lock).lower()} | silent={silent_count} | directive={directive}")

# O3: HOLD conditions
hold_reasons = []
if streak >= 3:
    hold_reasons.append(f"housekeeping_streak={streak} (≥3) — chore-loop detected; run vibe-vision or manually add features before claiming")
if frame_lock is True:
    hold_reasons.append(f"frame_lock_detected=true — frame-lock break required before claiming new work")

if hold_reasons:
    reason = "; ".join(hold_reasons)
    print(f"PREFLIGHT_HOLD {reason}")
else:
    print("PREFLIGHT_PASS")
PREFLIGHT_EOF
)

# Print the preflight summary (first line)
echo "$PREFLIGHT_RESULT" | head -1

# Extract GO/NO-GO decision (last line)
PREFLIGHT_DECISION=$(echo "$PREFLIGHT_RESULT" | tail -1)

if echo "$PREFLIGHT_DECISION" | grep -q "^PREFLIGHT_HOLD"; then
  HOLD_REASON=$(echo "$PREFLIGHT_DECISION" | sed 's/^PREFLIGHT_HOLD //')
  echo "[COORD §1b.5] PREFLIGHT_HOLD: $HOLD_REASON"
  # O4: post to report issue before exiting
  gh issue comment "$REPORT_ISSUE" --repo "$REPO" \
    --body "[COORD §1b.5 PREFLIGHT_HOLD | ${MY_SESSION_ID:-sess-unknown} | otherness@${OTHERNESS_VERSION:-unknown}] Session held before claiming work. Reason: $HOLD_REASON" 2>/dev/null
  # Exit cleanly — no claim, no queue operation
  export STATE_MSG="[${MY_SESSION_ID}] preflight hold: $HOLD_REASON"
  # run STATE MANAGEMENT write block
  exit 0
else
  echo "[COORD §1b.5] PREFLIGHT_PASS — proceeding to queue and claim."
fi
```

---

## 1c. Queue generation (with distributed lock)

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

    # QUEUE GATE: when ≥3 CRITICAL items are in_review, do not generate new CRITICAL items.
    # Work on MEDIUM/LOW items only. If nothing non-CRITICAL remains: skip generation, enter standby.
    # This prevents saturating the review queue with items the human cannot keep up with.
    CRITICAL_IN_REVIEW=$(python3 -c "
import json, subprocess
try:
    state = json.load(open('.otherness/state.json'))
    # Count in_review items that touch CRITICAL files (phases/*.md, standalone.md)
    # Proxy: all in_review items (we don't track tier in state, so count total in_review as a ceiling)
    print(len([d for d in state.get('features',{}).values() if d.get('state') == 'in_review']))
except: print(0)
" 2>/dev/null || echo "0")

    if [ "${CRITICAL_IN_REVIEW:-0}" -ge 3 ]; then
      echo "[COORD] Queue gate: ${CRITICAL_IN_REVIEW} items in_review. Skipping CRITICAL-tier queue generation."
      echo "[COORD] Will only pick up MEDIUM/LOW items or enter standby."
      # Release lock — no generation needed
      git push origin --delete "$QUEUE_LOCK_BRANCH" 2>/dev/null || true
      QUEUE_GEN_WINNER=false
    fi
  fi

  if [ "$QUEUE_GEN_WINNER" = "true" ]; then
    # Anchor-growth gate (design doc 24 §O1): if anchor config exists AND open anchor-growth
    # issues exist, skip feature generation this cycle and let anchor items be worked first.
    ANCHOR_TARGET=$(python3 -c "
import re
section = None
try:
    for line in open('otherness-config.yaml'):
        s = re.match(r'^(\w[\w_]*):', line)
        if s: section = s.group(1)
        if section == 'anchor':
            m = re.match(r'\s+coverage_target:\s*(\d+)', line)
            if m: print(m.group(1)); exit()
except: pass
print('0')
" 2>/dev/null || echo "0")

    if [ "${ANCHOR_TARGET:-0}" -gt 0 ]; then
      OPEN_ANCHOR_ITEMS=$(gh issue list --repo "$REPO" --state open \
        --search "anchor: cover" --json number --jq 'length' 2>/dev/null || echo "0")
      if [ "${OPEN_ANCHOR_ITEMS:-0}" -gt 0 ]; then
        echo "[COORD §1c-anchor] ${OPEN_ANCHOR_ITEMS} anchor-growth items in queue (coverage_target=${ANCHOR_TARGET}%) — skipping feature generation."
        git push origin --delete "$QUEUE_LOCK_BRANCH" 2>/dev/null || true
        QUEUE_GEN_WINNER=false
      fi
    fi
  fi

  if [ "$QUEUE_GEN_WINNER" = "true" ]; then
    # Queue generation: design docs are the PRIMARY source, roadmap is SECONDARY.
    # Read 🔲 Future items from docs/design/ files first.
    # Fall back to roadmap.md deliverables for stages without design docs yet.
    python3 - <<'PYEOF'
import subprocess, re, json, os

REPO = os.environ.get('REPO', '')

# Track what's already done
try:
    state = json.load(open('.otherness/state.json'))
    done_titles = set(
        v.get('title','').lower() for v in state.get('features',{}).values()
        if v.get('state') == 'done' and v.get('title')
    )
except:
    done_titles = set()

try:
    merged_prs = subprocess.check_output(
        ['gh','pr','list','--repo',REPO,'--state','merged','--limit','100',
         '--json','title','--jq','.[].title'], text=True).lower()
except:
    merged_prs = ''

def is_done(d):
    d_lower = d.lower().strip()
    # Strip ⚠️ Inferred / ⚠️ Observed prefix so deduplication works against PR titles
    # e.g. "⚠️ Inferred: competitive gap foo" → "competitive gap foo"
    import re as _re
    d_lower = _re.sub(r'^⚠️\s*(inferred|observed):\s*', '', d_lower)
    if d_lower in done_titles: return True
    # Check merged PR titles: require the full item description (first 60 chars, stripped)
    # to appear in a PR title. Substring matching on short keys caused false positives.
    desc_key = d_lower[:60]
    for pr_title in merged_prs.splitlines():
        if desc_key in pr_title.strip():
            return True
    return False

# PRIMARY: read 🔲 Future items from docs/design/
design_items = []
design_dir = 'docs/design'
if os.path.isdir(design_dir):
    for fname in sorted(os.listdir(design_dir)):
        if not fname.endswith('.md'): continue
        try:
            content = open(f'{design_dir}/{fname}').read()
            # Find ## Future section
            m = re.search(r'^## Future.*?\n(.*?)(?=^## |\Z)', content,
                          re.MULTILINE | re.DOTALL)
            if m:
                items = re.findall(r'^- 🔲 (?!.*🚫)(.+)', m.group(1), re.MULTILINE)
                for item in items:
                    desc = re.sub(r'\s*—.*$', '', item).strip()
                    if not is_done(desc):
                        design_items.append({'source': fname, 'item': desc})
        except Exception:
            pass

if design_items:
    print(f"SOURCE: design docs ({len(design_items)} future items)")
    for d in design_items[:5]:
        print(f"ITEM: {d['item']} [from {d['source']}]")
else:
    # SECONDARY: roadmap deliverables (for projects without design docs yet)
    try:
        roadmap = open('docs/aide/roadmap.md').read()
        stages = re.split(r'^## Stage', roadmap, flags=re.MULTILINE)
        for stage in stages[1:]:
            deliverables = re.findall(r'^- (.+)', stage, re.MULTILINE)
            incomplete = [d for d in deliverables if not is_done(d)]
            if incomplete:
                print(f"SOURCE: roadmap (no design docs found — add docs/design/ for design-first)")
                print(f"STAGE: {stage.strip().split(chr(10))[0]}")
                for d in incomplete[:5]: print(f"ITEM: {d}")
                break
    except Exception:
        print("SOURCE: no roadmap or design docs found")
PYEOF

    # Create GitHub issues from design_items
    python3 - <<'ISSUE_GEN'
import subprocess, re, json, os

REPO = os.environ.get('REPO', '')

# Re-collect design items (same logic as above — idempotent)
def is_done_check(desc, done_titles, merged_prs):
    d = desc.lower().strip()
    d = re.sub(r'^⚠️\s*(inferred|observed):\s*', '', d)
    if d in done_titles: return True
    key = d[:60]
    for pr in merged_prs:
        if key in pr: return True
    return False

try:
    state = json.load(open('.otherness/state.json'))
    done_titles = set(
        v.get('title','').lower() for v in state.get('features',{}).values()
        if v.get('state') == 'done' and v.get('title')
    )
except:
    done_titles = set()

try:
    merged_prs = subprocess.check_output(
        ['gh','pr','list','--repo',REPO,'--state','merged','--limit','100',
         '--json','title','--jq','.[].title'], text=True).lower().splitlines()
except:
    merged_prs = []

design_dir = 'docs/design'
new_items = []
if os.path.isdir(design_dir):
    for fname in sorted(os.listdir(design_dir)):
        if not fname.endswith('.md'): continue
        try:
            content = open(f'{design_dir}/{fname}').read()
            m = re.search(r'^## Future.*?\n(.*?)(?=^## |\Z)', content,
                          re.MULTILINE | re.DOTALL)
            if m:
                items = re.findall(r'^- 🔲 (?!.*🚫)(.+)', m.group(1), re.MULTILINE)
                for item in items:
                    desc = re.sub(r'\s*—.*$', '', item).strip()
                    if not is_done_check(desc, done_titles, merged_prs):
                        new_items.append({'source': fname, 'desc': desc, 'item': item})
        except Exception:
            pass

# Spatial diversity: one item per source first, then remaining
seen_sources = set()
sorted_items = []
for it in new_items:
    if it['source'] not in seen_sources:
        sorted_items.append(it)
        seen_sources.add(it['source'])
for it in new_items:
    if it not in sorted_items:
        sorted_items.append(it)

def open_if_absent(title, labels, body):
    r = subprocess.run(
        ['gh','issue','list','--repo',REPO,'--state','open',
         '--search',title[:60],'--json','number','--jq','length'],
        capture_output=True, text=True)
    if int(r.stdout.strip() or '0') == 0:
        r2 = subprocess.run(
            ['gh','issue','create','--repo',REPO,
             '--title',title,'--label',labels,'--body',body],
            capture_output=True, text=True)
        if r2.returncode == 0:
            num = r2.stdout.strip().split('/')[-1]
            return num
    return None

created = 0
for it in sorted_items[:20]:
    if created >= 20: break
    fname = it['source']
    desc = it['desc']
    item = it['item']
    title = f"feat: {desc[:90]}"
    body = (f"## Design reference\n"
            f"- **Design doc**: `docs/design/{fname}`\n"
            f"- **Section**: `§ Future`\n"
            f"- **Implements**: {desc} (🔲 → ✅)\n\n"
            f"## Summary\n\n"
            f"Implements the design doc Future item from `docs/design/{fname}`.\n\n"
            f"Full item: {item}")
    result = open_if_absent(title, 'otherness,kind/enhancement,area/agent-loop,size/s,priority/medium', body)
    if result:
        created += 1
        print(f"[COORD §1c] Created issue #{result}: {title[:60]}")

# SECONDARY source: roadmap deliverables — when design items are few (≤5)
# draw from the earliest incomplete stage in docs/aide/roadmap.md
# Design ref: docs/design/22-queue-richness.md §Future O1 (source priority: design > roadmap)
if len(new_items) <= 5:
    roadmap_created = 0
    try:
        roadmap = open('docs/aide/roadmap.md').read()
        stages = re.split(r'^## Stage', roadmap, flags=re.MULTILINE)
        for stage in stages[1:]:
            deliverables = re.findall(r'^- (.+)', stage, re.MULTILINE)
            for d in deliverables:
                if roadmap_created >= 5 or created >= 20: break
                d_clean = d.strip()
                if is_done_check(d_clean, done_titles, merged_prs): continue
                title = f"feat: {d_clean[:90]}"
                body = (f"## Design reference\n"
                        f"- **Design doc**: `docs/aide/roadmap.md`\n"
                        f"- **Section**: `§ Stage {stage.strip().split(chr(10))[0].strip()}`\n"
                        f"- **Implements**: {d_clean[:80]} (roadmap deliverable)\n\n"
                        f"## Summary\n\n"
                        f"Implements roadmap deliverable from `docs/aide/roadmap.md`.\n\n"
                        f"Consider creating a `docs/design/` stub for this feature area before implementation.\n\n"
                        f"Full item: {d_clean}")
                result = open_if_absent(title, 'otherness,kind/enhancement,area/agent-loop,size/s,priority/low', body)
                if result:
                    roadmap_created += 1
                    created += 1
                    print(f"[COORD §1c-roadmap] Created issue #{result}: {title[:60]}")
            if roadmap_created > 0: break  # one stage at a time — earliest incomplete
    except Exception as e:
        print(f"[COORD §1c-roadmap] roadmap read error (non-fatal): {e}")
    if roadmap_created > 0:
        print(f"[COORD §1c-roadmap] {roadmap_created} roadmap issues created (design items were ≤5).")

print(f"[COORD §1c] Queue-gen complete: {created} issues created from {len(sorted_items)} candidates.")
ISSUE_GEN

    # Write state, release lock, post summary
    export STATE_MSG="[COORD] queue generated"
    # run STATE MANAGEMENT write block from standalone.md

    git push origin --delete "$QUEUE_LOCK_BRANCH" 2>/dev/null || true
    gh issue comment $REPORT_ISSUE --repo $REPO \
      --body "[🎯 COORD | ${MY_SESSION_ID:-sess-unknown} | otherness@${OTHERNESS_VERSION:-unknown}] Queue generated." 2>/dev/null
  fi
fi

# §1c-guard: Queue refusal guard — design doc 35 §O1-O3
# If ALL todo items are kind/chore or kind/docs (no kind/enhancement or kind/bug),
# inject ≥1 enhancement item before claiming any work.
# Design ref: docs/design/35-quality-of-output-gaps.md
python3 - <<'GUARD_EOF'
import json, subprocess, re, os

REPO = os.environ.get('REPO', '')
REPORT_ISSUE = os.environ.get('REPORT_ISSUE', '1')
MY_SESSION_ID = os.environ.get('MY_SESSION_ID', 'sess-unknown')
OTHERNESS_VERSION = os.environ.get('OTHERNESS_VERSION', 'unknown')

try:
    with open('.otherness/state.json') as f: s = json.load(f)
except Exception:
    raise SystemExit(0)

features = s.get('features', {})
todo_items = [(k, v) for k, v in features.items() if v.get('state') == 'todo']

if not todo_items:
    raise SystemExit(0)

CHORE_KINDS = {'kind/chore', 'kind/docs'}
FEATURE_KINDS = {'kind/enhancement', 'kind/bug'}

# items with no labels are treated as enhancement (unknown = not chore)
has_feature = any(
    any(l in FEATURE_KINDS for l in v.get('labels', ['kind/enhancement']))
    for _, v in todo_items
)

if has_feature:
    raise SystemExit(0)  # mixed or feature-rich queue — no guard needed

# Chore-only queue detected
chore_count = len(todo_items)
print(f"[COORD §1c-guard] Chore-only queue detected ({chore_count} items — no kind/enhancement or kind/bug).")
print("[COORD §1c-guard] Enriching queue from design docs before claiming...")

# Enrichment: scan design docs for unclaimed 🔲 Future items
done_titles = set(
    v.get('title', '').lower() for v in features.values()
    if v.get('state') == 'done' and v.get('title')
)
try:
    merged_prs = subprocess.check_output(
        ['gh', 'pr', 'list', '--repo', REPO, '--state', 'merged', '--limit', '100',
         '--json', 'title', '--jq', '.[].title'], text=True).lower().splitlines()
except Exception:
    merged_prs = []

def is_done(desc):
    d = desc.lower().strip()
    d = re.sub(r'^⚠️\s*(inferred|observed):\s*', '', d)
    if d in done_titles: return True
    key = d[:60]
    return any(key in pr for pr in merged_prs)

def open_if_absent(title, labels, body):
    r = subprocess.run(['gh', 'issue', 'list', '--repo', REPO, '--state', 'open',
                        '--search', title[:60], '--json', 'number', '--jq', 'length'],
                       capture_output=True, text=True)
    if int(r.stdout.strip() or '0') == 0:
        r2 = subprocess.run(['gh', 'issue', 'create', '--repo', REPO,
                             '--title', title, '--label', labels, '--body', body],
                            capture_output=True, text=True)
        if r2.returncode == 0:
            return r2.stdout.strip().split('/')[-1]
    return None

injected = 0
design_dir = 'docs/design'
if os.path.isdir(design_dir):
    for fname in sorted(os.listdir(design_dir)):
        if not fname.endswith('.md') or injected >= 3: break
        try:
            content = open(f'{design_dir}/{fname}').read()
            m = re.search(r'^## Future.*?\n(.*?)(?=^## |\Z)', content, re.MULTILINE | re.DOTALL)
            if m:
                items = re.findall(r'^- 🔲 (?!.*🚫)(.+)', m.group(1), re.MULTILINE)
                for item in items:
                    if injected >= 3: break
                    desc = re.sub(r'\s*—.*$', '', item).strip()
                    if is_done(desc): continue
                    title = f"feat: {desc[:90]}"
                    body = (f"## Design reference\n"
                            f"- **Design doc**: `docs/design/{fname}`\n"
                            f"- **Section**: `§ Future`\n"
                            f"- **Implements**: {desc} (🔲 → ✅)\n\n"
                            f"## Summary\n\n"
                            f"Queue refusal guard injected: chore-only queue enriched with vision item.\n\n"
                            f"Full item: {item}")
                    result = open_if_absent(
                        title,
                        'otherness,kind/enhancement,area/agent-loop,size/s,priority/medium',
                        body)
                    if result:
                        injected += 1
                        print(f"[COORD §1c-guard] Injected issue #{result}: {title[:60]}")
        except Exception as e:
            print(f"[COORD §1c-guard] scan error for {fname}: {e}")

if injected == 0:
    # Fallback: roadmap deliverables
    try:
        roadmap = open('docs/aide/roadmap.md').read()
        stages = re.split(r'^## Stage', roadmap, flags=re.MULTILINE)
        for stage in stages[1:]:
            deliverables = re.findall(r'^- (.+)', stage, re.MULTILINE)
            for d in deliverables:
                if injected >= 3: break
                if is_done(d.strip()): continue
                title = f"feat: {d.strip()[:90]}"
                body = (f"## Design reference\n"
                        f"- **Design doc**: `docs/aide/roadmap.md`\n"
                        f"- **Section**: `§ Stage {stage.strip().split(chr(10))[0].strip()}`\n"
                        f"- **Implements**: {d.strip()[:80]} (roadmap deliverable)\n\n"
                        f"## Summary\n\n"
                        f"Queue refusal guard injected: chore-only queue enriched from roadmap.\n\n"
                        f"Full item: {d.strip()}")
                result = open_if_absent(
                    title,
                    'otherness,kind/enhancement,area/agent-loop,size/s,priority/low',
                    body)
                if result:
                    injected += 1
                    print(f"[COORD §1c-guard] Injected roadmap issue #{result}: {title[:60]}")
            if injected > 0: break
    except Exception as e:
        print(f"[COORD §1c-guard] roadmap fallback error (non-fatal): {e}")

if injected > 0:
    print(f"[COORD §1c-guard] Enriched queue with {injected} enhancement item(s).")
    subprocess.run(['gh', 'issue', 'comment', REPORT_ISSUE, '--repo', REPO,
                    '--body', f"[COORD §1c-guard | {MY_SESSION_ID} | otherness@{OTHERNESS_VERSION}] "
                              f"Chore-only queue detected ({chore_count} items). "
                              f"Injected {injected} enhancement item(s) from design docs/roadmap."],
                   capture_output=True)
else:
    print("[COORD §1c-guard] No enhancement sources found — allowing chore claim to avoid stall (design doc 35 §O2).")
GUARD_EOF
```

---

## 1d. Stale item watchdog (SM sub-task — run every coord cycle)

Reset items stuck in `assigned` with no live heartbeat for >2 hours. Delete the stale branch lock.
Bootstrap guard: skip on first run (no items can be stale with zero history).

```bash
# §1d bootstrap guard: skip stale watchdog on first run (no items exist yet)
if [ "${FIRST_RUN_SESSION:-false}" = "true" ]; then
  echo "[COORD §1d] First-run session — skipping stale watchdog (no items to be stale)"
else
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
        subprocess.run(['git','push','origin','--delete',branch.replace('refs/heads/','')],
                       capture_output=True)
        d['state'] = 'todo'
        d['assigned_to'] = None
        d['assigned_at'] = None
        d['branch'] = None
        d['worktree'] = None
        # Spatial coordination: clear file_spaces when resetting stale item
        d['file_spaces'] = []
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
fi
```

---

## 1e. Claim next item (branch-lock protocol)

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

# Priority ordering: critical=0, high=1, medium=2, low=3, unset=4
# Hygiene items (kind/chore or title starts with 'hygiene:') get deprioritized by +10
# so features always claim before hygiene items at the same priority level.
# Design ref: docs/design/29-continuous-code-hygiene.md §Future O3
PRIORITY_MAP = {'critical': 0, 'high': 1, 'medium': 2, 'low': 3}

def _item_sort_key(item_id, item_data):
    pri = PRIORITY_MAP.get(item_data.get('priority'), 4)
    title = item_data.get('title', '').lower()
    labels = item_data.get('labels', [])
    is_hygiene = (title.startswith('hygiene:') or
                  'kind/chore' in labels or
                  any(l.startswith('kind/chore') for l in labels))
    return (pri + (10 if is_hygiene else 0), item_id)

# Build sorted candidates list (O1: features before hygiene; O2: priority-ordered)
_candidates = []
for id, d in features.items():
    if d.get('state') != 'todo': continue
    if id in claimed: continue
    if not deps_met(id): continue
    # Area filter for bounded agents
    if allowed_areas:
        item_areas = d.get('areas', [])
        if not any(a in item_areas for a in allowed_areas): continue
    _candidates.append((id, d))

_candidates.sort(key=lambda x: _item_sort_key(x[0], x[1]))

for id, d in _candidates:
    # Spatial collision detection: skip if item's file_spaces overlap with active claims
    AREA_TO_SPACES = {
        'area/ui': ['src/components/', 'src/styles/', 'src/hooks/'],
        'area/controller': ['internal/', 'pkg/', 'api/'],
        'area/cli': ['cmd/', 'internal/cli/'],
        'area/docs': ['docs/', 'README.md'],
        'area/release': ['.github/workflows/', 'Makefile'],
        'area/graph': ['internal/graph/', 'scripts/'],
        'area/agent-loop': ['agents/', 'scripts/'],
        'area/tooling': ['scripts/', '.github/'],
        'area/onboarding': ['agents/onboard.md', 'onboarding-'],
        'area/skills': ['agents/skills/'],
    }
    candidate_spaces = []
    for label in d.get('labels', []):
        candidate_spaces += AREA_TO_SPACES.get(label, [])

    active_spaces = []
    for other_id, other_d in features.items():
        if other_d.get('state') in ('assigned', 'in_review') and other_id != id:
            active_spaces += other_d.get('file_spaces', [])

    def overlaps(a, b):
        return any(x.startswith(y) or y.startswith(x) for x in a for y in b)

    # Fail-open: if either side has no spaces, no collision detected
    if candidate_spaces and active_spaces and overlaps(candidate_spaces, active_spaces):
        continue  # skip — spatial collision with active item
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

  # Learn scheduling: trigger when queue is empty OR <5 items (not just >14 days)
  TODO_NOW=$(python3 -c "
import json
try:
    s=json.load(open('.otherness/state.json'))
    print(len([d for d in s.get('features',{}).values() if d.get('state')=='todo']))
except: print(0)
" 2>/dev/null || echo "0")

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

  # Trigger learn if: queue < 5 items OR >3 days since last learn
  if [ "${TODO_NOW:-0}" -lt 5 ] || [ "${DAYS_SINCE_LEARN:-999}" -ge 3 ]; then
    LEARN_BRANCH="feat/learn-$(date +%Y%m%d-%H%M)"
    if git push origin "HEAD:refs/heads/$LEARN_BRANCH" 2>/dev/null; then
      LEARN_WT="../${REPO_NAME}.learn-$(date +%Y%m%d)"
      [ -d "$LEARN_WT" ] && git worktree remove "$LEARN_WT" --force 2>/dev/null
      git worktree add "$LEARN_WT" "$LEARN_BRANCH"
      gh issue comment $REPORT_ISSUE --repo $REPO \
        --body "[STANDALONE | ${MY_SESSION_ID:-sess-unknown}] Queue low (${TODO_NOW} items, ${DAYS_SINCE_LEARN}d since learn) — triggering learn session." 2>/dev/null
      # [AI-STEP] Navigate to $LEARN_WT, read and follow ~/.otherness/agents/otherness.learn.md
      # After learn PR open and CI green: merge and clean up
      gh pr merge "$LEARN_BRANCH" --repo "$REPO" --squash --delete-branch 2>/dev/null || true
      git worktree remove "$LEARN_WT" --force 2>/dev/null || true
      git worktree prune
    fi
  fi

  # Run vibe-vision-auto to refill queue from code gaps — do NOT sleep or idle
  AGENTS_PATH=$(python3 -c "
import re, os
section = None
for line in open('otherness-config.yaml'):
    s = re.match(r'^(\w[\w_]*):', line)
    if s: section = s.group(1)
    if section == 'maqa':
        m = re.match(r'\s+agents_path:\s*[\"\'']?([^\"\'#\n]+)[\"\'']?', line)
        if m: print(os.path.expanduser(m.group(1).strip())); break
" 2>/dev/null || echo "$HOME/.otherness/agents")

  if [ -f "$AGENTS_PATH/vibe-vision-auto.md" ]; then
    echo "[COORD] Queue empty/low — running vibe-vision-auto to synthesize new items..."
    # [AI-STEP] Read and follow $AGENTS_PATH/vibe-vision-auto.md in the current worktree.
    # This scan adds 🔲 Future items to design docs. After the scan, re-run queue-gen.
    git pull origin main --quiet 2>/dev/null || true
    # Re-run queue generation after vision scan
    TODO_AFTER=$(python3 -c "
import json
try:
    s=json.load(open('.otherness/state.json'))
    print(len([d for d in s.get('features',{}).values() if d.get('state')=='todo']))
except: print(0)
" 2>/dev/null || echo "0")
    echo "[COORD] After vision scan: ${TODO_AFTER} todo items."
    if [ "${TODO_AFTER:-0}" -gt 0 ]; then
      continue  # restart loop with new items
    fi
  fi

  # If still empty after learn + vision: generate competitive/inferred items from roadmap
  echo "[COORD] Generating inferred items from roadmap and competitive gaps..."
  # [AI-STEP] Read docs/aide/roadmap.md and competitive landscape in vision.md.
  # Identify 3-5 concrete Next items (labeled ⚠️ Inferred) and create issues for them.
  # These become the queue. Do NOT idle — always have work.
  continue
fi

# §1e-chore-gate: Proactive queue enrichment at claim time (design doc 21 §Future → ✅, issue-882)
# If MEANINGFUL_PRS_THIS_SESSION==0 AND selected item is kind/chore:
#   (1) Scan docs/design/*.md for an unissued 🔲 Future item
#   (2) Create a GitHub issue for it and claim that instead
#   (3) Fallback: write meaningful_pr_guarantee_failed=true to state.json, claim the chore
# Fail-open: any error → claim the item as normal.
_CHORE_GATE_RESULT=$( python3 - <<'CHORE_GATE_EOF'
import json, subprocess, re, os, sys

REPO = os.environ.get('REPO', '')
ITEM_ID = os.environ.get('ITEM_ID', '')
MEANINGFUL_PRS = int(os.environ.get('MEANINGFUL_PRS_THIS_SESSION', '0') or '0')

# Fail-open guard: missing vars → pass through
if not REPO or not ITEM_ID:
    print(f"PASS {ITEM_ID}")
    sys.exit(0)

# Check if the claimed item is kind/chore
try:
    with open('.otherness/state.json') as f: s = json.load(f)
    labels = s.get('features', {}).get(ITEM_ID, {}).get('labels', [])
except Exception:
    print(f"PASS {ITEM_ID}")
    sys.exit(0)

# is_chore: True only when ALL kind/ labels are chore/docs and at least one kind/ label exists
_kind_labels = [l for l in labels if l.startswith('kind/')]
is_chore = bool(_kind_labels) and all(l in ('kind/chore', 'kind/docs') for l in _kind_labels)

if MEANINGFUL_PRS > 0 or not is_chore:
    # Gate does not fire: session already shipped a feature, or item is not a chore
    print(f"PASS {ITEM_ID}")
    sys.exit(0)

print(f"[COORD §1e-chore-gate] MEANINGFUL_PRS_THIS_SESSION=0 and item '{ITEM_ID}' is kind/chore — scanning for feature item to inject.", file=sys.stderr)

# Collect done/merged items for dedup
done_titles = set(
    v.get('title', '').lower() for v in s.get('features', {}).values()
    if v.get('state') == 'done' and v.get('title')
)
try:
    merged_prs = subprocess.check_output(
        ['gh', 'pr', 'list', '--repo', REPO, '--state', 'merged', '--limit', '100',
         '--json', 'title', '--jq', '.[].title'], text=True, timeout=15).lower().splitlines()
except Exception:
    merged_prs = []

try:
    open_issues = subprocess.check_output(
        ['gh', 'issue', 'list', '--repo', REPO, '--state', 'open', '--limit', '200',
         '--json', 'title', '--jq', '.[].title'], text=True, timeout=15).lower().splitlines()
except Exception:
    open_issues = []

def is_done_or_open(desc):
    d = desc.lower().strip()
    d = re.sub(r'^⚠️\s*(inferred|observed):\s*', '', d)
    key = d[:40]
    if d in done_titles: return True
    if any(key in pr for pr in merged_prs): return True
    if any(key in oi for oi in open_issues): return True
    return False

def open_if_absent(title, labels_str, body):
    r = subprocess.run(
        ['gh', 'issue', 'list', '--repo', REPO, '--state', 'open',
         '--search', title[:60], '--json', 'number', '--jq', 'length'],
        capture_output=True, text=True, timeout=15)
    if int(r.stdout.strip() or '0') == 0:
        r2 = subprocess.run(
            ['gh', 'issue', 'create', '--repo', REPO,
             '--title', title, '--label', labels_str, '--body', body],
            capture_output=True, text=True, timeout=15)
        if r2.returncode == 0:
            return r2.stdout.strip().split('/')[-1]
    return None

# Scan docs/design/ for an unissued 🔲 Future item
design_dir = 'docs/design'
injected_id = None
if os.path.isdir(design_dir):
    for fname in sorted(os.listdir(design_dir)):
        if not fname.endswith('.md'): break
        try:
            content = open(f'{design_dir}/{fname}').read()
            m = re.search(r'^## Future.*?\n(.*?)(?=^## |\Z)', content,
                          re.MULTILINE | re.DOTALL)
            if not m: continue
            items = re.findall(r'^- 🔲 (?!.*🚫)(.+)', m.group(1), re.MULTILINE)
            for item in items:
                desc = re.sub(r'\s*—.*$', '', item).strip()
                if is_done_or_open(desc): continue
                title = f"feat: {desc[:90]}"
                body = (f"## Design reference\n"
                        f"- **Design doc**: `docs/design/{fname}`\n"
                        f"- **Section**: `§ Future`\n"
                        f"- **Implements**: {desc} (🔲 → ✅)\n\n"
                        f"## Summary\n\n"
                        f"§1e-chore-gate injected: session has 0 meaningful PRs; "
                        f"forcing feature work before chore claim.\n\n"
                        f"Full item: {item}")
                num = open_if_absent(title,
                                     'otherness,kind/enhancement,area/agent-loop,size/s,priority/medium',
                                     body)
                if num:
                    injected_id = f"issue-{num}"
                    print(f"[COORD §1e-chore-gate] Injected issue #{num}: {title[:60]}", file=sys.stderr)
                    break
        except Exception:
            pass
        if injected_id:
            break

if injected_id:
    # Add injected issue to state.json as todo
    try:
        r = subprocess.run(['gh', 'issue', 'view', injected_id.split('-')[1], '--repo', REPO,
                           '--json', 'title,labels', '--jq', '{title:.title,labels:[.labels[].name]}'],
                          capture_output=True, text=True, timeout=15)
        if r.returncode == 0:
            d = json.loads(r.stdout)
            s.setdefault('features', {})[injected_id] = {
                'state': 'todo', 'title': d.get('title',''),
                'labels': d.get('labels', []), 'priority': 'medium'
            }
            with open('.otherness/state.json', 'w') as f2: json.dump(s, f2, indent=2)
    except Exception:
        pass
    print(f"REPLACE {injected_id}")
else:
    # Fallback: no unissued Future items — write guarantee_failed flag, claim the chore
    try:
        s['meaningful_pr_guarantee_failed'] = True
        with open('.otherness/state.json', 'w') as f2: json.dump(s, f2, indent=2)
    except Exception:
        pass
    print(f"[COORD §1e-chore-gate] No unissued Future items found — allowing chore claim (meaningful_pr_guarantee_failed=true).", file=sys.stderr)
    print(f"PASS {ITEM_ID}")
CHORE_GATE_EOF
)
_GATE_ACTION=$(echo "$_CHORE_GATE_RESULT" | grep -E '^(REPLACE|PASS)' | head -1 | awk '{print $1}')
_GATE_ITEM=$(echo "$_CHORE_GATE_RESULT" | grep -E '^(REPLACE|PASS)' | head -1 | awk '{print $2}')
if [ "$_GATE_ACTION" = "REPLACE" ] && [ -n "$_GATE_ITEM" ]; then
  echo "[COORD §1e-chore-gate] Replacing chore $ITEM_ID with feature $_GATE_ITEM"
  ITEM_ID="$_GATE_ITEM"
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
    'worktree': '$MY_WORKTREE',
    # Spatial coordination: declare file_spaces at claim time
    _AREA_TO_SPACES = {
        'area/ui': ['src/components/', 'src/styles/', 'src/hooks/'],
        'area/controller': ['internal/', 'pkg/', 'api/'],
        'area/cli': ['cmd/', 'internal/cli/'],
        'area/docs': ['docs/', 'README.md'],
        'area/release': ['.github/workflows/', 'Makefile'],
        'area/graph': ['internal/graph/', 'scripts/'],
        'area/agent-loop': ['agents/', 'scripts/'],
        'area/tooling': ['scripts/', '.github/'],
        'area/onboarding': ['agents/onboard.md', 'onboarding-'],
        'area/skills': ['agents/skills/'],
    }
    _item_labels = s['features']['$ITEM_ID'].get('labels', [])
    _file_spaces = []
    for _lbl in _item_labels:
        _file_spaces += _AREA_TO_SPACES.get(_lbl, [])
    'file_spaces': list(set(_file_spaces)),
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

  # D4 classification at issue intake — classify the issue title/body before speccing.
  _D4_RESULT=$(python3 - <<'D4EOF'
import subprocess, re, os, sys

ISSUE_NUM = os.environ.get('ISSUE_NUM', '')
REPO = os.environ.get('REPO', '')
MY_SESSION_ID = os.environ.get('MY_SESSION_ID', '')
OTHERNESS_VERSION = os.environ.get('OTHERNESS_VERSION', 'unknown')

if not ISSUE_NUM or not REPO:
    sys.exit(0)

# Step 1: Read issue title and body
try:
    r = subprocess.run(
        ['gh', 'issue', 'view', ISSUE_NUM, '--repo', REPO,
         '--json', 'title,body', '--jq', '{title: .title, body: .body}'],
        capture_output=True, text=True, timeout=15)
    if r.returncode != 0:
        sys.exit(0)
    import json
    data = json.loads(r.stdout.strip())
    title = data.get('title', '')
    body = data.get('body', '')
except Exception:
    sys.exit(0)

# Step 2: Classify the title
DECLARATIVE_PAT = re.compile(
    r'^(feat|fix|chore|docs|refactor|test|perf|ci|build|security)(\([^)]+\))?:', re.IGNORECASE)
INFRA_PAT = re.compile(
    r'\b(bump|update dep|fix ci|fix lint|clean up|pin |unpin )\b', re.IGNORECASE)
DESIGN_DOC_REF = re.compile(r'🔲|design doc|docs/design/', re.IGNORECASE)

if DECLARATIVE_PAT.match(title) or DESIGN_DOC_REF.search(title):
    classification = 'DECLARATIVE'
elif INFRA_PAT.search(title):
    classification = 'INFRA'
else:
    classification = 'IMPERATIVE'

# Step 3: If IMPERATIVE, post D4 translation (no 60s wait — standalone.md §D4 says "Proceed immediately")
if classification == 'IMPERATIVE':
    # Infer intent from title
    intent = f"Implement: {title}"
    d4_layer = 'design doc'
    artifact = f"docs/design/: 🔲 {title} — (intent inferred from imperative title)"
    translation_body = (
        f"[📋 D4 TRANSLATION]\n"
        f"Heard:     \"{title}\"\n"
        f"Intent:    {intent}\n"
        f"D4 layer:  {d4_layer}\n"
        f"Artifact:  {artifact}\n"
        f"Proceeding immediately."
    )
    subprocess.run(
        ['gh', 'issue', 'comment', ISSUE_NUM, '--repo', REPO, '--body', translation_body],
        capture_output=True, timeout=15)

# Step 5: If DECLARATIVE or INFRA — no-op, proceed
D4EOF
  ) 2>/dev/null || true

else
  echo "[COORD] ⚡ $ITEM_ID already claimed — picking another."
  ITEM_ID=""
  # loop back
fi
```

---

## 1f. Multi-item session loop

**Design ref**: `docs/design/21-session-throughput.md` — Fix A.

After ENG → QA completes one item and the PR is merged (or queued for merge), COORD
does not hand off to SM/PM yet. Instead it checks whether the session has budget
remaining and the queue has more work.

**Session budget**: tracked in memory as `ITEMS_COMPLETED` (shell variable, not
written to `_state`). Read `session_item_limit` from `otherness-config.yaml`:

```bash
SESSION_LIMIT=$(python3 -c "
import re
for line in open('otherness-config.yaml'):
    m = re.match(r'^\s+session_item_limit:\s*(\d+)', line)
    if m: print(m.group(1)); break
" 2>/dev/null || echo "10")

# Increment after each completed item (set in ENG/QA handoff)
ITEMS_COMPLETED=${ITEMS_COMPLETED:-0}
```

**After each item completes**, before entering SM/PM:

```bash
ITEMS_COMPLETED=$((ITEMS_COMPLETED + 1))

# Check: more work available AND budget remaining?
QUEUE_REMAINING=$(python3 -c "
import json
try:
    s = json.load(open('.otherness/state.json'))
    todos = [v for v in s.get('features', {}).values() if v.get('status') == 'todo']
    print(len(todos))
except: print(0)
" 2>/dev/null || echo "0")

if [ "$ITEMS_COMPLETED" -lt "$SESSION_LIMIT" ] && [ "$QUEUE_REMAINING" -gt 0 ]; then
  echo "[COORD] Item $ITEMS_COMPLETED/$SESSION_LIMIT complete. $QUEUE_REMAINING items remaining. Continuing..."
  # Skip SM/PM — loop back to §1e (claim next item)
  # SM/PM will run at end of session when queue is empty or limit reached
else
  echo "[COORD] Session gate: $ITEMS_COMPLETED items done, $QUEUE_REMAINING remaining. Running SM/PM."
  # Proceed to Phase 4 (SM) and Phase 5 (PM) normally
fi
```

**SM/PM gate fires when:**
- `ITEMS_COMPLETED >= SESSION_LIMIT` (budget exhausted), OR
- `QUEUE_REMAINING == 0` (queue empty), OR
- A `[NEEDS HUMAN]` block was posted (error state — stop implementing, triage first)

**Minimum queue depth guard**: if `QUEUE_REMAINING < 5` AND queue-gen is not already
locked, trigger queue-gen immediately (don't wait for next session) so the queue
never hits zero mid-session.

```bash
# Minimum queue depth guard — run after each §1f check
if [ "${QUEUE_REMAINING:-5}" -lt 5 ]; then
  LOCK_EXISTS=$(git ls-remote --heads origin otherness/queue-gen 2>/dev/null | wc -l | tr -d ' ')
  if [ "${LOCK_EXISTS:-0}" -eq 0 ]; then
    echo "[COORD §1f] Queue depth low (${QUEUE_REMAINING} items) — triggering queue-gen now."
    # Acquire queue-gen lock
    QUEUE_LOCK_BRANCH="otherness/queue-gen"
    if git push origin "HEAD:refs/heads/$QUEUE_LOCK_BRANCH" 2>/dev/null; then
      echo "[COORD §1f] Queue-gen lock acquired. Generating items inline..."
      python3 - <<'INLINE_QGEN'
import subprocess, re, json, os

REPO = os.environ.get('REPO', '')

try:
    state = json.load(open('.otherness/state.json'))
    done_titles = set(
        v.get('title','').lower() for v in state.get('features',{}).values()
        if v.get('state') == 'done' and v.get('title')
    )
except:
    done_titles = set()

try:
    merged_prs = subprocess.check_output(
        ['gh','pr','list','--repo',REPO,'--state','merged','--limit','100',
         '--json','title','--jq','.[].title'], text=True).lower()
except:
    merged_prs = ''

def is_done(d):
    d_lower = d.lower().strip()
    d_lower = re.sub(r'^⚠️\s*(inferred|observed):\s*', '', d_lower)
    if d_lower in done_titles: return True
    desc_key = d_lower[:60]
    for pr_title in merged_prs.splitlines():
        if desc_key in pr_title.strip(): return True
    return False

def open_if_absent(title, labels, body):
    r = subprocess.run(['gh','issue','list','--repo',REPO,'--state','open',
                        '--search',title[:60],'--json','number','--jq','length'],
                       capture_output=True, text=True)
    if int(r.stdout.strip() or '0') == 0:
        r2 = subprocess.run(['gh','issue','create','--repo',REPO,
                             '--title',title,'--label',labels,'--body',body],
                            capture_output=True, text=True)
        if r2.returncode == 0:
            return r2.stdout.strip().split('/')[-1]
    return None

design_dir = 'docs/design'
new_items = 0
if os.path.isdir(design_dir):
    for fname in sorted(os.listdir(design_dir)):
        if not fname.endswith('.md'): continue
        if new_items >= 10: break
        try:
            content = open(f'{design_dir}/{fname}').read()
            m = re.search(r'^## Future.*?\n(.*?)(?=^## |\Z)', content, re.MULTILINE | re.DOTALL)
            if m:
                items = re.findall(r'^- 🔲 (?!.*🚫)(.+)', m.group(1), re.MULTILINE)
                for item in items:
                    if new_items >= 10: break
                    desc = re.sub(r'\s*—.*$', '', item).strip()
                    if is_done(desc): continue
                    title = f"feat: {desc[:80]}"
                    body = (f"## Design reference\n"
                            f"- **Design doc**: `docs/design/{fname}`\n"
                            f"- **Section**: `§ Future`\n"
                            f"- **Implements**: {desc} (🔲 → ✅)\n\n"
                            f"## Summary\n\n"
                            f"Implements the design doc Future item from `docs/design/{fname}`.\n\n"
                            f"Full item: {item}")
                    result = open_if_absent(title, 'otherness,kind/enhancement,area/agent-loop,size/s,priority/medium', body)
                    if result:
                        new_items += 1
                        print(f"[COORD §1f] Created issue #{result}: {title[:60]}")
        except Exception as e:
            print(f"[COORD §1f] queue-gen error for {fname}: {e}")

print(f"[COORD §1f] Inline queue-gen complete: {new_items} issues created.")
INLINE_QGEN
      git push origin --delete "$QUEUE_LOCK_BRANCH" 2>/dev/null || true
      echo "[COORD §1f] Queue-gen lock released."
    else
      echo "[COORD §1f] Could not acquire queue-gen lock (another session may have just acquired it)."
    fi
  else
    echo "[COORD §1f] Queue depth low but queue-gen already running — skipping."
  fi
fi
```
