# Spec: [AI-STEP] elimination in qa.md (issue-958)

## Design reference
- **Design doc**: `docs/design/45-distil-and-simplify.md`
- **Section**: `§ Future 45.6`
- **Implements**: [AI-STEP] elimination in qa.md (🔲 → ✅)

## Zone 1 — Obligations

**O1**: Zero `[AI-STEP]` stubs remain in `agents/phases/qa.md` after this PR.
Violation: `grep -c '\[AI-STEP\]' agents/phases/qa.md` returns non-zero.

**O2**: §3b spec conformance check is fully executable without AI judgment.
Violation: if `$SPEC_FILE` exists, QA reads the Zone 1 obligations and verifies them
against the diff using grep/diff commands — not descriptive comments.

**O3**: §3b design reference check is executable: verifies `## Design reference` section
exists in spec.md, and if a design doc is named, checks the PR diff updates it.
Violation: design reference check relies on AI narrative instead of shell commands.

**O4**: §3b verification gate check (§41.4) is executable: checks whether the PR diff
contains `🔲 → ✅` or `🔲` removed, and whether spec.md or PR description contains
a verification phrase.
Violation: verification check is a comment stub, not an executable expression.

**O5**: §3a CI fix loop — all 4 named failure patterns (hardcoded path, missing file,
unknown pattern, self-update missing) have executable fix attempts, even if imperfect.
Violation: `_FIX_APPLIED=false` with a comment stub and no executable action.

## Zone 2 — Implementer's judgment

- The spec conformance check reads `spec.md` via `grep` and `awk` for Zone 1 obligations.
  The exact grep patterns are up to the implementer.
- The verification gate check uses simple substring matching — does not need to be perfect.
- For unknown CI patterns (stub at line 183): acceptable to post a PR comment with the
  failure log and set `_FIX_APPLIED=false` (already done) — but the `sleep 30; continue`
  without comment is the stub. Replace with a comment + explicit continue.

## Zone 3 — Scoped out

- Do not improve CI fix patterns beyond the 6 already listed (Pattern 1-6).
- Do not change the structure or flow of §3a, §3b, §3c, §3d, §3e.
- Do not add new QA checks beyond eliminating the stubs.
- Do not change qa.md header or mode block.
