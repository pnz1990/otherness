# 38: QA CI Gate — Never Merge When CI Is Red

> Status: Active | Created: 2026-04-20
> Applies to: otherness itself and all managed projects

---

## What this does

Before this design doc, QA's merge protocol (`§3e _merge_pr`) never checked whether
CI was actually passing. It checked `mergeStateStatus` only to detect `BEHIND` (branch
needs rebase) — but it had no gate that stopped the merge when checks were failing.

Steps 1–3 of `_merge_pr` escalate through increasing levels of bypass:
- Step 1: normal merge (respects branch protection)
- Step 2: `--admin` (bypasses review requirements)
- Step 3: clears branch protection entirely

**None of these steps checked CI status.** `--admin` and the protection-clear bypass
review requirements and status check requirements together. A PR with a red CI build
would sail through Step 2 or 3 and land on main.

Additionally, `§3a` waited for CI using `gh run list --branch $MY_BRANCH --limit 1`
— which returns the most recent *workflow run* on the branch, not the aggregate status
of all required checks. On projects with multiple CI workflows, this means QA might
see the security-checks workflow succeed, declare CI green, and proceed — while the
actual build/lint/test workflow is still failing.

This design doc specifies the correct CI gate:
1. `§3a` waits for `gh pr checks` to report all checks as passing — not just one run
2. `§3e _merge_pr` verifies CI status *before* every merge attempt, including `--admin`
3. The only legitimate bypass is DCO sign-off failures on projects the agent controls

---

## Present (✅)

- ✅ Design doc created (this file) (2026-04-20)
- ✅ 38.1 — `qa.md §3a`: uses `gh pr checks $PR_NUM` (not `gh run list`) — authoritative aggregate check status for the PR. Waits until no pending checks remain. On failure: reads log, attempts fix, max 3 attempts, then `[NEEDS HUMAN]`.
- ✅ 38.2 — `qa.md §3e _merge_pr`: CI gate fires before Steps 1, 2, and 3 — if any check is in `failure` state, merge is refused and returns 1. `--admin` and branch-protection-clear bypass review requirements only, never CI checks.
- ✅ 38.4 — `qa.md §3a`: DCO failure detection — if check name contains `dco` or `sign.off`, amend commit with `Signed-off-by: otherness[bot]` automatically. Not treated as a blocking CI failure.
- ✅ 38.3 — `qa.md §3a`: CI fix path is now executable — pattern-matching loop replaces the `[AI-STEP]` comment. Handles: gofmt formatting, CRLF line endings, null bytes. Commits and pushes deterministic fixes automatically; posts failure log as PR comment on first unknown-pattern failure; falls back to `[AI-STEP]` judgment comment for project-specific errors. Max 3 attempts before `[NEEDS HUMAN]`. (2026-04-22)

---

## Future (🔲)
- 🔲 38.5 — `qa.md §3a`: distinguish flaky external checks — checks that fail with "infrastructure" errors (runner timeout, network error, external service unavailable) get one automatic retry before being treated as a real failure.
- ✅ 38.6 — SM §4b-qa-rejection: QA rejection pattern tracker — detects unmerged closed feat/* PRs, classifies rejection reason (ci_failure / spec_violation / scope_creep / test_missing / other) from PR title/body, stores rolling 20-entry list in state.json as `qa_rejections`. If same reason ≥3 of last 5: opens `kind/chore priority/high` issue. Fail-open on gh CLI errors. (issue-892, 2026-04-22)

---

## Zone 1 — Obligations

**O1 — CI gate fires before every merge path, including `--admin` and protection-clear.**
The `_merge_pr` function must check `gh pr checks` before Steps 1, 2, and 3. There is
no merge path that bypasses a failing CI check. Branch protection clearing is for review
requirements only — never for status checks.

**O2 — `gh pr checks` is the authoritative source, not `gh run list`.**
`gh pr checks $PR_NUM` returns the aggregate status of all required checks on the PR.
`gh run list --branch $MY_BRANCH` returns only the most recent workflow run. On repos with
multiple workflows, the latter will miss failures. The former is always used.

**O3 — A failing CI check returns to ENG, not to `[NEEDS HUMAN]`.**
CI failures are almost always fixable by the agent. The fix loop (§38.3) attempts up to
3 times before escalating. Escalating to `[NEEDS HUMAN]` for a red CI build is a bug,
not a safety measure.

**O4 — DCO is treated as a mechanical fix, not a CI failure.**
Amending `Signed-off-by: otherness[bot] <otherness[bot]@users.noreply.github.com>` into
the commit is deterministic and always correct for agent-authored commits.

**O5 — The gate applies on the session branch PR too (SM §4g).**
When SM §4g merges the session branch PR, it must also call `gh pr checks` before merging.
The session branch may accumulate commits from both Step A and Step B; all must pass.

---

## Zone 2 — Implementer's judgment

- Wait timeout: 30 minutes for a full CI pass is sufficient for most projects. If CI
  takes longer than 30 min to complete, that is a separate problem (slow CI) not a QA
  gate problem. Post `[NEEDS HUMAN]` after 30 min with "CI still pending after 30 min."
- The `gh pr checks` output format: `gh pr checks $PR_NUM --json name,state,conclusion`
  returns a JSON array. Check: `state == "COMPLETED"` and `conclusion == "SUCCESS"` for
  all entries. Any `conclusion == "FAILURE"` or `conclusion == "TIMED_OUT"` triggers the
  fix loop. `conclusion == "SKIPPED"` and `conclusion == "NEUTRAL"` are passing states.
- The fix loop reads `gh run view --log-failed` on the specific failed workflow run,
  not the entire job log. This keeps context size manageable.

---

## Zone 3 — Scoped out

- Selectively waiving individual CI checks by name (too much per-project configuration)
- Parallel CI retries
- Tracking CI failure history across batches (separate design doc if needed)
