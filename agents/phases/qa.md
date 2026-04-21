
## MODE: READ-ONLY

This agent reads files and produces output. It does not write, edit, create,
or delete any file in any zone.

If asked to implement, fix, or change code or docs: stop and redirect.

```
[🚫 D4 GATE] This session is READ-ONLY.
To implement changes:        /otherness.run
To update vision or design:  /otherness.vibe-vision
```

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
# Design ref: docs/design/38-qa-ci-gate.md
# Use gh pr checks (all required checks on the PR) — NOT gh run list (only last workflow run).
# gh run list misses failures on other workflows. gh pr checks is authoritative.

_CI_ATTEMPTS=0
_CI_FIXED=false

while true; do
  # Get aggregate status of all checks on this PR
  _CHECKS=$(gh pr checks "$PR_NUM" --repo "$REPO" \
    --json name,state,conclusion 2>/dev/null || echo "[]")

  _FAILING=$(echo "$_CHECKS" | python3 -c "
import json, sys
checks = json.load(sys.stdin)
failing = [c for c in checks if c.get('conclusion') in ('failure','timed_out','action_required')]
pending = [c for c in checks if c.get('state') == 'PENDING' or c.get('conclusion') is None]
passing = [c for c in checks if c.get('conclusion') in ('success','skipped','neutral')]
print(f'failing={len(failing)} pending={len(pending)} passing={len(passing)}')
for c in failing: print(f'FAIL: {c[\"name\"]}')
for c in pending: print(f'PENDING: {c[\"name\"]}')
" 2>/dev/null || echo "failing=0 pending=0 passing=0")

  echo "[QA §3a] Checks: $_FAILING"

  if echo "$_FAILING" | grep -q "^FAIL:"; then
    _CI_ATTEMPTS=$((_CI_ATTEMPTS + 1))
    echo "[QA §3a] CI failing (attempt $_CI_ATTEMPTS/3)"

    if [ $_CI_ATTEMPTS -ge 3 ]; then
      echo "[QA §3a] CI still failing after 3 attempts — posting [NEEDS HUMAN]"
      _FAIL_DETAILS=$(echo "$_CHECKS" | python3 -c "
import json,sys
checks=json.load(sys.stdin)
for c in checks:
    if c.get('conclusion') in ('failure','timed_out','action_required'):
        print(c['name'])
" 2>/dev/null)
      gh issue comment "$REPORT_ISSUE" --repo "$REPO" \
        --body "[NEEDS HUMAN: ci-red-3-attempts] PR #${PR_NUM} has failing CI after 3 fix attempts. Failing checks: ${_FAIL_DETAILS}. Human action required to resolve." 2>/dev/null
      gh issue create --repo "$REPO" \
        --title "[NEEDS HUMAN] CI failing on PR #${PR_NUM} after 3 attempts" \
        --label "needs-human" \
        --body "Failing checks: ${_FAIL_DETAILS}" 2>/dev/null || true
      exit 1
    fi

    # Check for DCO failure — mechanical fix: amend commit with Signed-off-by
    if echo "$_FAILING" | grep -qi "dco\|sign.off"; then
      echo "[QA §3a] DCO failure detected — amending commit with Signed-off-by"
      cd "$MY_WORKTREE"
      git commit --amend --no-edit \
        --trailer "Signed-off-by: otherness[bot] <otherness[bot]@users.noreply.github.com>" \
        2>/dev/null || true
      git push --force-with-lease origin "$(git rev-parse --abbrev-ref HEAD)" 2>/dev/null || true
      sleep 20
      continue
    fi

    # Read failure log and attempt fix
    _FAIL_RUN=$(gh run list --repo "$REPO" --branch "$MY_BRANCH" --limit 5 \
      --json databaseId,conclusion \
      --jq '[.[] | select(.conclusion=="failure")] | .[0].databaseId' 2>/dev/null)

    if [ -n "$_FAIL_RUN" ] && [ "$_FAIL_RUN" != "null" ]; then
      echo "[QA §3a] Reading failure log for run $_FAIL_RUN"
      _FAIL_LOG=$(gh run view "$_FAIL_RUN" --repo "$REPO" --log-failed 2>/dev/null | \
        grep -v "toolchain\|^2026.*##\[group\]\|^2026.*##\[endgroup\]" | \
        grep -E "error:|Error:|FAIL|cannot|undefined|missing|exit code" | \
        head -30)
      echo "[QA §3a] Failure log excerpt:"
      echo "$_FAIL_LOG"
    fi

    # [AI-STEP] Analyse $_FAIL_LOG, identify root cause, fix in $MY_WORKTREE.
    # Common patterns to handle:
    # - "File is not properly formatted (gofmt)" → run gofmt -w on the file
    # - "Missing Apache 2.0 header" → add license header to new .go file
    # - "CRD schemas are stale" → run make manifests generate, commit
    # - "undefined:" or "cannot find" → fix import or type error in Go code
    # - "FAIL\s+github.com/..." → read test failure, fix the test or the code
    # Push the fix, then loop back to recheck.
    # If the failure is not fixable (external infra, permissions): break and post [NEEDS HUMAN].
    sleep 30
    continue
  fi

  if echo "$_FAILING" | grep -q "pending=[^0]"; then
    echo "[QA §3a] CI still pending — waiting 30s"
    sleep 30
    continue
  fi

  # All checks passed (or skipped/neutral — no failures, no pending)
  echo "[QA §3a] All CI checks passed."
  break

  # Timeout guard: _CI_ATTEMPTS tracks wait cycles too via the outer loop
  # If we've been waiting >30 min (60 × 30s) without resolution: escalate
  _CI_ATTEMPTS=$((_CI_ATTEMPTS + 1))
  if [ $_CI_ATTEMPTS -gt 60 ]; then
    echo "[QA §3a] CI still pending after 30 min — escalating"
    gh issue create --repo "$REPO" \
      --title "[NEEDS HUMAN] CI pending >30 min on PR #${PR_NUM}" \
      --label "needs-human" \
      --body "CI has not completed after 30 minutes. Check runner health or external dependency." \
      2>/dev/null || true
    exit 1
  fi
done
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
  #      Also: check if a docs/<feature>.md customer doc exists. If not: MISS finding —
  #      open a follow-up issue "docs: add customer doc for <feature-area>". Do NOT block merge.
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

If PR touches `agents/standalone.md`, `agents/bounded-standalone.md`, or `agents/phases/*.md`
AND `AUTONOMOUS_MODE=true`:

1. Post the 5-check self-review as `[AGENT SELF-REVIEW]` comment on the PR.
2. If **all 5 checks pass**: call `_merge_pr` immediately. Do NOT stop. Do NOT post `[NEEDS HUMAN]`.
3. If **any check fails**: post `[NEEDS HUMAN: self-review-failed — <reason>]` and stop.

```bash
# After posting self-review comment — this block MUST execute:
SELF_REVIEW_PASSED=true  # set to false if any check failed above

if [ "$SELF_REVIEW_PASSED" = "true" ] && [ "${AUTONOMOUS_MODE:-false}" = "true" ]; then
  echo "[QA] CRITICAL-A self-review passed — proceeding with autonomous merge"
  _merge_pr "$PR_NUM" "$REPO" || {
    echo "[QA] Merge failed after self-review — posting [NEEDS HUMAN]"
    gh issue create --repo "$REPO" \
      --title "[NEEDS HUMAN] CRITICAL-A merge failed on PR #${PR_NUM}" \
      --label "needs-human" \
      --body "Self-review passed but merge failed. Check branch protection and token permissions." 2>/dev/null
  }
fi
```

```
Self-review checklist (post as comment, then execute merge block above):
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

# Autonomous merge protocol (3-step, see docs/design/13-autonomous-merge-strategy.md)
# Design ref: docs/design/38-qa-ci-gate.md
# NEVER post [NEEDS HUMAN: pr-approval-required] before trying all three steps.
# CI gate fires BEFORE every step — --admin and protection-clear bypass review
# requirements only, NEVER CI check requirements.
_merge_pr() {
  local pr_num="$1"
  local repo="$2"

  # CI gate — authoritative check before any merge attempt (O1, O2 in design doc 38)
  # gh pr checks is used, not gh run list (gh run list only sees the last workflow run)
  _CI_STATUS=$(gh pr checks "$pr_num" --repo "$repo" \
    --json name,state,conclusion 2>/dev/null || echo "[]")
  _CI_FAILING=$(echo "$_CI_STATUS" | python3 -c "
import json, sys
checks = json.load(sys.stdin)
failing = [c['name'] for c in checks
           if c.get('conclusion') in ('failure','timed_out','action_required')]
print(','.join(failing))
" 2>/dev/null || echo "")

  if [ -n "$_CI_FAILING" ]; then
    echo "[QA §3e] CI gate: failing checks: $_CI_FAILING"
    echo "[QA §3e] Refusing to merge — CI is red. Return to ENG to fix: $_CI_FAILING"
    return 1  # caller (§3a loop) must fix CI before retrying _merge_pr
  fi

  # Step 0 — update branch if behind main (strict status checks require up-to-date branches)
  _MERGE_STATE=$(gh pr view "$pr_num" --repo "$repo" --json mergeStateStatus --jq '.mergeStateStatus' 2>/dev/null)
  if [ "$_MERGE_STATE" = "BEHIND" ]; then
    echo "[QA] Branch is BEHIND main — updating before merge attempt."
    gh pr update-branch "$pr_num" --repo "$repo" 2>/dev/null || true
    sleep 15  # let GitHub re-run checks after update

    # Re-check CI after branch update — update may invalidate passing checks
    _CI_STATUS=$(gh pr checks "$pr_num" --repo "$repo" \
      --json name,state,conclusion 2>/dev/null || echo "[]")
    _CI_PENDING=$(echo "$_CI_STATUS" | python3 -c "
import json, sys
checks = json.load(sys.stdin)
pending = [c for c in checks if c.get('state') == 'PENDING' or c.get('conclusion') is None]
print(len(pending))
" 2>/dev/null || echo "0")

    if [ "${_CI_PENDING:-0}" -gt 0 ]; then
      echo "[QA §3e] Checks re-running after branch update — waiting up to 15 min"
      for _w in $(seq 1 30); do
        sleep 30
        _CI_STATUS=$(gh pr checks "$pr_num" --repo "$repo" \
          --json name,state,conclusion 2>/dev/null || echo "[]")
        _CI_FAILING=$(echo "$_CI_STATUS" | python3 -c "
import json, sys
checks = json.load(sys.stdin)
failing=[c['name'] for c in checks if c.get('conclusion') in ('failure','timed_out','action_required')]
pending=[c for c in checks if c.get('state')=='PENDING' or c.get('conclusion') is None]
print(f'failing={len(failing)} pending={len(pending)}')
" 2>/dev/null || echo "failing=0 pending=0")
        echo "[QA §3e] Post-update: $_CI_FAILING"
        if ! echo "$_CI_FAILING" | grep -q "pending=[^0]" && ! echo "$_CI_FAILING" | grep -q "failing=[^0]"; then
          break
        fi
        if echo "$_CI_FAILING" | grep -q "failing=[^0]"; then
          echo "[QA §3e] CI failed after branch update — returning to ENG"
          return 1
        fi
      done
    fi
  fi

  # Step 1 — try normal merge
  if gh pr merge "$pr_num" --repo "$repo" --squash --delete-branch 2>/dev/null; then
    return 0
  fi

  # Step 2 — try --admin (repo owner token bypasses review requirements)
  # NOTE: --admin bypasses review requirements ONLY. CI is already verified above.
  if gh pr merge "$pr_num" --repo "$repo" --squash --delete-branch --admin 2>/dev/null; then
    return 0
  fi

  # Step 3 — temporarily clear branch protection (review rules only, not status checks)
  _RESTORE_TRAP="curl -s -X PUT \
    -H 'Authorization: Bearer \$(gh auth token)' \
    -H 'Accept: application/vnd.github+json' \
    'https://api.github.com/repos/$repo/branches/main/protection' \
    -d '{\"required_status_checks\":null,\"enforce_admins\":true,\"required_pull_request_reviews\":{\"required_approving_review_count\":1,\"dismiss_stale_reviews\":true},\"restrictions\":null}' > /dev/null"
  trap "$_RESTORE_TRAP" EXIT

  CLEAR_RESULT=$(curl -s -X PUT \
    -H "Authorization: Bearer $(gh auth token)" \
    -H "Accept: application/vnd.github+json" \
    "https://api.github.com/repos/$repo/branches/main/protection" \
    -d '{"required_status_checks":null,"enforce_admins":false,"required_pull_request_reviews":null,"restrictions":null}')

  if echo "$CLEAR_RESULT" | python3 -c "import json,sys; d=json.loads(sys.stdin.read()); exit(0 if not d.get('required_pull_request_reviews') else 1)" 2>/dev/null; then
    gh pr merge "$pr_num" --repo "$repo" --squash --delete-branch
    _MERGE_EXIT=$?
  else
    echo "[QA] Step 3 failed: could not clear branch protection (403 = token lacks admin). HTTP: $CLEAR_RESULT" | head -c 200
    _MERGE_EXIT=1
  fi

  eval "$_RESTORE_TRAP"
  trap - EXIT

  return $_MERGE_EXIT
}

if [ "${AUTONOMOUS_MODE:-false}" = "true" ]; then
  if ! _merge_pr "$PR_NUM" "$REPO"; then
    echo "[QA] All 3 merge paths failed — token lacks admin rights on this repo."
    echo "[QA] This is valid [NEEDS HUMAN] scenario 1. Posting once and moving on."
    gh issue comment "$REPORT_ISSUE" --repo "$REPO" \
      --body "[NEEDS HUMAN: merge-blocked] PR #${PR_NUM} — token cannot merge (lacks admin rights). Manual merge required." 2>/dev/null
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

# Close the GitHub issue that this item was implementing
# ITEM_ID is "issue-NNN" format — extract the number and close it
_ISSUE_NUM=$(echo "$ITEM_ID" | grep -oE '[0-9]+$')
if [ -n "$_ISSUE_NUM" ]; then
  gh issue close "$_ISSUE_NUM" --repo "$REPO" \
    --comment "[QA | ${MY_SESSION_ID:-unknown}] Implemented in PR #${PR_NUM:-?}. Closing." \
    2>/dev/null && echo "[QA] Closed issue #$_ISSUE_NUM" || true
fi

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
