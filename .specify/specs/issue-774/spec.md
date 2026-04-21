# Spec: Frame-lock break protocol as a scheduled mechanism

## Design reference
- **Design doc**: `docs/design/31-stage-2-skills-expansion.md`
- **Section**: `§ Future`
- **Implements**: Frame-lock break protocol as a scheduled mechanism, not a human-triggered event (🔲 → ✅)

---

## Zone 1 — Obligations (falsifiable)

**O1 — SM §4c-framelock auto-triggers a learn session when 3 conditions are all met.**
When ALL of these are true simultaneously:
(a) arch_convergence > 0.7 (frame-lock confirmed)
(b) last autonomous learn session (PROVENANCE.md last entry) is >14 days ago
(c) the frame-lock [NEEDS HUMAN] issue has been open for >48 hours without a human comment
Then SM §4c must automatically trigger a learn session (same mechanism as §4d-learn:
push a `feat/learn-*` branch, create worktree, run learn.md with paradigm_diversity_required=true).
Violation: all 3 conditions met but no learn session triggered.

**O2 — The human notification issue remains open — it is not closed or resolved.**
Auto-triggering learn does not close the [NEEDS HUMAN] issue. It posts a comment explaining
that the system is self-healing, and the human should review when convenient.
Violation: [NEEDS HUMAN] issue is closed automatically.

**O3 — Auto-trigger only fires once per frame-lock event.**
A flag `frame_lock_auto_triggered` must be set in state.json when auto-trigger fires.
The flag is cleared when arch_convergence drops below the reset threshold (0.55).
Subsequent SM cycles in the same frame-lock event do not re-trigger.
Violation: auto-trigger fires multiple times for the same frame-lock condition.

**O4 — Fail-open: if any pre-condition check fails, log and skip.**
If PROVENANCE.md is unreadable, if the [NEEDS HUMAN] issue API call fails, or if the
learn branch push fails: SM must log the failure and proceed without blocking work.
Violation: frame-lock check causes SM to crash or block claiming.

---

## Zone 2 — Implementer's judgment

- How to check "no human comment in 48h": read issue comments from gh API, check if any
  non-bot commenter commented within the last 48h on the frame-lock issue.
- Definition of "autonomous learn session": PROVENANCE.md was updated (has an entry dated
  within the last 14 days). Not whether a feat/learn-* branch exists.
- Where to add the trigger: after the existing Step 8 (issue creation) in §4c-framelock,
  in a new Step 9.
- `paradigm_diversity_required: true` flag: embed in the learn branch commit message or
  a file in the worktree so the learn agent can read it.

---

## Zone 3 — Scoped out

- Actually running the full learn session end-to-end (that is learn.md's job)
- Closing the [NEEDS HUMAN] issue automatically
- Triggering when arch_convergence is only AMBER (0.65-0.7) — only fires when > 0.7
