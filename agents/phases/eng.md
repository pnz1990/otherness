# PHASE 2 — [🔨 ENG] SPEC + IMPLEMENT

**Role identity** — read `job_family` from `otherness-config.yaml`:
- `SDE` (default): backend/general — own end-to-end, write for the next person, no speculative scope
- `FEE`: frontend — accessibility, design system compliance, i18n, error/loading states are done
- `SysDE`: platform — blast radius, idempotency, failure visibility, runbook coverage are done

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

# 3. [AI-STEP] Read the matching design doc. Find the 🔲 Future item(s) this
#    issue implements. The spec you write MUST reference this design doc.
#
#    If no matching design doc exists:
#    - Create docs/design/<N>-<area>.md using the design doc structure from
#      docs/design/01-declarative-design-driven-development.md
#    - Mark the new item as 🔲 Future (you will flip it to ✅ Present in §2f)
#    - Creating the design doc is part of THIS item's work — not a separate issue
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

# [AI-STEP] Write .specify/specs/$ITEM_ID/spec.md using the three-zone structure:
# Zone 1 — Obligations (falsifiable, must satisfy)
# Zone 2 — Implementer's judgment (choices left to engineer)
# Zone 3 — Scoped out (explicitly not covered)
# Each obligation must be falsifiable — describe behavior that would violate it.
#
# The spec MUST include a ## Design reference section:
#
#   ## Design reference
#   - **Design doc**: `docs/design/<N>-<area>.md`
#   - **Section**: `<section name>`
#   - **Implements**: <brief description of 🔲 item being moved to ✅>
#
# If this item has no user-visible behavior change (pure chore/fix/refactor):
#   ## Design reference
#   - N/A — infrastructure change with no user-visible behavior
```

**Spec quality gate** — do not proceed to code until:
- [ ] Three-zone structure present (Obligations / Judgment / Scoped out)
- [ ] Every obligation is falsifiable
- [ ] `## Design reference` section present (or N/A for infra items)
- [ ] Spec stands alone without referencing the current implementation
- [ ] No obligation contradicts `decisions.md` or `constitution.md`

---

## 2c. Customer doc check

```bash
# If this item adds or changes user-visible behavior:
# 1. Check whether a customer-facing doc exists for this feature area
#    (docs/<feature>.md — e.g. docs/keyboard-shortcuts.md, docs/cli-reference.md)
# 2. If it exists: read it. The spec obligations must be consistent with it.
# 3. If it doesn't exist: create a stub with the interface contract.
#    Mark unimplemented sections 🔲 Future — do NOT describe how the code works.
#
# [AI-STEP] Perform this check. Update or create the customer doc stub if needed.
# The customer doc change will ship in the same PR as the feature (see §2f).
```

---

## 2d. Implement TDD — all work in `$MY_WORKTREE`

Load skill: `~/.otherness/agents/skills/agent-coding-discipline.md` before writing code.

**Before writing a single line of code:**
- Write the concrete success criterion (failing test, or exact observable behavior)
- Mark tasks.md: which steps are AI steps (require judgment) vs command steps (deterministic)
- Read `cwd` — every shell command that changes directory must use `cd $MY_WORKTREE &&` prefix.
  Bash resets `$PWD` between invocations. Never assume you are in the worktree.

**While writing code:**
- Touch only what the task requires. Do not improve adjacent code.
- Write the minimum that satisfies the spec Zone 1 obligations.
- If implementing >8 distinct file operations: re-read spec.md, state what is done vs remaining.

**After each meaningful change — write to project memory if an architectural decision was made:**

```bash
# If you made a decision that future agents should not re-debate:
# Append to .specify/memory/decisions.md (create if missing)
cat >> .specify/memory/decisions.md << 'EOF'

## $(date +%Y-%m-%d): <decision topic>
**Decision**: <what was decided>
**Rationale**: <why — reference issue/PR if applicable>
**Applies to**: <what future items this constrains>
EOF
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

---

## 2f. Update design doc, commit and push

Load skill: `~/.otherness/agents/skills/contribution-hygiene.md` before committing.
Load skill: `~/.otherness/agents/skills/ephemeral-pr-artifacts.md` before opening the PR.

**Before committing — update the design doc (if this item has user-visible behavior):**

```bash
# [AI-STEP] Open the design doc identified in §2b.
# Find the 🔲 Future item(s) this PR implements.
# Move them to the ✅ Present section, adding "(PR #N, date)".
# If new behavior was added that wasn't in the design doc: add it to ✅ Present.
# Do NOT add new 🔲 Future items here — that is the PM's job.
#
# Also update the customer doc (docs/<feature>.md) to match what was actually shipped:
# - Remove 🔲 Future markers from sections now implemented
# - Ensure the doc accurately describes what the user can do today
```

```bash
cd $MY_WORKTREE

# Use specific git add — never `git add .` (contribution-hygiene skill)
# Include design doc and customer doc changes in the same commit as the feature
git add <specific files> docs/design/<relevant-doc>.md docs/<relevant-customer-doc>.md
git commit -m "<type>(<scope>): <description>

<body explaining why, not what>

Design doc updated: docs/design/<N>-<area>.md (🔲 → ✅)

🤖 Generated with [Claude Code](https://claude.ai/code)"

git push origin $MY_BRANCH
```

Open PR — the PR body must list which design doc was updated:
```bash
gh pr create --repo $REPO --base main --head $MY_BRANCH \
  --title "<type>(<scope>): <description>" \
  --label "$PR_LABEL" \
  --body "## Summary
...

## Design doc
Updated \`docs/design/<N>-<area>.md\`: moved <item> from 🔲 Future to ✅ Present.

## Customer doc
Updated \`docs/<feature>.md\`: <what changed>."
```

Update state: `state=in_review`, `pr_number=<N>`.

**CRITICAL tier check** — if this PR touches `agents/standalone.md` or `agents/bounded-standalone.md`:
- Add `needs-human` label
- Post `[NEEDS HUMAN: critical-tier-change]` on the PR
- If `AUTONOMOUS_MODE=false`: stop, wait for human
- If `AUTONOMOUS_MODE=true`: proceed to Phase 3 self-review protocol
