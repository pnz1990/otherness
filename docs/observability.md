# Observability — Session Telemetry, Cost, and Fleet Health

> Design doc: [docs/design/44-otlp-observability.md](../docs/design/44-otlp-observability.md)

otherness emits structured telemetry across four layers. All layers are **opt-in**.
Zero config = zero telemetry. No otherness-hosted backend. Your data stays in your infrastructure.

---

## The four-layer model

| Layer | What it tracks | Where it goes |
|---|---|---|
| **1 — Session telemetry** | Per-LLM-call spans, per-tool spans, token counts | OTLP → X-Ray, Grafana, Prometheus |
| **2 — Security audit log** | Every git push, PR merge, branch protection change | S3, CloudWatch Logs, or stdout |
| **3 — Cost governance** | Token spend, budget alerts, session cost estimates | `state.json` + report issue |
| **4 — Fleet intelligence** | Cross-project health, comparative velocity, stall risk | `_state` branch snapshot |

This guide covers **Layer 1 (session telemetry)** setup with the recommended AWS stack.
Layers 2–4 are configured separately in `otherness-config.yaml` — see design doc 44 for details.

---

## Layer 1: Session telemetry (OTLP)

### What you get

OpenCode exports AI SDK telemetry spans. Each run produces:

| Signal | What you learn |
|---|---|
| `ai.generateText` span | LLM call latency, input/output token counts, finish reason |
| `ai.toolCall` span | Which tools are slow? `gh api` rate waits, large file reads |
| Session root span | Total duration, step (vision-scan vs run), batch number |
| Token rate (derived) | Input + output tokens per session, per step, per model |

### Recommended AWS stack (zero new secrets beyond `AMP_REMOTE_WRITE_ENDPOINT`)

```
OpenCode session
  ├── OTLP traces  ──→ ADOT collector ──→ AWS X-Ray
  └── OTLP metrics ──→ ADOT collector ──→ Amazon Managed Prometheus (AMP)
                                          └── Amazon Managed Grafana (AMG)
```

**Auth**: The existing OIDC role (used for Bedrock) is extended with X-Ray and AMP emit permissions.
No new IAM roles. No long-lived credentials.

---

## Setup: AWS backend (recommended)

### Step 1: Deploy the observability infrastructure

```bash
cd infra/observability

# Plan
terraform plan -var="oidc_role_name=<your-bedrock-oidc-role-name>"

# Apply — creates AMP workspace, AMG workspace, and IAM policy extensions
terraform apply -var="oidc_role_name=<your-bedrock-oidc-role-name>"
```

**Getting your OIDC role name**: it's the role referenced by `secrets.AWS_ROLE_ARN` in your workflow.
Extract the role name from the ARN: `arn:aws:iam::569190534191:role/my-role-name` → `my-role-name`.

### Step 2: Set the GitHub secret

```bash
# Get the AMP remote write endpoint from Terraform output
terraform output amp_remote_write_endpoint

# Set as a secret on each managed project
gh secret set AMP_REMOTE_WRITE_ENDPOINT --body "<endpoint>" --repo owner/your-project
```

### Step 3: Enable OTLP in `otherness-config.yaml`

```yaml
observability:
  otlp:
    enabled: true
    backend: aws-xray
    service_name: otherness
    amp_endpoint_secret: AMP_REMOTE_WRITE_ENDPOINT
```

### Step 4: Set the repository variable

In GitHub → Settings → Variables → Actions:
```
OTHERNESS_OTLP_ENABLED = true
```

This gates the ADOT sidecar step and OTEL env injection in the workflow.

### Step 5: Verify

After the next scheduled run, check:
```bash
# X-Ray: look for traces from your service
aws xray get-trace-summaries --start-time $(date -d '1 hour ago' +%s) --end-time $(date +%s) --region us-east-1

# AMP: check metrics are flowing
aws amp query-metrics --workspace-id <workspace-id> --query 'up{service="otherness"}' --region us-east-1
```

---

## Setup: Other backends

### Grafana Cloud

```yaml
observability:
  otlp:
    enabled: true
    backend: grafana
    service_name: otherness
    endpoint_secret: OTEL_EXPORTER_OTLP_ENDPOINT    # secret → https://otlp-gateway-prod-us-central-0.grafana.net/otlp
    headers_secret: OTEL_EXPORTER_OTLP_HEADERS       # secret → "Authorization=Bearer <grafana-token>"
```

### Self-hosted Prometheus + Jaeger

```yaml
observability:
  otlp:
    enabled: true
    backend: prometheus
    service_name: otherness
    endpoint_secret: OTEL_EXPORTER_OTLP_ENDPOINT    # secret → http://your-collector:4318
```

### Custom OTLP endpoint

Any OTLP-compatible backend (Honeycomb, Datadog, Jaeger, etc.):

```yaml
observability:
  otlp:
    enabled: true
    backend: custom
    service_name: otherness
    endpoint_secret: OTEL_EXPORTER_OTLP_ENDPOINT
    headers_secret: OTEL_EXPORTER_OTLP_HEADERS
```

---

## Grafana dashboards

### Import pre-built dashboards

Once AMG is running, import these dashboards from the Grafana UI (Dashboards → Import):

**Session duration histogram** — paste this JSON:

```json
{
  "title": "otherness — Session Duration",
  "panels": [{
    "type": "histogram",
    "title": "Session duration p50/p95/p99",
    "targets": [{
      "expr": "histogram_quantile(0.95, sum(rate(ai_generate_text_duration_ms_bucket{service=\"otherness\"}[1h])) by (le, project))",
      "legendFormat": "p95 {{project}}"
    }]
  }]
}
```

**Token usage per project per day:**

```promql
sum by (project) (
  increase(ai_generate_text_input_tokens_total{service="otherness"}[1d])
)
```

**Most expensive sessions (top 10):**

```promql
topk(10,
  sum by (session_id, project) (
    ai_generate_text_input_tokens_total{service="otherness"} * 0.000003
    + ai_generate_text_output_tokens_total{service="otherness"} * 0.000015
  )
)
```

**Slowest tool calls (p99):**

```promql
histogram_quantile(0.99,
  sum by (le, tool_name) (
    rate(ai_tool_call_duration_ms_bucket{service="otherness"}[1h])
  )
)
```

---

## Resource attributes

Every span is tagged with:

| Attribute | Value | Example |
|---|---|---|
| `service.name` | From `observability.otlp.service_name` | `otherness` |
| `project` | `github.repository` | `pnz1990/otherness` |
| `step` | Workflow step: `A-vision-scan` or `B-run` | `B-run` |

Use `project=<repo>` to filter dashboards to a specific managed project.

---

## Cost estimate (3 projects)

| Service | Monthly usage | Cost |
|---|---|---|
| AWS X-Ray | ~10K traces/month | Free (100K/month free tier) |
| Amazon Managed Prometheus | ~1M samples/month | Free (10M/month free tier) |
| Amazon Managed Grafana | 1 workspace | ~$9/month (1 active editor) |
| **Total** | | **~$9/month** |

---

## Troubleshooting

**No traces in X-Ray:**
1. Check ADOT sidecar logs: `docker logs adot-sidecar` in the workflow run
2. Verify OIDC role has `xray:PutTraceSegments` permission: `aws xray put-trace-segments --help`
3. Check `OTHERNESS_OTLP_ENABLED` is set to `true` in repository variables (not secrets)

**No metrics in AMP:**
1. Verify `AMP_REMOTE_WRITE_ENDPOINT` secret is set (not a variable — it's a secret)
2. Check OIDC role has `aps:RemoteWrite` permission on the AMP workspace ARN
3. Verify AMP workspace is in the same region as the workflow (`us-east-1` by default)

**ADOT sidecar fails to start (non-blocking):**
- Workflow continues regardless — telemetry is non-blocking per design doc 44 §O5
- Check runner has Docker available (`runs-on: ubuntu-latest` does)
- The ADOT container image pull may fail on first run — retry is automatic on next run

**OTEL env vars are empty:**
- Verify `OTHERNESS_OTLP_ENABLED` is a repository **variable** (not a secret — secrets can't be used in `if:` expressions)
- Setting location: Settings → Secrets and variables → Actions → Variables tab
