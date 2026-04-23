# spec: feat(observability) — AWS observability backend + OTLP wiring (issue-817)

## Design reference

- **Design doc**: `docs/design/44-otlp-observability.md`
- **Section**: `§ Future` items 44.1–44.5
- **Issue**: https://github.com/pnz1990/otherness/issues/817
- **Status**: in_progress

---

## Zone 1 — Obligations (from design doc 44)

**O1** All infrastructure in AWS account `569190534191`. No new AWS accounts.

**O2** Shared backend; per-project data tagged and filterable by `project=<repo>`.

**O3** All resources tagged: `Owner=otherness`, `Purpose=observability`, `ManagedBy=otherness-agent`.

**O4** Zero new secrets required beyond `AMP_REMOTE_WRITE_ENDPOINT`. Auth via existing OIDC role.

**O5** AMG workspace uses GitHub OAuth. No IAM users.

**O6** Cost: X-Ray free tier + AMP free tier + AMG ~$9/mo. Estimated <$10/month for 3 projects.

**O7** All three project workflows updated to enable OTLP when `backend: aws-xray` configured.

---

## Zone 1 — Implementation obligations

**I1 — infra/observability/**: Terraform module creating:
- AMP workspace (`aws_prometheus_workspace`)
- AMG workspace (`aws_grafana_workspace`) with GitHub OAuth
- IAM policy document adding X-Ray + AMP permissions to existing OIDC role

**I2 — otherness-config-template.yaml §44.1**: Formalize `observability.otlp` section (currently commented-out stub). Add `amp_endpoint_secret` key. Zero config = zero telemetry default preserved.

**I3 — otherness-scheduled.yml §44.2–44.4**:
- Step A/B: read `observability.otlp.enabled`; if true + backend=aws-xray: inject `experimental.openTelemetry: true` into opencode config and set `OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318`
- Add ADOT sidecar container step (SHA-pinned) before agent steps when `backend: aws-xray`
- Set `OTEL_RESOURCE_ATTRIBUTES` with project/session/step

**I4 — docs/observability.md §44.5**: User-facing guide: setup instructions per backend, example Grafana dashboard JSON (session duration, token/hour), example queries.

---

## Zone 2 — Implementer's judgment

- Terraform uses AWS provider ~> 5.0. No remote state (project owner applies manually).
- ADOT collector image SHA-pinned per design doc 27 §M1.
- Workflow changes use `if: ${{ vars.OTHERNESS_OTLP_ENABLED == 'true' }}` as the gate — no config file parsing in the workflow itself (keeps it simple and explicit).
- AMG requires a VPC in some regions; use `account_access_type = "CURRENT_ACCOUNT"` and `authentication_providers = ["AWS_SSO"]` with GitHub IdP federation — simpler than a VPC setup.

---

## Acceptance criteria (from issue-817)

- [ ] `infra/observability/` contains valid Terraform (`terraform validate` passes)
- [ ] `otherness-config-template.yaml` `observability.otlp` section documented and uncommented
- [ ] `otherness-scheduled.yml` injects OTEL config when `OTHERNESS_OTLP_ENABLED=true`
- [ ] ADOT sidecar step present, SHA-pinned
- [ ] `docs/observability.md` exists with setup instructions for aws-xray backend
- [ ] `scripts/validate.sh` still passes
