# Spec: Acceptance test for /otherness.onboard output quality

## Design reference
- **Design doc**: `docs/design/32-stage-3-onboarding-quality.md`
- **Section**: `## Future`
- **Implements**: Acceptance test: run `/otherness.onboard` on a fresh repo (not pre-configured), verify `/otherness.run` starts without manual edits (🔲 → ✅)

---

## Zone 1 — Obligations

**O1 — `scripts/check-onboarding.sh <owner/repo>` validates onboarding output.**
The script takes a repo slug and checks that all required `docs/aide/` files exist with
correct structure. Exits 0 if pass, 1 if fail (with specific reason printed).

**O2 — Required files checked: vision.md, roadmap.md, definition-of-done.md.**
For each: must exist, must be non-empty, must have the required section headers.
- `vision.md`: must contain `## What is` or `## Vision`
- `roadmap.md`: must contain at least one `## Stage` section
- `definition-of-done.md`: must contain at least one `## Journey` section

**O3 — AGENTS.md validated for required fields.**
Required fields: `PROJECT_NAME`, `BUILD_COMMAND`, `TEST_COMMAND`, `REPORT_ISSUE`, `PR_LABEL`.
If any are missing or have empty values: report as gap.

**O4 — `otherness-config.yaml` validated for required sections.**
Required sections: `project:`, `schedule:`. Both must be present.

**O5 — Script is non-destructive (read-only).**
The script only reads files. It does not modify any repo.

**O6 — Design doc 32 updated: Future item moved to Present (🔲 → ✅).**
The acceptance test item in docs/design/32-stage-3-onboarding-quality.md must be
updated from `🔲 Future` to `✅ Present` (with stale marker on the existing item removed).

---

## Zone 2 — Implementer's judgment

- Whether to add check-onboarding.sh to test.sh [5c]: yes, but as an informational check
  (non-fatal) since it requires a live repo argument
- Whether to clone the repo or check locally: check locally (no network required for
  structure validation against the current repo)
- Whether to check optional files (progress.md, metrics.md): warn, don't fail

---

## Zone 3 — Scoped out

- Actually running /otherness.onboard on a fresh repo (requires live GitHub + new repo setup)
- Checking the quality of the content (AI-generated prose quality is out of scope)
- Validating /otherness.run actually starts after onboarding (end-to-end test)
