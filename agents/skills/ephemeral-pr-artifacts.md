# Skill: Ephemeral PR Artifacts

<!-- provenance: All-Hands-AI/OpenHands, AGENTS.md, 2026-04-14 -->
<!-- otherness-learn: .pr/ ephemeral directory for reviewer context; auto-cleanup on merge; specific git staging -->

Load this skill when implementing a complex feature that would benefit from reviewer context
beyond the PR description, or when writing git staging commands.

---

## The `.pr/` Directory: Reviewer Context That Cleans Itself Up <!-- provenance: All-Hands-AI/OpenHands, AGENTS.md, 2026-04-14 -->

OpenHands uses a `.pr/` directory at the repo root for PR-specific artifacts:

```
.pr/
├── design.md       # Design decisions, why this approach was chosen
├── analysis.md     # Investigation notes
└── notes.md        # Context that helps reviewers but isn't needed post-merge
```

Key properties:
- `.pr/` is **not** merged to main — a workflow auto-removes it when the PR is approved
- When `.pr/` exists, a bot posts a notification to the PR alerting reviewers it's there
- Content goes in `.pr/`, not as a `PLAN.md` in the repo root (which would persist)

**The otherness implication:** For complex CRITICAL tier PRs where the change is subtle, add a `.pr/design.md` explaining the reasoning. The human reviewer sees it in the PR, it disappears on merge. This is better than a long PR description because:
- It can include diagrams, decision trees, rejected alternatives
- It's file-searchable, not buried in PR comments
- It auto-cleans — doesn't pollute the repo

**Concrete use case in otherness:** Any CRITICAL tier PR that touches the state write block, the coordinator phase, or the parallel session protocol should include a `.pr/design.md` with:
1. What invariant this change preserves
2. The failure mode it fixes or prevents
3. Why the chosen approach is safer than the alternative considered

**Implementation:** Add to the PR commit, then note in the PR body that a `.pr/design.md` exists. The reviewer can read it as a file. Since otherness doesn't have the auto-cleanup workflow, manually delete `.pr/` before merging or add a note to the PR checklist.

---

## Specific Git Staging: `git add <file>` Not `git add .` <!-- provenance: All-Hands-AI/OpenHands, AGENTS.md, 2026-04-14 -->

OpenHands: "Prefer specific `git add <filename>` instead of `git add .` to avoid accidentally staging unintended files."

This is particularly important for autonomous agents because:
- The agent may have created temporary files during investigation that shouldn't be committed
- State files (`.otherness/state.json`) may have been modified as a side effect of reading them
- Debug output or scratch files from tool use may exist in the working directory

**The otherness implication:** Every `git add` in standalone.md should be specific. Audit:

```bash
# Wrong — stages everything including accidental files
git add .
git add .otherness/

# Right — stages only the intended files
git add agents/standalone.md
git add agents/skills/new-skill.md
git add docs/aide/metrics.md
```

**The one exception**: The state write block uses a temp worktree that contains only `.otherness/state.json` — `git add .otherness/state.json` there is fine since the worktree was created clean.

**Concrete check before any commit:** List what `git status` shows and verify every staged file is intentional. If unexpected files appear: `git restore --staged <file>` before committing.

---

## Trigger-Based Skill Loading <!-- provenance: All-Hands-AI/OpenHands, AGENTS.md, 2026-04-14 -->

OpenHands microagents load only when the user's message matches trigger keywords:

```yaml
---
triggers:
- PR review
- code review
- review this
---
# QA Checklist
...specialized review content...
```

Without triggers: always loaded (baseline context). With triggers: loaded on-demand.

**The otherness implication:** Loading all 7+ skill files at the start of every phase adds context that may not be relevant. A QA reviewing a docs-only PR doesn't need `declaring-designs.md` or `agent-coding-discipline.md`. An engineer implementing a learn session doesn't need `reconciling-implementations.md`.

**Current otherness pattern:** "Load skill: read `~/.otherness/agents/skills/<name>.md`" — explicit, manual, always the full file.

**Improvement direction:** Add a trigger comment to each skill file header indicating when to load it. The agent reads the header (first 3 lines) of each skill file at phase start, and only reads the full file if the current task matches the trigger:

```markdown
# Skill: Reconciling Implementations
<!-- triggers: PR review, QA, adversarial review, merge decision -->
<!-- load: always during Phase 3 (QA); on-demand in other phases -->
```

This reduces context consumption without losing coverage. The full skill is still available — it just isn't loaded unless relevant.

**Note**: This is an improvement direction, not a current requirement. The existing explicit load pattern is correct. This optimization matters when the skills library grows to 15+ files.
