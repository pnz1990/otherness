# PHASE 3 — [🔍 QA] ADVERSARIAL REVIEW

**Role identity** — use same `JOB_FAMILY` from Phase 2. Adopt the matching QA backstory from
`~/.otherness/agents/skills/role-based-agent-identity.md` §Layer 2:
- `SDE`: L6 SDE on-call — scrutinize error paths, interface stability, one-way door decisions
- `FEE`: L6 FEE — accessibility, responsive design, error/loading states, design system compliance
- `SysDE`: L6 SysDE — blast radius, rollback, idempotency, failure visibility, runbook coverage

Load skill: `~/.otherness/agents/skills/reconciling-implementations.md` before reviewing.

You are looking for reasons to **REJECT**. Correctness issues block. Style issues do not.
The review comment should teach, not just block. Max 3 QA cycles.

---

## 3a. Wait for CI, read diff

```bash
# Wait for CI on the PR branch — poll up to 20 min
for i in $(seq 1 40); do
  CI=$(gh run list --repo $REPO --branch $MY_BRANCH --limit 1 \
    --json conclusion,status --jq '.[0] | (.conclusion // .status)' 2>/dev/null)
  case "$CI" in
    success) echo "[QA] CI green"; break ;;
    failure) echo "[QA] CI failed — filing for ENG fix"; break ;;
    "") sleep 15 ;; # not started yet
    *) sleep 30 ;; # in_progress, queued
  esac
done

if [ "$CI" = "failure" ]; then
  # Read the failure, fix it (go back to ENG phase step 2d-2e), push, re-check
  echo "[QA] CI failure — returning to ENG for fix"
  # [AI-STEP] Read failure log, fix root cause in $MY_WORKTREE, push, re-enter QA
fi
```

---

## 3b. Spec conformance check (step 0 — **MANDATORY**, blocks approval)

**This check is not optional. QA cannot approve without completing it.**

```bash
SPEC_FILE="$MY_WORKTREE/.specify/specs/$ITEM_ID/spec.md"
if [ ! -f "$SPEC_FILE" ]; then
  echo "[QA] WRONG — spec.md missing at $SPEC_FILE"
  echo "[QA] ENG must write spec.md (three-zone structure) before PR can be approved."
  echo "[QA] Returning to ENG phase — write spec first, then re-push."
  # [AI-STEP] Go back to ENG phase 2b, write the spec, commit it, re-enter QA
else
  echo "[QA] Running spec conformance check..."
  # [AI-STEP] For each Zone 1 obligation in spec.md:
  #   1. Find the corresponding code in the diff
  #   2. Verify the behavior matches the obligation
  #   3. If any obligation unimplemented or misimplemented: WRONG finding — must fix before approve
  # All obligations must be verified. This is the highest-priority check.

  # Design reference check — MANDATORY for feature PRs
  # [AI-STEP] Read spec.md and find the ## Design reference section.
  # Three valid outcomes:
  #   A) Section present with a docs/design/ file named → verify that file exists and
  #      check that the PR diff updates it (🔲 → ✅). If design doc not updated: WRONG.
  #   B) Section present with "N/A — infrastructure change" → acceptable for chore/fix/refactor.
  #   C) Section absent → WRONG. Post:
  #      "[QA] WRONG — spec.md missing ## Design reference section.
  #       Per docs/design/01-declarative-design-driven-development.md O2, every spec must
  #       reference its design doc (or declare N/A for infra-only changes).
  #       ENG must add this section and re-push."
fi
```

---

## 3c. Full review — reconciling-implementations checklist

Apply in priority order: **Correctness → Performance → Observability → Testing → Simplicity**

Label every finding:
- `WRONG` — implementation incorrect. Fix before merge.
- `STALE` — spec/design doc needs updating. Surface to human, do not silently resolve.
- `SMELL` — code quality issue. Fix before merge.
- `MISS` — gap in coverage. Open follow-up issue, do not block merge.

**Gap classification rule**: if implementation diverges from design, determine whether the
code is wrong or the design is stale *before acting*. Never silently resolve a conflict
between two design commitments — post `[NEEDS HUMAN]` with the exact conflicting statements.

---

## 3d. Approval or rejection

**Approve when:**
- All CI checks pass
- All Zone 1 obligations satisfied (spec conformance check passed)
- No WRONG or STALE findings remain
- All MISS findings filed as new issues

**`AUTONOMOUS_MODE=true` — do NOT post `[NEEDS HUMAN: pr-approval-required]`.**
Branch protection requiring a human review is bypassed in §3e via `--admin`. The correct
flow is: approve (self-review comment) → proceed to §3e merge with `--admin`. Do not
stop and wait. Only escalate to `[NEEDS HUMAN]` when there is a genuine judgment call
(WRONG finding you cannot fix, STALE requiring human decision, test failures after 3 attempts).

```bash
# File any MISS findings as new issues before merging
# gh issue create --repo $REPO --title "..." --label "otherness,..."

# Post review comment on PR
gh pr review $PR_NUM --repo $REPO \
  --approve \
  --body "[🔍 QA | ${MY_SESSION_ID:-sess-unknown} | otherness@${OTHERNESS_VERSION:-unknown}] APPROVED — spec conformance ✓, CI ✓, no blocking findings."
```

**CRITICAL TIER — AUTONOMOUS MODE SELF-REVIEW PROTOCOL**

If PR touches `agents/standalone.md` or `agents/bounded-standalone.md` AND `AUTONOMOUS_MODE=true`:

Post answers to each check as `[AGENT SELF-REVIEW]` comment. If any fails: post
`[NEEDS HUMAN: self-review-failed — <reason>]` and do NOT merge.

```
1. SPEC COMPLETENESS — every Zone 1 obligation satisfied?
2. FAILURE MODE ANALYSIS — name 3 ways this breaks a project not this one
   (no docs/aide/, no _state branch, non-GitHub CI, 0 features in state.json, monorepo)
3. GLOBAL DEPLOYMENT CHECK — every new code path has graceful fallback?
4. SIMPLICITY CHECK — minimum necessary change? follows existing patterns?
5. LONG-TERM VISION CHECK — moves roadmap forward? more generic not less?
```

---

## 3e. Merge and clean up

```bash
# Merge from main worktree (not from feature worktree — avoids permission issues)
cd $(git -C $MY_WORKTREE rev-parse --show-toplevel)/../$(basename $(git rev-parse --show-toplevel))

# Merge with --admin fallback when autonomous_mode=true.
# Branch protection may require 1 approving review; --admin bypasses that gate when
# the token has admin rights (repo owner / admin collaborator).
# The agent never self-approves — it uses admin privilege to merge directly.
if [ "${AUTONOMOUS_MODE:-false}" = "true" ]; then
  if ! gh pr merge $PR_NUM --repo $REPO --squash --delete-branch 2>/dev/null; then
    echo "[QA] Normal merge blocked (branch protection) — retrying with --admin (autonomous_mode=true)"
    gh pr merge $PR_NUM --repo $REPO --squash --delete-branch --admin
  fi
else
  gh pr merge $PR_NUM --repo $REPO --squash --delete-branch
fi

# Clean up worktree
git worktree remove "$MY_WORKTREE" --force
git worktree prune
git pull origin main --quiet

# Update state to done
python3 - <<PYEOF
import json, datetime, subprocess
r = subprocess.run(['git','show','origin/_state:.otherness/state.json'],
                   capture_output=True, text=True)
s = json.loads(r.stdout) if r.returncode == 0 else json.load(open('.otherness/state.json'))
s['features']['$ITEM_ID'].update({
    'state': 'done',
    'pr_merged': True,
    'done_at': datetime.datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ')
})
with open('.otherness/state.json', 'w') as f: json.dump(s, f, indent=2)
PYEOF
export STATE_MSG="[$MY_SESSION_ID] $ITEM_ID done"
# run STATE MANAGEMENT write block

ITEM_ID="" ; MY_BRANCH="" ; MY_WORKTREE="" ; MY_SESSION_ID="" ; PR_NUM=""
```

---

## 3f. Archive stale features (run once per 10 merges)

When the `done` count modulo 10 is 0, archive old done items to keep `state.json` lean.

```bash
python3 - <<'EOF'
import json, datetime, os

with open('.otherness/state.json') as f: s = json.load(f)
features = s.get('features', {})
done_items = {id: d for id, d in features.items()
              if d.get('state') == 'done' and d.get('pr_merged')}

if len(done_items) % 10 != 0 or len(done_items) == 0:
    exit(0)

cutoff = datetime.datetime.utcnow() - datetime.timedelta(days=90)
to_archive = {}
for id, d in done_items.items():
    done_at = d.get('done_at', d.get('assigned_at', ''))
    if done_at:
        try:
            dt = datetime.datetime.fromisoformat(done_at.replace('Z',''))
            if dt < cutoff:
                to_archive[id] = d
        except: pass

if not to_archive:
    exit(0)

# Append to archive file
archive_path = '.otherness/features_archive.json'
try:
    archive = json.load(open(archive_path))
except:
    archive = {}
archive.update(to_archive)
with open(archive_path, 'w') as f: json.dump(archive, f, indent=2)

# Remove from active state
for id in to_archive:
    del s['features'][id]
with open('.otherness/state.json', 'w') as f: json.dump(s, f, indent=2)

print(f"Archived {len(to_archive)} done items older than 90 days → features_archive.json")
EOF
```
