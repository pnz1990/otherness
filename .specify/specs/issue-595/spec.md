# spec: M3 — Replace GH_TOKEN PAT with GitHub App

## Design reference
- **Design doc**: `docs/design/27-security-model.md`
- **Section**: `§ Mitigations → M3 — Replace PAT with GitHub App`
- **Implements**: M3: Replace GH_TOKEN PAT with GitHub App — per-repo scoped, non-exportable, auditable (🔲 → ✅)

---

## Zone 1 — Obligations (falsifiable)

**O1 — Backward compatibility**: When `APP_ID` secret is NOT configured, the workflow MUST
fall back to using `GH_TOKEN` PAT exactly as before. No existing project breaks.
_Violation: any project without APP_ID fails to authenticate after this change._

**O2 — App token when available**: When `APP_ID` AND `APP_PRIVATE_KEY` secrets ARE
configured, the workflow MUST obtain a short-lived installation token via
`actions/create-github-app-token` and use it instead of the PAT for all `gh` and `git`
operations.
_Violation: workflow uses PAT even when APP_ID is set._

**O3 — SHA pinning**: The `actions/create-github-app-token` action MUST be SHA-pinned
(per M1, docs/design/27-security-model.md). No `@latest` or floating tags.
_Violation: workflow uses `@vN` or `@latest` for create-github-app-token._

**O4 — Preflight validates App token**: When App mode is active, the token preflight
step MUST validate the App token instead of (or in addition to) the PAT.
_Violation: preflight passes with an invalid App token._

**O5 — Onboarding docs updated**: `onboarding-new-project.md` MUST include a step
for GitHub App setup as an alternative to PAT, with instructions to create the App,
install it on the repo, and add APP_ID + APP_PRIVATE_KEY secrets.
_Violation: onboarding docs still only describe PAT setup._

**O6 — Config template updated**: `otherness-config-template.yaml` MUST include
commented-out fields for `auth.app_id` and `auth.app_private_key_secret` to document
the App auth option.
_Violation: template has no mention of GitHub App configuration._

**O7 — Design doc updated**: `docs/design/27-security-model.md` M3 entry MUST be
moved from `🔲 Future` to `✅ Present` with PR reference.
_Violation: design doc still shows M3 as 🔲._

---

## Zone 2 — Implementer's judgment

- Whether to use `actions/create-github-app-token` v2 or v3: use v3.1.1 (latest stable,
  SHA-pinned to `1b10c78c7865c340bc4f6099eb2f838309f1e8c3`).
- Whether to require both APP_ID and APP_PRIVATE_KEY or just APP_ID: require both.
  If only one is set, fall back to PAT and log a warning — don't fail.
- Whether to update managed project workflows (kardinal-promoter, kro-ui): No. That
  requires separate PRs on those repos. This PR documents the pattern; projects adopt
  it on their own schedule.
- Token scope: `actions/create-github-app-token` uses the repos configured at App
  installation time. No additional scope configuration needed in the workflow.

---

## Zone 3 — Scoped out

- Creating the GitHub App itself (requires human action in GitHub UI — documented in
  onboarding but not automated)
- Updating managed project workflows (kardinal-promoter, kro-ui) — separate PRs
- Implementing App token for the `git push` step specifically (the `checkout` action
  handles this via `token:` parameter)
- Rotating the PAT as part of this PR — separate operational task
