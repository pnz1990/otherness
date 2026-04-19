# Spec: validate.sh check + setup/onboard integration

> Items: 324, 325 | Created: 2026-04-19 | Status: Active

## Design reference
- **Design doc**: `docs/design/19-scheduled-execution.md`
- **Implements**: validate.sh check + setup/onboard deploy step (🔲 → ✅)

---

## Zone 1 — Obligations

**O1 — validate.sh checks that `.github/workflows/otherness-scheduled.yml` exists when `schedule.cron` is set in config.**
If `otherness-config.yaml` has a `schedule.cron` field with a non-empty value, and
`.github/workflows/otherness-scheduled.yml` does not exist, validate.sh fails with a
clear message: "schedule.cron is set but .github/workflows/otherness-scheduled.yml is missing."

**O2 — `/otherness.setup` includes a step to deploy the scheduled workflow.**
The setup command file adds a step: "If the user wants scheduled runs: add
`ANTHROPIC_API_KEY` to GitHub repo Secrets, and uncomment the `schedule:` section
in `otherness-config.yaml`." The workflow file already exists (deployed by PR #326)
so no additional file creation is needed.

**O3 — `/otherness.onboard` references the scheduled workflow in its setup instructions.**
The onboard command mentions that after onboarding, the human can activate scheduled
runs by setting up the GitHub secret.

**O4 — Design doc 19 marks these items ✅ Present.**

---

## Zone 2 — Implementer's judgment

- validate.sh change: LOW tier (scripts/). Add a new optional check at the end,
  only runs when schedule.cron is set in config.
- setup/onboard changes: LOW tier (command files in .opencode/command/).
  Brief additions — not full rewrites.

---

## Zone 3 — Scoped out

- Automatically creating the GitHub secret (impossible — needs PAT with secrets scope)
- Validating the cron expression format
