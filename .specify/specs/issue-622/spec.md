# Spec: agents/onboard.md post-run validation

## Design reference
- **Design doc**: `docs/design/35-quality-of-output-gaps.md`
- **Section**: `§ Future`
- **Implements**: `agents/onboard.md` post-run validation: structural self-check after generating docs/aide/ (🔲 → ✅)

---

## Zone 1 — Obligations (falsifiable)

**O1 — Post-run validation runs inline before STEP 8 PR creation.**
After generating all `docs/aide/` files (STEPs 1-6), onboard.md must run a
structural self-check equivalent to `scripts/check-onboarding.sh` inline.
The check runs on the working directory (not a subprocess call to the shell script).
Violation: check absent from onboard.md; check deferred to after PR creation.

**O2 — If gaps are found, the agent fixes them before opening the PR.**
For each error found (missing section, empty file, placeholder text, no stages,
no journeys): the agent must fix the gap in the working files, not just report it.
Only when all checks pass does the agent proceed to STEP 8.
Violation: agent opens PR with known errors and asks human to fix them.

**O3 — The inline check mirrors the 4 criteria of check-onboarding.sh.**
The check must verify: (1) required docs/aide/ files exist and are non-empty,
(2) content structure (vision section, ≥1 Stage, ≥1 Journey), (3) AGENTS.md
required fields, (4) otherness-config.yaml required sections.
Violation: check omits any of the 4 check-onboarding.sh criteria.

**O4 — Unfixable gaps post a warning and do not block PR creation.**
If a gap cannot be auto-fixed (e.g. vision.md is semantically empty but
structurally present), the agent posts a [⚠️ ONBOARD REVIEW NEEDED] note in the
PR body for the human. The PR is created regardless.
Violation: onboarding exits without PR when unfixable gaps exist.

---

## Zone 2 — Implementer's judgment

- Inline check uses bash with the same logic as check-onboarding.sh (not a subprocess call)
- "Placeholder text" detection: lines containing TBD, PLACEHOLDER, YOUR_PROJECT_NAME,
  or empty h2 sections with no body
- Fix mechanism: if vision.md has no vision section header, add `## Vision\n\n`
  before the first line. If roadmap has no Stage, add `## Stage 1 — Initial\n\n- TBD`.
  These are minimal fixes to make structure checks pass; the human reviews content.
- The post-run check is a new section STEP 7b between STEP 7 and STEP 8.

---

## Zone 3 — Scoped out

- Deep semantic validation of content quality (separate concern)
- Validation of otherness-config.yaml field values beyond section presence
- Running the actual shell check-onboarding.sh script (inline is sufficient)
