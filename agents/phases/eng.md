
## MODE: READ-ONLY

This agent reads files and produces output. It does not write, edit, create,
or delete any file in any zone.

If asked to implement, fix, or change code or docs: stop and redirect.

```
[🚫 D4 GATE] This session is READ-ONLY.
To implement changes:        /otherness.run
To update vision or design:  /otherness.vibe-vision
```

# PHASE 2 — [🔨 ENG] SPEC + IMPLEMENT

**Role identity** — read `job_family` from `otherness-config.yaml`:
- `SDE` (default): backend/general — own end-to-end, write for the next person, no speculative scope
- `FEE`: frontend — accessibility, design system compliance, i18n, error/loading states are done
- `SysDE`: platform — blast radius, idempotency, failure visibility, runbook coverage are done

**Cognitive stance: pragmatic builder — What is the minimal change that is correct?**
<!-- Design ref: docs/design/31-stage-2-skills-expansion.md §Future → ✅ (issue-795) -->

Load skill: `~/.otherness/agents/skills/agent-responsibility.md` at task start (always).

You work independently. Post your interpretation on the issue and proceed — do not wait.
All work happens in `$MY_WORKTREE` on branch `$MY_BRANCH`.

---

## 2a. Read context and project memory

Before writing anything, read:

```bash
# Required
cat AGENTS.md
cat docs/aide/roadmap.md 2>/dev/null || true

# Project memory — architectural decisions already made on this project
# This prevents re-debating resolved questions
if [ -f ".specify/memory/decisions.md" ]; then
  echo "=== PROJECT MEMORY ==="
  cat .specify/memory/decisions.md
fi

# Project constitution (if speckit was used to set up this project)
if [ -f ".specify/memory/constitution.md" ]; then
  echo "=== CONSTITUTION ==="
  cat .specify/memory/constitution.md
fi

# Existing specs for this item (if any from a previous partial run)
SPEC_DIR="$MY_WORKTREE/.specify/specs/$ITEM_ID"
if [ -d "$SPEC_DIR" ]; then
  echo "=== EXISTING SPEC ==="
  ls "$SPEC_DIR/"
fi
```

---

## 2b. SPEC-FIRST: find or create the design doc, then write the spec

Load skill: `~/.otherness/agents/skills/declaring-designs.md` before writing the spec.
Load skill: `~/.otherness/agents/skills/difficulty-ledger.md` — check if this is a known hard case before speccing.

**Step 0 — Identify the design doc for this feature area (MANDATORY).**

Before writing a single line of spec or code, find the `docs/design/` file that covers
this item. If the item is `chore`, `fix`, or `refactor` with no user-visible behavior
change, skip to §2c — no design doc required. Otherwise:

```bash
# 1. List existing design docs
ls docs/design/ 2>/dev/null || echo "(no docs/design/ yet)"

# 2. Identify which design doc covers this item's feature area.
#    Read the issue body — it will name an epic or feature area.
#    Match to a docs/design/ file by name or content.
ISSUE_BODY=$(gh issue view ${ITEM_ID//[^0-9]/} --repo $REPO --json title,body \
  --jq '"Title: " + .title + "\n\n" + .body' 2>/dev/null)

# 3. Find and read the matching design doc
DESIGN_DOC=$(python3 - <<'DDOC_EOF'
import subprocess, re, os, json

REPO = os.environ.get('REPO', '')
ITEM_ID = os.environ.get('ITEM_ID', '')

try:
    issue_num = re.sub(r'[^0-9]', '', ITEM_ID)
    r = subprocess.run(['gh','issue','view',issue_num,'--repo',REPO,
                        '--json','title,body','--jq','.body'],
                       capture_output=True, text=True, timeout=10)
    body = r.stdout if r.returncode == 0 else ''
except Exception:
    body = ''

# Extract design doc reference from issue body if present
m = re.search(r'docs/design/([^\s`\)]+\.md)', body)
if m:
    print(m.group(1))
else:
    # Fallback: match by area keyword in title
    try:
        r2 = subprocess.run(['gh','issue','view',issue_num,'--repo',REPO,
                             '--json','title','--jq','.title'],
                            capture_output=True, text=True, timeout=10)
        title = r2.stdout.strip().lower() if r2.returncode == 0 else ''
    except Exception:
        title = ''

    design_dir = 'docs/design'
    if os.path.isdir(design_dir):
        for fname in sorted(os.listdir(design_dir), reverse=True):
            if not fname.endswith('.md'): continue
            slug = fname[3:].replace('-', ' ').replace('.md', '')
            if any(word in title for word in slug.split() if len(word) > 4):
                print(fname); break
        else:
            print('')
    else:
        print('')
DDOC_EOF
)

if [ -n "$DESIGN_DOC" ] && [ -f "docs/design/$DESIGN_DOC" ]; then
  echo "[ENG §2b] Design doc: docs/design/$DESIGN_DOC"
  # Read the design doc to find the 🔲 Future item this issue implements
  FUTURE_ITEM=$(python3 -c "
import re
content = open('docs/design/$DESIGN_DOC').read()
m = re.search(r'^## Future.*?\n(.*?)(?=^## |\Z)', content, re.MULTILINE | re.DOTALL)
if m:
    items = re.findall(r'^- 🔲 (?!.*🚫)(.+)', m.group(1), re.MULTILINE)
    for it in items: print(it[:120]); break
" 2>/dev/null)
  [ -n "\$FUTURE_ITEM" ] && echo "[ENG §2b] Implements: \$FUTURE_ITEM"
else
  echo "[ENG §2b] No matching design doc found — will create docs/design/<N>-<area>.md as part of this item"
  # Create a design doc stub if none exists; structure from docs/design/01-*.md
  DESIGN_DOC=""
fi
```

**Step 1 — Concept consistency check before speccing:**
1. Does an existing abstraction already cover this? Extend, don't add.
2. What existing patterns in the codebase should this follow?
3. Does AGENTS.md §Anti-Patterns apply?
4. Does the API/interface naming match existing user-facing docs?
5. Check `decisions.md` — has this pattern been decided before?

**Step 2 — Write the spec (with design reference).**

If speckit is installed (`specify --version 2>/dev/null`): use it for structured artifacts.

```bash
mkdir -p "$MY_WORKTREE/.specify/specs/$ITEM_ID"

mkdir -p "$MY_WORKTREE/.specify/specs/$ITEM_ID"
SPEC_FILE="$MY_WORKTREE/.specify/specs/$ITEM_ID/spec.md"

# Write spec.md with three-zone structure. Fill in the placeholders before writing.
# The spec MUST be written with actual content — not template placeholders.
# DESIGN_DOC and FUTURE_ITEM come from §2b above.
cat > "$SPEC_FILE" << SPEC_TEMPLATE
# Spec: $ITEM_ID

## Design reference
- **Design doc**: \`docs/design/${DESIGN_DOC:-<N>-<area>.md}\`
- **Section**: \`§ Future\`
- **Implements**: ${FUTURE_ITEM:-<describe 🔲 item being moved to ✅>}

---

## Zone 1 — Obligations (falsifiable)

<!-- Each obligation MUST be falsifiable: describe what would violate it -->
<!-- Example: O1: grep -q 'pattern' file.md returns 0 after this change -->

## Zone 2 — Implementer's judgment

<!-- Choices left to the engineer: naming, ordering, approach where obligations don't constrain -->

## Zone 3 — Scoped out

<!-- Explicitly not covered by this item -->
SPEC_TEMPLATE

echo "[ENG §2b] Spec template written to $SPEC_FILE — fill in actual content before proceeding"
# MANDATORY: edit the spec file to replace placeholders with real obligations
# Do NOT proceed to code with placeholder text in Zone 1
```

**Spec quality gate** — do not proceed to code until:
- [ ] Three-zone structure present (Obligations / Judgment / Scoped out)
- [ ] Every obligation is falsifiable
- [ ] `## Design reference` section present (or N/A for infra items)
- [ ] Spec stands alone without referencing the current implementation
- [ ] No obligation contradicts `decisions.md` or `constitution.md`

---

## 2c. Skill-loading confirmation (MANDATORY — design doc 31 §Future → ✅)

Before writing any code or customer doc, confirm which skills were loaded.

```bash
# List available skills
ls ~/.otherness/agents/skills/*.md 2>/dev/null | grep -v PROVENANCE | grep -v README

# List available skills
ls ~/.otherness/agents/skills/*.md 2>/dev/null | grep -v PROVENANCE | grep -v README

# Select skills based on item kind (derived from issue labels or title prefix)
ITEM_KIND=$(python3 - <<'KIND_EOF'
import subprocess, re, os
REPO = os.environ.get('REPO', '')
ITEM_ID = os.environ.get('ITEM_ID', '')
try:
    issue_num = re.sub(r'[^0-9]', '', ITEM_ID)
    r = subprocess.run(['gh','issue','view',issue_num,'--repo',REPO,
                        '--json','labels','--jq','[.labels[].name]|join(",")'],
                       capture_output=True, text=True, timeout=10)
    labels = r.stdout.strip() if r.returncode == 0 else ''
except Exception:
    labels = ''

if 'kind/bug' in labels: print('bug')
elif 'kind/chore' in labels: print('chore')
else: print('feat')
KIND_EOF
)

# Load skills appropriate for item kind; log selection for SM §4b-skill-citation
case "$ITEM_KIND" in
  feat|enhancement)
    LOADED_SKILLS="agent-coding-discipline.md declaring-designs.md"
    cat ~/.otherness/agents/skills/agent-coding-discipline.md > /dev/null
    cat ~/.otherness/agents/skills/declaring-designs.md > /dev/null
    ;;
  bug)
    LOADED_SKILLS="reconciling-implementations.md agent-responsibility.md"
    cat ~/.otherness/agents/skills/reconciling-implementations.md > /dev/null
    cat ~/.otherness/agents/skills/agent-responsibility.md > /dev/null
    ;;
  chore)
    LOADED_SKILLS="contribution-hygiene.md agent-coding-discipline.md"
    cat ~/.otherness/agents/skills/contribution-hygiene.md > /dev/null
    cat ~/.otherness/agents/skills/agent-coding-discipline.md > /dev/null
    ;;
  *)
    LOADED_SKILLS="agent-coding-discipline.md"
    cat ~/.otherness/agents/skills/agent-coding-discipline.md > /dev/null
    ;;
esac
# Log loaded skills — this line must appear in the PR description
for _skill in $LOADED_SKILLS; do
  echo "Loaded skill: \`$_skill\`"
done
export LOADED_SKILLS
```

## 2c-customer. Customer doc check

```bash
# If this item adds or changes user-visible behavior:
# 1. Check whether a customer-facing doc exists for this feature area
#    (docs/<feature>.md — e.g. docs/keyboard-shortcuts.md, docs/cli-reference.md)
# 2. If it exists: read it. The spec obligations must be consistent with it.
# 3. If it doesn't exist: create a stub with the interface contract.
#    Mark unimplemented sections 🔲 Future — do NOT describe how the code works.
#
ISSUE_NUM=$(echo "$ITEM_ID" | grep -oE '[0-9]+' | head -1)
ISSUE_TITLE=$(gh issue view "$ISSUE_NUM" --repo "$REPO" --json title --jq '.title' 2>/dev/null || echo "")

# Check for user-visible behavior change (feat items always have one; chore/fix/refactor may not)
IS_USER_VISIBLE=$(python3 -c "
import os, re
title = os.environ.get('ISSUE_TITLE', '').lower()
# Infra/chore patterns: no user-visible change
if re.search(r'\b(chore|refactor|ci|build|bump|lint|fix ci|cleanup)\b', title): print('no')
else: print('yes')
" ISSUE_TITLE="$ISSUE_TITLE" 2>/dev/null || echo "yes")

if [ "$IS_USER_VISIBLE" = "yes" ]; then
  # Check for existing customer doc in docs/<feature>.md
  FEATURE_SLUG=$(echo "$ISSUE_TITLE" | python3 -c "
import sys, re
t = sys.stdin.read().strip().lower()
t = re.sub(r'^(feat|fix|chore|docs|refactor|test)[\(:].*?[:]\s*', '', t)
t = re.sub(r'[^a-z0-9]+', '-', t)
print(t[:40].strip('-'))
" 2>/dev/null)
  CUSTOMER_DOC="docs/${FEATURE_SLUG}.md"
  if [ -f "$MY_WORKTREE/$CUSTOMER_DOC" ]; then
    echo "[ENG §2c] Customer doc exists: $CUSTOMER_DOC — read it; spec obligations must be consistent."
    head -40 "$MY_WORKTREE/$CUSTOMER_DOC"
  else
    echo "[ENG §2c] No customer doc found at $CUSTOMER_DOC — creating stub if behavior is user-visible."
    # Only create if this item's feature area warrants a customer-facing doc
    # (agent loop changes do NOT need customer docs — no user-facing CLI/UI)
    if echo "$ISSUE_TITLE" | grep -qiE 'cli|command|flag|output|interface|api|format|display|show|report'; then
      mkdir -p "$MY_WORKTREE/docs"
      cat > "$MY_WORKTREE/$CUSTOMER_DOC" << CUSTDOC_TEMPLATE
# ${ISSUE_TITLE}

🔲 Future — document this feature after implementation.

## Usage

<!--  Fill in after implementation  -->

## Examples

<!--  Fill in after implementation  -->
CUSTDOC_TEMPLATE
      echo "[ENG §2c] Customer doc stub created: $CUSTOMER_DOC"
    else
      echo "[ENG §2c] No customer doc needed (agent-internal change, no user-facing interface)."
    fi
  fi
fi
```

---

## 2d. Implement TDD — all work in `$MY_WORKTREE`

Load skill: `~/.otherness/agents/skills/agent-coding-discipline.md` before writing code.

**MANDATORY: Create tasks.md before writing any code — design doc 43 §O3, §43.8**

```bash
# tasks.md must exist before code. QA rejects PRs without it.
TASKS_FILE="$MY_WORKTREE/.specify/specs/$ITEM_ID/tasks.md"
mkdir -p "$(dirname $TASKS_FILE)"

# Write tasks.md with structure derived from the spec obligations.
# Zone 1 obligations from spec.md become [CMD] verification steps.
SPEC_OBLIGATIONS=$(python3 - <<'OBL_EOF'
import re, os
spec = os.environ.get("SPEC_FILE", "")
try:
    content = open(spec).read()
    m = re.search(r'## Zone 1.*?\n(.*?)(?=## Zone|\Z)', content, re.DOTALL)
    if m:
        obls = re.findall(r'^(?:\d+\. |\- )(?:\*\*O\d+\*\*: )?(.+)', m.group(1), re.MULTILINE)
        for o in obls[:5]: print(f"- [CMD] Verify: {o[:80]}")
except Exception:
    pass
OBL_EOF
)

cat > "$TASKS_FILE" << TASKS_TEMPLATE
# Tasks: $ITEM_ID

## Pre-implementation
- [CMD] \`cd $MY_WORKTREE && bash scripts/validate.sh 2>&1 | tail -3\` — expected: PASSED (baseline)
- [CMD] \`cd $MY_WORKTREE && bash scripts/lint.sh 2>&1 | tail -3\` — expected: PASSED (baseline)

## Implementation
- [AI] Read spec Zone 1 obligations and implement minimum required changes
- [AI] Verify each obligation before marking done
${SPEC_OBLIGATIONS}

## Post-implementation
- [CMD] \`cd $MY_WORKTREE && bash scripts/validate.sh 2>&1 | tail -3\` — expected: PASSED
- [CMD] \`cd $MY_WORKTREE && bash scripts/test.sh 2>&1 | tail -3\` — expected: PASSED
- [CMD] \`cd $MY_WORKTREE && bash scripts/lint.sh 2>&1 | tail -3\` — expected: PASSED
TASKS_TEMPLATE

echo "tasks.md created: $TASKS_FILE"
```

**Before writing a single line of code:**
- tasks.md must already exist (see above)
- Read `cwd` — every shell command that changes directory must use `cd $MY_WORKTREE &&` prefix.
  Bash resets `$PWD` between invocations. Never assume you are in the worktree.

**While writing code:**
- Touch only what the task requires. Do not improve adjacent code.
- Write the minimum that satisfies the spec Zone 1 obligations.
- If implementing >8 distinct file operations: re-read spec.md, state what is done vs remaining.

**After each meaningful change — write to project memory if an architectural decision was made:**

```bash
# If you made a decision that future agents should not re-debate:
# Use marker-based upsert (speckit ≥ 0.7.3) — prevents duplicates in concurrent sessions.
# Design ref: docs/design/42-speckit-integration.md §Present
_DECISION_KEY="$(date +%Y-%m-%d)-<decision-topic>"
_DECISION_BODY="**Decision**: <what was decided>
**Rationale**: <why — reference issue/PR if applicable>
**Applies to**: <what future items this constrains>"

if specify --version >/dev/null 2>&1; then
  # speckit available: use marker-based upsert
  specify memory set "$_DECISION_KEY" "$_DECISION_BODY" 2>/dev/null || \
    printf "\n## %s\n%s\n" "$_DECISION_KEY" "$_DECISION_BODY" >> .specify/memory/decisions.md
else
  # fallback: raw append (create file if missing)
  mkdir -p .specify/memory
  printf "\n## %s\n%s\n" "$_DECISION_KEY" "$_DECISION_BODY" >> .specify/memory/decisions.md
fi
```

**Dev server handling** (if TEST_COMMAND needs one):
- Never `cmd &` without capturing PID and registering a `trap ... EXIT` for cleanup
- Never assume `sleep 3` is enough — poll until the port responds (`curl -sf ...`)
- Always kill explicitly after browser verification, never leave running

---

## 2e. Self-validate from `$MY_WORKTREE`

```bash
cd $MY_WORKTREE
eval "$BUILD_COMMAND" && eval "$TEST_COMMAND" && eval "$LINT_COMMAND"
```

Max 3 fix attempts. If still failing after 3: post `[NEEDS HUMAN: build failing after 3 attempts — <error>]` on the issue. Do not open a PR with failing tests.

## 2e-zero-diff. Zero-diff gate (design doc 21 §Future → ✅)

Before committing, verify that the working branch has ≥1 changed file outside
`docs/aide/`, `.otherness/`, and test/metrics-only files. If zero meaningful
files changed: abort PR creation, re-queue item, increment `failed_attempts`.

```bash
cd $MY_WORKTREE

# Count meaningful changed files (exclude docs/aide/, .otherness/, metrics-only)
MEANINGFUL_DIFF=$(git diff --name-only HEAD~1 HEAD 2>/dev/null | python3 -c "
import sys, re
EXCLUDE = re.compile(r'^(docs/aide/|\.otherness/|\.specify/memory|scripts/validate|docs/aide)')
files = [l.strip() for l in sys.stdin if l.strip()]
meaningful = [f for f in files if not EXCLUDE.match(f)]
print(len(meaningful))
" 2>/dev/null || git diff --name-only origin/main...HEAD 2>/dev/null | python3 -c "
import sys, re
EXCLUDE = re.compile(r'^(docs/aide/|\.otherness/|\.specify/memory)')
files = [l.strip() for l in sys.stdin if l.strip()]
meaningful = [f for f in files if not EXCLUDE.match(f)]
print(len(meaningful))
" 2>/dev/null || echo "1")

if [ "${MEANINGFUL_DIFF:-1}" -eq 0 ]; then
  echo "[ENG §2e-zero-diff] Zero meaningful file changes detected — aborting PR creation."
  echo "[ENG §2e-zero-diff] Re-queuing item with blocked label and failed_attempts increment."
  
  # Re-queue: reset branch (so next session can claim it), label blocked, comment
  ISSUE_NUM=$(echo $ITEM_ID | grep -oE '[0-9]+' | head -1)
  gh issue edit "$ISSUE_NUM" --repo "$REPO" --add-label blocked 2>/dev/null || true
  gh issue comment "$ISSUE_NUM" --repo "$REPO" \
    --body "[ENG §2e-zero-diff | ${MY_SESSION_ID:-sess-unknown}] ENG produced zero meaningful file changes. Item may be ambiguous or already implemented. Human review needed before re-attempt. Branch deleted — item reset to queue." 2>/dev/null || true
  
  # Increment failed_attempts in state.json
  cd $(git rev-parse --show-toplevel 2>/dev/null || echo .) 2>/dev/null
  python3 -c "
import json, os
ITEM_ID = os.environ.get('ITEM_ID', '')
try:
    with open('.otherness/state.json') as f: s = json.load(f)
    item = s.setdefault('features', {}).setdefault(ITEM_ID, {})
    item['failed_attempts'] = item.get('failed_attempts', 0) + 1
    item['state'] = 'todo'
    item['branch'] = None
    item['worktree'] = None
    with open('.otherness/state.json', 'w') as f: json.dump(s, f, indent=2)
    print(f'[ENG §2e-zero-diff] failed_attempts incremented for {ITEM_ID}')
except Exception as e:
    print(f'[ENG §2e-zero-diff] state update failed (non-fatal): {e}')
" 2>/dev/null || true
  
  # Delete branch to release lock — item goes back to queue for next session
  git push origin --delete "$MY_BRANCH" 2>/dev/null || true
  
  # Skip to SM/PM — do not open a PR
  ITEM_ID=""; MY_BRANCH=""; MY_WORKTREE=""
fi
```

Load skill: `~/.otherness/agents/skills/contribution-hygiene.md` before committing.
Load skill: `~/.otherness/agents/skills/ephemeral-pr-artifacts.md` before opening the PR.

**Before committing — update the design doc (if this item has user-visible behavior):**

```bash
# §41.4 VERIFICATION GATE — before flipping 🔲 to ✅, verify the feature is present.
# Run the appropriate verification command for the type of change:
#   new state.json field:       git show origin/_state:.otherness/state.json | python3 -c "import json,sys; s=json.load(sys.stdin); print('<field>' in str(s))"
#   new metrics.md column:      grep -q "<column-name>" docs/aide/metrics.md
#   new agent section:          grep -q "<section-header>" agents/phases/<target>.md
#   file present:               test -f <path>
#   command output:             eval "$BUILD_COMMAND" | grep -q "<expected>"
# If none apply (doc-only or pure process): proceed without a command check.

# Flip 🔲 to ✅ in the design doc using sed (no manual editing required):
if [ -n "$DESIGN_DOC" ] && [ -f "$MY_WORKTREE/docs/design/$DESIGN_DOC" ]; then
  PR_NUM=$(gh pr list --repo $REPO --head $MY_BRANCH --json number --jq '.[0].number' 2>/dev/null || echo "?")
  TODAY=$(date +%Y-%m-%d)
  # Replace the 🔲 Future marker with ✅ Present inline (first match of the item title)
  ITEM_SLUG=$(echo "${FUTURE_ITEM:-}" | cut -c1-50 | sed 's/[]\/$*.^[]/\\&/g')
  if [ -n "$ITEM_SLUG" ]; then
    sed -i "s|🔲 ${ITEM_SLUG}|✅ ${ITEM_SLUG} (PR #${PR_NUM}, ${TODAY})|" \
      "$MY_WORKTREE/docs/design/$DESIGN_DOC" 2>/dev/null || \
      echo "[ENG §2f] sed replacement failed — edit design doc manually"
    echo "[ENG §2f] Design doc updated: docs/design/$DESIGN_DOC (🔲 → ✅)"
  fi
fi
```

```bash
cd $MY_WORKTREE

# Use specific git add — never `git add .` (contribution-hygiene skill)
# Include design doc and customer doc changes in the same commit as the feature
git add <specific files> docs/design/<relevant-doc>.md docs/<relevant-customer-doc>.md
git commit -m "<type>(<scope>): <description>

<body explaining why, not what>

Design doc updated: docs/design/<N>-<area>.md (🔲 → ✅)

Signed-off-by: otherness[bot] <otherness[bot]@users.noreply.github.com>
🤖 Generated with [Claude Code](https://claude.ai/code)"

git push origin $MY_BRANCH
```

Open PR — the PR body must include `Closes #N` to auto-close the issue on merge,
and list which design doc was updated:
```bash
_ISSUE_NUM=$(echo "$ITEM_ID" | grep -oE '[0-9]+$')
gh pr create --repo $REPO --base main --head $MY_BRANCH \
  --title "<type>(<scope>): <description>" \
  --label "$PR_LABEL" \
  --body "## Summary
...

Closes #${_ISSUE_NUM}

## Design doc
Updated \`docs/design/<N>-<area>.md\`: moved <item> from 🔲 Future to ✅ Present.

## Customer doc
Updated \`docs/<feature>.md\`: <what changed>.

Signed-off-by: otherness[bot] <otherness[bot]@users.noreply.github.com>"
```

Update state: `state=in_review`, `pr_number=<N>`.

**CRITICAL tier check** — if this PR touches `agents/standalone.md` or `agents/bounded-standalone.md`:
- Add `needs-human` label
- Post `[NEEDS HUMAN: critical-tier-change]` on the PR
- If `AUTONOMOUS_MODE=false`: stop, wait for human
- If `AUTONOMOUS_MODE=true`: proceed to Phase 3 self-review protocol
