# Spec: issue-637 — Onboarding End-to-End Smoke Test

## Design reference
- **Design doc**: `docs/design/32-stage-3-onboarding-quality.md`
- **Section**: `§ Future`
- **Implements**: End-to-end onboarding smoke test (🔲 → ✅)

---

## Zone 1 — Obligations

**O1** — `scripts/check-onboarding.sh` adds a Check 5 that validates all prerequisites for a clean first `/otherness.run`, beyond structural docs checks. Check 5 must include:
- `report_issue` in `otherness-config.yaml` is a real integer (not `TBD` or empty)
- `otherness-config.yaml` `autonomous_mode` is explicitly set (not absent)
- GitHub labels `kind/enhancement`, `kind/bug`, `otherness`, `needs-human` exist in the repo (verified via `gh label list`)
- `REPORT_ISSUE` in `AGENTS.md` is a real integer

**O2** — `agents/onboard.md` STEP 8 (final verification) explicitly calls `bash scripts/check-onboarding.sh` and fails if it exits non-zero.

**O3** — `agents/onboard.md` documents the post-onboarding verification instruction: "Run `/otherness.run`; confirm the first batch opens ≥1 PR before declaring onboarding complete."

**O4** — `scripts/check-onboarding.sh` exits 0 on the current `pnz1990/otherness` repo (self-check must pass).

**O5** — Check 5 label verification is skipped with a WARN (not ERROR) if `gh` CLI is not authenticated or `REPO` env var is not set, so the script can run in offline/CI contexts that lack GH credentials.

---

## Zone 2 — Implementer's judgment

- Check 5 is ordered after Check 4 (config sections) and labeled `[5/5]`.
- Label check uses `gh label list --repo $REPO --json name --jq '[.[].name]'` and checks for membership.
- The "first run instruction" in onboard.md STEP 8 is a text note, not a blocking gate (the agent cannot actually run a remote session).
- `check-onboarding.sh` total check count in the header comment is updated to 5.

---

## Zone 3 — Scoped out

- Actually running `/otherness.run` in CI (not feasible without a full agent runtime)
- Checking CI workflow files during onboarding
- Verifying `_state` branch exists (it's bootstrapped on first write, so absence is normal)
