# Spec: D4 Classification at Issue Intake

> Item: 207 | Created: 2026-04-18 | Status: Active

## Design reference
- **Design doc**: `docs/design/01-declarative-design-driven-development.md`
- **Section**: `## Future`
- **Implements**: D4 enforced at issue intake — ENG classifies issue title/body before speccing (🔲 → ✅)

---

## Zone 1 — Obligations

**O1 — ENG classifies the claimed issue before speccing.**
When ENG claims an issue in coord.md §1e (after the branch push succeeds), before
reading or writing any spec, it reads the issue title and body from GitHub and
classifies the instruction as IMPERATIVE, DECLARATIVE, or INFRA.

Behavior that violates this: ENG reads the issue body and immediately starts writing
spec.md without posting a classification.

**O2 — IMPERATIVE issues trigger a D4 translation comment.**
If the issue title/body is classified as IMPERATIVE (contains imperative language:
add, fix, update, change, make, create, remove, implement, enable, enforce, migrate,
bump), the agent posts a `[📋 D4 TRANSLATION]` block on the issue (same format as
session-start D4: Heard / Intent / D4 layer / Artifact).

Behavior that violates this: an imperative issue is specced and implemented without
a translation comment ever appearing on it.

**O3 — A 60-second wait follows the translation comment.**
After posting the translation, the agent waits 60 seconds for human correction before
proceeding.

Behavior that violates this: the agent posts the translation and immediately continues
without pausing.

**O4 — DECLARATIVE and INFRA issues proceed without translation.**
If the issue was created by a previous queue-gen run referencing a design doc 🔲 item,
or if it is a pure maintenance task (classified as INFRA), the agent proceeds directly
to the spec phase without translation.

Behavior that violates this: every single issue — including design-doc-sourced queue
items — triggers a translation comment, creating noise.

**O5 — Classification uses the issue title as primary signal.**
The title is the canonical summary of the issue. If the title is declarative (begins
with "feat(" or "fix(" in conventional-commit format, or references a design doc item),
it is classified DECLARATIVE even if the body contains imperative language in the
"What correct looks like" section.

Behavior that violates this: design-doc-sourced issues with "feat(...): ..." titles
are incorrectly classified as IMPERATIVE and trigger unnecessary translations.

**O6 — The classification logic is an [AI-STEP] in coord.md §1e.**
The classification check is added to coord.md §1e, between the branch-lock success
message and the state write, labeled as `[AI-STEP]`. It replaces or extends the
existing `[AI-STEP]` stub for D4 check in that section.

Behavior that violates this: the check is placed in a different phase file or in a
separate new file.

---

## Zone 2 — Implementer's judgment

- Exact heuristic for IMPERATIVE/DECLARATIVE: title starts with `feat(` or `fix(` or
  `chore(` → DECLARATIVE. Otherwise, presence of imperative verb in title → IMPERATIVE.
  Body content alone does not override a DECLARATIVE title classification.
- Whether to create a new GitHub issue from the translation (as the session-start D4
  does): no — this is issue intake at claim time. The issue already exists. The
  translation is a comment on the existing issue.
- Whether the 60s wait can be shortened for obvious design-doc items: the 60s wait is
  only triggered for IMPERATIVE classifications. DECLARATIVE and INFRA proceed immediately.
- Placement of the [AI-STEP] in coord.md: after `echo "[COORD] ✅ Claimed $ITEM_ID"`,
  before the worktree `git worktree add` call, or after it — whichever is cleaner.
  The check must happen after the branch lock is secured.

---

## Zone 3 — Scoped out

- Retroactively classifying issues already in the queue (only applies to newly claimed items)
- Classifying comments added after the initial claim (that is the existing §1c stub,
  a separate mechanism)
- Refusing to proceed if the translation is not confirmed — the agent always proceeds
  after 60s regardless of human response
- Storing the classification result in state.json (not needed — it is ephemeral per-session context)
