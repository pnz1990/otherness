
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

**Cognitive stance: adversarial skeptic — What assumption is wrong here?**
<!-- Design ref: docs/design/31-stage-2-skills-expansion.md §Future → ✅ (issue-795) -->

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

    # §38.3 — Pattern-matching CI fix loop (design doc 38 §Future 38.3 → ✅)
    # Attempt a deterministic fix from known error patterns.
    # Known-pattern fixes run first; unknown patterns post a PR comment and continue.
    _FIX_APPLIED=false
    if [ -n "$_FAIL_LOG" ]; then
      # Pattern 1: Go formatting
      if echo "$_FAIL_LOG" | grep -qi "not properly formatted\|gofmt"; then
        echo "[QA §3a] Pattern: gofmt — running gofmt -w"
        find "$MY_WORKTREE" -name "*.go" -exec gofmt -w {} + 2>/dev/null || true
        _FIX_APPLIED=true
      fi

      # Pattern 2: CRLF line endings (otherness lint check)
      if echo "$_FAIL_LOG" | grep -qi "CRLF\|line ending\|carriage return"; then
        echo "[QA §3a] Pattern: CRLF — stripping carriage returns from agent files"
        find "$MY_WORKTREE/agents" -name "*.md" -exec sed -i 's/\r//' {} + 2>/dev/null || true
        _FIX_APPLIED=true
      fi

      # Pattern 3: validate.sh — hardcoded project path
      if echo "$_FAIL_LOG" | grep -qi "hardcoded.*project\|specific project"; then
        echo "[QA §3a] Pattern: hardcoded path — scanning agent files for project-specific strings"
        # Extract the offending string from the failure log (validate.sh prints the line)
        _BAD_LINE=$(echo "$_FAIL_LOG" | grep -i "hardcoded\|specific project" | head -1)
        # Extract quoted content (e.g. 'owner/repo' or "owner/repo") from the error line
        _BAD_SLUG=$(echo "$_BAD_LINE" | grep -oE "'[^']+/[^']+'" | head -1 | tr -d "'" || \
                    echo "$_BAD_LINE" | grep -oE '"[^"]+/[^"]+"' | head -1 | tr -d '"')
        if [ -n "$_BAD_SLUG" ]; then
          echo "[QA §3a] Removing hardcoded slug '$_BAD_SLUG' from agent files"
          find "$MY_WORKTREE/agents" -name "*.md" -exec grep -l "$_BAD_SLUG" {} + 2>/dev/null | \
            xargs -I{} sed -i "s|$_BAD_SLUG|\$REPO|g" {} 2>/dev/null || true
          _FIX_APPLIED=true
        else
          echo "[QA §3a] Pattern 3: could not extract slug from error — posting as comment"
          gh pr comment "$PR_NUM" --repo "$REPO" \
            --body "[QA §3a | attempt $_CI_ATTEMPTS] Hardcoded path detected but could not auto-fix. Failure log:\n\`\`\`\n$_FAIL_LOG\n\`\`\`\nENG must remove the project-specific string manually." \
            2>/dev/null || true
          _FIX_APPLIED=false
        fi
      fi

      # Pattern 4: missing required file (validate.sh check)
      if echo "$_FAIL_LOG" | grep -qi "required.*file.*missing\|not found.*required"; then
        echo "[QA §3a] Pattern: missing required file — checking validate.sh output for missing path"
        # validate.sh prints the missing file path — extract it
        _MISSING_FILE=$(echo "$_FAIL_LOG" | grep -i "required.*file.*missing\|not found.*required" | \
          grep -oE '[a-zA-Z0-9_/.-]+\.(md|sh|yaml|yml)' | head -1)
        if [ -n "$_MISSING_FILE" ]; then
          echo "[QA §3a] Required file missing: $_MISSING_FILE — creating placeholder"
          mkdir -p "$MY_WORKTREE/$(dirname "$_MISSING_FILE")" 2>/dev/null || true
          if [ ! -f "$MY_WORKTREE/$_MISSING_FILE" ]; then
            printf "# %s\n\nPlaceholder — created by QA CI fix loop.\n" \
              "$(basename "$_MISSING_FILE" .md)" > "$MY_WORKTREE/$_MISSING_FILE"
            _FIX_APPLIED=true
          fi
        else
          echo "[QA §3a] Pattern 4: could not identify missing file — posting as comment"
          gh pr comment "$PR_NUM" --repo "$REPO" \
            --body "[QA §3a | attempt $_CI_ATTEMPTS] Required file missing but could not auto-fix. Failure:\n\`\`\`\n$_FAIL_LOG\n\`\`\`\nENG must create the missing file." \
            2>/dev/null || true
          _FIX_APPLIED=false
        fi
      fi

      # Pattern 5: self-update block missing (validate.sh check)
      if echo "$_FAIL_LOG" | grep -qi "self-update\|git.*pull.*missing"; then
        echo "[QA §3a] Pattern: self-update block — check standalone.md contains git -C ~/.otherness pull"
        _FIX_APPLIED=false  # needs judgment
      fi

      # Pattern 6: null bytes or binary content (lint check)
      if echo "$_FAIL_LOG" | grep -qi "null byte\|binary\|NUL"; then
        echo "[QA §3a] Pattern: null bytes — removing null bytes from agent files"
        for _f in $(find "$MY_WORKTREE/agents" -name "*.md" 2>/dev/null); do
          python3 -c "
import sys
data = open('$_f', 'rb').read()
if b'\\x00' in data:
    open('$_f', 'wb').write(data.replace(b'\\x00', b''))
    print(f'Cleaned null bytes from $_f')
" 2>/dev/null || true
        done
        _FIX_APPLIED=true
      fi
    fi

    if [ "$_FIX_APPLIED" = "true" ]; then
      echo "[QA §3a] Deterministic fix applied — committing and pushing"
      (cd "$MY_WORKTREE" && \
        git add -A && \
        git commit -m "fix(ci): automated CI fix (attempt $_CI_ATTEMPTS) — pattern-matched from failure log" \
          --trailer "Signed-off-by: otherness[bot] <otherness[bot]@users.noreply.github.com>" \
          2>/dev/null && \
        git push --force-with-lease origin "$(git rev-parse --abbrev-ref HEAD)" 2>/dev/null) || true
      sleep 20
    else
      # Post failure log as PR comment so operator can see what failed
      if [ -n "$_FAIL_LOG" ] && [ $_CI_ATTEMPTS -eq 1 ]; then
        gh pr comment "$PR_NUM" --repo "$REPO" \
          --body "[QA §3a | attempt $_CI_ATTEMPTS] No deterministic fix pattern matched. Failure log:\n\`\`\`\n$_FAIL_LOG\n\`\`\`" \
          2>/dev/null || true
      fi
      # No known pattern matched — log is posted above; increment and retry CI.
      # ENG must fix: read the PR comment for the failure log excerpt.
      sleep 30
    fi
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
  echo "[QA] Posting WRONG finding on PR and exiting QA — loop must return to ENG."
  gh pr comment "$PR_NUM" --repo "$REPO" \
    --body "[🔍 QA] WRONG — \`.specify/specs/$ITEM_ID/spec.md\` missing. ENG must write the spec (three-zone structure: Obligations / Judgment / Scoped out) and re-push before QA can approve. See eng.md §2b." \
    2>/dev/null || true
  exit 1  # Non-zero exit returns loop to ENG phase
else
  echo "[QA] Running spec conformance check..."
  # Extract Zone 1 obligations from spec.md (lines under "## Zone 1" section)
  _OBLIGATIONS=$(awk '/^## Zone 1/,/^## Zone [23]/' "$SPEC_FILE" | \
    grep -E '^\*\*O[0-9]+\*\*|^- \*\*O[0-9]+\*\*' | sed 's/\*\*//g')
  _DIFF=$(gh pr diff "$PR_NUM" --repo "$REPO" 2>/dev/null || echo "")
  _SPEC_FAIL=""
  while IFS= read -r _OBL; do
    # Each obligation must have a matching keyword in the diff
    # Extract key noun/verb from the obligation text (first significant word after ONN:)
    _KEY=$(echo "$_OBL" | sed 's/^O[0-9]*[:.] *//' | grep -oE '[A-Za-z_][A-Za-z0-9_-]{3,}' | head -1)
    if [ -n "$_KEY" ] && [ -n "$_DIFF" ]; then
      if ! echo "$_DIFF" | grep -qi "$_KEY"; then
        _SPEC_FAIL="$_SPEC_FAIL\n- Obligation '$_OBL' — no diff evidence for key '$_KEY'"
      fi
    fi
  done <<< "$_OBLIGATIONS"

  if [ -n "$_SPEC_FAIL" ]; then
    echo "[QA] WRONG — spec conformance failures:"
    echo -e "$_SPEC_FAIL"
    gh pr comment "$PR_NUM" --repo "$REPO" \
      --body "[🔍 QA] WRONG — spec conformance check failed.\n\nUnverified obligations:\n$(echo -e "$_SPEC_FAIL")\n\nENG must satisfy these before merge." \
      2>/dev/null || true
    exit 1
  fi
  echo "[QA] Spec conformance: all Zone 1 obligations have diff evidence."

   # Design reference check — MANDATORY for feature PRs
   _DESIGN_REF=$(grep -A 2 "^## Design reference" "$SPEC_FILE" 2>/dev/null | \
     grep "docs/design/" | grep -oE 'docs/design/[^`]+\.md' | head -1)
   _DESIGN_NA=$(grep -i "N/A.*infrastructure\|infrastructure.*N/A\|no user-visible" "$SPEC_FILE" 2>/dev/null | head -1)

   if [ -n "$_DESIGN_NA" ]; then
     echo "[QA §3b] Design ref: N/A (infrastructure change) — acceptable."
   elif [ -z "$_DESIGN_REF" ]; then
     # Check if ## Design reference section exists at all
     if ! grep -q "^## Design reference" "$SPEC_FILE" 2>/dev/null; then
       echo "[QA] WRONG — spec.md missing ## Design reference section."
       gh pr comment "$PR_NUM" --repo "$REPO" \
         --body "[🔍 QA] WRONG — \`spec.md\` missing \`## Design reference\` section. Per docs/design/01-declarative-design-driven-development.md O2, every spec must reference its design doc (or declare N/A for infra-only changes). ENG must add this section and re-push." \
         2>/dev/null || true
       exit 1
     fi
     echo "[QA §3b] Design ref section present but no docs/design/ path found — treating as N/A."
   else
     echo "[QA §3b] Design ref: $_DESIGN_REF"
     # Verify the design doc is updated in the diff (🔲 → ✅)
     if [ -n "$_DIFF" ] && ! echo "$_DIFF" | grep -q "$(basename "$_DESIGN_REF")"; then
       echo "[QA] WRONG — design doc '$_DESIGN_REF' not updated in PR diff."
       gh pr comment "$PR_NUM" --repo "$REPO" \
         --body "[🔍 QA] WRONG — spec.md references \`$_DESIGN_REF\` but that file is not updated in this PR. ENG must flip the 🔲 item to ✅ Present in the design doc and re-push." \
         2>/dev/null || true
       exit 1
     fi
     echo "[QA §3b] Design doc updated in diff: ✓"
   fi
   #
   # §41.4 VERIFICATION GATE CHECK (QA mandatory): if this PR marks a design doc item 🔲 → ✅
   _FLIPS_CHECKMARK=$(echo "$_DIFF" | grep -c '^\+.*✅' 2>/dev/null || echo "0")
   _REMOVES_FUTURE=$(echo "$_DIFF" | grep -c '^\-.*🔲' 2>/dev/null || echo "0")
   if [ "${_FLIPS_CHECKMARK:-0}" -gt 0 ] || [ "${_REMOVES_FUTURE:-0}" -gt 0 ]; then
     # PR flips a design doc item — check for verification note
     _PR_BODY=$(gh pr view "$PR_NUM" --repo "$REPO" --json body --jq '.body' 2>/dev/null || echo "")
     _VERIFICATION_PHRASES="verified state.json\|verified metrics\|verified section\|documentation-only\|pure process change\|verification note\|verified.*agents/phases\|verified.*_state"
     if ! grep -qi "$_VERIFICATION_PHRASES" "$SPEC_FILE" 2>/dev/null && \
        ! echo "$_PR_BODY" | grep -qi "$_VERIFICATION_PHRASES"; then
       echo "[QA] WRONG — verification gate not satisfied."
       gh pr comment "$PR_NUM" --repo "$REPO" \
         --body "[🔍 QA] WRONG — ENG §2f verification gate not satisfied. This PR marks a design doc item ✅ Present without a verification note in spec.md or the PR description. Per docs/design/41-design-doc-integrity.md §41.4, ENG must add a verification note (e.g. 'verified section X in agents/phases/Y.md') and re-push." \
         2>/dev/null || true
       exit 1
     fi
      echo "[QA §3b] Verification gate: verification note found ✓"
    fi

   # §41.5 docs gate — user-visible feature without docs update (design doc 41 §41.5)
   # Fires only when: (a) this PR flips a 🔲 → ✅ AND (b) the feature is user-visible
   # User-visible signals in the flipped item text: CLI, CRD, UI, endpoint, api, command, flag, output
   # Pass condition: any docs file in the diff (docs/*.md, README.md, excluding agents/, .specify/, docs/design/, docs/aide/)
   # Fail-open: any exception → skip check (no false WRONG findings)
   if [ "${_FLIPS_CHECKMARK:-0}" -gt 0 ] || [ "${_REMOVES_FUTURE:-0}" -gt 0 ]; then
     _DOCS_GATE_RESULT=$(python3 - <<'DOCSGATE_EOF' 2>/dev/null || echo "SKIP"
import subprocess, re, os, sys

PR_NUM = os.environ.get('PR_NUM', '')
REPO = os.environ.get('REPO', '')
SPEC_FILE = os.environ.get('SPEC_FILE', '')

if not PR_NUM or not REPO:
    print('SKIP')
    sys.exit(0)

# Step 1: Extract the flipped item description from the diff
try:
    diff = subprocess.check_output(
        ['gh', 'pr', 'diff', PR_NUM, '--repo', REPO],
        text=True, timeout=20)
except Exception:
    print('SKIP')
    sys.exit(0)

# Find lines that removed 🔲 (flipped to ✅)
removed_future = [l[1:].strip() for l in diff.splitlines()
                  if l.startswith('-') and '🔲' in l and not l.startswith('---')]

if not removed_future:
    print('PASS')
    sys.exit(0)

# Step 2: Check if any flipped item is user-visible
USER_VISIBLE_KEYWORDS = re.compile(
    r'\b(cli|crd|ui|endpoint|api|command|flag|output|interface|webhook|'
    r'dashboard|page|button|menu|config\s+field|yaml\s+field|argument)\b',
    re.IGNORECASE)

is_user_visible = any(USER_VISIBLE_KEYWORDS.search(item) for item in removed_future)

if not is_user_visible:
    print('PASS')
    sys.exit(0)

# Step 3: Check for a docs file in the diff
DOC_EXCLUDE = re.compile(r'^(agents/|\.specify/|docs/design/|docs/aide/)')
doc_files_in_diff = []
for line in diff.splitlines():
    if line.startswith('+++ b/') or line.startswith('--- a/'):
        path = line.split(' b/', 1)[-1].split(' a/', 1)[-1].strip()
        if (path.endswith('.md') or path == 'README.md') and not DOC_EXCLUDE.match(path):
            doc_files_in_diff.append(path)

if doc_files_in_diff:
    print(f'PASS (doc files found: {", ".join(doc_files_in_diff[:2])})')
    sys.exit(0)

# Step 4: Fail — user-visible feature with no docs update
flipped_item = removed_future[0][:100]
print(f'WRONG: user-visible feature flipped to ✅ Present without docs update. '
      f'Flipped item: "{flipped_item}". '
      f'ENG must update a docs file (docs/*.md, README.md) or declare docs are auto-generated.')
DOCSGATE_EOF
)
     if echo "$_DOCS_GATE_RESULT" | grep -q "^WRONG:"; then
       _DOCS_GATE_MSG=$(echo "$_DOCS_GATE_RESULT" | head -1)
       echo "[QA §41.5] WRONG — docs gate: $_DOCS_GATE_MSG"
       gh pr comment "$PR_NUM" --repo "$REPO" \
         --body "[🔍 QA §41.5] WRONG — User-visible feature marked ✅ Present without a docs update. $_DOCS_GATE_MSG Per \`docs/design/41-published-docs-freshness.md §41.5\`, ENG must update a docs file or declare the feature is auto-documented by Layer 1." \
         2>/dev/null || true
       exit 1
     else
       echo "[QA §41.5] Docs gate: $_DOCS_GATE_RESULT"
     fi
   fi
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

  # Set board Status: Done — design doc 43 §O1, §43.5
  # Non-blocking: board update failure must not stop the loop (O5)
  _BOARD_PROJECT_ID=$(python3 -c "
import re
section=None
for line in open('otherness-config.yaml'):
    s=re.match(r'^(\w[\w_]*):', line)
    if s: section=s.group(1)
    if section=='project':
        m=re.match(r'^\s+board_project_id:\s*[\"\'']?([^\"\'#\n\s]+)[\"\'']?', line)
        if m: print(m.group(1).strip()); break
" 2>/dev/null || echo "")

  if [ -n "$_BOARD_PROJECT_ID" ]; then
    python3 - <<BOARD_EOF 2>/dev/null || true
import subprocess, json, os

PROJECT_ID = os.environ.get('_BOARD_PROJECT_ID', '${_BOARD_PROJECT_ID}')
ISSUE_NUM = int('${_ISSUE_NUM}')
REPO = os.environ.get('REPO', '${REPO}')

# Get the board item ID for this issue
q1 = subprocess.run(['gh','api','graphql','-f',
    f'query={{ node(id: "{PROJECT_ID}") {{ ... on ProjectV2 {{ items(first:200) {{ nodes {{ id content {{ ... on Issue {{ number }} }} }} }} }} }} }}'],
    capture_output=True, text=True)
try:
    data = json.loads(q1.stdout)
    items = data['data']['node']['items']['nodes']
    item_id = next((i['id'] for i in items if i.get('content',{}).get('number')==ISSUE_NUM), None)
except: item_id = None

if not item_id: print(f'[PM] Issue #{ISSUE_NUM} not on board — skipping status update'); exit(0)

# Get Status field ID and Done option ID
q2 = subprocess.run(['gh','api','graphql','-f',
    f'query={{ node(id: "{PROJECT_ID}") {{ ... on ProjectV2 {{ fields(first:20) {{ nodes {{ ... on ProjectV2SingleSelectField {{ id name options {{ id name }} }} }} }} }} }} }}'],
    capture_output=True, text=True)
try:
    fdata = json.loads(q2.stdout)
    fields = fdata['data']['node']['fields']['nodes']
    status_field = next((f for f in fields if f.get('name')=='Status'), None)
    field_id = status_field['id']
    done_id = next((o['id'] for o in status_field['options'] if o['name']=='Done'), None)
except: field_id = done_id = None

if not field_id or not done_id: print('[PM] Could not find Status/Done field — skipping'); exit(0)

# Set Done
mut = f'mutation {{ updateProjectV2ItemFieldValue(input: {{ projectId: "{PROJECT_ID}" itemId: "{item_id}" fieldId: "{field_id}" value: {{ singleSelectOptionId: "{done_id}" }} }}) {{ projectV2Item {{ id }} }} }}'
subprocess.run(['gh','api','graphql','-f',f'mutation={mut}'],capture_output=True)
print(f'[PM] Board Status → Done for issue #{ISSUE_NUM}')
BOARD_EOF
  fi
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
