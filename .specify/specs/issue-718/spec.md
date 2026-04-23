# spec: onboarding-existing-project.md first-run smoke test section (issue-718)

## Design reference

- **Design doc**: `docs/design/32-stage-3-onboarding-quality.md`
- **Section**: `§ Future`
- **Issue**: https://github.com/pnz1990/otherness/issues/718
- **Status**: in_progress

---

## Zone 1 — Obligations

**O1** The "Is the loop still working?" section must include a one-shot script that runs all three checks and prints GREEN / AMBER / RED in under 2 minutes.

**O2** The three checks are: (1) `_state` branch updated in last 24h, (2) ≥1 PR opened or merged in last 7 days, (3) no `[NEEDS HUMAN]` issues older than 48h.

**O3** Each FAIL must include a one-line actionable description of what failed.

**O4** The existing three individual checks must remain as a "step-by-step" alternative.

**O5** The one-command alternative reference to `/otherness.status` must remain.

---

## Zone 2 — Implementer's judgment

- Python3 stdlib only (no external deps) — consistent with the rest of the guides.
- Output format: `==== otherness health: GREEN ====` with ✅/⚠️/❌ per check.
- Fail-open: if a check cannot run (gh not configured, network error), it shows WARN not FAIL.

---

## Acceptance criteria

- [ ] `onboarding-existing-project.md` has one-shot combined health check script
- [ ] Script outputs GREEN / AMBER / RED overall health
- [ ] `bash scripts/validate.sh` passes
- [ ] `bash scripts/lint.sh` passes
