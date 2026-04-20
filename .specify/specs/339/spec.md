# Spec: feat(ci): token expiry preflight — validate GH_TOKEN scopes before push

## Design reference
- **Design doc**: `docs/design/19-scheduled-execution.md`
- **Section**: `§ Future`
- **Implements**: Token expiry detection: if `GH_TOKEN` PAT expires, the workflow fails silently on push; add a preflight step that validates the token has required scopes and posts a `[NEEDS HUMAN]` issue on failure (🔲 → ✅)

---

## Zone 1 — Obligations (falsifiable)

**O1 — A preflight step must exist before any agent work steps.**
A step named "Validate GH_TOKEN" (or equivalent) must appear in `otherness-scheduled.yml`
before the "Run otherness" step. Violation: no validation step, or validation step
appears after "Run otherness".

**O2 — The preflight step must detect an expired/invalid token.**
If `GH_TOKEN` is empty, invalid, or expired, the preflight step must exit with a
non-zero exit code, causing the job to fail. The step uses `gh auth status` or
`gh api user` to verify token validity. Violation: step exits 0 on an invalid token.

**O3 — On failure, a `[NEEDS HUMAN]` issue must be posted.**
If the token check fails, a GitHub issue is created with title containing
`[NEEDS HUMAN]` and body explaining the PAT has expired. The issue must be created
using `GITHUB_TOKEN` (the built-in Actions token, always valid) as a fallback,
NOT `GH_TOKEN` (which is the failing credential). Violation: failure exits without
creating an issue.

**O4 — On success, subsequent steps continue normally.**
If token validation passes, the step exits 0 and the job continues to the next step.
Violation: validation step exits non-zero when token is valid.

**O5 — The step must handle the case where `GH_TOKEN` secret is not configured.**
If `GH_TOKEN` is empty or not set, the step detects this as a misconfiguration and
posts a `[NEEDS HUMAN]` issue identifying that the secret is missing. Violation: empty
`GH_TOKEN` causes an opaque failure instead of a clear error message.

---

## Zone 2 — Implementer's judgment

- Whether to use `gh auth status` vs `gh api user` for validation: both work; prefer
  `gh api user` as it directly tests API access and is less verbose.
- Issue label: `needs-human` if it exists on the repo, otherwise unlabeled (gh issue
  create fails if label doesn't exist).
- Whether to check specific scopes (repo, workflow) or just token validity: checking
  validity is sufficient; scope checking via API is complex and fragile.
- The preflight step runs before `Configure AWS credentials` — token failure should
  abort before any AWS setup to keep the failure message clear.

---

## Zone 3 — Scoped out

- Automatic PAT rotation (out of scope per design doc Zone 3)
- Validating AWS credentials separately (already handled by configure-aws-credentials step)
- Checking token expiry date proactively (only check validity, not remaining TTL)
- Sending notifications via Slack, email, or other channels
