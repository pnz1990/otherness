# Spec: Scheduled execution workflow + config fields

> Items: 321, 322, 323 | Created: 2026-04-19 | Status: Active

## Design reference
- **Design doc**: `docs/design/19-scheduled-execution.md`
- **Implements**: workflow file + config schema + config template (🔲 → ✅)

---

## Zone 1 — Obligations

**O1 — `.github/workflows/otherness-scheduled.yml` exists with schedule trigger.**
Uses `anomalyco/opencode/github@latest`. Permissions: `contents: write`,
`pull-requests: write`, `issues: write`. Includes `workflow_dispatch`. Default
cron: every 6 hours. Prompt is the standard `standalone.md` invocation.

**O2 — `otherness-config.yaml` has `schedule.cron` and `schedule.model` fields.**
Under a new `schedule:` top-level section. Both fields are optional — the workflow
uses the config if present, defaults if absent.

**O3 — `otherness-config-template.yaml` has the `schedule` section added.**
Commented out by default. Includes `cron`, `model`, and `api_key_secret` fields.

**O4 — validate.sh passes after these changes.**

---

## Zone 2 — Implementer's judgment

- Model: use `amazon-bedrock/global.anthropic.claude-sonnet-4-6` as default
  (matches the current manual session model). Override via `schedule.model` in config.
- The `ANTHROPIC_API_KEY` secret name is documented in config but must be set
  by the human — the agent cannot create GitHub secrets.
- The `~/.otherness` clone step uses HTTPS (no auth needed — public repo).

---

## Zone 3 — Scoped out

- Creating the GitHub secret automatically
- Multiple schedule triggers per project
- Cost budgeting / token limits per run
