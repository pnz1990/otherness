# Spec: SM §4a — M3 App adoption tracking for managed projects

**Item**: issue-716
**Design doc**: `docs/design/27-security-model.md`
**Section**: `§ Future` (🔲 → ✅)

## Design reference

- **Design doc**: `docs/design/27-security-model.md`
- **Section**: `§ Future`
- **Implements**: "M3 App adoption: explicitly track which managed projects have the GitHub App configured vs using PAT fallback" (🔲 → ✅)

---

## Zone 1 — Obligations (falsifiable)

**O1**: SM §4a includes a new block that iterates over `monitor.projects` from `otherness-config.yaml` and checks whether each project's `otherness-scheduled.yml` workflow contains a condition referencing `OTHERNESS_USE_APP_TOKEN`. The check reads the workflow file via `gh api repos/<project>/contents/.github/workflows/otherness-scheduled.yml` and searches the decoded content for the string `OTHERNESS_USE_APP_TOKEN`.

**O2**: For each managed project where `OTHERNESS_USE_APP_TOKEN` is NOT found in the workflow file (indicating PAT-only mode), SM §4a appends a `[SECURITY-AMBER]` comment to `REPORT_ISSUE` with the message: `Project <project> appears to be using PAT fallback (no OTHERNESS_USE_APP_TOKEN in workflow) — cross-repo blast radius risk. See docs/design/27-security-model.md §M3.`

**O3**: The check is fail-open and fully deduplicated: if the `gh api` call fails (rate-limit, permission error, private repo), the project is skipped silently — no AMBER comment is posted. If a `[SECURITY-AMBER]` comment for the same project has been posted in the last 7 days (checked via REPORT_ISSUE comments), the duplicate is suppressed.

**O4**: The check only runs once per 5 SM cycles (not every cycle) to avoid noisy repeated posts. The cycle counter uses the existing `SM_CYCLE` variable.

**O5**: The implementation is entirely within `agents/phases/sm.md` §4a bash block. No other executable file is modified except `docs/design/27-security-model.md` (design doc update: 🔲 → ✅).

**O6**: The log line `[SM §4a] M3 app adoption check: <project> mode=app|pat|unknown` appears for each project checked.

---

## Zone 2 — Implementer's judgment

- Where in §4a to insert: after the existing stale spec check, before the changelog update.
- The workflow content is base64-encoded in the GitHub API response — decode with `base64.b64decode` and search the string.
- "unknown" mode when the API call fails — log it but don't post AMBER.
- Deduplication: check if a comment containing `[SECURITY-AMBER]` and the project name was posted on REPORT_ISSUE recently (gh issue comment list, limit 20, search for the pattern).

---

## Zone 3 — Scoped out

- Checking App installation status (requires GitHub App API — not available in all envs).
- Checking whether APP_ID and APP_PRIVATE_KEY secrets are set (secrets API returns 403).
- Modifying the managed projects themselves.
- Checking otherness.run via vars API (returns 403 for most tokens).
