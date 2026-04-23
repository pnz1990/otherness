# infra/observability — AWS observability backend for otherness

Deploys the shared observability backend for all otherness-managed projects:

- **Amazon Managed Prometheus (AMP)** — remote write endpoint for OTLP metrics
- **Amazon Managed Grafana (AMG)** — unified dashboard (session telemetry, token cost, fleet health)
- **IAM policy additions** — extends the existing Bedrock OIDC role with X-Ray + AMP emit permissions

AWS account: `569190534191`  
All resources tagged: `Owner=otherness`, `Purpose=observability`, `ManagedBy=otherness-agent`

---

## Prerequisites

- AWS CLI configured for account `569190534191`
- Terraform >= 1.5 installed
- The Bedrock OIDC role name (from `secrets.AWS_ROLE_ARN` or `otherness-config.yaml → ci.github_actions.role_arn`)

---

## First-time apply

```bash
cd infra/observability

# Initialize Terraform
terraform init

# Plan — review before applying
terraform plan -var="oidc_role_name=<your-oidc-role-name>"

# Apply — creates AMP workspace, AMG workspace, and IAM policy additions
terraform apply -var="oidc_role_name=<your-oidc-role-name>"
```

**Getting your OIDC role name:**
```bash
aws sts get-caller-identity
# Or: extract from AWS_ROLE_ARN secret — the part after the last '/' before the next '/'
```

---

## After apply: set the GitHub secret

Copy `amp_remote_write_endpoint` from Terraform output:
```bash
terraform output amp_remote_write_endpoint
```

Add as a GitHub Actions secret named `AMP_REMOTE_WRITE_ENDPOINT` on each managed project:
```bash
gh secret set AMP_REMOTE_WRITE_ENDPOINT --body "<endpoint>" --repo pnz1990/otherness
gh secret set AMP_REMOTE_WRITE_ENDPOINT --body "<endpoint>" --repo pnz1990/kardinal-promoter
gh secret set AMP_REMOTE_WRITE_ENDPOINT --body "<endpoint>" --repo pnz1990/kro-ui
```

---

## Enable OTLP on each managed project

In each project's `otherness-config.yaml`:
```yaml
observability:
  otlp:
    enabled: true
    backend: aws-xray
    service_name: otherness
    amp_endpoint_secret: AMP_REMOTE_WRITE_ENDPOINT
```

In each project's GitHub repository settings → Variables:
```
OTHERNESS_OTLP_ENABLED = true
```

---

## GitHub OAuth setup for Grafana (post-apply)

1. Open the Grafana workspace URL: `terraform output amg_workspace_url`
2. Go to **Configuration → Authentication → SAML**
3. Configure GitHub as your SAML IdP using GitHub Enterprise Cloud or GitHub OAuth App
4. Alternatively: use AWS IAM Identity Center (SSO) with GitHub as the external IdP

> Note: AMG native GitHub OAuth is available in `authentication_providers = ["AWS_SSO"]` mode.
> The current Terraform uses SAML mode for flexibility. If you have AWS IAM Identity Center
> configured with GitHub, switch `authentication_providers = ["AWS_SSO"]` in main.tf.

---

## Adding a new project

1. Enable OTLP in the project's `otherness-config.yaml` (see above)
2. Set `OTHERNESS_OTLP_ENABLED = true` as a repository variable
3. Add the `AMP_REMOTE_WRITE_ENDPOINT` secret
4. No Terraform changes needed — the backend is shared

---

## Cost estimate (3 projects, current session volumes)

| Service | Usage | Cost |
|---|---|---|
| X-Ray | ~10K traces/month | Free tier (100K/month) |
| AMP | ~1M samples/month | Free tier (10M/month) |
| AMG | 1 workspace, 1 active editor | ~$9/month |
| **Total** | | **~$9/month** |

---

## Re-applying (idempotent)

```bash
terraform apply -var="oidc_role_name=<your-oidc-role-name>"
```

Terraform will detect no changes if nothing has drifted. Safe to run on every deployment.

---

## Destroying (cleanup)

```bash
terraform destroy -var="oidc_role_name=<your-oidc-role-name>"
```

This removes the AMP workspace, AMG workspace, Grafana service role, and inline IAM policy.
It does **not** remove the existing OIDC Bedrock role.
