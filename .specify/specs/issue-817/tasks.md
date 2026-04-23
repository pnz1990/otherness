# tasks: issue-817 — AWS observability backend + OTLP wiring

## Task list

- [x] [CMD] Create `.specify/specs/issue-817/spec.md` and `tasks.md`
- [ ] [CMD] Create `infra/observability/` directory
- [ ] [AI]  Write `infra/observability/main.tf` — AMP workspace, AMG workspace, IAM policy additions
- [ ] [AI]  Write `infra/observability/outputs.tf` — AMP endpoint, AMG workspace URL
- [ ] [AI]  Write `infra/observability/variables.tf` — oidc_role_name, aws_region, tags
- [ ] [AI]  Write `infra/observability/README.md` — apply instructions, new project onboarding
- [ ] [AI]  Update `otherness-config-template.yaml` — formalize `observability.otlp` section (44.1)
- [ ] [AI]  Update `otherness-scheduled.yml` — ADOT sidecar step + OTEL env vars (44.2–44.4)
- [ ] [AI]  Write `docs/observability.md` — user guide (44.5)
- [ ] [CMD] Run `bash scripts/validate.sh` — must pass
- [ ] [CMD] Run `bash scripts/lint.sh` — must pass
- [ ] [CMD] Commit all changes
- [ ] [CMD] Open PR with design doc references
