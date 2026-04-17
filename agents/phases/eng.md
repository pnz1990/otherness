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

## 2b. SPEC-FIRST: generate spec + plan + tasks using speckit (if available)

Load skill: `~/.otherness/agents/skills/declaring-designs.md` before writing the spec.

**Concept consistency check before speccing:**
1. Does an existing abstraction already cover this? Extend, don't add.
2. What existing patterns in the codebase should this follow?
3. Does AGENTS.md §Anti-Patterns apply?
4. Does the API/interface naming match existing user-facing docs?
5. Check `decisions.md` — has this pattern been decided before?

**If speckit is installed (`specify --version 2>/dev/null`)**: use it for structured artifacts.

```bash
if specify --version &>/dev/null; then
  # Use speckit for spec, plan, and tasks — structured artifacts, better quality

  # Point speckit to THIS item's spec directory in the worktree (parallel-safe)
  export SPECIFY_FEATURE_DIRECTORY="$MY_WORKTREE/.specify/specs/$ITEM_ID"
  mkdir -p "$SPECIFY_FEATURE_DIRECTORY"

  # Read the issue to build the feature description
  ISSUE_NUM=$(echo $ITEM_ID | grep -oE '[0-9]+' | head -1)
  ISSUE_BODY=$(gh issue view $ISSUE_NUM --repo $REPO --json title,body \
    --jq '"Title: " + .title + "\n\nBody: " + .body' 2>/dev/null)

  echo "[ENG] Generating spec via /speckit.specify..."
  # [AI-STEP] Run /speckit.specify with the issue title + body as the feature description.
  # This creates spec.md in $SPECIFY_FEATURE_DIRECTORY using the spec-template.
  # SPECIFY_FEATURE_DIRECTORY is set — speckit will use it instead of .specify/feature.json.

  echo "[ENG] Generating plan via /speckit.plan..."
  # [AI-STEP] Run /speckit.plan to generate research.md, data-model.md, contracts/, plan.md.
  # This runs in $MY_WORKTREE with SPECIFY_FEATURE_DIRECTORY set.

  echo "[ENG] Generating tasks via /speckit.tasks..."
  # [AI-STEP] Run /speckit.tasks to generate dependency-ordered tasks.md with [P] markers.
  # This reads the spec and plan from $SPECIFY_FEATURE_DIRECTORY.

else
  # Fallback: manual spec (no speckit) — still follow the three-zone structure
  mkdir -p "$MY_WORKTREE/.specify/specs/$ITEM_ID"

  echo "[ENG] Writing spec manually (speckit not installed)..."
  # [AI-STEP] Write .specify/specs/$ITEM_ID/spec.md using the three-zone structure:
  # Zone 1 — Obligations (falsifiable, must satisfy)
  # Zone 2 — Implementer's judgment (choices left to engineer)
  # Zone 3 — Scoped out (explicitly not covered)
  # Each obligation must be falsifiable — describe behavior that would violate it.

  # [AI-STEP] Write .specify/specs/$ITEM_ID/tasks.md — actionable, file-path-specific,
  # dependency-ordered, with [P] markers for tasks safe to parallelize.
fi
```

**Spec quality gate** (from declaring-designs skill) — do not proceed to code until:
- [ ] Three-zone structure present (Obligations / Judgment / Scoped out)
- [ ] Every obligation is falsifiable
- [ ] Concrete artifacts (interfaces, schemas, examples) carry the spec — not prose
- [ ] Spec stands alone without referencing the current implementation
- [ ] No obligation contradicts `decisions.md` or `constitution.md`

---

## 2c. DOC-FIRST + ARCHITECTURE check

```bash
# If this item touches user-facing behavior: verify/create user-facing doc page first
# Re-read any architecture constraint docs listed in AGENTS.md
# Re-read AGENTS.md §Anti-Patterns
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

## 2f. Commit and push

Load skill: `~/.otherness/agents/skills/contribution-hygiene.md` before committing.
Load skill: `~/.otherness/agents/skills/ephemeral-pr-artifacts.md` before opening the PR.

```bash
cd $MY_WORKTREE

# Use specific git add — never `git add .` (contribution-hygiene skill)
git add <specific files>
git commit -m "<type>(<scope>): <description>

<body explaining why, not what>

🤖 Generated with [Claude Code](https://claude.ai/code)"

git push origin $MY_BRANCH
```

Open PR:
```bash
gh pr create --repo $REPO --base main --head $MY_BRANCH \
  --title "<type>(<scope>): <description>" \
  --label "$PR_LABEL" \
  --body "..."
```

Update state: `state=in_review`, `pr_number=<N>`.

**CRITICAL tier check** — if this PR touches `agents/standalone.md` or `agents/bounded-standalone.md`:
- Add `needs-human` label
- Post `[NEEDS HUMAN: critical-tier-change]` on the PR
- If `AUTONOMOUS_MODE=false`: stop, wait for human
- If `AUTONOMOUS_MODE=true`: proceed to Phase 3 self-review protocol
