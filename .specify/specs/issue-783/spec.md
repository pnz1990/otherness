# Spec: SM §4f health signal must include managed project velocity in the GREEN definition

**Item**: issue-783  
**Branch**: feat/issue-783  
**Date**: 2026-04-21

## Design reference
- **Design doc**: `docs/design/16-journey-2-reference-project.md`
- **Section**: `§ Future`
- **Implements**: SM §4f health signal must include managed project velocity in the GREEN definition (🔲 → ✅)

---

## Zone 1 — Obligations (falsifiable)

**O1 — When GREEN self but managed project has 0 feat/fix/refactor PRs in the last 14 days, SM §4f must set HEALTH=AMBER.**  
Violation: SM §4f outputs GREEN when the reference project has shipped no feature PRs in 14 days.

**O2 — The health comment in SM §4f must include a "Managed:" line showing reference project velocity.**  
Format: `Managed: N feat PRs/7d (reference: <repo>)`  
Violation: the SDM health comment does not include a managed project velocity metric.

**O3 — When no reference project is configured in `otherness-config.yaml` `monitor.projects`, the check must be a no-op (fail-open).**  
Violation: SM §4f errors or blocks when there is no reference project entry.

**O4 — The managed velocity check uses `kind/enhancement` or `feat/*`/`fix/*`/`refactor/*` PRs merged in the last 14 days on the reference project.**  
Violation: the count uses a different time window or different PR filter.

**O5 — API errors in the managed velocity check are non-fatal (fail-open).**  
Violation: a GitHub API error on the reference project prevents SM §4f from completing.

---

## Zone 2 — Implementer's judgment

- 14-day window chosen over 7-day to reduce false AMBER signals on slow-moving managed projects.
- Whether to include the managed summary in the THROUGHPUT_WARN variable or as a separate variable.
- The exact text of the AMBER reason string.
- Whether to persist `managed_feat_prs_14d` in state.json (not required by this spec — that's PM's job).

---

## Zone 3 — Scoped out

- Persisting managed velocity to state.json or metrics.md (that is PM §5n's responsibility).
- Opening a velocity-stall issue (that is PM §5j's responsibility — already implemented).
- Multi-project velocity (only the reference/first non-otherness project is checked here).
- RED escalation for managed project stall (that happens at PM §5, not SM §4f).
