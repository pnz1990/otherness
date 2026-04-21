# Spec: M7 full close — _state write integrity check in SM §4a

**Item**: issue-773  
**Branch**: feat/issue-773  
**Date**: 2026-04-21

## Design reference
- **Design doc**: `docs/design/27-security-model.md`
- **Section**: `§ Future`
- **Implements**: M7 full close: state write integrity check (🔲 → ✅)

---

## Zone 1 — Obligations (falsifiable)

**O1 — When `OTHERNESS_USE_APP_TOKEN=true`, SM §4a reads recent `_state` commits and checks authors.**  
Violation: integrity check does not run when App mode is active.

**O2 — Commits not matching the bot/App identity pattern open a deduplicated `[NEEDS HUMAN]` issue.**  
Violation: anomalous author commit does not open a `[NEEDS HUMAN]` issue.

**O3 — When `OTHERNESS_USE_APP_TOKEN != true`, the check is a no-op.**  
Violation: check runs when App mode is not configured.

**O4 — Duplicate issues are suppressed (one open issue per integrity event).**  
Violation: multiple `[NEEDS HUMAN] M7-integrity` issues are opened for the same anomaly.

**O5 — The check is fail-open.**  
Violation: API errors prevent SM §4a from completing.

---

## Zone 2 — Implementer's judgment

- Check frequency: once per 5 SM cycles (same as M3 check).
- Author pattern: `[bot]`, `otherness.*bot`, `github-actions` (case insensitive).
- Bootstrap and cleanup commits are excluded from anomaly detection.
- Number of commits to inspect: last 10.

---

## Zone 3 — Scoped out

- Automated revocation of PAT or App token on detection (requires human action).
- Checking commits to feature branches (only `_state` commits are security-critical).
- Forensic attribution (which human pushed) — that requires GitHub audit log access.
