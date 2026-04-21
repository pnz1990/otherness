# Spec: issue-633 — Graceful partial handoff on GitHub Actions job timeout

## Design reference
- **Design doc**: `docs/design/19-scheduled-execution.md`
- **Section**: `§ Future`
- **Implements**: Graceful partial handoff on GitHub Actions job timeout (🔲 → ✅)

---

## Zone 1 — Obligations

**O1 — `timeout-minutes` must be set to 330 (5.5 hours)**
The `otherness` job in `.github/workflows/otherness-scheduled.yml` must have
`timeout-minutes: 330`. This gives the agent 5.5 hours of work time before
GitHub's hard 6-hour runner limit forces termination, allowing the cleanup step
to run. Previously `timeout-minutes: 120` was used; that was a conservative
ceiling that is no longer appropriate given the loop's throughput requirements.

**O2 — A cleanup step must run unconditionally (`if: always()`)**
After the main "Run otherness" step, a new step named
"Graceful timeout cleanup" must exist with `if: always()`. This step executes
regardless of whether the preceding steps succeeded, failed, or were cancelled.

**O3 — The cleanup step must read `_state`, find in-progress items, and reset them**
The cleanup step must:
- Fetch `origin/_state:.otherness/state.json`
- Find all items with `state: in_progress` or `state: assigned`
- For each such item, reset `state` → `todo`, clear `assigned_to`, `assigned_at`,
  `branch`, `worktree`
- Push the updated state to `origin/_state` (field-level merge, not force push)

**O4 — The cleanup step must post a warning comment on the report issue**
The cleanup step must check whether any items were actually reset; if yes, it
posts on the report issue comment: `"⚠️ Session timed out. In-flight item reset to
queue. Next session will reattempt."`. If no items were in-flight, the step is
silent (no comment).

**O5 — The cleanup step must be non-blocking**
If the cleanup step itself fails (e.g. state push conflict, API error), the
workflow must still succeed. The cleanup step uses `continue-on-error: true` OR
internal `|| true` guards on all shell commands. A cleanup failure must not
mask the upstream agent result.

**O6 — The cleanup step uses the effective token (App or PAT)**
The cleanup step must use `${{ steps.app-token.outputs.token || secrets.GH_TOKEN }}`
as its `GH_TOKEN` environment variable — the same pattern used by all other steps
in the workflow.

---

## Zone 2 — Implementer's judgment

- Where to position the cleanup step: immediately after the "Run otherness" step
  (Step 8). It must run after the main agent step to catch items that were in-flight
  when the agent was killed.
- Whether to also delete the abandoned feature branch: optional. The stale watchdog
  already handles branch cleanup. The cleanup step only needs to reset state.json.
- Python vs bash for state manipulation: Python is preferred (matches existing
  state-write patterns in standalone.md). Bash `|| true` is acceptable as guard.
- The comment text is fixed by O4. The step may omit the comment when no items were
  reset (avoids noise in the clean-exit case).

---

## Zone 3 — Scoped out

- Workflow file changes on managed projects (kardinal-promoter, etc.) — each project
  owns its own workflow. This PR changes only the otherness repo workflow.
- Changing the cron cadence
- Adding SIGTERM signal handling inside the agent itself
- Recovery of partial git state (abandoned commits, partial file writes)
