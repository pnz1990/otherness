# Spec: onboarding-*.md first-run smoke test section

## Design reference
- **Design doc**: `docs/design/35-quality-of-output-gaps.md`
- **Section**: `§ Future`
- **Implements**: onboarding-existing-project.md + onboarding-new-project.md: "first-run smoke test" section (🔲 → ✅)

---

## Zone 1 — Obligations (falsifiable)

**O1 — Both onboarding docs have a "First-run smoke test" section.**
Both `onboarding-existing-project.md` and `onboarding-new-project.md` must have a
new section titled `## First-run smoke test` that describes what a healthy first run
looks like and what to check if it fails.
Violation: section absent from either doc.

**O2 — The section describes 3 observable success signals.**
The section must list: (1) queue generated (COORD opens issues), (2) first item
claimed (feat/* branch appears on remote), (3) PR opened (gh pr list shows open PR).
Violation: section present but omits any of the 3 signals.

**O3 — The section describes how to diagnose a silent failure.**
If 20 minutes pass with no open PR and no [NEEDS HUMAN] issue, the human must know
what to check: report issue (#2 or equivalent), _state branch activity, CI status.
Violation: section does not describe what to do when first run produces nothing visible.

**O4 — The section is actionable — includes the exact commands to check.**
At minimum: check report issue for startup comment, check `_state` branch for activity,
check GitHub Actions for run status. These are exact `gh` commands, not prose.
Violation: section describes symptoms only without commands.

---

## Zone 2 — Implementer's judgment

- Placement: add at the end of both docs, after the "run /otherness.run" step.
- The section focuses on human-observable signals (GitHub issue, PR, branch) — not
  terminal output (the human cannot see terminal output of a GitHub Actions run
  without clicking into it).
- Self-validating run: note that `session_heartbeats` in `_state:.otherness/state.json`
  shows recent session activity. `gh api repos/$REPO/branches/_state --jq '.commit.commit.committer.date'`
  gives last commit time.

---

## Zone 3 — Scoped out

- Automated CI step that verifies first-run health
- Modifying the agent loop to post a "first-run complete" summary
- Detailed failure taxonomy beyond the 3 main signals
