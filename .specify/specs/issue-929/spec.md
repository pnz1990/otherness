# Spec: Workflow disabled detection in PM §5j

## Design reference
- **Design doc**: `docs/design/19-scheduled-execution.md`
- **Section**: `§ Future`
- **Implements**: Workflow disabled detection from within the loop (🔲 → ✅)

---

## Zone 1 — Obligations (falsifiable)

**O1** — When PM §5j detects `_state` age > 2× the configured cron interval,
it must attempt `gh workflow list --repo $REF_PROJECT --json name,state` to
check whether the `otherness scheduled run` workflow is disabled.

_Violation_: §5j opens a stale issue without ever calling `gh workflow list`.

**O2** — If the workflow is found to have `state == "disabled_manually"` or
`state == "disabled_inactivity"`, PM §5j must open a `[NEEDS HUMAN: workflow-disabled]`
issue with title: `[NEEDS HUMAN] Scheduled workflow disabled on $REF_PROJECT — re-enable to restart loop`.
The issue body must include the GitHub URL to the Actions settings page for that workflow.

_Violation_: Issue is not opened when workflow is disabled, or issue is opened for
transient failures where workflow is still `active`.

**O3** — The workflow-disabled detection must NOT duplicate: if an open issue with
title containing `workflow-disabled` and the ref project name already exists on the
otherness repo, do not open another.

_Violation_: Multiple identical `[NEEDS HUMAN: workflow-disabled]` issues pile up
across consecutive sessions.

**O4** — If `gh workflow list` fails (no permission, unknown project, API error):
PM §5j must fall back silently to the existing generic stale warning behavior. It
must not raise a new error or prevent the rest of PM from running.

_Violation_: PM crashes or posts an error when `gh workflow list` returns non-zero.

**O5** — If the workflow is `active` (not disabled) but `_state` is still stale:
PM §5j continues with existing generic stale handling (Journey 2 stall issue).
The two conditions (disabled vs stale-active) are reported separately.

_Violation_: A stale+active workflow incorrectly triggers the workflow-disabled issue.

**O6** — The cron interval for comparison must be read from `otherness-config.yaml`
`schedule.cron` on the _managed project_, not on the otherness repo itself.
If unavailable: default to 6 hours (the otherness self-improvement cadence).

_Violation_: Detection fires too early or too late because it uses the wrong project's cron.

---

## Zone 2 — Implementer's judgment

- The workflow name to look for is `"otherness scheduled run"` (exact match preferred,
  case-insensitive fallback acceptable).
- Whether to check all workflows or just the named one is implementer's choice; checking
  only the named one is preferred to avoid false positives from unrelated disabled workflows.
- The GitHub URL in the issue body may be constructed as:
  `https://github.com/<owner>/<repo>/actions/workflows/otherness-scheduled.yml`
  (best-effort; exact filename may differ per project).
- Disabling detection can use Python or bash as the implementer sees fit.

---

## Zone 3 — Scoped out

- Re-enabling the workflow automatically (requires workflow write permissions not currently granted)
- Detecting workflows disabled by branch protection rules (separate issue)
- Detecting cron-skip by GitHub's own 60-day inactivity policy (separate edge case)
- Cross-project monitoring of all managed projects' workflows (this spec covers the single reference project check only)
